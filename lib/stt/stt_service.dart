import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;

import 'wav_chunker.dart';

/// Azure Speech-to-Text service, ported from the Python `stt_service`.
///
/// Uses the Azure AI Speech **real-time REST short-audio** API (there is no
/// native Azure Speech SDK for Dart). Each request handles up to ~60 seconds,
/// so longer recordings are split into chunks and transcribed sequentially.
class SttService {
  /// Resource endpoint, e.g. `https://<name>.cognitiveservices.azure.com/`,
  /// used to mint the auth token.
  final String endpoint;

  /// Speech resource subscription key.
  final String apiKey;

  /// Azure region of the resource, e.g. `southafricanorth`.
  final String region;

  /// Candidate locales. Only the first is used (short-audio takes one locale).
  final List<String> locales;

  /// Max seconds of audio per recognition request (short-audio limit is 60).
  final int chunkSeconds;

  SttService({
    required this.endpoint,
    required this.apiKey,
    required this.region,
    this.locales = const ['en-US'],
    this.chunkSeconds = 50,
  });

  /// Builds a service from `.env` (AZURE_SPEECH_* keys), independent of the
  /// ARI/DB config so it never requires those values to be present.
  factory SttService.fromEnv() {
    final env = DotEnv(includePlatformEnvironment: true)..load();

    final endpoint = env['AZURE_SPEECH_ENDPOINT'];
    if (endpoint == null || endpoint.isEmpty) {
      throw StateError('AZURE_SPEECH_ENDPOINT is not set in .env');
    }

    final apiKey = env['AZURE_SPEECH_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == '<your-api-key>') {
      throw StateError('AZURE_SPEECH_KEY is not set in .env');
    }

    final region = env['AZURE_SPEECH_REGION'];
    if (region == null || region.isEmpty) {
      throw StateError('AZURE_SPEECH_REGION is not set in .env');
    }

    final locales = (env['AZURE_STT_LANGUAGES'] ?? 'en-US')
        .split(',')
        .map((locale) => locale.trim())
        .where((locale) => locale.isNotEmpty)
        .toList();

    final chunkSeconds = int.tryParse(env['STT_CHUNK_SECONDS'] ?? '') ?? 50;

    return SttService(
      endpoint: endpoint,
      apiKey: apiKey,
      region: region,
      locales: locales.isEmpty ? const ['en-US'] : locales,
      chunkSeconds: chunkSeconds.clamp(5, 59),
    );
  }

  Uri _recognitionUri() {
    final language = locales.isNotEmpty ? locales.first : 'en-US';
    return Uri.parse(
      'https://$region.stt.speech.microsoft.com'
      '/speech/recognition/conversation/cognitiveservices/v1'
      '?language=$language&format=detailed',
    );
  }

  /// Mints a short-lived auth token from the resource's issueToken endpoint.
  ///
  /// Custom-domain multi-service resources reject the raw key on the data-plane
  /// (401), so a bearer token is used for the recognition request instead.
  Future<String> _fetchAuthToken() async {
    final base =
        endpoint.endsWith('/') ? endpoint.substring(0, endpoint.length - 1) : endpoint;
    final uri = Uri.parse('$base/sts/v1.0/issueToken');
    final response = await http.post(
      uri,
      headers: {'Ocp-Apim-Subscription-Key': apiKey},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Failed to obtain auth token (${response.statusCode}): ${response.body}',
        uri: uri,
      );
    }
    return response.body;
  }

  /// Transcribes a WAV file of any length, chunking as needed, and returns the
  /// concatenated transcript text.
  Future<String> transcribeFile(String audioPath) async {
    final file = File(audioPath);
    if (!file.existsSync()) {
      throw ArgumentError('Audio file not found: $audioPath');
    }

    final token = await _fetchAuthToken();
    final bytes = await file.readAsBytes();
    final chunks = WavChunker.split(bytes, maxSeconds: chunkSeconds);

    final parts = <String>[];
    for (final chunk in chunks) {
      final text = await _recognizeBytes(chunk, token);
      if (text.isNotEmpty) parts.add(text);
    }
    return parts.join(' ');
  }

  /// Recognizes a single WAV chunk (<= 60s) using a pre-minted [token].
  Future<String> _recognizeBytes(Uint8List wavBytes, String token) async {
    final uri = _recognitionUri();
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'audio/wav',
        'Accept': 'application/json',
      },
      body: wavBytes,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Recognition failed (${response.statusCode}): ${response.body}',
        uri: uri,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['RecognitionStatus'] != 'Success') {
      return '';
    }

    final nBest = decoded['NBest'] as List<dynamic>?;
    if (nBest != null && nBest.isNotEmpty) {
      final display = (nBest.first as Map<String, dynamic>)['Display'] as String?;
      if (display != null && display.isNotEmpty) {
        return display;
      }
    }
    return decoded['DisplayText'] as String? ?? '';
  }

  /// Transcribes [audioPath] and writes the transcript to a `.txt` file.
  ///
  /// With [outputDir] the transcript is written to `<outputDir>/<name>.txt`;
  /// otherwise it is written next to the audio file.
  Future<({String text, String outputPath})> transcribeAndSave(
    String audioPath, {
    String? outputDir,
  }) async {
    final text = await transcribeFile(audioPath);
    final outputPath = transcriptPathFor(audioPath, outputDir: outputDir);
    final parent = File(outputPath).parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }
    await File(outputPath).writeAsString('$text\n');
    return (text: text, outputPath: outputPath);
  }

  /// Returns the `.txt` path for [audioPath], honouring an optional [outputDir].
  static String transcriptPathFor(String audioPath, {String? outputDir}) {
    if (outputDir != null && outputDir.isNotEmpty) {
      final name = _basenameWithoutExtension(audioPath);
      final dir = outputDir.endsWith('/') || outputDir.endsWith('\\')
          ? outputDir.substring(0, outputDir.length - 1)
          : outputDir;
      return '$dir${Platform.pathSeparator}$name.txt';
    }
    return '${_withoutExtension(audioPath)}.txt';
  }

  /// Transcribes every `.wav` file in [folderPath], saving a `.txt` for each.
  ///
  /// With [outputDir] all transcripts are written there instead of alongside
  /// the audio files.
  Future<void> transcribeFolder(String folderPath, {String? outputDir}) async {
    final dir = Directory(folderPath);
    if (!dir.existsSync()) {
      throw ArgumentError('Folder not found: $folderPath');
    }

    final wavFiles = dir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.wav'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    if (wavFiles.isEmpty) {
      throw ArgumentError('No .wav files found in $folderPath');
    }

    for (var i = 0; i < wavFiles.length; i++) {
      final path = wavFiles[i].path;
      stdout.writeln('\n=== [${i + 1}/${wavFiles.length}] $path ===');
      try {
        final result = await transcribeAndSave(path, outputDir: outputDir);
        stdout.writeln(result.text.isEmpty ? '(no speech recognized)' : result.text);
        stdout.writeln('Saved transcript: ${result.outputPath}');
      } catch (err) {
        stderr.writeln('Failed: $path -> $err');
      }
    }
  }

  static String _withoutExtension(String path) {
    final dot = path.lastIndexOf('.');
    final separator = _lastSeparator(path);
    return dot > separator ? path.substring(0, dot) : path;
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
