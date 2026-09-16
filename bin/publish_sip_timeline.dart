import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_ari/ari/homer/homer_client.dart';
import 'package:dart_ari/ari/homer/sip_timeline.dart';
import 'package:dotenv/dotenv.dart';
import 'package:eloquent/eloquent.dart';

/// SIP-timeline publisher: watches `PUBLISH_SIDECARS_DIR` (default:
/// `ENRICHED_DIR`, falls back to `RECORDINGS_DIR`) for JSON sidecars
/// that already carry a `legs[]` array (produced by
/// `bin/enrich_from_homer.dart`), reloads every SIP message for those
/// legs from Homer TimescaleDB, reduces them to a per-call timeline
/// (invite / ringing / answered / bye / cancel / who-hung-up), and
/// upserts one row per call into the Laravel dashboard's
/// `recording_sip_timeline` MySQL table.
///
/// Column mapping (see the CCIVRDashboard migration for the schema):
///   recording_id          <- lookup: recordings.file_name = <daemon_basename>.<ext>
///   caller_number         <- sidecar.src
///   callee_extension      <- sidecar.dst, normalised ("PJSIP/3636@mytrunk" -> "3636")
///   primary_sip_call_id   <- Call-ID of the caller-facing dialog
///   invite_at, ringing_at, answered_at, bye_at, cancel_at,
///   terminated_at, hangup_initiator, hangup_method,
///   hangup_status_code    <- SipTimeline.reduce()
///   caller_user_agent     <- user-agent of primary leg
///   callee_user_agent     <- user-agent of the leg to the agent extension
///   caller_media_ip/port  <- SDP c=IN IP4 / m=audio of primary leg
///   callee_media_ip/port  <- SDP of agent leg
///   leg_count             <- sidecar['legs'].length
///   legs (JSON)           <- verbatim sidecar['legs'] + is_primary/is_agent
///   events (JSON)         <- first N request/response lines of primary leg
///
/// Idempotency: `recording_id` is UNIQUE. Existing rows are UPDATEd.
///
/// Env:
///   PUBLISH_SIDECARS_DIR        (default: ENRICHED_DIR or RECORDINGS_DIR)
///   PUBLISH_AUDIO_EXT           (default: wav) — resolves audio file
///                                name for the stasis_cdr lookup
///   TIMELINE_POLL_SECS          (default: 30)
///   TIMELINE_LOOKBACK_MINUTES   (default: 120)
///   TIMELINE_EVENT_LIMIT        (default: 100) — cap for `events[]` blob
///
///   HOMER_PG_HOST/PORT/DB/USER/PASS         (same as enrich_from_homer)
///
///   DASHBOARD_MYSQL_HOST/PORT/DB/USER/PASSWORD  (falls back to AST_DB_*)
///   DASHBOARD_MYSQL_POOL_SIZE   (default: 3)
///
/// Flags:
///   --once       run one scan and exit (for cron)
///   --backfill   ignore TIMELINE_LOOKBACK_MINUTES; process everything
///   --refresh    re-process sidecars even if a timeline row exists
///   --dry-run    log what would be inserted/updated; write nothing

Future<void> main(List<String> args) async {
  final env = DotEnv(includePlatformEnvironment: true)..load();
  final once = args.contains('--once');
  final backfill = args.contains('--backfill');
  final refresh = args.contains('--refresh');
  final dryRun = args.contains('--dry-run');

  final inputDirPath =
      env['PUBLISH_SIDECARS_DIR'] ??
      env['ENRICHED_DIR'] ??
      env['RECORDINGS_DIR'] ??
      './recordings_enriched';
  final inputDir = Directory(inputDirPath);
  if (!inputDir.existsSync()) {
    stderr.writeln('input dir does not exist: ${inputDir.path}');
    exit(2);
  }

  final audioExt = env['PUBLISH_AUDIO_EXT'] ?? 'wav';
  final poll = Duration(seconds: int.parse(env['TIMELINE_POLL_SECS'] ?? '30'));
  final lookback = backfill
      ? const Duration(days: 3650)
      : Duration(minutes: int.parse(env['TIMELINE_LOOKBACK_MINUTES'] ?? '120'));
  final eventLimit = int.parse(env['TIMELINE_EVENT_LIMIT'] ?? '100');

  final homer = HomerClient(
    host: _require(env, 'HOMER_PG_HOST'),
    port: int.parse(env['HOMER_PG_PORT'] ?? '5432'),
    database: env['HOMER_PG_DB'] ?? 'homer_data',
    username: env['HOMER_PG_USER'] ?? 'root',
    password: _require(env, 'HOMER_PG_PASS'),
  );

  final mysqlHost = env['DASHBOARD_MYSQL_HOST'] ?? env['AST_DB_HOST'];
  final mysqlPort = env['DASHBOARD_MYSQL_PORT'] ?? env['AST_DB_PORT'] ?? '3306';
  final mysqlDb = env['DASHBOARD_MYSQL_DB'] ?? env['AST_DB_DATABASE'];
  final mysqlUser = env['DASHBOARD_MYSQL_USER'] ?? env['AST_DB_USERNAME'];
  final mysqlPass =
      env['DASHBOARD_MYSQL_PASSWORD'] ?? env['AST_DB_PASSWORD'] ?? '';
  final poolSize = env['DASHBOARD_MYSQL_POOL_SIZE'] ?? '3';
  if (mysqlHost == null || mysqlDb == null || mysqlUser == null) {
    stderr.writeln('missing DASHBOARD_MYSQL_* (or AST_DB_*) env vars');
    exit(2);
  }

  final manager = Manager();
  manager.addConnection({
    'driver': 'mysql',
    'host': mysqlHost,
    'port': mysqlPort,
    'database': mysqlDb,
    'username': mysqlUser,
    'password': mysqlPass,
    'pool': 'true',
    'poolsize': poolSize,
    'allowreconnect': 'true',
    'application_name': 'publish_sip_timeline',
  });
  manager.setAsGlobal();
  final db = await manager.connection();

  print(
    '[timeline] input=${inputDir.path} ext=$audioExt '
    'mysql=$mysqlUser@$mysqlHost:$mysqlPort/$mysqlDb '
    'homer=${homer.host} poll=${poll.inSeconds}s '
    'lookback=${lookback.inMinutes}m refresh=$refresh dry_run=$dryRun',
  );

  ProcessSignal.sigint.watch().listen((_) async {
    print('[timeline] shutting down');
    try {
      await db.disconnect();
    } catch (_) {}
    await homer.close();
    exit(0);
  });

  while (true) {
    try {
      await _scan(
        inputDir,
        audioExt,
        lookback,
        eventLimit,
        homer,
        db,
        refresh: refresh,
        dryRun: dryRun,
      );
    } catch (e, st) {
      print('[timeline] scan error: $e\n$st');
    }
    if (once) break;
    await Future.delayed(poll);
  }
  try {
    await db.disconnect();
  } catch (_) {}
  await homer.close();
}

Future<void> _scan(
  Directory inputDir,
  String audioExt,
  Duration lookback,
  int eventLimit,
  HomerClient homer,
  Connection db, {
  required bool refresh,
  required bool dryRun,
}) async {
  final cutoff = DateTime.now().toUtc().subtract(lookback);
  final files = inputDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .where((f) => f.statSync().modified.toUtc().isAfter(cutoff))
      .toList();

  for (final file in files) {
    await _publishOne(
      file,
      audioExt,
      eventLimit,
      homer,
      db,
      refresh: refresh,
      dryRun: dryRun,
    );
  }
}

Future<void> _publishOne(
  File file,
  String audioExt,
  int eventLimit,
  HomerClient homer,
  Connection db, {
  required bool refresh,
  required bool dryRun,
}) async {
  final baseName = file.uri.pathSegments.last;

  Map<String, dynamic> sidecar;
  try {
    sidecar = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  } catch (e) {
    print('[timeline] skip $baseName: bad JSON ($e)');
    return;
  }

  // Must have been enriched (has `legs[]`) — otherwise there's nothing
  // for us to pull a timeline from. enrich_from_homer.dart writes this
  // key only once it decides the sidecar is final.
  final legsRaw = sidecar['legs'];
  if (legsRaw is! List || legsRaw.isEmpty) {
    return;
  }

  final stem =
      _s(sidecar['daemon_basename']) ?? _s(sidecar['ip_tagged_basename']);
  if (stem == null) {
    print('[timeline] skip $baseName: no daemon_basename / ip_tagged_basename');
    return;
  }
  final fileName = '$stem.$audioExt';

  // Match to the recordings row (populated by publish_to_mysql.dart).
  // file_name is the natural key.
  final rec = await db
      .table('recordings')
      .where('file_name', '=', fileName)
      .select(['id', 'src', 'dst'])
      .limit(1)
      .get();
  if (rec.isEmpty) {
    print(
      '[timeline] skip $baseName: no recordings row for $fileName '
      '(publish_to_mysql may not have caught up yet)',
    );
    return;
  }
  final recordingId = rec.first['id'];
  final callerNumber = _s(rec.first['src']) ?? _s(sidecar['src']);
  final calleeExtension = _normalizeUser(
    _s(rec.first['dst']) ?? _s(sidecar['dst']),
  );

  if (!refresh) {
    final existing = await db
        .table('recording_sip_timeline')
        .where('recording_id', '=', recordingId)
        .select(['id'])
        .limit(1)
        .get();
    if (existing.isNotEmpty) return;
  }

  // Time window: reuse the sidecar's own timestamps with slack on
  // both sides. Sidecar times are ISO-UTC.
  final calldate =
      DateTime.tryParse(_s(sidecar['calldate']) ?? '')?.toUtc() ??
      DateTime.now().toUtc().subtract(const Duration(hours: 1));
  final hangupdate =
      DateTime.tryParse(_s(sidecar['hangupdate']) ?? '')?.toUtc() ??
      calldate.add(const Duration(minutes: 30));
  final from = calldate.subtract(const Duration(seconds: 30));
  final to = hangupdate.add(const Duration(seconds: 30));

  final sids = <String>[
    for (final l in legsRaw)
      if (l is Map && l['callid'] is String) l['callid'] as String,
  ];
  if (sids.isEmpty) return;

  final messagesBySid = await homer.loadMessagesForSids(
    sids,
    from: from,
    to: to,
  );

  // Pick the primary leg (customer → system) — the one whose from_user
  // suffix-matches the sidecar's `src` phone number. Fall back to the
  // first leg if no match.
  final srcSuffix = _phoneSuffix(_s(sidecar['src']) ?? '');
  Map<String, dynamic>? primaryLeg;
  for (final l in legsRaw) {
    if (l is! Map) continue;
    final fu = _s(l['from_user']);
    if (srcSuffix != null && fu != null && fu.contains(srcSuffix)) {
      primaryLeg = Map<String, dynamic>.from(l);
      break;
    }
  }
  primaryLeg ??= Map<String, dynamic>.from(legsRaw.first as Map);

  // Pick the agent leg (to the extension). Same normalize as HomerClient.
  Map<String, dynamic>? agentLeg;
  if (calleeExtension != null) {
    for (final l in legsRaw) {
      if (l is! Map) continue;
      if (_s(l['to_user']) == calleeExtension) {
        agentLeg = Map<String, dynamic>.from(l);
        break;
      }
    }
  }

  final primaryMessages = messagesBySid[primaryLeg['callid']] ?? const [];
  if (primaryMessages.isEmpty) {
    print(
      '[timeline] skip $baseName: no Homer messages for primary sid '
      '${primaryLeg['callid']}',
    );
    return;
  }

  // Media anchor prefixes: SDP c=IN IP4 in these ranges means media is
  // still on infrastructure (OXE B2BUA at 10.1.8.x, or Asterisk itself at
  // 10.1.101.x) and has NOT reached a real agent phone. Same set as
  // PUBLISH_AGENT_IP_EXCLUDE, which agent_phone_ip already uses.
  final mediaAnchorPrefixes =
      (Platform.environment['TIMELINE_MEDIA_ANCHOR_PREFIXES'] ??
              Platform.environment['PUBLISH_AGENT_IP_EXCLUDE'] ??
              '10.1.8.,10.1.101.')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

  final timeline = SipTimeline.reduce(
    primaryMessages,
    callerFromUser: _s(primaryLeg['from_user']),
    customerNumber: callerNumber,
    mediaAnchorPrefixes: mediaAnchorPrefixes,
  );

  final primarySdp = _extractSdp(primaryLeg['sdp']);
  final agentSdp = _extractSdp(agentLeg?['sdp']);

  // Business-meaning agent phone IP: first SDP IP across all legs that
  // isn't in the B2BUA / Asterisk anchor range. Same convention as
  // publish_to_mysql.dart's PUBLISH_AGENT_IP_EXCLUDE.
  final excludePrefixes =
      (Platform.environment['PUBLISH_AGENT_IP_EXCLUDE'] ?? '10.1.8.,10.1.101.')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
  final agentPhoneIp = _pickAgentIp(legsRaw, excludePrefixes);

  final legsBlob = <Map<String, dynamic>>[
    for (final l in legsRaw)
      if (l is Map)
        {
          ...l.map((k, v) => MapEntry(k.toString(), v)),
          'is_primary': l['callid'] == primaryLeg['callid'],
          'is_agent': agentLeg != null && l['callid'] == agentLeg['callid'],
        },
  ];

  final eventFlow = primaryMessages
      .take(eventLimit)
      .map(
        (m) => {
          'ts': m.createDate.toIso8601String(),
          'method': m.method,
          'from_user': m.fromUser,
          'to_user': m.toUser,
          'cseq': m.cseq,
          // SDP media IP (c=IN IP4 …) so the anchor→agent switch is visible.
          if (m.sdp?.ip != null) 'ip': m.sdp!.ip,
        },
      )
      .toList();

  final now = _mysqlNow();
  final row = <String, dynamic>{
    'recording_id': recordingId,
    'caller_number': callerNumber,
    'callee_extension': calleeExtension,
    'primary_sip_call_id': primaryLeg['callid'],
    'invite_at': _mysqlTs(timeline.inviteAt),
    'ringing_at': _mysqlTs(timeline.ringingAt),
    'answered_at': _mysqlTs(timeline.answeredAt),
    'agent_answered_at': _mysqlTs(timeline.agentAnsweredAt),
    'bye_at': _mysqlTs(timeline.byeAt),
    'cancel_at': _mysqlTs(timeline.cancelAt),
    'terminated_at': _mysqlTs(timeline.terminatedAt),
    'hangup_initiator': timeline.hangupInitiator,
    'hangup_method': timeline.hangupMethod,
    'hangup_status_code': timeline.hangupStatusCode,
    'hangup_by': timeline.hangupBy,
    'caller_user_agent': _s(primaryLeg['user_agent']),
    'callee_user_agent': _s(agentLeg?['user_agent']),
    'caller_media_ip': primarySdp?['ip'],
    'caller_media_port': primarySdp?['port'],
    'callee_media_ip': agentSdp?['ip'],
    'callee_media_port': agentSdp?['port'],
    'agent_phone_ip': agentPhoneIp,
    'leg_count': legsRaw.length,
    'legs': jsonEncode(legsBlob),
    'events': jsonEncode(eventFlow),
    'updated_at': now,
  };

  final existing = await db
      .table('recording_sip_timeline')
      .where('recording_id', '=', recordingId)
      .select(['id'])
      .limit(1)
      .get();

  if (existing.isNotEmpty) {
    if (dryRun) {
      print(
        '[timeline]   would UPDATE rec=$recordingId '
        'initiator=${timeline.hangupInitiator} method=${timeline.hangupMethod}',
      );
      return;
    }
    await db
        .table('recording_sip_timeline')
        .where('id', '=', existing.first['id'])
        .update(row);
    print(
      '[timeline]   UPDATE rec=$recordingId '
      'initiator=${timeline.hangupInitiator} '
      'method=${timeline.hangupMethod} '
      'code=${timeline.hangupStatusCode}',
    );
    return;
  }

  row['created_at'] = now;
  if (dryRun) {
    print(
      '[timeline]   would INSERT rec=$recordingId '
      'initiator=${timeline.hangupInitiator} '
      'method=${timeline.hangupMethod}',
    );
    return;
  }
  await db.table('recording_sip_timeline').insert(row);
  print(
    '[timeline]   INSERT rec=$recordingId '
    'initiator=${timeline.hangupInitiator} '
    'method=${timeline.hangupMethod} '
    'code=${timeline.hangupStatusCode} legs=${legsRaw.length}',
  );
}

Map<String, dynamic>? _extractSdp(Object? raw) {
  if (raw is! Map) return null;
  final ip = raw['ip'];
  final port = raw['port'];
  if (ip == null && port == null) return null;
  return {
    if (ip is String && ip.isNotEmpty) 'ip': ip,
    if (port is int) 'port': port,
    if (port is String) 'port': int.tryParse(port),
  };
}

/// Return the first SDP IP across all [legsRaw] that does NOT start with
/// any of [excludePrefixes] — i.e. the real phone IP behind a B2BUA.
String? _pickAgentIp(Object? legsRaw, List<String> excludePrefixes) {
  if (legsRaw is! List) return null;
  for (final leg in legsRaw) {
    if (leg is! Map) continue;
    final sdp = leg['sdp'];
    if (sdp is! Map) continue;
    final ip = sdp['ip'];
    if (ip is! String || ip.isEmpty) continue;
    if (excludePrefixes.any(ip.startsWith)) continue;
    return ip;
  }
  return null;
}

/// Sidecar `dst` is stored as the ARI endpoint ("PJSIP/3636@mytrunk").
/// Homer stores just the user part ("3636").
String? _normalizeUser(String? v) {
  if (v == null || v.isEmpty) return v;
  var s = v;
  final slash = s.indexOf('/');
  if (slash >= 0) s = s.substring(slash + 1);
  final at = s.indexOf('@');
  if (at >= 0) s = s.substring(0, at);
  return s;
}

String? _phoneSuffix(String v) {
  final digits = v.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 7) return null;
  return digits.length <= 9 ? digits : digits.substring(digits.length - 9);
}

/// MySQL `TIMESTAMP` wants `YYYY-MM-DD HH:MM:SS` — no `T`, no fractional
/// seconds. Convert UTC to server-local so display in Laravel lines up
/// with `config('app.timezone')`.
String? _mysqlTs(DateTime? dt) {
  if (dt == null) return null;
  return _formatTs(dt.toLocal());
}

String _mysqlNow() => _formatTs(DateTime.now().toLocal());

String _formatTs(DateTime dt) {
  String p(int n, [int w = 2]) => n.toString().padLeft(w, '0');
  return '${p(dt.year, 4)}-${p(dt.month)}-${p(dt.day)} '
      '${p(dt.hour)}:${p(dt.minute)}:${p(dt.second)}';
}

String? _s(Object? v) => v == null ? null : v.toString();

String _require(DotEnv env, String name) {
  final v = env[name];
  if (v == null || v.isEmpty) {
    stderr.writeln('missing required env var: $name');
    exit(2);
  }
  return v;
}
