import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_ari/ari/api/enums.dart';
import 'package:dart_ari/webserver/models/recordings2.dart';
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
//   Timer? periodicTimer; // Timer for the 2-second agent check
//   Timer? timeoutTimer; // Timer for the 10-minute max duration

//   const maxDuration = Duration(minutes: 10);
//   const checkInterval = Duration(seconds: 2);

//   // Function to clean up both timers and complete the completer with a result.
//   // This is the single, safe entry point for completing the process.
//   void cleanupAndComplete(String result) {
//     if (!completer.isCompleted) {
//       periodicTimer?.cancel();
//       timeoutTimer?.cancel();
//       // Crucially, remove the event listener once done.
//       incoming.off();
//       print("pickAgent: Completing with result: '$result'. Timers cancelled.");
//       completer.complete(result);
//     } else {
//       // Just in case a cleanup call is slightly delayed after completion.
//       periodicTimer?.cancel();
//       timeoutTimer?.cancel();
//     }
//   }

//   // 1. Set up the 10-minute timeout timer
//   timeoutTimer = Timer(maxDuration, () {
//     print("pickAgent: 10-minute timeout reached. No agent found.");
//     // Complete with an empty string on timeout.
//     cleanupAndComplete("");
//   });

//   // 2. Listener for StasisEnd (Incoming channel hangs up)
//   // This ensures a cleanup if the caller hangs up while waiting.
//   incoming.on('StasisEnd', (_) {
//     print("pickAgent: Incoming channel hung up (StasisEnd).");
//     cleanupAndComplete("");
//   });

//   // 3. Start the periodic timer for agent checking
//   periodicTimer = Timer.periodic(checkInterval, (Timer t) async {
//     // If we somehow get a tick after cleanup, stop the timer immediately.
//     if (completer.isCompleted) {
//       t.cancel();
//       return;
//     }

//     print("pickAgent: Timer tick. Attempting to find an agent...");
//     final freeAgent =
//         await longestWaiting(); // Assuming this is defined elsewhere

//     if (freeAgent != null) {
//       print("pickAgent: Agent found! $freeAgent. Cancelling timers...");
//       // Agent found, complete with the agent endpoint
//       cleanupAndComplete(freeAgent);
//     } else {
//       print("pickAgent: No agent found in this tick. Will retry...");
//     }
//   });

//   // Return the Future that resolves upon agent found, hangup, or timeout.
//   return completer.future;
// }

// Future<String> pickAgent(
//   Channel incoming,
// ) async {
//   Completer<String> completer = Completer<String>();
//   Timer? searchTimer; // Holds the reference for the next scheduled search
//   Timer? timeoutTimer; // Timer for the 10-minute max duration

//   const maxDuration = Duration(minutes: 10);
//   const checkInterval = Duration(seconds: 2);

//   // Single entry point for cleanup and completion
//   void cleanupAndComplete(String result) {
//     if (!completer.isCompleted) {
//       searchTimer?.cancel();
//       timeoutTimer?.cancel();
//       incoming.off(); // Remove listeners from the channel
//       print("pickAgent: Completing with result: '$result'. Search stopped.");
//       completer.complete(result);
//     }
//   }

//   // 1. 10-minute timeout
//   timeoutTimer = Timer(maxDuration, () {
//     print("pickAgent: 10-minute timeout reached.");
//     cleanupAndComplete("");
//   });

//   // 2. Listener for Incoming hangup
//   incoming.on('StasisEnd', (_) {
//     print("pickAgent: Incoming channel hung up (StasisEnd).");
//     cleanupAndComplete("");
//   });

//   // 3. Recursive Search Function
//   Future<void> startSearch() async {
//     // Stop if the caller hung up or timed out while we were waiting for DB
//     if (completer.isCompleted) return;

//     print("pickAgent: Starting agent search tick...");

//     try {
//       final freeAgent = await longestWaiting();

//       if (freeAgent != null) {
//         print("pickAgent: Agent found! $freeAgent.");
//         cleanupAndComplete(freeAgent);
//       } else {
//         print(
//             "pickAgent: No agent found. Retrying in ${checkInterval.inSeconds}s...");
//         // Schedule the next search ONLY if we haven't completed yet
//         if (!completer.isCompleted) {
//           searchTimer = Timer(checkInterval, startSearch);
//         }
//       }
//     } catch (e) {
//       print("pickAgent: Error during search: $e. Retrying...");
//       if (!completer.isCompleted) {
//         searchTimer = Timer(checkInterval, startSearch);
//       }
//     }
//   }

//   // Initial call to start the loop
//   startSearch();

//   return completer.future;
// }

Future<String> pickAgent(Channel incoming) async {
  Completer<String> completer = Completer<String>();
  Timer? searchTimer;
  Timer? timeoutTimer;
  bool isSearching = false; // Prevents overlapping timer executions

  const maxDuration = Duration(minutes: 10);
  const checkInterval = Duration(seconds: 2);

  void cleanupAndComplete(String result) {
    if (!completer.isCompleted) {
      searchTimer?.cancel();
      timeoutTimer?.cancel();
      // Remove specific listeners instead of .off() if you have other
      // important listeners on this channel, but for this flow .off() is fine.
      incoming.off();
      completer.complete(result);
    }
  }

  timeoutTimer = Timer(maxDuration, () => cleanupAndComplete(""));
  incoming.on('StasisEnd', (_) => cleanupAndComplete(""));

  Future<void> startSearch() async {
    // 1. Critical Guards
    if (completer.isCompleted || isSearching) return;

    isSearching = true;
    try {
      // longestWaiting now handles the Atomic DB Claim internally.
      // If it returns a string, that agent is ALREADY marked as RINGING in the DB.
      final freeAgent = await longestWaiting();

      if (freeAgent != null) {
        cleanupAndComplete(freeAgent);
      } else {
        // Only schedule the next tick if we didn't find anyone
        if (!completer.isCompleted) {
          searchTimer = Timer(checkInterval, startSearch);
        }
      }
    } catch (e) {
      print("Search Error: $e");
      if (!completer.isCompleted) {
        searchTimer = Timer(checkInterval, startSearch);
      }
    } finally {
      isSearching = false; // Always unlock the search flag
    }
  }

  startSearch();
  return completer.future;
}

// Future<void> originate(
//   Channel incoming,
//   Bridge holdingBridge,
// ) async {
//   final filename = Uuid().v1();
//   final rtpport = await rtpPort(filename);

//   // 1. ACQUIRE AGENT
//   final freeAgent = await pickAgent(incoming);

//   if (freeAgent.isEmpty) {
//     print("Originate: No agent picked or queue timed out. Exiting.");
//     return;
//   }

//   // PRUNE OLD LISTENERS to avoid logic duplication on retry
//   incoming.off();

//   try {
//     final endpoint = freeAgent;
//     String dst =
//         endpoint.startsWith("PJSIP/") ? endpoint.substring(6) : endpoint;

//     CallRecording? voiceRecord;
//     print("Dialing agent: $endpoint");

//     final dialed = await client.channel(endpoint: endpoint);
//     final mixingBridge = await client.bridge(type: ['mixing']);

//     // --- SHARED CLEANUP FUNCTION ---
//     bool isReleased = false;
//     Future<void> cleanUp() async {
//       if (isReleased) return;
//       isReleased = true;

//       try {
//         await DbQueries.updateAgentStatus(
//             endpoint, AgentState.LOGGEDIN, AgentState.IDLE);
//         await mixingBridge.destroy().catchError((e) => null);
//       } finally {
//         releaseAgentLock(freeAgent);
//       }
//     }

//     // Path 1: Agent side ends
//     dialed.on('StasisEnd', (event) async {
//       try {
//         final (sEnd, _) = event as (StasisEnd, Channel);
//         await incoming.hangup().catchError((e) => null);

//         if (voiceRecord != null) {
//           voiceRecord!.hangupdate = sEnd.timestamp.toIso8601String();
//           await voiceRecord!.insertCallRecording();
//         }
//         await Future.delayed(Duration(seconds: 15)); // Wrap-up cooldown
//       } finally {
//         await cleanUp();
//       }
//     });

//     // Path 2: Customer side ends
//     incoming.on('StasisEnd', (_) async {
//       await dialed.hangup().catchError((e) => null);
//       await cleanUp();
//     });

//     // Path 3: Channel Destruction
//     dialed.on('ChannelDestroyed', (_) => cleanUp());
//     incoming.on('ChannelDestroyed', (_) => cleanUp());

//     // --- State Updates ---
//     dialed.on('ChannelStateChange', (event) async {
//       final (_, dialChannel) = event as (ChannelStateChange, Channel);
//       if (dialChannel.state == 'Up') {
//         await holdingBridge
//             .removeChannel(channel: [incoming.id]).catchError((e) => null);
//         await DbQueries.updateAgentStatus(
//             endpoint, AgentState.LOGGEDIN, AgentState.ONCONVERSATION);
//       } else if (dialChannel.state == 'Ringing') {
//         await DbQueries.updateAgentStatus(
//             endpoint, AgentState.LOGGEDIN, AgentState.RINGING);
//       }
//     });

//     // --- Connection Logic ---
//     dialed.on('StasisStart', (event) async {
//       final (sStart, _) = event as (StasisStart, Channel);
//       await dialed.answer();

//       voiceRecord = CallRecording(
//         file_name: filename,
//         file_path: filename,
//         agent_number: dst,
//         phone_number: incoming.caller.number,
//         answerdate: sStart.timestamp.toIso8601String(),
//         src: incoming.caller.number,
//         dst: dst,
//         clid: incoming.caller.number,
//       );

//       try {
//         await mixingBridge.addChannel(channels: [dialed.id, incoming.id]);

//         if (rtpport != null) {
//           final externalChannel = await client.externalMedia(
//             (err, _) => err ? throw err : null,
//             app: 'hello',
//             variables: {'CALLERID(name)': endpoint, 'recording': 'yes'},
//             external_host: '$voiceLoggerIp:$rtpport',
//             format: 'alaw',
//           );
//           await mixingBridge.addChannel(channels: [externalChannel.id]);
//           dialed.on('StasisEnd',
//               (_) => externalChannel.hangup().catchError((e) => null));
//         }
//       } catch (e) {
//         print("Bridge Error: $e");
//         await dialed.hangup().catchError((e) => null);
//         await cleanUp();
//       }
//     });

//     // Execute Dial
//     await dialed.originate(
//       endpoint: endpoint,
//       app: 'hello',
//       appArgs: [
//         'dialed',
//         endpoint,
//         incoming.id,
//         incoming.caller.number,
//         filename
//       ],
//       callerId: incoming.caller.number,
//     );
//   } catch (e, st) {
//     print("FATAL ERROR: $e");
//     // If dial fails to even start, reset agent immediately
//     await DbQueries.updateAgentStatus(
//         freeAgent, AgentState.LOGGEDIN, AgentState.IDLE);
//     releaseAgentLock(freeAgent);
//   }
// }

Future<void> originate(
  Channel incoming,
  Bridge holdingBridge,
) async {
  final filename = Uuid().v1();
  final rtpport = await rtpPort(filename);

  // 1. ACQUIRE AGENT
  final freeAgent = await pickAgent(incoming);
  if (freeAgent.isEmpty) return;

  incoming.off();

  final endpoint = freeAgent;
  String dst = endpoint.startsWith("PJSIP/") ? endpoint.substring(6) : endpoint;

  // Declare variables here so cleanUp() can see them
  Bridge? mixingBridge;
  bool isReleased = false;

  // THE FINALIZER
  Future<void> cleanUp() async {
    if (isReleased) return;
    isReleased = true;

    try {
      print("Finalizer: Setting $endpoint to IDLE.");
      // ALWAYS AWAIT DB calls
      await DbQueries.updateAgentStatus(
          endpoint, AgentState.LOGGEDIN, AgentState.IDLE);

      // Only destroy if it was actually created
      if (mixingBridge != null) {
        await mixingBridge!.destroy().catchError((e) => null);
      }
    } catch (e) {
      print("Finalizer Error: $e");
    } finally {
      releaseAgentLock(freeAgent);
    }
  }

  try {
    final dialed = await client.channel(endpoint: endpoint);
    // Initialize the scoped variable
    mixingBridge = await client.bridge(type: ['mixing']);
    CallRecording? voiceRecord;

    // WATCHDOG
    Timer watchdog = Timer(Duration(seconds: 60), () async {
      if (!isReleased) {
        print("Watchdog: Forcing cleanup for $endpoint.");
        await dialed.hangup().catchError((e) => null);
        await cleanUp();
      }
    });

    // --- EVENT LISTENERS ---
    dialed.on('StasisEnd', (event) async {
      watchdog.cancel();
      try {
        final (sEnd, _) = event as (StasisEnd, Channel);
        await incoming.hangup().catchError((e) => null);

        if (voiceRecord != null) {
          voiceRecord!.hangupdate = sEnd.timestamp.toIso8601String();
          await voiceRecord!.insertCallRecording();
        }
      } finally {
        await cleanUp();
      }
    });

    incoming.on('StasisEnd', (_) async {
      watchdog.cancel();
      await dialed.hangup().catchError((e) => null);
      await cleanUp();
    });

    dialed.on('ChannelDestroyed', (_) async => await cleanUp());
    incoming.on('ChannelDestroyed', (_) async => await cleanUp());

    dialed.on('ChannelStateChange', (event) async {
      final (_, dialChannel) = event as (ChannelStateChange, Channel);
      if (dialChannel.state == 'Up') {
        watchdog.cancel();
        await holdingBridge
            .removeChannel(channel: [incoming.id]).catchError((e) => null);
        await DbQueries.updateAgentStatus(
            endpoint, AgentState.LOGGEDIN, AgentState.ONCONVERSATION);
      } else if (dialChannel.state == 'Ringing') {
        await DbQueries.updateAgentStatus(
            endpoint, AgentState.LOGGEDIN, AgentState.RINGING);
      }
    });

    dialed.on('StasisStart', (event) async {
      watchdog.cancel();
      final (sStart, _) = event as (StasisStart, Channel);
      await dialed.answer().catchError((e) => null);

      voiceRecord = CallRecording(
        file_name: filename,
        file_path: filename,
        agent_number: dst,
        phone_number: incoming.caller.number,
        answerdate: sStart.timestamp.toIso8601String(),
        src: incoming.caller.number,
        dst: dst,
        clid: incoming.caller.number,
      );

      try {
        // Safe check for mixingBridge
        if (mixingBridge != null) {
          await mixingBridge!.addChannel(channels: [dialed.id, incoming.id]);
        }

        if (rtpport != null) {
          final externalChannel = await client.externalMedia(
            (err, _) => err ? throw err : null,
            app: 'hello',
            variables: {'CALLERID(name)': endpoint, 'recording': 'yes'},
            external_host: '$voiceLoggerIp:$rtpport',
            format: 'alaw',
          );

          if (mixingBridge != null) {
            await mixingBridge.addChannel(channels: [externalChannel.id]);
          }

          dialed.on('StasisEnd', (_) async {
            await externalChannel.hangup().catchError((e) => null);
          });
        }
      } catch (e) {
        print("StasisStart Error: $e");
        await dialed.hangup().catchError((e) => null);
        await cleanUp();
      }
    });

    // ORIGINATE
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
  } catch (e) {
    print("Originate Setup Error: $e");
    await cleanUp();
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
