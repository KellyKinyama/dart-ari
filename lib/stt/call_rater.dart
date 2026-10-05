import 'dart:convert';

import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;

/// A QA score for a single call, produced by the LLM.
class CallRating {
  final int introduction;
  final int callHandling;
  final int closing;
  final int overall;
  final String feedback;
  final String model;

  CallRating({
    required this.introduction,
    required this.callHandling,
    required this.closing,
    required this.overall,
    required this.feedback,
    required this.model,
  });
}

/// Scores a call transcript on agent performance via the Azure AI Foundry LLM
/// (OpenAI-compatible Responses API), returning 1-5 ratings per category.
class CallRater {
  final String endpoint;
  final String apiKey;
  final String deployment;

  CallRater({
    required this.endpoint,
    required this.apiKey,
    required this.deployment,
  });

  static const String _systemPrompt =
      'You are a call-center QA evaluator for ZESCO, a Zambian electricity '
      'utility. You are given a transcript of a phone call between an Agent and '
      'a Caller. Score the AGENT from 1 (poor) to 5 (excellent) on each of: '
      '"introduction" (greeted the caller, gave their name, identified ZESCO, '
      'offered to assist), "call_handling" (professionalism, listening, '
      'addressing the issue, politeness), "closing" (recap or next steps and a '
      'courteous sign-off), and "overall". Also provide brief "feedback" of at '
      'most two sentences. Respond with ONLY a JSON object with integer keys '
      'introduction, call_handling, closing, overall (each 1-5) and a string '
      'key feedback. No markdown, no commentary.';

  factory CallRater.fromEnv() {
    final env = DotEnv(includePlatformEnvironment: true)..load();

    final endpoint = env['AZURE_AI_ENDPOINT'] ??
        'https://aiml4good.services.ai.azure.com/openai/v1';

    final apiKey = env['AZURE_AI_KEY'] ?? env['AZURE_SPEECH_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == '<your-api-key>') {
      throw StateError('AZURE_AI_KEY (or AZURE_SPEECH_KEY) is not set in .env');
    }

    return CallRater(
      endpoint: endpoint,
      apiKey: apiKey,
      deployment: env['AZURE_AI_DEPLOYMENT'] ?? 'gpt-5.4',
    );
  }

  Uri _responsesUri() {
    final base =
        endpoint.endsWith('/') ? endpoint.substring(0, endpoint.length - 1) : endpoint;
    return Uri.parse('$base/responses');
  }

  /// Rates [transcript]; returns null when the transcript is empty or the
  /// model response can't be parsed into a valid rating.
  Future<CallRating?> rate(String transcript) async {
    if (transcript.trim().isEmpty) return null;

    final response = await http.post(
      _responsesUri(),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': deployment,
        'instructions': _systemPrompt,
        'input': transcript,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Rating failed (${response.statusCode}): ${response.body}');
    }

    final text = _extractOutputText(response.body);
    final map = _parseJsonObject(text);
    if (map == null) return null;

    return CallRating(
      introduction: _score(map['introduction']),
      callHandling: _score(map['call_handling']),
      closing: _score(map['closing']),
      overall: _score(map['overall']),
      feedback: (map['feedback'] ?? '').toString().trim(),
      model: deployment,
    );
  }

  static int _score(dynamic value) {
    final n = value is num ? value.round() : int.tryParse('$value') ?? 0;
    return n.clamp(1, 5);
  }

  static Map<String, dynamic>? _parseJsonObject(String text) {
    var raw = text.trim();
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final decoded = jsonDecode(raw.substring(start, end + 1));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static String _extractOutputText(String responseBody) {
    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    final output = decoded['output'] as List<dynamic>? ?? [];
    final buffer = StringBuffer();
    for (final item in output) {
      final message = item as Map<String, dynamic>;
      if (message['type'] != 'message') continue;
      for (final part in (message['content'] as List<dynamic>? ?? [])) {
        final partMap = part as Map<String, dynamic>;
        if (partMap['type'] == 'output_text') {
          buffer.write(partMap['text'] as String? ?? '');
        }
      }
    }
    return buffer.toString();
  }
}
