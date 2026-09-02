import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:eloquent/eloquent.dart';

/// Sidecar publisher: watches `PUBLISH_SIDECARS_DIR` (default:
/// `ENRICHED_DIR`, falls back to `RECORDINGS_DIR`) for JSON sidecars
/// produced by `bin/record_calls.dart` and `bin/enrich_from_homer.dart`,
/// and upserts one row per call into the Laravel dashboard's
/// `recordings` MySQL table.
///
/// Column mapping (see the CCIVRDashboard migrations for the schema):
///   agent_number     <- dst, normalised ("PJSIP/3636@mytrunk" -> "3636")
///   phone_number     <- src (customer number)
///   duration_number  <- duration (legacy string field)
///   file_name        <- <daemon_basename>.<PUBLISH_AUDIO_EXT>
///                       (matches the audio file the recorder daemon
///                        actually wrote, e.g.
///                        20260825-073255_unknown_unknown_<uuid>.wav)
///   file_path        <- <PUBLISH_AUDIO_DIR>/<file_name>
///   src, dst, clid, calldate, answerdate, hangupdate,
///   duration, billsec, disposition        <- direct from sidecar
///   agent_no         <- first non-B2BUA / non-Asterisk SDP IP from
///                       sidecar `legs[]` (best-guess physical agent IP);
///                       Laravel's IP-agent map can override.
///   user_id, session_id, transaction_code <- left null (owned by the
///                                            Laravel app on the QA side).
///
/// Idempotency: uses `file_name` as the natural key (already indexed).
/// If a row exists it is UPDATEd, else INSERTed.
///
/// Env:
///   PUBLISH_SIDECARS_DIR        (default: ENRICHED_DIR or RECORDINGS_DIR)
///   PUBLISH_AUDIO_DIR           (default: /u01/recordings)
///   PUBLISH_AUDIO_EXT           (default: wav)  -- audio file extension
///                               (independent of RECORDER_FORMAT, which
///                                is the RTP payload)
///   PUBLISH_POLL_SECS           (default: 30)
///   PUBLISH_LOOKBACK_MINUTES    (default: 120)
///   PUBLISH_AGENT_IP_EXCLUDE    (default: 10.1.8.,10.1.101.)  -- comma-
///                               separated prefixes of B2BUA/Asterisk IPs
///                               to skip when picking `agent_no`
///
///   DASHBOARD_MYSQL_HOST/PORT/DB/USER/PASSWORD   (falls back to AST_DB_*)
///   DASHBOARD_MYSQL_POOL_SIZE   (default: 3)
///
/// Flags:
///   --once       run one scan and exit (for cron)
///   --backfill   ignore PUBLISH_LOOKBACK_MINUTES; process everything
///   --dry-run    log what would be inserted/updated; write nothing

Future<void> main(List<String> args) async {
  final env = DotEnv(includePlatformEnvironment: true)..load();
  final once = args.contains('--once');
  final backfill = args.contains('--backfill');
  final dryRun = args.contains('--dry-run');

  final inputDirPath = env['PUBLISH_SIDECARS_DIR'] ??
      env['ENRICHED_DIR'] ??
      env['RECORDINGS_DIR'] ??
      './recordings_enriched';
  final inputDir = Directory(inputDirPath);
  if (!inputDir.existsSync()) {
    stderr.writeln('input dir does not exist: ${inputDir.path}');
    exit(2);
  }

  final audioDir = env['PUBLISH_AUDIO_DIR'] ?? '/u01/recordings';
  final audioExt = env['PUBLISH_AUDIO_EXT'] ?? 'wav';
  final poll = Duration(seconds: int.parse(env['PUBLISH_POLL_SECS'] ?? '30'));
  final lookback = backfill
      ? const Duration(days: 3650)
      : Duration(minutes: int.parse(env['PUBLISH_LOOKBACK_MINUTES'] ?? '120'));
  final excludePrefixes =
      (env['PUBLISH_AGENT_IP_EXCLUDE'] ?? '10.1.8.,10.1.101.')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

  final host = env['DASHBOARD_MYSQL_HOST'] ?? env['AST_DB_HOST'];
  final port = env['DASHBOARD_MYSQL_PORT'] ?? env['AST_DB_PORT'] ?? '3306';
  final database = env['DASHBOARD_MYSQL_DB'] ?? env['AST_DB_DATABASE'];
  final username = env['DASHBOARD_MYSQL_USER'] ?? env['AST_DB_USERNAME'];
  final password =
      env['DASHBOARD_MYSQL_PASSWORD'] ?? env['AST_DB_PASSWORD'] ?? '';
  final poolSize = env['DASHBOARD_MYSQL_POOL_SIZE'] ?? '3';
  if (host == null || database == null || username == null) {
    stderr.writeln('missing DASHBOARD_MYSQL_* (or AST_DB_*) env vars');
    exit(2);
  }

  final manager = Manager();
  manager.addConnection({
    'driver': 'mysql',
    'host': host,
    'port': port,
    'database': database,
    'username': username,
    'password': password,
    'pool': 'true',
    'poolsize': poolSize,
    'allowreconnect': 'true',
    'application_name': 'publish_to_mysql',
  });
  manager.setAsGlobal();
  final db = await manager.connection();

  print('[publish] input=${inputDir.path} audio=$audioDir ext=$audioExt '
      'mysql=$username@$host:$port/$database poolsize=$poolSize '
      'poll=${poll.inSeconds}s lookback=${lookback.inMinutes}m '
      'dry_run=$dryRun');

  ProcessSignal.sigint.watch().listen((_) async {
    print('[publish] shutting down');
    try {
      await db.disconnect();
    } catch (_) {}
    exit(0);
  });

  while (true) {
    try {
      await _scan(
          inputDir, audioDir, audioExt, lookback, excludePrefixes, db, dryRun);
    } catch (e, st) {
      print('[publish] scan error: $e\n$st');
    }
    if (once) break;
    await Future.delayed(poll);
  }
  try {
    await db.disconnect();
  } catch (_) {}
}

Future<void> _scan(
    Directory inputDir,
    String audioDir,
    String audioExt,
    Duration lookback,
    List<String> excludePrefixes,
    Connection db,
    bool dryRun) async {
  final cutoff = DateTime.now().toUtc().subtract(lookback);
  final files = inputDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .where((f) => f.statSync().modified.toUtc().isAfter(cutoff))
      .toList();

  for (final file in files) {
    await _publishOne(file, audioDir, audioExt, excludePrefixes, db, dryRun);
  }
}

Future<void> _publishOne(File file, String audioDir, String audioExt,
    List<String> excludePrefixes, Connection db, bool dryRun) async {
  final baseName = file.uri.pathSegments.last;

  Map<String, dynamic> sidecar;
  try {
    sidecar = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  } catch (e) {
    print('[publish] skip $baseName: bad JSON ($e)');
    return;
  }

  // The recorder daemon writes audio using `daemon_basename` (built at
  // StasisStart before SDPs resolve, always <stamp>_unknown_unknown_<uuid>).
  // `ip_tagged_basename` is only the sidecar JSON's own filename, not the
  // audio. Fall back the other way only if a sidecar lacks daemon_basename.
  final stem =
      _s(sidecar['daemon_basename']) ?? _s(sidecar['ip_tagged_basename']);
  if (stem == null) {
    print('[publish] skip $baseName: no daemon_basename / ip_tagged_basename');
    return;
  }
  final fileName = '$stem.$audioExt';
  final filePath = '$audioDir/$fileName';

  final srcRaw = _s(sidecar['src']) ?? '';
  final dstRaw = _s(sidecar['dst']) ?? '';
  final dstNorm = _normalizeExtension(dstRaw);
  final duration = _s(sidecar['duration']) ?? '0';
  final billsec = _s(sidecar['billsec']) ?? '0';
  final calldate = _mysqlTs(_s(sidecar['calldate']));
  final answerdate = _mysqlTs(_s(sidecar['answerdate']));
  final hangupdate = _mysqlTs(_s(sidecar['hangupdate']));
  final agentNo = _pickAgentIp(sidecar['legs'], excludePrefixes);

  final row = <String, dynamic>{
    'agent_number': dstNorm,
    'phone_number': srcRaw,
    'duration_number': duration,
    'file_name': fileName,
    'file_path': filePath,
    'src': srcRaw,
    'dst': dstNorm,
    'clid': _s(sidecar['clid']) ?? '',
    'calldate': calldate,
    'answerdate': answerdate,
    'hangupdate': hangupdate,
    'duration': int.tryParse(duration) ?? 0,
    'billsec': int.tryParse(billsec) ?? 0,
    'disposition': _s(sidecar['disposition']) ?? '',
    'agent_no': agentNo,
  };

  // Natural key: file_name (indexed). Check-then-write is safe here
  // because this is the only writer for the recordings table.
  final existing = await db
      .table('recordings')
      .where('file_name', '=', fileName)
      .select(['id'])
      .limit(1)
      .get();

  if (existing.isNotEmpty) {
    if (dryRun) {
      print('[publish]   would UPDATE $fileName '
          '(id=${existing.first['id']}, agent=$agentNo dst=$dstNorm)');
      return;
    }
    await db
        .table('recordings')
        .where('id', '=', existing.first['id'])
        .update(row);
    print('[publish]   UPDATE $fileName (agent=$agentNo dst=$dstNorm)');
    return;
  }

  final now = _mysqlNow();
  row['created_at'] = now;
  row['updated_at'] = now;
  if (dryRun) {
    print('[publish]   would INSERT $fileName '
        '(agent=$agentNo phone=$srcRaw dur=$duration billsec=$billsec)');
    return;
  }
  await db.table('recordings').insert(row);
  print('[publish]   INSERT $fileName '
      '(agent=$agentNo phone=$srcRaw dur=$duration billsec=$billsec)');
}

/// Sidecar `dst` is stored as the ARI endpoint ("PJSIP/3636@mytrunk").
/// The `recordings` table wants just the extension ("3636").
String _normalizeExtension(String v) {
  if (v.isEmpty) return '';
  var s = v;
  final slash = s.indexOf('/');
  if (slash >= 0) s = s.substring(slash + 1);
  final at = s.indexOf('@');
  if (at >= 0) s = s.substring(0, at);
  return s;
}

/// Return the first SDP IP from [legsRaw] that doesn't start with any of
/// [excludePrefixes] (i.e. isn't the B2BUA anchor or Asterisk itself) —
/// that's the physical agent phone. Null if none found.
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

/// Sidecar timestamps are ISO-8601 UTC (`2026-08-27T13:35:23.810511Z`).
/// MySQL `TIMESTAMP` wants `YYYY-MM-DD HH:MM:SS` — no `T`, no fractional
/// seconds. Return null for empty / unparseable input.
String? _mysqlTs(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  final dt = DateTime.tryParse(iso);
  if (dt == null) return null;
  return _formatTs(dt.toUtc());
}

String _mysqlNow() => _formatTs(DateTime.now().toUtc());

String _formatTs(DateTime dt) {
  String p(int n, [int w = 2]) => n.toString().padLeft(w, '0');
  return '${p(dt.year, 4)}-${p(dt.month)}-${p(dt.day)} '
      '${p(dt.hour)}:${p(dt.minute)}:${p(dt.second)}';
}

String? _s(Object? v) => v == null ? null : v.toString();
