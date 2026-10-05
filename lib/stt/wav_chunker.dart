import 'dart:typed_data';

/// Parsed fields from a WAV header plus the location of its audio data.
class WavInfo {
  final int audioFormat;
  final int channels;
  final int sampleRate;
  final int bitsPerSample;
  final int byteRate;
  final Uint8List fmtChunk;
  final int dataOffset;
  final int dataLength;

  WavInfo({
    required this.audioFormat,
    required this.channels,
    required this.sampleRate,
    required this.bitsPerSample,
    required this.byteRate,
    required this.fmtChunk,
    required this.dataOffset,
    required this.dataLength,
  });

  int get bytesPerSecond =>
      byteRate > 0 ? byteRate : sampleRate * channels * (bitsPerSample ~/ 8);
}

/// Splits a PCM WAV file into smaller self-contained WAV chunks so each stays
/// within the Azure short-audio recognition limit (~60 seconds).
class WavChunker {
  /// Returns the WAV [bytes] split into sub-WAVs of at most [maxSeconds] each.
  ///
  /// Returns a single-element list (the original bytes) when the audio is
  /// short enough, not PCM, or the header can't be parsed.
  static List<Uint8List> split(Uint8List bytes, {int maxSeconds = 50}) {
    final info = parse(bytes);
    if (info == null || info.audioFormat != 1) {
      return [bytes]; // non-PCM or unparseable: let the caller send as-is
    }

    final blockAlign = info.channels * (info.bitsPerSample ~/ 8);
    final bps = info.bytesPerSecond;
    if (bps <= 0 || blockAlign <= 0) return [bytes];

    var chunkBytes = bps * maxSeconds;
    chunkBytes -= chunkBytes % blockAlign; // align to a whole sample frame
    if (chunkBytes <= 0 || info.dataLength <= chunkBytes) return [bytes];

    final chunks = <Uint8List>[];
    var pos = 0;
    while (pos < info.dataLength) {
      final len =
          (pos + chunkBytes <= info.dataLength) ? chunkBytes : info.dataLength - pos;
      final slice = Uint8List.sublistView(
        bytes,
        info.dataOffset + pos,
        info.dataOffset + pos + len,
      );
      chunks.add(_buildWav(info.fmtChunk, slice));
      pos += len;
    }
    return chunks;
  }

  /// Parses the RIFF/WAVE header, locating the `fmt ` and `data` chunks.
  static WavInfo? parse(Uint8List b) {
    if (b.length < 12) return null;
    if (String.fromCharCodes(b.sublist(0, 4)) != 'RIFF') return null;
    if (String.fromCharCodes(b.sublist(8, 12)) != 'WAVE') return null;

    final view = ByteData.sublistView(b);
    var pos = 12;
    Uint8List? fmt;
    var audioFormat = 0, channels = 0, sampleRate = 0, bitsPerSample = 0, byteRate = 0;
    var dataOffset = -1, dataLength = 0;

    while (pos + 8 <= b.length) {
      final id = String.fromCharCodes(b.sublist(pos, pos + 4));
      final size = view.getUint32(pos + 4, Endian.little);
      final body = pos + 8;
      if (id == 'fmt ' && body + 16 <= b.length) {
        audioFormat = view.getUint16(body, Endian.little);
        channels = view.getUint16(body + 2, Endian.little);
        sampleRate = view.getUint32(body + 4, Endian.little);
        byteRate = view.getUint32(body + 8, Endian.little);
        bitsPerSample = view.getUint16(body + 14, Endian.little);
        fmt = Uint8List.sublistView(b, body, body + size);
      } else if (id == 'data') {
        dataOffset = body;
        dataLength = size;
        break;
      }
      pos = body + size + (size & 1); // chunks are word-aligned
    }

    if (fmt == null || dataOffset < 0) return null;
    if (dataOffset + dataLength > b.length) dataLength = b.length - dataOffset;

    return WavInfo(
      audioFormat: audioFormat,
      channels: channels,
      sampleRate: sampleRate,
      bitsPerSample: bitsPerSample,
      byteRate: byteRate,
      fmtChunk: fmt,
      dataOffset: dataOffset,
      dataLength: dataLength,
    );
  }

  static Uint8List _buildWav(Uint8List fmt, Uint8List data) {
    final riffSize = 4 + (8 + fmt.length) + (8 + data.length);
    final out = BytesBuilder();
    void str(String s) => out.add(s.codeUnits);
    void u32(int v) =>
        out.add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());

    str('RIFF');
    u32(riffSize);
    str('WAVE');
    str('fmt ');
    u32(fmt.length);
    out.add(fmt);
    str('data');
    u32(data.length);
    out.add(data);
    return out.toBytes();
  }
}
