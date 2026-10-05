import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;

/// Enhances raw speech-to-text transcripts using the Azure AI Foundry LLM
/// (OpenAI-compatible **Responses** API).
///
/// There is no OpenAI SDK for Dart, so this calls the REST endpoint directly:
/// `POST {endpoint}/responses` with `Authorization: Bearer <key>`.
class LlmEnhancer {
  /// OpenAI-compatible base URL,
  /// e.g. `https://<name>.services.ai.azure.com/openai/v1`.
  final String endpoint;

  /// Resource API key (same multi-service key as the Speech resource).
  final String apiKey;

  /// Model/deployment name, e.g. `gpt-5.4`.
  final String deployment;

  /// System instructions that steer the enhancement.
  final String systemPrompt;

  LlmEnhancer({
    required this.endpoint,
    required this.apiKey,
    required this.deployment,
    String? systemPrompt,
  }) : systemPrompt = systemPrompt ?? defaultSystemPrompt;

  static const String defaultSystemPrompt =
      'You are a transcript editor for a Zambian electricity utility (ZESCO) '
      'call center. You are given a raw speech-to-text transcript of a phone '
      'call. Produce a cleaned, readable version: fix punctuation and '
      'capitalization, correct obvious recognition errors, and format it as a '
      'dialogue between Agent and Caller when the speakers can be inferred. Do '
      'not invent or omit information. Output only the cleaned transcript.';

  /// Builds an enhancer from `.env`, independent of the ARI/DB config.
  factory LlmEnhancer.fromEnv() {
    final env = DotEnv(includePlatformEnvironment: true)..load();

    final endpoint = env['AZURE_AI_ENDPOINT'] ??
        'https://aiml4good.services.ai.azure.com/openai/v1';

    // Falls back to the shared Speech resource key.
    final apiKey = env['AZURE_AI_KEY'] ?? env['AZURE_SPEECH_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == '<your-api-key>') {
      throw StateError('AZURE_AI_KEY (or AZURE_SPEECH_KEY) is not set in .env');
    }

    final deployment = env['AZURE_AI_DEPLOYMENT'] ?? 'gpt-5.4';
    final systemPrompt = env['AZURE_AI_SYSTEM_PROMPT'];

    return LlmEnhancer(
      endpoint: endpoint,
      apiKey: apiKey,
      deployment: deployment,
      systemPrompt: (systemPrompt != null && systemPrompt.isNotEmpty)
          ? systemPrompt
          : null,
    );
  }

  Uri _responsesUri() {
    final base =
        endpoint.endsWith('/') ? endpoint.substring(0, endpoint.length - 1) : endpoint;
    return Uri.parse('$base/responses');
  }

  /// Sends [transcript] to the LLM and returns the enhanced text.
  Future<String> enhance(String transcript) async {
    if (transcript.trim().isEmpty) return '';

    final uri = _responsesUri();
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': deployment,
        'instructions': systemPrompt,
        'input': transcript,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'LLM enhance failed (${response.statusCode}): ${response.body}',
        uri: uri,
      );
    }

    return _extractOutputText(response.body);
  }

  /// Enhances the transcript in [transcriptPath] and writes the result.
  ///
  /// With [outputDir] the output is `<outputDir>/<name>.enhanced.txt`;
  /// otherwise it is `<name>.enhanced.txt` next to the source.
  Future<({String text, String outputPath})> enhanceFile(
    String transcriptPath, {
    String? outputDir,
  }) async {
    final file = File(transcriptPath);
    if (!file.existsSync()) {
      throw ArgumentError('Transcript not found: $transcriptPath');
    }

    final enhanced = await enhance(await file.readAsString());
    final outputPath = enhancedPathFor(transcriptPath, outputDir: outputDir);
    final parent = File(outputPath).parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }
    await File(outputPath).writeAsString('$enhanced\n');
    return (text: enhanced, outputPath: outputPath);
  }

  /// Returns the `.enhanced.txt` path for [transcriptPath].
  static String enhancedPathFor(String transcriptPath, {String? outputDir}) {
    final base = _basenameWithoutExtension(transcriptPath);
    if (outputDir != null && outputDir.isNotEmpty) {
      final dir = outputDir.endsWith('/') || outputDir.endsWith('\\')
          ? outputDir.substring(0, outputDir.length - 1)
          : outputDir;
      return '$dir${Platform.pathSeparator}$base.enhanced.txt';
    }
    final sep = _lastSeparator(transcriptPath);
    final dir = sep >= 0 ? transcriptPath.substring(0, sep) : '.';
    return '$dir${Platform.pathSeparator}$base.enhanced.txt';
  }

  static String _extractOutputText(String responseBody) {
    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    final output = decoded['output'] as List<dynamic>? ?? [];
    final buffer = StringBuffer();
    for (final item in output) {
      final message = item as Map<String, dynamic>;
      if (message['type'] != 'message') continue;
      final content = message['content'] as List<dynamic>? ?? [];
      for (final part in content) {
        final partMap = part as Map<String, dynamic>;
        if (partMap['type'] == 'output_text') {
          buffer.write(partMap['text'] as String? ?? '');
        }
      }
    }
    return buffer.toString().trim();
  }

  static String _basenameWithoutExtension(String path) {
    final name = path.substring(_lastSeparator(path) + 1);
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  static int _lastSeparator(String path) {
    final slash = path.lastIndexOf('/');
    final backslash = path.lastIndexOf(r'\');
    return slash > backslash ? slash : backslash;
  }
}
