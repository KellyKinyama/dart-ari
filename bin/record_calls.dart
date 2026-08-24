import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_ari/ari/api/ari_exception.dart';
import 'package:dart_ari/dart_ari.dart';
import 'package:dotenv/dotenv.dart';
import 'package:uuid/uuid.dart';

/// Runnable ARI recorder using the externalMedia pattern: answers the
/// incoming Stasis channel, dials a peer endpoint, joins caller + peer +
/// an externalMedia UnicastRTP leg into a mixing bridge, and forks the
/// mixed RTP to a separate recorder daemon (which you provide). Also
/// drops a JSON sidecar per call into [recordingsDir] with the SDP-
/// negotiated IPs from both signaling legs.
///
/// Env required:
///   ASTERISK_ARI_SCHEME   (default: http)
///   ASTERISK_ARI_HOST
///   ASTERISK_ARI_PORT     (default: 8088)
///   ASTERISK_ARI_USERNAME
///   ASTERISK_ARI_PASSWORD
///   PHONE_ENDPOINT        (endpoint to dial, e.g. "PJSIP/7000")
///
///   RECORDER_HTTP_HOST    (the recorder daemon's HTTP control host)
///   RECORDER_HTTP_PORT    (default: 8080)
///   RECORDER_RTP_HOST     (default: same as `RECORDER_HTTP_HOST` — where
///                          Asterisk will send RTP)
///   RECORDER_ALLOC_PATH   (default: `/` — POSTed with `?filename=<basename>`,
///                          must return JSON `{"rtp_port": <int>}`)
///   RECORDER_STOP_PATH    (optional, default unset — if set, POSTed with
///                          `?filename=<basename>` on call end)
///   RECORDER_FORMAT       (default: `alaw` — RTP payload format,
///                          e.g. `alaw|ulaw|slin16`)
///
///   RECORDINGS_DIR        (default: ./recordings_out — JSON sidecars)
///
/// Dialplan needs to route inbound calls into Stasis:
///   exten => _X.,1,NoOp(ari-recorder inbound)
///    same =>   n,Stasis(hello)
///    same =>   n,Hangup()
late ARI ari;
late String peerEndpoint;
late Directory recordingsDir;
late _RecorderConfig _recorder;

final HttpClient _recorderHttp = HttpClient()
  ..connectionTimeout = const Duration(seconds: 5);

class _RecorderConfig {
  _RecorderConfig({
    required this.httpHost,
    required this.httpPort,
    required this.rtpHost,
    required this.allocPath,
    required this.stopPath,
    required this.format,
  });

  final String httpHost;
  final int httpPort;
  final String rtpHost;
  final String allocPath;
  final String? stopPath;
  final String format;
}

/// In-flight state per incoming (customer) channel id.
final Map<String, _CallState> _calls = {};

class _CallState {
  _CallState({
    required this.callerId,
    required this.baseName,
  });

  final String callerId;
  final String baseName;

  String? peerId;
  String? bridgeId;
  String? externalMediaId;
  int? rtpPort;
  DateTime callDate = DateTime.now().toUtc();
  DateTime? answerDate;
  DateTime? hangupDate;
  String disposition = 'NO ANSWER';

  SdpEndpoints? callerSdp;
  SdpEndpoints? peerSdp;

  /// SIP correlation headers per leg. Populated in the same order the ARI
  /// events fire; each map key is the SIP header name (Call-ID, From, To,
  /// Contact, ...). Enables downstream tools to pull a pcap-side dialog
  /// that carries the "real" agent SDP behind a B2BUA like Alcatel OXE.
  final Map<String, String?> callerSip = {};
  final Map<String, String?> peerSip = {};

  late final CallRecording rec = CallRecording(
    agent_number: peerEndpoint,
    phone_number: '',
    file_name: baseName,
    file_path: baseName,
    calldate: callDate.toIso8601String(),
  );
}

Future<void> main(List<String> args) async {
  final env = DotEnv(includePlatformEnvironment: true)..load();

  final scheme = env['ASTERISK_ARI_SCHEME'] ?? 'http';
  final host = _require(env, 'ASTERISK_ARI_HOST');
  final port = int.parse(env['ASTERISK_ARI_PORT'] ?? '8088');
  final user = _require(env, 'ASTERISK_ARI_USERNAME');
  final pass = _require(env, 'ASTERISK_ARI_PASSWORD');
  peerEndpoint = _require(env, 'PHONE_ENDPOINT');

  final recHttpHost = _require(env, 'RECORDER_HTTP_HOST');
  _recorder = _RecorderConfig(
    httpHost: recHttpHost,
    httpPort: int.parse(env['RECORDER_HTTP_PORT'] ?? '8080'),
    rtpHost: env['RECORDER_RTP_HOST'] ?? recHttpHost,
    allocPath: env['RECORDER_ALLOC_PATH'] ?? '/',
    stopPath: env['RECORDER_STOP_PATH'],
    format: env['RECORDER_FORMAT'] ?? 'alaw',
  );

  recordingsDir = Directory(env['RECORDINGS_DIR'] ?? './recordings_out');
  if (!recordingsDir.existsSync()) {
    recordingsDir.createSync(recursive: true);
  }

  ari = ARI(scheme, host, port, '$user:$pass');

  ari.on('StasisStart', (event) {
    final (stasisStart, channel) = event as (StasisStart, Channel);
    unawaited(_handleStasisStart(stasisStart, channel));
  });

  ari.on('StasisEnd', (event) {
    final (stasisEnd, channel) = event as (StasisEnd, Channel);
    unawaited(_handleStasisEnd(stasisEnd, channel));
  });

  print('[recorder] connecting to $scheme://$host:$port ari/events '
      '(app=hello, dial=$peerEndpoint, '
      'recorder=${_recorder.rtpHost}:<alloc>, format=${_recorder.format}, '
      'out=${recordingsDir.path})');
  await ari.connect();
  print('[recorder] ready — waiting for Stasis(hello) calls');

  // Keep the isolate alive until Ctrl+C.
  final done = Completer<void>();
  ProcessSignal.sigint.watch().listen((_) {
    print('[recorder] SIGINT received, exiting');
    done.complete();
  });
  await done.future;
}

String _require(DotEnv env, String key) {
  final v = env[key];
  if (v == null || v.isEmpty) {
    stderr.writeln('[recorder] FATAL: env var $key is required');
    exit(2);
  }
  return v;
}

Future<void> _handleStasisStart(StasisStart event, Channel channel) async {
  final dialed = event.args.isNotEmpty && event.args[0] == 'dialed';
  if (dialed) {
    // The peer leg entered Stasis — the incoming-side handler wires it up.
    return;
  }
  if (channel.name.contains('UnicastRTP')) {
    return;
  }

  try {
    print('[recorder] StasisStart caller=${channel.name} id=${channel.id}');
    await channel.answer();

    final uid = const Uuid().v1();
    final baseName = CallRecording.buildFilename(uniqueId: uid);

    final state = _CallState(
      callerId: channel.id,
      baseName: baseName,
    );
    state.rec.phone_number = channel.caller.number;
    state.rec.src = channel.caller.number;
    state.rec.dst = peerEndpoint;
    state.rec.clid = channel.caller.name;
    _calls[channel.id] = state;

    // Caller is now Up; SDP is already negotiated (we just sent 200 OK).
    state.callerSdp = await _safeSdp(channel);
    _mergeSdp(state);
    print('[recorder] caller SDP: ${state.callerSdp}');

    state.callerSip.addAll(await _readSipHeaders(channel));
    print('[recorder] caller SIP: ${state.callerSip}');

    await _originatePeer(channel, state);
  } catch (e, st) {
    print('[recorder] StasisStart error: $e\n$st');
    try {
      await channel.hangup();
    } catch (_) {}
  }
}

Future<void> _originatePeer(Channel incoming, _CallState state) async {
  final peer = await ari.channel(
    endpoint: peerEndpoint,
    app: 'hello',
    appArgs: ['dialed'],
    callerId: incoming.caller.number,
  );
  state.peerId = peer.id;

  peer.on('StasisStart', (evt) {
    unawaited(_onPeerStasisStart(incoming, peer, state));
  });

  peer.on('ChannelDestroyed', (evt) {
    unawaited(_finalize(incoming, state, reason: 'peer destroyed'));
  });

  // `POST /channels/create` only ALLOCATES the channel and puts it into
  // Stasis in pre-dial state. Without this dial() call the far endpoint
  // never sees a SIP INVITE — the caller just hears silence.
  await ChannelsApi.dial(
    channelId: peer.id,
    caller: incoming.id,
    timeout: 30,
  );
}

Future<void> _onPeerStasisStart(
    Channel incoming, Channel peer, _CallState state) async {
  try {
    print('[recorder] peer ${peer.name} entered Stasis');

    // Reaching Stasis after ari.channel(app=hello) means the peer answered.
    state.answerDate = DateTime.now().toUtc();
    state.disposition = 'ANSWERED';

    final rtpPort = await _allocateRecorderPort(state.baseName);
    state.rtpPort = rtpPort;

    final ext = await ari.externalMedia(
      (err, _) {
        if (err) throw StateError('externalMedia setup failed');
      },
      app: 'hello',
      external_host: '${_recorder.rtpHost}:$rtpPort',
      format: _recorder.format,
      variables: {
        'CALLERID(name)': 'recorder',
        'recording': state.baseName,
      },
    );
    state.externalMediaId = ext.id;
    print('[recorder] externalMedia leg=${ext.name} -> '
        '${_recorder.rtpHost}:$rtpPort (${_recorder.format})');

    final bridge = await ari.bridge(type: ['mixing']);
    state.bridgeId = bridge.id;

    await bridge.addChannel(channels: [incoming.id, peer.id, ext.id]);
    print('[recorder] mixing bridge=${bridge.id} has caller+peer+extMedia; '
        'recording $rtpPort -> ${state.baseName}.${_recorder.format}');

    // Fire-and-forget: trunk SDP finishes negotiating shortly after the
    // bridge is assembled; poll until CHANNEL(rtp,dest) is populated.
    unawaited(_capturePeerSdp(peer, state));
    unawaited(_capturePeerSip(peer, state));
  } catch (e, st) {
    print('[recorder] externalMedia/bridge setup failed: $e\n$st');
    await _finalize(incoming, state, reason: 'setup failed');
  }
}

/// Retry the peer SDP fetch until we get RTP endpoints or run out of tries.
/// Trunk-side SDP negotiation completes AFTER Stasis entry, so a single read
/// at StasisStart returns nulls.
Future<void> _capturePeerSdp(Channel peer, _CallState state) async {
  const attempts = [200, 400, 800, 1600]; // ms backoff
  for (final delayMs in attempts) {
    await Future.delayed(Duration(milliseconds: delayMs));
    if (!_calls.containsKey(state.callerId)) return; // call already ended
    final sdp = await _debugSdp(peer, 'peer(t=+${delayMs}ms)');
    if (sdp == null) continue;
    state.peerSdp = sdp;
    _mergeSdp(state);
    if (sdp.rtpDest != null) {
      print('[recorder] peer SDP resolved: $sdp');
      return;
    }
  }
  print('[recorder] peer SDP not populated after retries: ${state.peerSdp}');
}

/// Capture SIP correlation headers on the peer channel. Retries because the
/// PJSIP session may not have processed the trunk's 200 OK by the time
/// StasisStart fires. See docs/ari-recorder/agent-identification.md.
Future<void> _capturePeerSip(Channel peer, _CallState state) async {
  const attempts = [100, 300, 800, 1500];
  for (final delayMs in attempts) {
    await Future.delayed(Duration(milliseconds: delayMs));
    if (!_calls.containsKey(state.callerId)) return;
    final headers = await _readSipHeaders(peer);
    if (headers.values.every((v) => v == null)) continue;
    state.peerSip
      ..clear()
      ..addAll(headers);
    print('[recorder] peer SIP: ${state.peerSip}');
    return;
  }
  print('[recorder] peer SIP headers not populated after retries');
}

/// Ask the recorder daemon to reserve a UDP port for [basename].
/// Contract: `POST http://<httpHost>:<httpPort><allocPath>?filename=<basename>`
/// returns JSON `{"rtp_port": <int>}`. Throws on any non-2xx or malformed
/// response so the caller can be cleanly hung up instead of left hanging.
Future<int> _allocateRecorderPort(String basename) async {
  final uri = Uri(
    scheme: 'http',
    host: _recorder.httpHost,
    port: _recorder.httpPort,
    path: _recorder.allocPath,
    queryParameters: {'filename': basename},
  );
  final req = await _recorderHttp.postUrl(uri);
  final resp = await req.close();
  final body = await resp.transform(utf8.decoder).join();
  if (resp.statusCode < 200 || resp.statusCode >= 300) {
    throw StateError(
        'recorder alloc failed: HTTP ${resp.statusCode} body=$body');
  }
  final decoded = jsonDecode(body);
  final port = decoded is Map ? decoded['rtp_port'] : null;
  if (port is! int) {
    throw StateError('recorder alloc returned no rtp_port: $body');
  }
  return port;
}

/// Optional: tell the daemon to close the file for [basename]. Best-effort.
Future<void> _stopRecorderPort(String basename) async {
  final path = _recorder.stopPath;
  if (path == null || path.isEmpty) return;
  try {
    final uri = Uri(
      scheme: 'http',
      host: _recorder.httpHost,
      port: _recorder.httpPort,
      path: path,
      queryParameters: {'filename': basename},
    );
    final req = await _recorderHttp.postUrl(uri);
    final resp = await req.close();
    await resp.drain<void>();
  } catch (e) {
    print('[recorder] stop hook failed for $basename: $e');
  }
}

Future<SdpEndpoints?> _safeSdp(Channel ch) async {
  try {
    return await ch.sdpEndpoints();
  } catch (e) {
    print('[recorder] sdpEndpoints failed for ${ch.name}: $e');
    return null;
  }
}

/// Read the SIP correlation headers from a PJSIP channel via
/// `PJSIP_HEADER(read,<name>)`. Any header that isn't set (or the channel
/// isn't PJSIP) returns null and is skipped by the caller. These identify
/// the exact SIP dialog for offline pcap correlation.
Future<Map<String, String?>> _readSipHeaders(Channel ch) async {
  const headerNames = [
    'Call-ID',
    'From',
    'To',
    'Contact',
    'Remote-Party-ID',
    'P-Asserted-Identity',
    'Diversion',
  ];
  final out = <String, String?>{};
  for (final name in headerNames) {
    try {
      final resp = await ChannelsApi.getChannelVariable(
          ch.id, 'PJSIP_HEADER(read,$name)');
      final decoded = jsonDecode(resp.resp) as Map<String, dynamic>;
      final value = decoded['value'] as String?;
      out[name] = (value == null || value.isEmpty) ? null : value;
    } on AriException {
      out[name] = null;
    }
  }
  return out;
}

/// Diagnostic: query each channel variable individually and log what came
/// back so we can see which ones are populated for a given channel. Also
/// falls back to `/rtp_statistics` which returns the negotiated endpoint
/// pair even when CHANNEL(rtp,dest) isn't set. Returns a merged best-effort
/// SdpEndpoints.
Future<SdpEndpoints?> _debugSdp(Channel ch, String label) async {
  final vars = <String, String?>{};
  final logVars = <String, String?>{};
  for (final v in [
    'CHANNEL(pjsip,remote_addr)',
    'CHANNEL(pjsip,local_addr)',
    'CHANNEL(rtp,src)',
    'CHANNEL(rtp,dest)',
    'CHANNEL(rtp,them)',
    'CHANNEL(rtp,us)',
    'CHANNEL(rtp,direct)',
  ]) {
    try {
      final resp = await ChannelsApi.getChannelVariable(ch.id, v);
      final decoded = jsonDecode(resp.resp) as Map<String, dynamic>;
      final value = decoded['value'] as String?;
      vars[v] = value;
      logVars[v] = value;
    } on AriException catch (e) {
      vars[v] = null;
      logVars[v] = '<HTTP ${e.statusCode}>';
    }
  }
  print('[recorder] $label channel vars: $logVars');

  try {
    final stats = await ch.rtpStatistics();
    final relevant = {
      'local_addr': '${stats['local_ss'] ?? stats['local_addr'] ?? '?'}',
      'remote_addr': '${stats['remote_ss'] ?? stats['remote_addr'] ?? '?'}',
      'local_ssrc': stats['local_ssrc'],
      'remote_ssrc': stats['remote_ssrc'],
    };
    print('[recorder] $label rtp_statistics: $relevant');
  } catch (e) {
    print('[recorder] $label rtp_statistics failed: $e');
  }

  String? pick(String primary, [String? alt]) =>
      _nonEmpty(vars[primary]) ?? (alt != null ? _nonEmpty(vars[alt]) : null);

  return SdpEndpoints(
    pjsipRemote: pick('CHANNEL(pjsip,remote_addr)'),
    pjsipLocal: pick('CHANNEL(pjsip,local_addr)'),
    rtpSrc: pick('CHANNEL(rtp,src)', 'CHANNEL(rtp,us)'),
    rtpDest: pick('CHANNEL(rtp,dest)', 'CHANNEL(rtp,them)'),
  );
}

String? _nonEmpty(String? s) => (s == null || s.isEmpty) ? null : s;

void _mergeSdp(_CallState state) {
  final c = state.callerSdp;
  final p = state.peerSdp;
  if (c != null) {
    state.rec.caller_rtp_local = c.rtpSrc;
    state.rec.caller_rtp_remote = c.rtpDest;
    state.rec.caller_sip_remote = c.pjsipRemote;
  }
  if (p != null) {
    state.rec.peer_rtp_local = p.rtpSrc;
    state.rec.peer_rtp_remote = p.rtpDest;
    state.rec.peer_sip_remote = p.pjsipRemote;
  }
}

Future<void> _handleStasisEnd(StasisEnd event, Channel channel) async {
  final state = _calls[channel.id];
  if (state == null) return;
  await _finalize(channel, state, reason: 'StasisEnd');
}

Future<void> _finalize(Channel caller, _CallState state,
    {required String reason}) async {
  if (!_calls.containsKey(state.callerId)) return;
  _calls.remove(state.callerId);

  state.hangupDate = DateTime.now().toUtc();
  final billsec = state.answerDate == null
      ? 0
      : state.hangupDate!.difference(state.answerDate!).inSeconds;
  final duration = state.hangupDate!.difference(state.callDate).inSeconds;

  state.rec.calldate = state.callDate.toIso8601String();
  state.rec.answerdate = state.answerDate?.toIso8601String() ?? '';
  state.rec.hangupdate = state.hangupDate!.toIso8601String();
  state.rec.duration = duration.toString();
  state.rec.billsec = billsec.toString();
  state.rec.disposition = state.disposition;

  final ipBaseName = CallRecording.buildFilename(
    uniqueId: state.baseName.split('_').last,
    callerIp: state.callerSdp?.remoteRtpIp,
    peerIp: state.peerSdp?.remoteRtpIp,
    timestamp: state.callDate,
  );

  final sidecar = {
    'reason': reason,
    'daemon_basename': state.baseName,
    'ip_tagged_basename': ipBaseName,
    'recorder_rtp_host': _recorder.rtpHost,
    'recorder_rtp_port': state.rtpPort,
    'recorder_format': _recorder.format,
    // SIP correlation IDs — feed to sngrep/tshark to pull the raw dialog
    // and (for B2BUAs like Alcatel OXE) the real agent SDP endpoint.
    'caller_sip': state.callerSip,
    'peer_sip': state.peerSip,
    ...state.rec.parse(),
    'src': state.rec.src,
    'dst': state.rec.dst,
    'clid': state.rec.clid,
    'calldate': state.rec.calldate,
    'answerdate': state.rec.answerdate,
    'hangupdate': state.rec.hangupdate,
    'duration': state.rec.duration,
    'billsec': state.rec.billsec,
    'disposition': state.rec.disposition,
  };

  final outFile =
      File('${recordingsDir.path}${Platform.pathSeparator}$ipBaseName.json');
  await outFile
      .writeAsString(const JsonEncoder.withIndent('  ').convert(sidecar));
  print('[recorder] wrote ${outFile.path} ($reason, billsec=$billsec)');

  // Best-effort cleanup, in dependency order: notify the daemon, delete
  // the externalMedia leg, destroy the bridge, hang up the peer.
  await _stopRecorderPort(state.baseName);
  if (state.externalMediaId != null) {
    try {
      await ChannelsApi.externalMediaDelete(state.externalMediaId!);
    } catch (_) {}
  }
  if (state.bridgeId != null) {
    try {
      await ari.bridges[state.bridgeId!]?.destroy();
    } catch (_) {}
  }
  if (state.peerId != null) {
    try {
      await ari.channels[state.peerId!]?.hangup();
    } catch (_) {}
  }
}
