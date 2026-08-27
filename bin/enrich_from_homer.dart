import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_ari/ari/homer/homer_client.dart';
import 'package:dotenv/dotenv.dart';

/// Sidecar enricher: polls `RECORDINGS_DIR` for JSON sidecars produced by
/// `bin/record_calls.dart`, looks up the matching SIP Call-ID in Homer's
/// TimescaleDB, and writes it back into the same JSON as a top-level
/// `callid` field. Idempotent — a sidecar is skipped once it has a
/// `callid` key, so re-running is safe.
///
/// Env required:
///   HOMER_PG_HOST        (e.g. 127.0.0.1 — Homer db container port must
///                         be exposed to the host, see docs)
///   HOMER_PG_PORT        (default: 5432)
///   HOMER_PG_DB          (default: homer_data)
///   HOMER_PG_USER        (default: root)
///   HOMER_PG_PASS        (must match heplify-server's DBPass)
///
///   RECORDINGS_DIR       (default: ./recordings_out)
///   POLL_INTERVAL_SECS   (default: 5)
///   LOOKBACK_MINUTES     (default: 60 — sidecars older than this are
///                         ignored on first scan to avoid re-processing
///                         a full backlog)
///
/// Optional flags:
///   --once               run one scan and exit (for cron)
///   --backfill           ignore LOOKBACK_MINUTES; process everything

Future<void> main(List<String> args) async {
  final env = DotEnv(includePlatformEnvironment: true)..load();
  final once = args.contains('--once');
  final backfill = args.contains('--backfill');

  final host = _require(env, 'HOMER_PG_HOST');
  final client = HomerClient(
    host: host,
    port: int.parse(env['HOMER_PG_PORT'] ?? '5432'),
    database: env['HOMER_PG_DB'] ?? 'homer_data',
    username: env['HOMER_PG_USER'] ?? 'root',
    password: _require(env, 'HOMER_PG_PASS'),
  );

  final dir = Directory(env['RECORDINGS_DIR'] ?? './recordings_out');
  if (!dir.existsSync()) {
    stderr.writeln('recordings dir does not exist: ${dir.path}');
    exit(2);
  }

  final poll = Duration(seconds: int.parse(env['POLL_INTERVAL_SECS'] ?? '5'));
  final lookback = backfill
      ? const Duration(days: 3650)
      : Duration(minutes: int.parse(env['LOOKBACK_MINUTES'] ?? '60'));

  print('[enricher] watching ${dir.path} '
      '(poll=${poll.inSeconds}s, lookback=${lookback.inMinutes}m, '
      'homer=$host)');

  ProcessSignal.sigint.watch().listen((_) async {
    print('[enricher] shutting down');
    await client.close();
    exit(0);
  });

  while (true) {
    try {
      await _scan(dir, client, lookback);
    } catch (e, st) {
      print('[enricher] scan error: $e\n$st');
    }
    if (once) break;
    await Future.delayed(poll);
  }
  await client.close();
}

Future<void> _scan(Directory dir, HomerClient client, Duration lookback) async {
  final cutoff = DateTime.now().toUtc().subtract(lookback);
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .where((f) => f.statSync().modified.toUtc().isAfter(cutoff))
      .toList();

  for (final file in files) {
    await _enrichOne(file, client);
  }
}

Future<void> _enrichOne(File file, HomerClient client) async {
  final Map<String, dynamic> sidecar;
  try {
    sidecar = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  } catch (e) {
    print('[enricher] skip ${file.path}: bad JSON ($e)');
    return;
  }

  if (sidecar.containsKey('callid')) return; // already enriched

  final src = _normalizeUser(_asString(sidecar['src']));
  final dst = _normalizeUser(_asString(sidecar['dst']));
  final callDate = _parseIso(sidecar['calldate']);
  final hangupDate = _parseIso(sidecar['hangupdate']) ??
      callDate?.add(const Duration(minutes: 5));

  if (src == null || dst == null || callDate == null || hangupDate == null) {
    print('[enricher] skip ${file.uri.pathSegments.last}: '
        'missing src/dst/calldate/hangupdate');
    return;
  }

  final String? callid;
  try {
    callid = await client
        .findCallId(
          fromUser: src,
          toUser: dst,
          from: callDate.subtract(const Duration(seconds: 30)),
          to: hangupDate.add(const Duration(seconds: 10)),
        )
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    print('[enricher] lookup failed for ${file.uri.pathSegments.last}: $e');
    return;
  }

  sidecar['callid'] = callid; // null marks "looked up, not found"
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(sidecar),
    flush: true,
  );
  print('[enricher] ${file.uri.pathSegments.last} '
      '(src=$src dst=$dst) -> callid=${callid ?? "not-found"}');
}

/// Sidecar `dst` is stored as the ARI endpoint string ("PJSIP/3636@mytrunk"),
/// but Homer extracts just the user part of the SIP To header ("3636").
/// Strip channel-tech prefix and @trunk suffix so the join matches.
String? _normalizeUser(String? v) {
  if (v == null || v.isEmpty) return v;
  var s = v;
  final slash = s.indexOf('/');
  if (slash >= 0) s = s.substring(slash + 1);
  final at = s.indexOf('@');
  if (at >= 0) s = s.substring(0, at);
  return s;
}

String? _asString(Object? v) => v == null ? null : v.toString();

DateTime? _parseIso(Object? v) {
  if (v == null) return null;
  final s = v.toString();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s)?.toUtc();
}

String _require(DotEnv env, String name) {
  final v = env[name];
  if (v == null || v.isEmpty) {
    stderr.writeln('missing required env var: $name');
    exit(2);
  }
  return v;
}
