import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dart_ari/ari/api/enums.dart';
import 'package:dart_ari/dart_ari.dart';
import 'package:dart_ari/webserver/models/recordings.dart';
import 'package:dotenv/dotenv.dart';
import 'package:uuid/uuid.dart';

late String voiceLoggerIp;
late int voiceLoggerPort;
late ARI client;

final HttpClient httpRtpClient = HttpClient()
  ..connectionTimeout = const Duration(seconds: 10)
  ..maxConnectionsPerHost = 1000;

final Map<String, Completer<void>> activeCalls = {};
final Map<String, Timer> agentSearchTimers = {};
final Map<String, Bridge> activeBridges = {};
final Random _random = Random();

Future<int?> rtpPort(String filename) async {
  final uri = Uri(
    scheme: "http",
    host: voiceLoggerIp,
    port: voiceLoggerPort,
    queryParameters: {'filename': filename},
  );

  try {
    final request = await httpRtpClient.postUrl(uri);
    final response = await request.close();
    final stringData = await response.transform(utf8.decoder).join();
    final port = json.decode(stringData);
    return port['rtp_port'];
  } catch (e) {
    print("RTP Port Error: $e");
    return null;
  }
}

Future<void> stasisStart(StasisStart event, Channel channel) async {
  try {
    final dialed = event.args.isNotEmpty ? event.args[0] == 'dialed' : false;

    if (!dialed && !channel.name.contains('UnicastRTP')) {
      await channel.answer();

      final playback = client.playback();
      await channel.play(playback, media: ['sound:vm-dialout']);

      await findOrCreateBridge(channel);
    }
  } catch (e, st) {
    print("StasisStart Error: $e\n$st");
    await _safeHangup(channel);
    await _cleanupCall(channel.id);
  }
}

Future<void> findOrCreateBridge(Channel channel) async {
  try {
    final callCompleter = Completer<void>();
    activeCalls[channel.id] = callCompleter;

    Bridge? availableBridge =
        activeBridges.isEmpty ? null : activeBridges.values.first;

    if (availableBridge == null) {
      availableBridge = await client.bridge(type: ['holding']);
      activeBridges[availableBridge.id] = availableBridge;
      print("Created new holding bridge: ${availableBridge.id}");

      try {
        await availableBridge.startMoh();
      } catch (e) {
        print("Error starting MOH: $e");
      }
    }

    await availableBridge.addChannel(channels: [channel.id]);

    _startAgentSearch(channel, availableBridge);

    channel.on('StasisEnd', (_) async {
      await _cleanupCall(channel.id);

      if (voiceRecords[channel.id] == null) {
        CallRecording(
          file_name: "empty",
          file_path: "empty",
          agent_number: "empty",
          phone_number: channel.caller.number,
          answerdate: DateTime.now().toString(),
          src: channel.caller.number,
          dst: "empty",
          clid: channel.caller.number,
        ).insertCallRecording();
      }
    });

    channel.on('ChannelDestroyed', (_) async {
      await _cleanupCall(channel.id);
    });

    // How long client can be on hold start

    Timer(const Duration(minutes: 10), () async {
      if (!callCompleter.isCompleted) {
        print("Call ${channel.id} timed out after 10 minutes");
        await _safeHangup(channel);
        await _cleanupCall(channel.id);
      }
    });
    // Do you wish to continue logic
  } catch (e, st) {
    print("Bridge Error: $e\n$st");
    await _safeHangup(channel);
    await _cleanupCall(channel.id);
  }
}

void _startAgentSearch(Channel channel, Bridge holdBridge) {
  const initialDelay = Duration(seconds: 3);
  const maxDelay = Duration(seconds: 30);
  var currentDelay = initialDelay;

  void search() async {
    if (activeCalls[channel.id]?.isCompleted ?? true) {
      return;
    }

    try {
      final freeAgent = await longestWaiting();
      if (freeAgent != null) {
        await originate(channel, holdBridge, freeAgent);
        return;
      }

      currentDelay = Duration(
        milliseconds: (currentDelay.inMilliseconds * 1.5)
                .clamp(
                  initialDelay.inMilliseconds,
                  maxDelay.inMilliseconds,
                )
                .toInt() +
            _random.nextInt(1000),
      );

      agentSearchTimers[channel.id] = Timer(currentDelay, search);
    } catch (e) {
      print("Agent Search Error: $e");
      await _safeHangup(channel);
      await _cleanupCall(channel.id);
    }
  }

  agentSearchTimers[channel.id] = Timer(initialDelay, search);
}

Future<bool> originate(
  Channel incoming,
  Bridge holdingBridge,
  String agent,
) async {
  final filename = Uuid().v1();
  final endpoint = "PJSIP${agent.substring(agent.lastIndexOf("/"))}";
  print("Dialing agent: $endpoint");

  try {
    final rtpport = await rtpPort(filename);
    final dialed = await client.channel(endpoint: endpoint);

    _setupCallHandlers(incoming, dialed, endpoint, filename, rtpport);

    dialed.on('ChannelStateChange', (event) async {
      final (_, dialChannel) = event as (ChannelStateChange, Channel);
      if (dialChannel.state == 'Up') {
        await holdingBridge.removeChannel(channel: [incoming.id]);
      }
    });

    await dialed.originate(
      endpoint: endpoint,
      app: 'hello',
      appArgs: [
        'dialed',
        endpoint,
        "channel${incoming.id}",
        incoming.caller.number,
        filename
      ],
      callerId: incoming.caller.number,
    );

    return true;
  } catch (e, st) {
    print("Originate Error: $e\n$st");
    await DbQueries.updateAgentStatus(
        endpoint, AgentState.UNKNOWN, AgentState.UNKNOWN);

    Timer(const Duration(seconds: 5), () {
      _startAgentSearch(incoming, holdingBridge);
    });

    return false;
  }
}

void _setupCallHandlers(
  Channel incoming,
  Channel dialed,
  String endpoint,
  String filename,
  int? rtpport,
) {
  voiceRecords[incoming.id] = CallRecording(
    file_name: filename,
    file_path: filename,
    agent_number: endpoint,
    phone_number: incoming.caller.number,
    answerdate: DateTime.now().toString(),
    src: incoming.caller.number,
    dst: endpoint,
    clid: incoming.caller.number,
  );

  incoming.on('StasisEnd', (_) async {
    await _cleanupCall(incoming.id);
    await _safeHangup(dialed);
  });

  dialed.on('ChannelStateChange', (event) async {
    final (_, dialChannel) = event as (ChannelStateChange, Channel);

    if (dialChannel.state == 'Up') {
      await DbQueries.updateAgentStatus(
          endpoint, AgentState.LOGGEDIN, AgentState.ONCONVERSATION);
    } else if (dialChannel.state == 'Ringing') {
      await DbQueries.updateAgentStatus(
          endpoint, AgentState.LOGGEDIN, AgentState.RINGING);
    }
  });

  dialed.on('ChannelDestroyed', (event) async {
    final (destroyedEvent, _) = event as (ChannelDestroyed, Channel);

    if (voiceRecords[incoming.id] != null) {
      voiceRecords[incoming.id]!
        ..duration_number = destroyedEvent.timestamp.toString()
        ..hangupdate = destroyedEvent.timestamp.toString();
    }

    await DbQueries.updateAgentStatus(
        endpoint, AgentState.LOGGEDIN, AgentState.IDLE);
    await _cleanupCall(incoming.id);
  });

  dialed.on('StasisStart', (_) async {
    await dialed.answer();

    final mixingBridge = await client.bridge(type: ['mixing']);

    if (rtpport != null) {
      final externalChannel = await client.externalMedia(
        (err, _) => err ? throw err : null,
        app: 'hello',
        variables: {'CALLERID(name)': endpoint, 'recording': 'yes'},
        external_host: '$voiceLoggerIp:$rtpport',
        format: 'alaw',
      );
      await mixingBridge
          .addChannel(channels: [incoming.id, dialed.id, externalChannel.id]);
    } else {
      await mixingBridge.addChannel(channels: [incoming.id, dialed.id]);
    }

    dialed.on('StasisEnd', (_) async {
      await mixingBridge.destroy();
      if (voiceRecords[incoming.id] != null) {
        await voiceRecords[incoming.id]!.insertCallRecording();
        voiceRecords.remove(incoming.id);
      }

      await _cleanupCall(incoming.id);
    });
  });
}

Future<void> _cleanupCall(String channelId) async {
  agentSearchTimers[channelId]?.cancel();
  agentSearchTimers.remove(channelId);

  activeCalls[channelId]?.complete();
  activeCalls.remove(channelId);

  // voiceRecords.remove(channelId);

  // _cleanupEmptyBridges();
}

Future<void> _safeHangup(Channel? channel) async {
  try {
    if (channel != null) {
      try {
        await channel.hangup();
      } catch (e) {
        print("Hangup Error: $e");
      }
    }
  } catch (e) {
    print("SafeHangup Error: $e");
  }
}

void _cleanupEmptyBridges() {
  Timer(const Duration(minutes: 5), () async {
    try {
      final bridgesToRemove = <String>[];

      for (final entry in activeBridges.entries) {
        try {
          await entry.value.destroy();
          bridgesToRemove.add(entry.key);
        } catch (e) {
          print("Error destroying bridge ${entry.key}: $e");
        }
      }

      bridgesToRemove.forEach(activeBridges.remove);
    } catch (e) {
      print("Bridge cleanup error: $e");
    }
  });
}

void queueApp(ARI ari) {
  final env = DotEnv(includePlatformEnvironment: true)..load();
  voiceLoggerIp = env['VOICE_LOGGER_IP']!;
  voiceLoggerPort = int.parse(env['VOICE_LOGGER_PORT']!);
  client = ari;

  client.on("StasisStart", (event) {
    final (stasisStartEvent, channel) = event as (StasisStart, Channel);
    print("Channel ${channel.id} entered application");
    unawaited(stasisStart(stasisStartEvent, channel));
  });
}
