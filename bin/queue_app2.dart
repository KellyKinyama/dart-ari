import 'dart:convert';
import 'dart:io';

import 'package:dart_ari/ari/api/enums.dart';
import 'package:dart_ari/dart_ari.dart';
import 'package:dart_ari/webserver/models/recordings.dart';
import 'package:dotenv/dotenv.dart';
import 'package:uuid/uuid.dart';

late String voiceLoggerIp;
late int voiceLoggerPort;
late ARI client;

Map<String, AgentState> agentsStatuses = {
  'SIP/7000/8828': AgentState.IDLE,
  'SIP/7000/8703': AgentState.IDLE,
};

HttpClient httpRtpClient = HttpClient();

Future<int?> rtpPort(String filename) async {
  var uri = Uri(
      scheme: "http",
      host: voiceLoggerIp,
      port: voiceLoggerPort,
      queryParameters: {'filename': filename});
  try {
    HttpClientRequest request = await httpRtpClient.postUrl(uri);
    HttpClientResponse response = await request.close();
    final String stringData = await response.transform(utf8.decoder).join();
    var port = json.decode(stringData);
    return port['rtp_port'];
  } catch (e) {
    print("Error: $e");
    return null;
  }
}

Future<void> playComfortMessage(Channel channel) async {
  const comfortInterval = Duration(seconds: 30);
  // while (channel.state == 'Up') {
  Playback playback = client.playback();
  await channel.play(playback, media: ['sound:please-hold']);
  await Future.delayed(comfortInterval);
  // }
}

Future<void> attemptAgentCall(Channel channel, int retries) async {
  const retryDelay = Duration(seconds: 10);
  const maxRetries = 3;

  final free = agentsStatuses.entries
      .firstWhere(
        (entry) => entry.value == AgentState.IDLE,
        orElse: () => MapEntry("", AgentState.ONCONVERSATION),
      )
      .key;

  if (free.isNotEmpty) {
    await originate(channel, free);
    return;
  }

  if (retries >= maxRetries) {
    Playback busyPlayback = client.playback();
    await channel.play(busyPlayback, media: ['sound:all-circuits-busy-now']);
    await busyPlayback.once('PlaybackFinished', (_) async {
      await channel.hangup();
    });
    return;
  }

  print("No agents available. Retrying in ${retryDelay.inSeconds} seconds...");
  await Future.delayed(retryDelay);
  await attemptAgentCall(channel, retries + 1);
}

stasisStart(StasisStart event, Channel channel) async {
  await channel.answer();
  await playComfortMessage(channel);
  await attemptAgentCall(channel, 0);
}

Future<bool> originate(Channel incoming, String agent) async {
  Uuid uid = Uuid();
  String filename = uid.v1();

  String endpoint = "PJSIP${agent.substring(agent.lastIndexOf("/"))}";
  print("Agent enpoint to dial: $endpoint");

  int? rtpport = await rtpPort(filename);

  //int? rtpport = await rtpPort(filename);
  try {
    var dialed = await client.channel(endpoint: endpoint);

    Channel? externalChannel;

    incoming.on('StasisEnd', (event) async {
      var (stasisEndEvent, channel) = event as (StasisEnd, Channel);

      // if (incomingStasisEndListeners[incoming.id] == null) {
      //   incomingStasisEndListeners[incoming.id] = 1;
      // } else {
      //   throw "Incoming channel: ${incoming.id} is already listening to StasisEnd event";
      // }

      print("Incoming channel: ${incoming.id} exited our apllication");

      await dialed.hangup();
    });

    dialed.on('ChannelStateChange', (event) {
      var (channelStateChangeEvent, dialChannel) =
          event as (ChannelStateChange, Channel);
      print('Dialed status to: ${dialChannel.state}');

      if (dialChannel.state == 'Up') {
        print("dialed channel: ${dialed.id} is on a call");
        voiceRecords[incoming.id] = CallRecording(
          file_name: filename,
          file_path: filename,
          agent_number: endpoint,
          phone_number: incoming.caller.number,
          answerdate: channelStateChangeEvent.timestamp.toString(),
          src: incoming.caller.number,
          dst: endpoint,
          clid: incoming.caller.number,
        );

        DbQueries.updateAgentStatus(endpoint, AgentState.LOGGEDIN.toString(),
            AgentState.ONCONVERSATION.toString());
        agentsStatuses[agent] = AgentState.ONCONVERSATION;

        //}
      }

      if (dialChannel.state == 'Ringing') {
        print("dialed channel: ${dialed.id} is ${dialChannel.state}");
        DbQueries.updateAgentStatus(endpoint, AgentState.LOGGEDIN.toString(),
            AgentState.RINGING.toString());
        agentsStatuses[agent] = AgentState.RINGING;
      }
    });

    dialed.on('ChannelDestroyed', (event) async {
      var (channelDestroyedEvent, channel) =
          event as (ChannelDestroyed, Channel);

      print("dialed channel: ${dialed.id} exited our application");

      // if (dialedChannelDestroyedListeners[incoming.id] == null) {
      //   dialedChannelDestroyedListeners[incoming.id] = 1;
      // } else {
      //   throw "Dialed channel: ${channel.id} is already listening to ChannelDestroyed event";
      // }

      if (voiceRecords[incoming.id] != null) {
        voiceRecords[incoming.id]!.duration_number =
            channelDestroyedEvent.timestamp.toString();
        voiceRecords[incoming.id]!.hangupdate =
            channelDestroyedEvent.timestamp.toString();
//          voiceRecords.remove(incoming.id);
      }
      agentsStatuses[agent] = AgentState.IDLE;

      DbQueries.updateAgentStatus(
          endpoint, AgentState.LOGGEDIN.toString(), AgentState.IDLE.toString());
      await incoming.hangup();
    });

    dialed.on('StasisStart', (event) async {
      // if (dialedStasisStartListeners[incoming.id] == null) {
      //   dialedStasisStartListeners[incoming.id] = 1;
      // } else {
      //   throw "Dialed channel: ${dialed.id} is already listening to ChannelDestroyed event";
      // }
      print("dialed channel: ${dialed.id} entered our application");

      Bridge mixingBridge = await client.bridge(type: ['mixing']);

      dialed.on('StasisEnd', (event) async {
        var (stasisEndEvent, channel) = event as (StasisEnd, Channel);

        print("dialed channel: ${dialed.id} exited our application");

        await mixingBridge.destroy();
        // if (externalChannel != null) {
        //   await externalChannel!.hangup();
        // }

        await incoming.hangup();

        if (voiceRecords[incoming.id] != null) {
          voiceRecords[incoming.id]!.duration_number =
              stasisEndEvent.timestamp.toString();

          voiceRecords[incoming.id]!.hangupdate =
              stasisEndEvent.timestamp.toString();
          await voiceRecords[incoming.id]!.insertCallRecording();
          DbQueries.updateAgentStatus(endpoint, AgentState.LOGGEDIN.toString(),
              AgentState.IDLE.toString());
          agentsStatuses[agent] = AgentState.IDLE;
          //agent.waitingSince = DateTime.now();
          //voiceRecords.remove(incoming.id);
        }
      });

      await dialed.answer();

      if (rtpport != null) {
        externalChannel = await client.externalMedia(
          (err, externChannel) {
            if (err) throw err;
          },
          app: 'hello',
          variables: {'CALLERID(name)': endpoint, 'recording': 'yes'},
          external_host: '$voiceLoggerIp:$rtpport',
          format: 'alaw',
        );

        // //final mixingBridge = await bridge.create(type: ['mixing']);
        await mixingBridge.addChannel(
            channels: [incoming.id, dialed.id, externalChannel!.id]);
      } else {
        await mixingBridge.addChannel(channels: [incoming.id, dialed.id]);
      }

      //await mixingBridge.addChannel(channels: [incoming.id, dialed.id]);
    });

    await dialed.originate(
        // endpoint: next_agent.number,
        endpoint: endpoint,
        app: 'hello',
        appArgs: ['dialed', endpoint, incoming.id],
        callerId: incoming.caller.number);
  } catch (e, st) {
    print("Error: $e, Stack trace: $st");
    return false;
  }
  return false;
}

void queueApp(ARI ari) {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  voiceLoggerIp = env['VOICE_LOGGER_IP']!;
  voiceLoggerPort = int.parse(env['VOICE_LOGGER_PORT']!);
  client = ari;

  client.on("StasisStart", (event) {
    var (stasisStartEvent, channel) = (event) as (StasisStart, Channel);
    print("Channel: ${channel.id} entered stasis application");
    stasisStart(stasisStartEvent, channel);
  });
}
