import 'dart:io';

import 'package:dart_ari/stt/stt_service.dart';

/// CLI entry point for the Azure Speech-to-Text service.
///
/// Usage:
///   `dart run bin/stt.dart <audio.wav>`   transcribe one file
///   `dart run bin/stt.dart <folder>`      transcribe every .wav in a folder
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run bin/stt.dart <audio.wav | folder>');
    exitCode = 64; // EX_USAGE
    return;
  }

  final SttService service;
  try {
    service = SttService.fromEnv();
  } on StateError catch (err) {
    stderr.writeln(err.message);
    exitCode = 78; // EX_CONFIG
    return;
  }

  final target = args.first;

  if (FileSystemEntity.isDirectorySync(target)) {
    await service.transcribeFolder(target);
    return;
  }

  stdout.writeln('Transcribing: $target');
  stdout.writeln('Locales: ${service.locales.join(', ')}');
  final result = await service.transcribeAndSave(target);
  stdout.writeln('\n--- Full transcript ---');
  stdout.writeln(result.text.isEmpty ? '(no speech recognized)' : result.text);
  stdout.writeln('Saved transcript: ${result.outputPath}');
}
