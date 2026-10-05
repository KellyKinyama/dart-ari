import 'dart:io';

import 'package:dart_ari/stt/llm_enhancer.dart';

/// CLI for enhancing transcripts with the Azure AI Foundry LLM.
///
/// Usage:
///   `dart run bin/enhance.dart <transcript.txt>`   enhance one file
///   `dart run bin/enhance.dart <folder>`           enhance every .txt
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run bin/enhance.dart <transcript.txt | folder>');
    exitCode = 64; // EX_USAGE
    return;
  }

  final LlmEnhancer enhancer;
  try {
    enhancer = LlmEnhancer.fromEnv();
  } on StateError catch (err) {
    stderr.writeln(err.message);
    exitCode = 78; // EX_CONFIG
    return;
  }

  final target = args.first;

  if (FileSystemEntity.isDirectorySync(target)) {
    final txtFiles = Directory(target)
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.path.toLowerCase().endsWith('.txt') &&
            !f.path.toLowerCase().endsWith('.enhanced.txt'))
        .map((f) => f.path)
        .toList()
      ..sort();

    if (txtFiles.isEmpty) {
      stderr.writeln('No .txt files found in $target');
      exitCode = 66; // EX_NOINPUT
      return;
    }

    for (var i = 0; i < txtFiles.length; i++) {
      final path = txtFiles[i];
      stdout.writeln('\n=== [${i + 1}/${txtFiles.length}] $path ===');
      try {
        final result = await enhancer.enhanceFile(path);
        stdout.writeln('Saved enhanced: ${result.outputPath}');
      } catch (err) {
        stderr.writeln('Failed: $path -> $err');
      }
    }
    return;
  }

  stdout.writeln('Enhancing: $target');
  final result = await enhancer.enhanceFile(target);
  stdout.writeln('\n--- Enhanced transcript ---');
  stdout.writeln(result.text);
  stdout.writeln('Saved enhanced: ${result.outputPath}');
}
