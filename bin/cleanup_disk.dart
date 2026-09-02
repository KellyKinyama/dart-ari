import 'dart:async';
import 'dart:io';

import 'package:dart_ari/ari/homer/homer_client.dart';
import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

/// Disk-space guardian: watches a filesystem, and when usage rises above a
/// high-water mark, prunes the oldest data across a configured list of
/// targets (recording sidecars, audio files, Asterisk logs, Homer SIP
/// chunks) until usage drops back below the low-water mark.
///
/// This is a safety valve. Homer already auto-rotates via heplify-server's
/// `DBDropDays`; Asterisk's own logrotate covers `/var/log/asterisk`. This
/// daemon only wakes up when normal retention isn't keeping up.
///
/// Env (all optional except the required HOMER_PG_* if pruning Homer):
///
///   CLEANUP_MONITOR_PATH        default: /
///                               the mount whose df% drives the decisions
///   DISK_HIGH_WATERMARK_PCT     default: 85 — start pruning at/above this
///   DISK_LOW_WATERMARK_PCT      default: 75 — stop when back under this
///
///   CLEANUP_MIN_AGE_DAYS        default: 14 — never touch anything younger
///   CLEANUP_SKIP_RECENT_SECS    default: 60 — never touch files modified
///                               in the last N seconds (writes-in-flight)
///   CLEANUP_MAX_DELETES_PER_RUN default: 5000 — per-target cap per pass
///   CLEANUP_POLL_MINUTES        default: 15
///
///   CLEANUP_ENRICHED_DIR        default: ./recordings_enriched
///   CLEANUP_SIDECARS_DIR        default: ./recordings_out
///   CLEANUP_AUDIO_DIR           default: /u01/recordings
///   CLEANUP_AUDIO_GLOB          default: *.wav,*.alaw,*.g729,*.ulaw
///   CLEANUP_ASTERISK_LOG_DIR    default: /var/log/asterisk
///   CLEANUP_ASTERISK_LOG_GLOB   default: full.*,messages.*,*.gz
///
///   HOMER_PRUNE_ENABLED         default: true — TimescaleDB drop_chunks
///   HOMER_PRUNE_MIN_AGE_DAYS    default: 14 (independent of file min-age)
///   HOMER_PG_HOST / _PORT / _DB / _USER / _PASS — same as enricher
///
/// Flags:
///   --once                      run one pass and exit
///   --dry-run                   log what would be deleted, delete nothing

Future<void> main(List<String> args) async {
  final env = DotEnv(includePlatformEnvironment: true)..load();
  final once = args.contains('--once');
  final dryRun = args.contains('--dry-run') ||
      (env['CLEANUP_DRY_RUN']?.toLowerCase() == 'true');

  final monitorPath = env['CLEANUP_MONITOR_PATH'] ?? '/';
  final high = int.parse(env['DISK_HIGH_WATERMARK_PCT'] ?? '85');
  final low = int.parse(env['DISK_LOW_WATERMARK_PCT'] ?? '75');
  final minAge = Duration(days: int.parse(env['CLEANUP_MIN_AGE_DAYS'] ?? '14'));
  final skipRecent =
      Duration(seconds: int.parse(env['CLEANUP_SKIP_RECENT_SECS'] ?? '60'));
  final maxPerRun = int.parse(env['CLEANUP_MAX_DELETES_PER_RUN'] ?? '5000');
  final poll =
      Duration(minutes: int.parse(env['CLEANUP_POLL_MINUTES'] ?? '15'));

  final targets = <Pruner>[
    DirPruner(
      name: 'enriched-sidecars',
      dir: env['CLEANUP_ENRICHED_DIR'] ?? './recordings_enriched',
      globs: const ['*.json'],
    ),
    DirPruner(
      name: 'raw-sidecars',
      dir: env['CLEANUP_SIDECARS_DIR'] ?? './recordings_out',
      globs: const ['*.json'],
    ),
    DirPruner(
      name: 'audio',
      dir: env['CLEANUP_AUDIO_DIR'] ?? '/u01/recordings',
      globs: _csv(env['CLEANUP_AUDIO_GLOB'] ?? '*.wav,*.alaw,*.g729,*.ulaw'),
      recursive: true,
    ),
    // Only rotated Asterisk logs — never the live `full` file (open FD).
    DirPruner(
      name: 'asterisk-logs',
      dir: env['CLEANUP_ASTERISK_LOG_DIR'] ?? '/var/log/asterisk',
      globs: _csv(env['CLEANUP_ASTERISK_LOG_GLOB'] ?? 'full.*,messages.*,*.gz'),
    ),
  ];

  final homerPruneEnabled =
      (env['HOMER_PRUNE_ENABLED'] ?? 'true').toLowerCase() == 'true';
  final homerMinAge =
      Duration(days: int.parse(env['HOMER_PRUNE_MIN_AGE_DAYS'] ?? '14'));
  HomerClient? homer;
  if (homerPruneEnabled && env['HOMER_PG_HOST'] != null) {
    homer = HomerClient(
      host: env['HOMER_PG_HOST']!,
      port: int.parse(env['HOMER_PG_PORT'] ?? '5432'),
      database: env['HOMER_PG_DB'] ?? 'homer_data',
      username: env['HOMER_PG_USER'] ?? 'root',
      password: env['HOMER_PG_PASS'] ?? 'homerSeven',
    );
    // Prune keepalives first (lowest value), then dialogs.
    targets.add(HomerChunksPruner(homer, 'hep_proto_1_default'));
    targets.add(HomerChunksPruner(homer, 'hep_proto_1_call'));
  }

  print('[cleanup] monitor=$monitorPath high=$high% low=$low% '
      'min_age=${minAge.inDays}d skip_recent=${skipRecent.inSeconds}s '
      'poll=${poll.inMinutes}m dry_run=$dryRun '
      'targets=${targets.map((t) => t.name).join(",")}');

  ProcessSignal.sigint.watch().listen((_) async {
    print('[cleanup] shutting down');
    await homer?.close();
    exit(0);
  });

  while (true) {
    try {
      await _passOnce(
        monitorPath: monitorPath,
        highPct: high,
        lowPct: low,
        minAge: minAge,
        skipRecent: skipRecent,
        maxPerRun: maxPerRun,
        homerMinAge: homerMinAge,
        targets: targets,
        dryRun: dryRun,
      );
    } catch (e, st) {
      print('[cleanup] pass error: $e\n$st');
    }
    if (once) break;
    await Future.delayed(poll);
  }
  await homer?.close();
}

Future<void> _passOnce({
  required String monitorPath,
  required int highPct,
  required int lowPct,
  required Duration minAge,
  required Duration skipRecent,
  required int maxPerRun,
  required Duration homerMinAge,
  required List<Pruner> targets,
  required bool dryRun,
}) async {
  var usage = await _diskUsagePct(monitorPath);
  print('[cleanup] $monitorPath at $usage% (high=$highPct, low=$lowPct)');
  if (usage < highPct) return;

  for (final t in targets) {
    if (usage < lowPct) {
      print('[cleanup] under low watermark; stopping this pass');
      return;
    }
    final effMinAge = t is HomerChunksPruner ? homerMinAge : minAge;
    final n = await t.pruneOldest(
      minAge: effMinAge,
      skipRecent: skipRecent,
      maxItems: maxPerRun,
      dryRun: dryRun,
    );
    if (n > 0) {
      print('[cleanup] ${t.name}: ${dryRun ? "would delete" : "deleted"} $n');
    }
    usage = await _diskUsagePct(monitorPath);
    print('[cleanup] $monitorPath now $usage%');
  }
  if (usage >= highPct) {
    print(
        '[cleanup] still $usage% after all targets exhausted — human check needed');
  }
}

/// Parse `df -Pk <path>` (POSIX portable): returns integer percent used.
Future<int> _diskUsagePct(String path) async {
  final r = await Process.run('df', ['-Pk', path]);
  if (r.exitCode != 0) {
    throw StateError('df failed for $path: ${r.stderr}');
  }
  final lines = (r.stdout as String).trim().split('\n');
  if (lines.length < 2) throw StateError('df output malformed:\n${r.stdout}');
  // Filesystem 1024-blocks Used Available Capacity Mounted-on
  final cols = lines[1].split(RegExp(r'\s+'));
  final capacity = cols[4].replaceAll('%', '');
  return int.parse(capacity);
}

List<String> _csv(String v) =>
    v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

// ---------------------------------------------------------------------------
// Pruners

abstract class Pruner {
  String get name;
  Future<int> pruneOldest({
    required Duration minAge,
    required Duration skipRecent,
    required int maxItems,
    required bool dryRun,
  });
}

class DirPruner extends Pruner {
  DirPruner({
    required this.name,
    required this.dir,
    required this.globs,
    this.recursive = false,
  });

  @override
  final String name;
  final String dir;
  final List<String> globs;
  final bool recursive;

  @override
  Future<int> pruneOldest({
    required Duration minAge,
    required Duration skipRecent,
    required int maxItems,
    required bool dryRun,
  }) async {
    final root = Directory(dir);
    if (!root.existsSync()) {
      // Silent: a target path may not exist on every install.
      return 0;
    }

    final now = DateTime.now();
    final matchers = globs.map(_globToRegex).toList();

    final files = <_Candidate>[];
    await for (final ent
        in root.list(recursive: recursive, followLinks: false)) {
      if (ent is! File) continue;
      final basename = ent.uri.pathSegments.last;
      if (!matchers.any((r) => r.hasMatch(basename))) continue;

      final stat = ent.statSync();
      final age = now.difference(stat.modified);
      if (age < minAge) continue;
      if (age < skipRecent) continue;

      files.add(_Candidate(ent, stat.modified, stat.size));
    }

    // Oldest first.
    files.sort((a, b) => a.mtime.compareTo(b.mtime));

    var deleted = 0;
    var bytes = 0;
    for (final c in files.take(maxItems)) {
      if (dryRun) {
        print('[cleanup]   would delete ${c.file.path} '
            '(${_kib(c.size)} KiB, ${_ageDays(now, c.mtime)}d old)');
      } else {
        try {
          await c.file.delete();
        } catch (e) {
          print('[cleanup]   failed to delete ${c.file.path}: $e');
          continue;
        }
      }
      deleted++;
      bytes += c.size;
    }
    if (deleted > 0) {
      print('[cleanup]   $name: ${dryRun ? "would free" : "freed"} '
          '~${_kib(bytes)} KiB across $deleted files');
    }
    return deleted;
  }
}

class HomerChunksPruner extends Pruner {
  HomerChunksPruner(this.client, this.hypertable);

  final HomerClient client;
  final String hypertable;

  @override
  String get name => 'homer:$hypertable';

  @override
  Future<int> pruneOldest({
    required Duration minAge,
    required Duration skipRecent, // unused for DB rows
    required int maxItems, // unused: chunks are dropped wholesale
    required bool dryRun,
  }) async {
    final conn = await client.connectRaw();
    final interval = '${minAge.inDays} days';

    if (dryRun) {
      final rows = await conn.execute(
        Sql.named(
            "SELECT show_chunks(@t::regclass, older_than => INTERVAL '$interval')"),
        parameters: {'t': hypertable},
      );
      for (final row in rows) {
        print('[cleanup]   would drop chunk ${row[0]}');
      }
      return rows.length;
    }

    try {
      final rows = await conn.execute(
        Sql.named(
            "SELECT drop_chunks(@t::regclass, older_than => INTERVAL '$interval')"),
        parameters: {'t': hypertable},
      );
      return rows.length;
    } catch (e) {
      // Not a hypertable? Fall back to DELETE.
      print('[cleanup]   drop_chunks failed on $hypertable ($e); using DELETE');
      final res = await conn.execute(
        Sql.named(
            "DELETE FROM $hypertable WHERE create_date < NOW() - INTERVAL '$interval'"),
      );
      return res.affectedRows;
    }
  }
}

// ---------------------------------------------------------------------------

class _Candidate {
  _Candidate(this.file, this.mtime, this.size);
  final File file;
  final DateTime mtime;
  final int size;
}

int _ageDays(DateTime now, DateTime mtime) => now.difference(mtime).inDays;

int _kib(int bytes) => (bytes / 1024).round();

/// Trivial glob → regex: only `*` (any run of chars) and `?` (one char).
/// Enough for the file patterns this daemon touches.
RegExp _globToRegex(String glob) {
  final buf = StringBuffer('^');
  for (final ch in glob.split('')) {
    switch (ch) {
      case '*':
        buf.write('.*');
        break;
      case '?':
        buf.write('.');
        break;
      case '.':
      case '(':
      case ')':
      case '+':
      case '|':
      case '^':
      case '\$':
      case '{':
      case '}':
      case '[':
      case ']':
      case '\\':
        buf.write('\\$ch');
        break;
      default:
        buf.write(ch);
    }
  }
  buf.write(r'$');
  return RegExp(buf.toString());
}
