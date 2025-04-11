import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_ari/ari/api/enums.dart';
import 'package:dart_ari/dart_ari.dart';
import 'package:dart_ari/webserver/models/recordings.dart';
import 'package:dotenv/dotenv.dart';
import 'package:events_emitter/events_emitter.dart';
import 'package:uuid/uuid.dart';
// import 'utils.dart';

late String voiceLoggerIp; // = env['VOICE_LOGGER_IP']!;
late int voiceLoggerPort; // = int.parse(env['VOICE_LOGGER_PORT']!);

late ARI client;

// Map<String, AgentState> agentsStatuses = {
//   // 'SIP/7000/8923': AgentState.LOGGEDIN,
//   // 'SIP/7000/6003': AgentState.IDLE,
//   // 'SIP/7000/8703': AgentState.IDLE,
// };

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

// Future<void> attemptAgentCall(Channel channel, int retries) async {
//   const retryDelay = Duration(seconds: 10); // Delay between retries
//   const maxRetries = 3; // Max number of retries

//   final free = await longestWaiting();
//   print("Free agent: $free");

//   if (free != null) {
//     print("Calling agent: $free");
//     // await originate(channel, free);
//     return; // Stop retrying if agent is found
//   }

//   if (retries >= maxRetries) {
//     print("All agents are busy after $maxRetries retries.");

//     // Play busy message
//     Playback busyPlayback = client.playback();
//     await channel.play(busyPlayback, media: ['sound:all-circuits-busy-now']);

//     // Hang up after the message is finished
//     await busyPlayback.once('PlaybackFinished', (_) async {
//       print("Playback finished, hanging up the call.");
//       await channel.hangup();
//     });
//     return;
//   }

//   print("No agents available. Retrying in ${retryDelay.inSeconds} seconds...");

//   // Wait before retrying
//   await Future.delayed(retryDelay);
//   await attemptAgentCall(channel, retries + 1);
// }

stasisStart(StasisStart event, Channel channel) async {
  bool dialed = event.args.length > 0 ? event.args[0] == 'dialed' : false;
  if (channel.name.contains('UnicastRTP')) {
    dialed = true;
  }

  if (!dialed) {
    await channel.answer();

    Playback playback = client.playback();
    await channel.play(playback, media: ['sound:vm-dialout']);

    print("Starting agent search with retries...");
    // await attemptAgentCall(channel, 0); // Start with zero retries

    // await originate(channel, free);
    await findOrCreateBridge(channel);
  } else {
    if (event.args.length > 0 && event.args[0] == 'dialed') {
      // Handle dialed calls if necessary
    }
  }
}

Future<void> findOrCreateBridge(Channel channel) async {
  final events = EventEmitter();
  channel.on('StasisEnd', (event) {
    events.emit('stopquery', channel);
  });
  final bridges = await Bridges.list();
  late Bridge holdBridge;

  final List<Bridge> holdingBridges = bridges.where((bridge) {
    if (bridge.bridge_type == 'holding') {
      // print("Found existing bridge: $bridge");
      return true;
    }
    return false;
  }).toList();

  if (holdingBridges.isEmpty) {
    holdBridge = await client.bridge(type: ['holding']);

    print("Created bridge: $holdBridge");
  } else {
    holdBridge = holdingBridges[0];
    print("Using existing holding bridge: $holdBridge");
  }

  await holdBridge.addChannel(channels: [channel.id]);

  await holdBridge.startMoh();
  try {
    Completer<bool> freeAgentCompleter = Completer();
    bool stopProbingForFreeAgent = false;
    String? free;
    // Timer.periodic(Duration(seconds: 3), (timer) async {
    channel.on('StasisEnd', (event) {
      // timer.cancel();
      stopProbingForFreeAgent = true;
      channel.off();
    });
    void findFreeAgent() async {
      free = await longestWaiting();
      if (free != null) {
        // timer.cancel();
        freeAgentCompleter.complete(true);
      } else {
        // timer.cancel();
        if (!stopProbingForFreeAgent) {
          await Future.delayed(Duration(seconds: 3), findFreeAgent);
        }
      }
    }

    // free = await longestWaiting();
    if (free == null) {
      // timer.cancel();
      await Future.delayed(Duration(seconds: 1), findFreeAgent);
    }
    // });

    print("Found agent: $free");
    // if (free != null) freeAgentCompleter.complete(true);

    channel.off();
    if (stopProbingForFreeAgent) {
      return;
    }

    await originate(channel, holdBridge, free!, events);
  } catch (e, st) {
    print("Error: $e, Stack trace: $st");
  }
}

// stasisStart(StasisStart event, Channel channel) async {
//   bool dialed = event.args.length > 0 ? event.args[0] == 'dialed' : false;
//   if (channel.name.contains('UnicastRTP')) {
//     dialed = true;
//   }

//   if (!dialed) {
//     //throw variable;
//     await channel.answer();

//     Playback playback = client.playback();
//     await channel.play(playback, media: ['sound:vm-dialout']);

//     // var free = await DbQueries.freeAgents();
//     final free = await longestWaiting(agentsStatuses);
//     print("Free agents: $free");

//     //const oneSec = Duration(seconds: 3);
//     // Timer.periodic(oneSec, (Timer t) {
//     //   callTimers[channel.id] = t;
//     //   channel.off();
//     // if (await checkAgentStatus(free.substring(free.lastIndexOf("/")))) {
//     print("Calling agent: $free");
//     await originate(channel, free!);
//     // }
//     //callTimers.remove(channel.id);
//     // });
//   } else {
//     if (event.args.length > 0 && event.args[0] == 'dialed') {}
//   }
// }

Future<bool> originate(Channel incoming, Bridge holdingBridge, String agent,
    EventEmitter event) async {
  Uuid uid = Uuid();
  String filename = uid.v1();

  bool dialedSucceful = false;

  String endpoint = "PJSIP${agent.substring(agent.lastIndexOf("/"))}";
  print("Agent enpoint to dial: $endpoint");

  int? rtpport = await rtpPort(filename);
  var dialed;

  Channel? externalChannel;

  //int? rtpport = await rtpPort(filename);
  try {
    dialed = await client.channel(endpoint: endpoint);

    incoming.on('StasisEnd', (event) async {
      // var (stasisEndEvent, channel) = event as (StasisEnd, Channel);

      // if (incomingStasisEndListeners[incoming.id] == null) {
      //   incomingStasisEndListeners[incoming.id] = 1;
      // } else {
      //   throw "Incoming channel: ${incoming.id} is already listening to StasisEnd event";
      // }

      print("Incoming channel: ${incoming.id} exited our apllication");
      if (dialedSucceful) {
        await DbQueries.updateAgentStatus(
            endpoint, AgentState.LOGGEDIN, AgentState.IDLE);
      }

      await dialed.hangup();
    });

    dialed.on('ChannelStateChange', (event) async {
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

        dialedSucceful = true;

        await DbQueries.updateAgentStatus(
            endpoint, AgentState.LOGGEDIN, AgentState.ONCONVERSATION);
        // agentsStatuses[agent] = AgentState.ONCONVERSATION;

        //}
      }

      if (dialChannel.state == 'Ringing') {
        if (!dialedSucceful) dialedSucceful = true;
        print("dialed channel: ${dialed.id} is ${dialChannel.state}");
        await DbQueries.updateAgentStatus(
            endpoint, AgentState.LOGGEDIN, AgentState.RINGING);
        // agentsStatuses[agent] = AgentState.RINGING;
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
      // agentsStatuses[agent] = AgentState.IDLE;

      await DbQueries.updateAgentStatus(
          endpoint, AgentState.LOGGEDIN, AgentState.IDLE);
      await incoming.hangup();
    });

    dialed.on('StasisStart', (event) async {
      // if (dialedStasisStartListeners[incoming.id] == null) {
      //   dialedStasisStartListeners[incoming.id] = 1;
      // } else {
      //   throw "Dialed channel: ${dialed.id} is already listening to ChannelDestroyed event";
      // }
      print("dialed channel: ${dialed.id} entered our application");

      await holdingBridge.removeChannel(channel: [incoming.id]);

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
          await DbQueries.updateAgentStatus(
              endpoint, AgentState.LOGGEDIN, AgentState.IDLE);
          // agentsStatuses[agent] = AgentState.IDLE;
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
        appArgs: ['dialed', endpoint, "channel${incoming.id}"],
        callerId: incoming.caller.number);
  } catch (e, st) {
    print("Error: $e, Stack trace: $st");
    await DbQueries.updateAgentStatus(
        endpoint, AgentState.UNKNOWN, AgentState.UNKNOWN);
    // agentsStatuses[agent] = AgentState.UNKNOWN;

    print("Attempting another call");
    // await findOrCreateBridge(incoming);
    String? free;
    Timer.periodic(Duration(seconds: 3), (timer) async {
      incoming.off();
      incoming.on('StasisEnd', (event) {
        // timer.cancel();
        incoming.off();
      });

      if (dialed != null) dialed.off();
      event.off();

      free = await longestWaiting();
      if (free != null) {
        timer.cancel();

        await originate(incoming, holdingBridge, free!, event);
      }
    });
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
