import 'dart:async';
import 'dart:io';

import 'package:dart_ari/stt/llm_enhancer.dart';
import 'package:dart_ari/stt/stt_service.dart';
import 'package:dotenv/dotenv.dart';

/// Recording watcher: monitors a directory for newly created WAV recordings
/// and transcribes each one with [SttService], writing a sibling `.txt` next
/// to the audio file.
///
/// It combines real-time filesystem events (fast pickup) with a periodic
/// sweep (catches anything the watcher misses, e.g. on network shares). A
/// stability guard avoids reading files that are still being written.
///
/// Env (AZURE_SPEECH_* are required, loaded by SttService.fromEnv):
///
///   STT_WATCH_DIR            default: ./recordings — directory to watch
///   STT_WATCH_POLL_SECONDS   default: 10 — sweep interval for missed events
///   STT_WATCH_STABLE_SECONDS default: 3 — ignore files modified more recently
///                            than this (avoids reading writes-in-flight)
///   STT_WATCH_OVERWRITE      default: false — reprocess even if a `.txt`
///                            already exists for the recording
///   STT_WATCH_OUTPUT_DIR      optional — write transcripts here instead of
///                            alongside the audio file
///   STT_WATCH_ENHANCE         default: false — also enhance each transcript
///                            with the LLM (writes `<name>.enhanced.txt`)
///   STT_WATCH_ENHANCED_DIR    optional — write enhanced transcripts here
///                            (defaults to STT_WATCH_OUTPUT_DIR)
///
/// Flags:
///   --once   transcribe existing untranscribed files once, then exit

Future<void> main(List<String> args) async {
  final env = DotEnv(includePlatformEnvironment: true)..load();
  final once = args.contains('--once');

  final watchDir = env['STT_WATCH_DIR'] ?? './recordings';
  final poll =
      Duration(seconds: int.parse(env['STT_WATCH_POLL_SECONDS'] ?? '10'));
  final stable =
      Duration(seconds: int.parse(env['STT_WATCH_STABLE_SECONDS'] ?? '3'));
  final overwrite =
      (env['STT_WATCH_OVERWRITE'] ?? 'false').toLowerCase() == 'true';
  final outputDir = env['STT_WATCH_OUTPUT_DIR'];
  final enhance = (env['STT_WATCH_ENHANCE'] ?? 'false').toLowerCase() == 'true';
  final enhancedDir = env['STT_WATCH_ENHANCED_DIR'] ?? outputDir;

  final SttService service;
  try {
    service = SttService.fromEnv();
  } on StateError catch (err) {
    stderr.writeln('[stt-watch] config error: ${err.message}');
    exit(78); // EX_CONFIG
  }

  // Enhancement is best-effort: a config error disables it but still lets
  // transcription run.
  LlmEnhancer? enhancer;
  if (enhance) {
    try {
      enhancer = LlmEnhancer.fromEnv();
    } on StateError catch (err) {
      stderr.writeln('[stt-watch] enhancement disabled: ${err.message}');
    }
  }

  final dir = Directory(watchDir);
  if (!dir.existsSync()) {
    stderr.writeln('[stt-watch] directory not found: $watchDir');
    exit(66); // EX_NOINPUT
  }

  if (outputDir != null && outputDir.isNotEmpty) {
    Directory(outputDir).createSync(recursive: true);
  }
  if (enhancer != null && enhancedDir != null && enhancedDir.isNotEmpty) {
    Directory(enhancedDir).createSync(recursive: true);
  }

  print('[stt-watch] dir=$watchDir '
      'out=${outputDir == null || outputDir.isEmpty ? '(alongside audio)' : outputDir} '
      'enhance=${enhancer != null} '
      'poll=${poll.inSeconds}s stable=${stable.inSeconds}s overwrite=$overwrite '
      'locales=${service.locales.join(",")}');

  // Guards against processing the same recording twice concurrently.
  final inFlight = <String>{};

  Future<void> process(String path) async {
    if (!path.toLowerCase().endsWith('.wav')) return;
    if (inFlight.contains(path)) return;

    final file = File(path);
    if (!file.existsSync()) return;

    final txtPath = SttService.transcriptPathFor(path, outputDir: outputDir);
    final enhancedPath = enhancer == null
        ? null
        : LlmEnhancer.enhancedPathFor(txtPath, outputDir: enhancedDir);
    final txtExists = File(txtPath).existsSync();
    final enhancedExists =
        enhancedPath != null && File(enhancedPath).existsSync();

    // Nothing to do if the expected outputs already exist.
    if (!overwrite) {
      if (enhancer == null && txtExists) return;
      if (enhancer != null && txtExists && enhancedExists) return;
    }

    // Skip files still being written; a later sweep/event retries them.
    final age = DateTime.now().difference(file.statSync().modified);
    if (age < stable) return;

    inFlight.add(path);
    try {
      String transcript;
      if (overwrite || !txtExists) {
        print('[stt-watch] transcribing: $path');
        final result =
            await service.transcribeAndSave(path, outputDir: outputDir);
        transcript = result.text;
        print('[stt-watch] saved: ${result.outputPath}'
            '${result.text.isEmpty ? ' (no speech)' : ''}');
      } else {
        transcript = await File(txtPath).readAsString();
      }

      if (enhancer != null &&
          transcript.trim().isNotEmpty &&
          (overwrite || !enhancedExists)) {
        print('[stt-watch] enhancing: $txtPath');
        final enhanced =
            await enhancer.enhanceFile(txtPath, outputDir: enhancedDir);
        print('[stt-watch] enhanced: ${enhanced.outputPath}');
      }
    } catch (err) {
      stderr.writeln('[stt-watch] failed: $path -> $err');
    } finally {
      inFlight.remove(path);
    }
  }

  Future<void> sweep() async {
    final wavs = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.wav'))
        .map((f) => f.path)
        .toList()
      ..sort();
    for (final path in wavs) {
      await process(path);
    }
  }

  // Pick up anything already present before watching for new arrivals.
  await sweep();

  if (once) {
    print('[stt-watch] --once complete');
    return;
  }

  StreamSubscription<FileSystemEvent>? watchSub;
  try {
    watchSub = dir
        .watch(events: FileSystemEvent.create | FileSystemEvent.modify)
        .listen(
      (event) {
        if (event.path.toLowerCase().endsWith('.wav')) {
          // Defer so the writer can finish; process() re-checks stability.
          Future.delayed(stable, () => process(event.path));
        }
      },
      onError: (Object e) => stderr.writeln('[stt-watch] watch error: $e'),
    );
  } on FileSystemException catch (e) {
    // Some filesystems (e.g. network shares) don't support watch; the
    // periodic sweep still covers new files.
    stderr.writeln('[stt-watch] watch unavailable, polling only: ${e.message}');
  }

  final sweepTimer = Timer.periodic(poll, (_) => sweep());

  final shutdown = Completer<void>();
  ProcessSignal.sigint.watch().listen((_) async {
    print('[stt-watch] shutting down');
    sweepTimer.cancel();
    await watchSub?.cancel();
    if (!shutdown.isCompleted) shutdown.complete();
  });

  await shutdown.future;
}
