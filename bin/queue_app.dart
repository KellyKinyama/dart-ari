import 'dart:convert';
import 'dart:io';

import 'package:dart_ari/dart_ari.dart';
import 'package:dart_ari/webserver/models/recordings.dart';
import 'package:dotenv/dotenv.dart';
import 'package:uuid/uuid.dart';
import 'utils.dart';

late String voiceLoggerIp; // = env['VOICE_LOGGER_IP']!;
late int voiceLoggerPort; // = int.parse(env['VOICE_LOGGER_PORT']!);

late ARI client;

HttpClient httpRtpClient = HttpClient();
Future<int?> rtpPort(String filename) async {
  var uri = Uri(
      scheme: "http",
      userInfo: "",
      host: voiceLoggerIp,
      port: voiceLoggerPort,
      query: "",
      queryParameters: {'filename': filename});
  try {
    HttpClientRequest request = await httpRtpClient.postUrl(uri);
    HttpClientResponse response = await request.close();
    //print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    var port = json.decode(stringData); //print(stringData);
    return port['rtp_port'];
  } catch (e) {
    print("Error: $e");
  }
}

Future<bool> checkAgentStatus(String endpoint) async {
  bool isIdle = await DbQueries.isAgentIdle(endpoint);
  if (isIdle) {
    print("The agent is idle.");
    return true;
  } else {
    print("The agent is not idle.");
    return false;
  }
}

stasisStart(StasisStart event, Channel channel) async {
  bool dialed = event.args.length > 0 ? event.args[0] == 'dialed' : false;
  if (channel.name.contains('UnicastRTP')) {
    dialed = true;
  }

  if (!dialed) {
    //throw variable;
    await channel.answer();

    Playback playback = client.playback();
    await channel.play(playback, media: ['sound:vm-dialout']);

    // var free = await DbQueries.freeAgents();
    final free = await longestWaiting();
    print("Free agents: $free");

    //const oneSec = Duration(seconds: 3);
    // Timer.periodic(oneSec, (Timer t) {
    //   callTimers[channel.id] = t;
    //   channel.off();
    // if (await checkAgentStatus(free.substring(free.lastIndexOf("/")))) {
    print("Calling agent: $free");
    await originate(channel, free);
    // }
    //callTimers.remove(channel.id);
    // });
  } else {
    if (event.args.length > 0 && event.args[0] == 'dialed') {}
  }
}

Future<void> originate(Channel incoming, String agent) async {
  Uuid uid = Uuid();
  String filename = uid.v1();

  String endpoint = "PJSIP${agent.substring(agent.lastIndexOf("/"))}";
  print("Agent enpoint to dial: $endpoint");

  int? rtpport = await rtpPort(filename);

  //int? rtpport = await rtpPort(filename);
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

      //}
    }

    if (dialChannel.state == 'Ringing') {
      print("dialed channel: ${dialed.id} is ${dialChannel.state}");
      DbQueries.updateAgentStatus(endpoint, AgentState.LOGGEDIN.toString(),
          AgentState.RINGING.toString());
    }
  });

  dialed.on('ChannelDestroyed', (event) async {
    var (channelDestroyedEvent, channel) = event as (ChannelDestroyed, Channel);

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
      await mixingBridge
          .addChannel(channels: [incoming.id, dialed.id, externalChannel!.id]);
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
