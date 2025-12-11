import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_ari/ari/api/enums.dart';
import 'package:dart_ari/webserver/models/recordings.dart';
import 'package:dotenv/dotenv.dart';
import 'package:dart_ari/dart_ari.dart';
import 'dart_ari.dart';
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
  var bridgesList = await Bridge.list();

  Bridge? holdingBridge = bridgesList
      .where((Bridge candidate) {
        return candidate.bridge_type == 'holding';
      })
      .toList()
      .firstOrNull;
  holdingBridge ??= await client.bridge(type: ['holding']);
  print("Created new holding bridge: ${holdingBridge.id}");

  try {
    await holdingBridge.addChannel(channels: [channel.id]);
    await holdingBridge.startMoh();
  } catch (e) {
    print("Error starting MOH: $e");
  }
  await originate(channel, holdingBridge);
}

// Future<String> pickAgent(
//   Channel incoming,
// ) async {
//   Completer<String> completer = Completer<String>();
//   Timer? timer; // Declare a Timer variable to hold the periodic timer
//   incoming.on('StasisEnd', (_) {
//     if (timer != null) {
//       timer.cancel();
//       completer.complete("");
//     }
//   });
//   // Start the periodic timer
//   timer = Timer.periodic(Duration(seconds: 2), (Timer t) async {
//     print("pickAgent: Timer tick. Attempting to find an agent...");
//     final freeAgent =
//         await longestWaiting(); // Await the result of longestWaiting

//     if (freeAgent != null) {
//       print("pickAgent: Agent found! $freeAgent. Cancelling timer...");
//       t.cancel(); // Cancel the periodic timer as soon as an agent is found

//       // Now, complete the main Completer with the found agent
//       incoming.off();
//       completer.complete(freeAgent);
//       // });
//     } else {
//       print("pickAgent: No agent found this tick. Will retry...");
//     }
//   });

//   // Return the Future associated with the completer.
//   // This Future will only complete when completer.complete() is called inside the timer's callback.
//   return completer.future;
// }

// Future<String> pickAgent(
//   Channel incoming,
// ) async {
//   Completer<String> completer = Completer<String>();
//   Timer? timer;

//   incoming.on('StasisEnd', (_) {
//     // --- FIX APPLIED HERE ---
//     // Only attempt to complete the Completer if it hasn't been completed yet.
//     if (!completer.isCompleted) {
//       if (timer != null) {
//         timer.cancel();
//         completer.complete("");
//       }
//     }
//   });

//   // Start the periodic timer
//   timer = Timer.periodic(Duration(seconds: 2), (Timer t) async {
//     print("pickAgent: Timer tick. Attempting to find an agent...");
//     final freeAgent = await longestWaiting();

//     if (freeAgent != null) {
//       print("pickAgent: Agent found! $freeAgent. Cancelling timer...");
//       t.cancel();

//       // --- FIX APPLIED HERE ---
//       // Although the StasisEnd event is less likely to beat the agent logic,
//       // it is safer to check here as well for race conditions.
//       if (!completer.isCompleted) {
//         incoming.off();
//         completer.complete(freeAgent);
//       } else {
//         t.cancel();
//       }
//     } else {
//       print("pickAgent: No agent found in this tick. Will retry...");

//       if (completer.isCompleted) {
//         t.cancel();
//       }
//     }
//   });

//   // Return the Future associated with the completer.
//   return completer.future;
// }

Future<String> pickAgent(
  Channel incoming,
) async {
  Completer<String> completer = Completer<String>();
  Timer? periodicTimer; // Timer for the 2-second agent check
  Timer? timeoutTimer; // Timer for the 10-minute max duration

  const maxDuration = Duration(minutes: 10);
  const checkInterval = Duration(seconds: 2);

  // Function to clean up both timers and complete the completer with a result.
  // This is the single, safe entry point for completing the process.
  void cleanupAndComplete(String result) {
    if (!completer.isCompleted) {
      periodicTimer?.cancel();
      timeoutTimer?.cancel();
      // Crucially, remove the event listener once done.
      incoming.off();
      print("pickAgent: Completing with result: '$result'. Timers cancelled.");
      completer.complete(result);
    } else {
      // Just in case a cleanup call is slightly delayed after completion.
      periodicTimer?.cancel();
      timeoutTimer?.cancel();
    }
  }

  // 1. Set up the 10-minute timeout timer
  timeoutTimer = Timer(maxDuration, () {
    print("pickAgent: 10-minute timeout reached. No agent found.");
    // Complete with an empty string on timeout.
    cleanupAndComplete("");
  });

  // 2. Listener for StasisEnd (Incoming channel hangs up)
  // This ensures a cleanup if the caller hangs up while waiting.
  incoming.on('StasisEnd', (_) {
    print("pickAgent: Incoming channel hung up (StasisEnd).");
    cleanupAndComplete("");
  });

  // 3. Start the periodic timer for agent checking
  periodicTimer = Timer.periodic(checkInterval, (Timer t) async {
    // If we somehow get a tick after cleanup, stop the timer immediately.
    if (completer.isCompleted) {
      t.cancel();
      return;
    }

    Channel? stillThere = ari.stsisChannel(incoming);

    if (stillThere == null) {
      print("pickAgent: Incoming channel no longer exists.");
      cleanupAndComplete("");
      return;
    }

    final freeAgent =
        await longestWaiting(); // Assuming this is defined elsewhere

    if (freeAgent != null) {
      print("pickAgent: Agent found! $freeAgent. Cancelling timers...");
      // Agent found, complete with the agent endpoint
      cleanupAndComplete(freeAgent);
    } else {
      print("pickAgent: No agent found in this tick. Will retry...");
    }
  });

  // Return the Future that resolves upon agent found, hangup, or timeout.
  return completer.future;
}

Future<void> originate(
  Channel incoming,
  Bridge holdingBridge,
) async {
  final filename = Uuid().v1();
  final rtpport = await rtpPort(filename);

  // 1. ACQUIRE AGENT (Agent selection and locking happens inside pickAgent/longestWaiting)
  final freeAgent = await pickAgent(incoming);

  // If pickAgent returns an empty string (timeout or incoming hangup), exit early.
  // No lock was successfully acquired that needs releasing.
  if (freeAgent.isEmpty) {
    print(
        "Originate: No agent picked or queue timed out/caller hung up. Exiting.");
    return;
  }

  // --- Start of GUARANTEED Execution Block ---
  // The try-catch block ensures that if any ARI or system exception occurs
  // before the event handlers are fully registered, the lock is released.
  try {
    // Standardize endpoint reference
    final endpoint = freeAgent;

    String dst = endpoint;
    if (dst.startsWith("PJSIP/")) {
      dst = dst.substring(6);
    }

    CallRecording? voiceRecord;
    print("Dialing agent: $endpoint");

    // This line might throw if the endpoint is invalid or ARI is down.
    final dialed = await client.channel(endpoint: endpoint);

    final mixingBridge = await client.bridge(type: ['mixing']);

    // --- EVENT HANDLERS FOR SUCCESSFUL RELEASE (Call Completion) ---

    // RELEASE PATH 1: Dialed channel ends (Agent hangs up/ARI terminates call)
    dialed.on('StasisEnd', (ssEndevent) async {
      final (sEndEvent, _) = ssEndevent as (StasisEnd, Channel);
      if (voiceRecord != null) {
        voiceRecord!.hangupdate = sEndEvent.timestamp.toIso8601String();
        await voiceRecord!.insertCallRecording();
      }

      await Future.delayed(Duration(seconds: 15)); // Wrap-up time

      await DbQueries.updateAgentStatus(
          endpoint, AgentState.LOGGEDIN, AgentState.IDLE);

      await incoming.hangup();

      releaseAgentLock(freeAgent);
    });

    // RELEASE PATH 2: Incoming channel ends (Customer hangs up)
    incoming.on('StasisEnd', (_) async {
      await mixingBridge.destroy();
      await dialed.hangup();
      // await holdingBridge.removeChannel(channel: [incoming.id]); // Covered by destroy
      releaseAgentLock(freeAgent);
    });

    // RELEASE PATH 3: Incoming channel is destroyed (External system action)
    incoming.on('ChannelDestroyed', (_) async {
      // await holdingBridge.removeChannel(channel: [incoming.id]); // Covered by destroy
      releaseAgentLock(freeAgent);
    });

    // RELEASE PATH 4: Dialed channel is destroyed (Agent drops call prematurely)
    dialed.on('ChannelDestroyed', (cdEvent) async {
      final (destroyedEvent, _) = cdEvent as (ChannelDestroyed, Channel);
      if (voiceRecord != null) {
        voiceRecord!
          ..duration_number = destroyedEvent.timestamp.toString()
          ..hangupdate = destroyedEvent.timestamp.toString();
      }

      await Future.delayed(Duration(seconds: 15)); // Wrap-up time

      await DbQueries.updateAgentStatus(
          endpoint, AgentState.LOGGEDIN, AgentState.IDLE);

      await incoming.hangup();

      releaseAgentLock(freeAgent);
    });

    // --- Agent State Updates (Lock is KEPT in these states) ---

    dialed.on('ChannelStateChange', (event) async {
      final (_, dialChannel) = event as (ChannelStateChange, Channel);
      if (dialChannel.state == 'Up') {
        await holdingBridge.removeChannel(channel: [incoming.id]);
        await DbQueries.updateAgentStatus(
            endpoint, AgentState.LOGGEDIN, AgentState.ONCONVERSATION);
        // Lock is correctly kept while ONCONVERSATION
      } else if (dialChannel.state == 'Ringing') {
        await DbQueries.updateAgentStatus(
            endpoint, AgentState.LOGGEDIN, AgentState.RINGING);
        // Lock is correctly kept while RINGING
      }
      // Removed: releaseAgentLock was here, which was incorrect as the agent is still busy.
    });

    // --- StasisStart (Channel Answered/Connected) ---

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

        // RELEASE PATHS for External Channel
        dialed.on('ChannelDestroyed', (_) async {
          releaseAgentLock(freeAgent);
          await externalChannel.hangup();
          await incoming.hangup();
        });

        dialed.on('StasisEnd', (_) async {
          releaseAgentLock(freeAgent);
          await externalChannel.hangup();
          await incoming.hangup();
        });

        incoming.on('ChannelDestroyed', (_) async {
          releaseAgentLock(freeAgent);
          await externalChannel.hangup();
        });

        incoming.on('StasisEnd', (_) async {
          releaseAgentLock(freeAgent);
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
          releaseAgentLock(freeAgent); // Nested catch also releases lock
        }
      } else {
        try {
          await mixingBridge.addChannel(channels: [dialed.id]);
          await mixingBridge.addChannel(channels: [incoming.id]);
        } catch (e, st) {
          print("Error adding channels to bridge: $e, stacktrace: $st");
          await dialed.hangup();
          await mixingBridge.destroy();
          releaseAgentLock(freeAgent); // Nested catch also releases lock
        }
      }
    });

    // This is the final step that might fail before all events are guaranteed to fire.
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
        timeout: -1);
  } catch (e, st) {
    // 2. GUARANTEED RELEASE PATH (Call Setup Failure)
    print(
        "Originate Setup FATAL ERROR for agent $freeAgent: $e\n$st. Releasing agent lock.");

    // This is the CRITICAL line to ensure the lock is always released on setup failure
    releaseAgentLock(freeAgent);

    // Attempt to clean up the incoming channel (the caller) and holding bridge
    try {
      //What to do next with an incoming call that failed to originate?
      // await incoming.hangup();
      // await holdingBridge.destroy();
    } catch (_) {
      // Ignore hangup/destroy errors during error handling
    }
  }
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

  // unawaited(activeConversations());
}

Future<void> activeConversations() async {
  var bridgesList = await Bridge.list();

  bridgesList = bridgesList.where((Bridge candidate) {
    return candidate.bridge_type == 'mixing';
  }).toList();

  client.on("StasisEnd", (event) async {
    final (stasisEndEvent, channel) = event as (StasisEnd, Channel);
    print("Channel ${channel.id} entered application");

    Bridge? mixingBridge = bridgesList
        .where((Bridge candidate) {
          return candidate.channels.contains(channel.id);
        })
        .toList()
        .firstOrNull;

    if (mixingBridge != null) {
      for (var ch in mixingBridge.channels) {
        if (ch != channel.id) {
          await channel.hangup();
        } else {
          await ChannelsApi.hangup(ch);
        }
      }
    }
  });
}
