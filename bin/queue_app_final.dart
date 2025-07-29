import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_ari/ari/api/enums.dart';
import 'package:dart_ari/ari/api/misc.dart';
import 'package:dart_ari/webserver/models/recordings.dart';
import 'package:dotenv/dotenv.dart';
import 'package:dart_ari/dart_ari.dart';
import 'package:uuid/uuid.dart';

late String voiceLoggerIp;
late int voiceLoggerPort;
late ARI client;

final HttpClient httpRtpClient = HttpClient()
  ..connectionTimeout = const Duration(seconds: 10)
  ..maxConnectionsPerHost = 1000;

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
    // await _safeHangup(channel);
    // await _cleanupCall(channel.id);
  }
}

Future<void> findOrCreateBridge(Channel channel) async {
  // final holdingBridge = await client.bridge(type: ['holding']);

  var bridgesList = await Bridge.list();

  Bridge? holdingBridge = bridgesList
      .where((Bridge candidate) {
        return candidate.bridge_type == 'holding';
      })
      .toList()
      .firstOrNull;
  holdingBridge ??= await client.bridge(type: ['holding']);
  // activeBridges[availableBridge.id] = availableBridge;
  print("Created new holding bridge: ${holdingBridge.id}");

  try {
    await holdingBridge.addChannel(channels: [channel.id]);
    await holdingBridge.startMoh();
  } catch (e) {
    print("Error starting MOH: $e");
  }
  await originate(channel, holdingBridge);
}

Future<String> pickAgent(
  Channel incoming,
) async {
  Completer<String> completer = Completer<String>();
  Timer? timer; // Declare a Timer variable to hold the periodic timer
  incoming.on('StasisEnd', (_) async {
    if (timer != null) {
      timer.cancel();
      completer.complete("");
    }
  });
  // Start the periodic timer
  timer = Timer.periodic(Duration(seconds: 2), (Timer t) async {
    print("pickAgent: Timer tick. Attempting to find an agent...");
    final freeAgent =
        await longestWaiting(); // Await the result of longestWaiting

    if (freeAgent != null) {
      print("pickAgent: Agent found! $freeAgent. Cancelling timer...");
      t.cancel(); // Cancel the periodic timer as soon as an agent is found

      // Now, complete the main Completer with the found agent after your desired 2-second delay
      // Future.delayed(Duration(seconds: 2), () {
      incoming.off();
      completer.complete(freeAgent);
      // });
    } else {
      print("pickAgent: No agent found this tick. Will retry...");
    }
  });

  // Return the Future associated with the completer.
  // This Future will only complete when completer.complete() is called inside the timer's callback.
  return completer.future;
}

Future<void> originate(
  Channel incoming,
  Bridge holdingBridge,
  // String agent,
) async {
  final filename = Uuid().v1();
  // final endpoint = "PJSIP${agent.substring(agent.lastIndexOf("/"))}";
  final rtpport = await rtpPort(filename);
  final freeAgent = await pickAgent(incoming);
  final endpoint = freeAgent;

  String dst = endpoint;
  if (dst.startsWith("PJSIP/")) {
    dst = dst.substring(6);
  }

  CallRecording? voiceRecord;
  print("Dialing agent: $endpoint");

  final dialed = await client.channel(endpoint: endpoint);

  final mixingBridge = await client.bridge(type: ['mixing']);

  dialed.on('StasisEnd', (ssEndevent) async {
    final (sEndEvent, _) = ssEndevent as (StasisEnd, Channel);
    await mixingBridge.destroy();
    // incoming.hangup();
    await holdingBridge.removeChannel(channel: [incoming.id]);
    if (voiceRecord != null) {
      voiceRecord!.hangupdate = sEndEvent.timestamp.toIso8601String();

      await voiceRecord!.insertCallRecording();
    }

    setTimeout(() async {
      await DbQueries.updateAgentStatus(
          endpoint, AgentState.LOGGEDIN, AgentState.IDLE);

      releaseAgentLock(freeAgent);
    }, 10000);
  });

  incoming.on('StasisEnd', (_) async {
    await mixingBridge.destroy();
    dialed.hangup();
    await holdingBridge.removeChannel(channel: [incoming.id]);
  });

  dialed.on('ChannelDestroyed', (cdEvent) async {
    final (destroyedEvent, _) = cdEvent as (ChannelDestroyed, Channel);
    if (voiceRecord != null) {
      voiceRecord!
        ..duration_number = destroyedEvent.timestamp.toString()
        // ..hangupdate = destroyedEvent.timestamp.toString();
        ..hangupdate = destroyedEvent.timestamp.toString();
    }
    await mixingBridge.destroy();
    incoming.hangup();
    await holdingBridge.removeChannel(channel: [incoming.id]);

    setTimeout(() async {
      await DbQueries.updateAgentStatus(
          endpoint, AgentState.LOGGEDIN, AgentState.IDLE);

      releaseAgentLock(freeAgent);
    }, 10000);
  });

  dialed.on('ChannelStateChange', (event) async {
    final (_, dialChannel) = event as (ChannelStateChange, Channel);
    if (dialChannel.state == 'Up') {
      await holdingBridge.removeChannel(channel: [incoming.id]);
    }
    if (dialChannel.state == 'Up') {
      await DbQueries.updateAgentStatus(
          endpoint, AgentState.LOGGEDIN, AgentState.ONCONVERSATION);
    } else if (dialChannel.state == 'Ringing') {
      await DbQueries.updateAgentStatus(
          endpoint, AgentState.LOGGEDIN, AgentState.RINGING);
    }
  });

  dialed.on('StasisStart', (ssEvent) async {
    final (sStartEvent, _) = ssEvent as (StasisStart, Channel);
    await dialed.answer();

    voiceRecord = CallRecording(
      file_name: filename,
      file_path: filename,
      agent_number: dst,
      phone_number: incoming.caller.number,
      answerdate: sStartEvent.timestamp.toIso8601String(),
      src: incoming.caller.number,
      dst: dst,
      clid: incoming.caller.number,
    );
    if (rtpport != null) {
      final externalChannel = await client.externalMedia(
        (err, _) => err ? throw err : null,
        app: 'hello',
        variables: {'CALLERID(name)': endpoint, 'recording': 'yes'},
        external_host: '$voiceLoggerIp:$rtpport',
        format: 'alaw',
      );

      dialed.on('ChannelDestroyed', (_) async {
        await externalChannel.hangup();
      });

      dialed.on('StasisEnd', (_) async {
        await externalChannel.hangup();
      });

      incoming.on('ChannelDestroyed', (_) async {
        await externalChannel.hangup();
      });

      incoming.on('StasisEnd', (_) async {
        await externalChannel.hangup();
      });

      try {
        await mixingBridge.addChannel(channels: [dialed.id]);
        await mixingBridge.addChannel(channels: [externalChannel.id]);
        await mixingBridge.addChannel(channels: [incoming.id]);
      } catch (e, st) {
        print("Error adding channels to bridge: $e, stacktrace: $st");
        await dialed.hangup();
        await externalChannel.hangup();
        await mixingBridge.destroy();
      }
    } else {
      try {
        await mixingBridge.addChannel(channels: [dialed.id]);
        await mixingBridge.addChannel(channels: [incoming.id]);
      } catch (e, st) {
        print("Error adding channels to bridge: $e, stacktrace: $st");
        await dialed.hangup();
        await mixingBridge.destroy();
      }
    }
  });

  await dialed.originate(
    endpoint: endpoint,
    app: 'hello',
    appArgs: [
      'dialed',
      endpoint,
      incoming.id,
      incoming.caller.number,
      filename
    ],
    callerId: incoming.caller.number,
  );
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
