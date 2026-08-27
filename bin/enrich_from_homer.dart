import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_ari/ari/homer/homer_client.dart';
import 'package:dotenv/dotenv.dart';

/// Sidecar enricher: polls `RECORDINGS_DIR` for JSON sidecars produced by
/// `bin/record_calls.dart`, looks up the matching SIP Call-ID in Homer's
/// TimescaleDB, and writes an enriched copy of each sidecar.
///
/// If `ENRICHED_DIR` is set, the enriched JSON is written there under the
/// same basename and the original in `RECORDINGS_DIR` is left untouched.
/// If unset, the enrichment is written in place (a `callid` key is added
/// to the original file). Either way the process is idempotent: it skips
/// sidecars that already have an enriched output.
///
/// Env required:
///   HOMER_PG_HOST        (e.g. 127.0.0.1 — Homer db container port must
///                         be exposed to the host, see docs)
///   HOMER_PG_PORT        (default: 5432)
///   HOMER_PG_DB          (default: homer_data)
///   HOMER_PG_USER        (default: root)
///   HOMER_PG_PASS        (must match heplify-server's DBPass)
///
///   RECORDINGS_DIR       (default: ./recordings_out — input)
///   ENRICHED_DIR         (optional — output; created if missing)
///   POLL_INTERVAL_SECS   (default: 5)
///   LOOKBACK_MINUTES     (default: 60 — sidecars older than this are
///                         ignored on first scan to avoid re-processing
///                         a full backlog)
///   MIN_AGE_SECS         (default: 15 — do NOT process a sidecar until it
///                         is this old, so heplify-server has had time to
///                         flush the last SIP messages into TimescaleDB)
///   RETRY_UNTIL_MINUTES  (default: 5 — if legs came back empty and the
///                         sidecar is younger than this, leave it un-
///                         finalized and try again next poll. After this
///                         age we accept the empty result as final.)
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

  final enrichedPath = env['ENRICHED_DIR'];
  final Directory? enrichedDir = (enrichedPath == null || enrichedPath.isEmpty)
      ? null
      : Directory(enrichedPath)
    ?..createSync(recursive: true);

  final poll = Duration(seconds: int.parse(env['POLL_INTERVAL_SECS'] ?? '5'));
  final lookback = backfill
      ? const Duration(days: 3650)
      : Duration(minutes: int.parse(env['LOOKBACK_MINUTES'] ?? '60'));
  final minAge = Duration(seconds: int.parse(env['MIN_AGE_SECS'] ?? '15'));
  final retryUntil =
      Duration(minutes: int.parse(env['RETRY_UNTIL_MINUTES'] ?? '5'));

  print('[enricher] watching ${dir.path} '
      '(poll=${poll.inSeconds}s, lookback=${lookback.inMinutes}m, '
      'min_age=${minAge.inSeconds}s, retry_until=${retryUntil.inMinutes}m, '
      'homer=$host, out=${enrichedDir?.path ?? "in-place"})');

  ProcessSignal.sigint.watch().listen((_) async {
    print('[enricher] shutting down');
    await client.close();
    exit(0);
  });

  while (true) {
    try {
      await _scan(dir, enrichedDir, client, lookback, minAge, retryUntil);
    } catch (e, st) {
      print('[enricher] scan error: $e\n$st');
    }
    if (once) break;
    await Future.delayed(poll);
  }
  await client.close();
}

Future<void> _scan(Directory dir, Directory? outDir, HomerClient client,
    Duration lookback, Duration minAge, Duration retryUntil) async {
  final now = DateTime.now().toUtc();
  final cutoff = now.subtract(lookback);
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .where((f) => f.statSync().modified.toUtc().isAfter(cutoff))
      .toList();

  for (final file in files) {
    await _enrichOne(file, outDir, client, minAge, retryUntil, now);
  }
}

Future<void> _enrichOne(File file, Directory? outDir, HomerClient client,
    Duration minAge, Duration retryUntil, DateTime now) async {
  final basename = file.uri.pathSegments.last;
  final ageOfSidecar = now.difference(file.statSync().modified.toUtc());

  // Too young: heplify may still be flushing the last SIP messages.
  if (ageOfSidecar < minAge) return;

  // Idempotency: if a target already exists, skip.
  if (outDir != null) {
    final target = File('${outDir.path}${Platform.pathSeparator}$basename');
    if (target.existsSync()) return;
  }

  final Map<String, dynamic> sidecar;
  try {
    sidecar = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  } catch (e) {
    print('[enricher] skip ${file.path}: bad JSON ($e)');
    return;
  }

  if (outDir == null && sidecar.containsKey('legs')) return;

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

  final List<HomerLeg> legs;
  try {
    legs = await client
        .findLegs(
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

  sidecar['legs'] = [for (final l in legs) l.toJson()];

  // If we found nothing yet AND the sidecar is still within the retry
  // window, don't write anything — leave the file un-marked so we scan
  // again next poll. After retry_until we accept empty as final.
  final finalizeNow = legs.isNotEmpty || ageOfSidecar >= retryUntil;
  if (!finalizeNow) {
    print('[enricher] $basename (src=$src dst=$dst) '
        '-> no legs yet, retry (age=${ageOfSidecar.inSeconds}s)');
    return;
  }

  final outFile = outDir == null
      ? file
      : File('${outDir.path}${Platform.pathSeparator}$basename');
  await outFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(sidecar),
    flush: true,
  );

  // Concise log: how many legs, and any non-anchor SDP IPs we spotted
  // (those are the real-agent IPs behind a B2BUA).
  final ips = [
    for (final l in legs)
      if (l.sdp?.ip != null) l.sdp!.ip!,
  ].toSet().toList();
  print('[enricher] $basename (src=$src dst=$dst) '
      '-> legs=${legs.length} sdp_ips=${ips.isEmpty ? "-" : ips.join(",")}');
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
