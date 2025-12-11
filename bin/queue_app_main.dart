import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_ari/ari/api/enums.dart';
import 'package:dart_ari/webserver/models/recordings.dart';
import 'package:dotenv/dotenv.dart';
import 'package:dart_ari/dart_ari.dart';
import 'package:uuid/uuid.dart';

// --------------------------------------------------------------------------
// --- EXTERNAL DEPENDENCIES (Assumed to be defined elsewhere) ---
// --------------------------------------------------------------------------
// NOTE: The following functions/classes must be implemented in your project:
// 1. Future<String?> longestWaiting() - Finds an IDLE agent and acquires a lock on it.
// 2. void releaseAgentLock(String agentFullString) - Releases the lock on the agent.
// 3. class DbQueries - Contains static methods like updateAgentStatus.
// 4. class CallRecording - The data model for call records, including insertCallRecording.

// Assuming the external definitions for these methods/classes exist:
// Future<String?> longestWaiting();
// void releaseAgentLock(String agentFullString);
// class DbQueries { static Future<void> updateAgentStatus(String endpoint, AgentState current, AgentState newState); }
// class CallRecording { ... methods/properties ... }

// --------------------------------------------------------------------------
// --- GLOBAL VARIABLES AND HELPERS ---
// --------------------------------------------------------------------------

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
    // Safely access 'rtp_port' as an integer
    return port['rtp_port'] is int ? port['rtp_port'] : null;
  } catch (e) {
    print("RTP Port Error: $e");
    return null;
  }
}

// --------------------------------------------------------------------------
// --- PICK AGENT LOGIC ---
// --------------------------------------------------------------------------

// The signature of pickAgent must be updated to accept the triedAgents set.
Future<String> pickAgent(
  Channel incoming,
  Set<String> triedAgents, // <-- NEW PARAMETER
) async {
  Completer<String> completer = Completer<String>();
  Timer? periodicTimer;
  Timer? timeoutTimer;

  const maxDuration = Duration(minutes: 10);
  const checkInterval = Duration(seconds: 2);

  void cleanupAndComplete(String result) {
    if (!completer.isCompleted) {
      periodicTimer?.cancel();
      timeoutTimer?.cancel();
      incoming.off();
      print("pickAgent: Completing with result: '$result'. Timers cancelled.");
      completer.complete(result);
    } else {
      periodicTimer?.cancel();
      timeoutTimer?.cancel();
    }
  }

  timeoutTimer = Timer(maxDuration, () {
    print("pickAgent: 10-minute timeout reached. No agent found.");
    cleanupAndComplete("");
  });

  incoming.on('StasisEnd', (_) {
    print("pickAgent: Incoming channel hung up (StasisEnd).");
    cleanupAndComplete("");
  });

  periodicTimer = Timer.periodic(checkInterval, (Timer t) async {
    if (completer.isCompleted) {
      t.cancel();
      return;
    }

    print("pickAgent: Timer tick. Attempting to find and lock an agent...");

    // CRITICAL CHANGE: Pass the set of agents to be excluded.
    // NOTE: Your external longestWaiting() function must be updated to respect this set.
    final freeAgent = await longestWaiting(triedAgents: triedAgents);

    if (freeAgent != null) {
      print(
          "pickAgent: Agent found and locked! $freeAgent. Cancelling timers...");
      // Agent found, complete with the agent endpoint. The lock is held.
      cleanupAndComplete(freeAgent);
    } else {
      print("pickAgent: No agent found in this tick. Will retry...");
    }
  });

  return completer.future;
}

// --------------------------------------------------------------------------
// --- ORIGINATE LOGIC (DIALING & EVENT MANAGEMENT) ---
// --------------------------------------------------------------------------

// --------------------------------------------------------------------------
// --- REFACTORED ORIGINATE LOGIC (Uses Completer to handle async timeout) ---
// --------------------------------------------------------------------------
Future<void> originate(
  Channel incoming,
  Bridge holdingBridge,
  String
      freeAgent, // Agent is passed in (already locked by pickAgent/longestWaiting)
) async {
  // CRITICAL: Completer to control the result (success or timeout) of the entire originate operation.
  final Completer<void> dialCompleter = Completer<void>();

  final filename = Uuid().v1();
  final rtpport = await rtpPort(filename);

  if (freeAgent.isEmpty) {
    print(
        "Originate: Agent string is empty (queue timed out or caller hung up). Exiting.");
    // NOTE: If freeAgent is truly empty, we cannot release a lock based on it.
    // Assuming the lock management system handles this edge case or it's guaranteed non-empty.
    return;
  }

  // --- Initial Setup and Dialing ---
  final endpoint = freeAgent;
  String dst = endpoint;
  if (dst.startsWith("PJSIP/")) {
    dst = dst.substring(6);
  }

  CallRecording? voiceRecord;
  print("Dialing agent: $endpoint");

  // These must be created before the timer/dial starts
  final dialed = await client.channel(endpoint: endpoint);
  final mixingBridge = await client.bridge(type: ['mixing']);

  // 🕒 30-SECOND DIAL TIMEOUT SETUP
  final timer = Timer(Duration(seconds: 30), () async {
    if (!dialCompleter.isCompleted) {
      print(
          "Originate to agent $endpoint timed out after 30 seconds. Performing cleanup.");

      try {
        await dialed
            .hangup(); // Hangup triggers StasisEnd/ChannelDestroyed cleanup
      } catch (e) {
        // Ignore hangup failure
      }

      // CRITICAL GUARANTEE: Agent status updated to IDLE (Status Reset)
      await DbQueries.updateAgentStatus(
          endpoint, AgentState.LOGGEDIN, AgentState.IDLE);
      releaseAgentLock(freeAgent); // CRITICAL: Release lock on dial timeout

      // Complete the future with an error, which will be caught by manageQueueAndOriginate
      dialCompleter.completeError(TimeoutException(
          "Originate to agent $endpoint timed out after 30 seconds."));
    }
  });

  // --- Event Handlers (Completion/Failure Logic) ---

  // SUCCESS PATH: Dialed channel answers (StasisStart)
  late void Function(dynamic) stasisStartHandler;
  stasisStartHandler = (ssEvent) async {
    // Ensure this runs only once and cancels the timer
    if (dialCompleter.isCompleted) return;
    timer.cancel();

    try {
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

      // Remove the StasisStart handler to prevent double trigger/memory leak
      dialed.off(type: 'StasisStart');

      // --- External Media and Bridge Add Logic ---
      if (rtpport != null) {
        final externalChannel = await client.externalMedia(
          (err, _) => err ? throw err : null,
          app: 'hello',
          variables: {'CALLERID(name)': endpoint, 'recording': 'yes'},
          external_host: '$voiceLoggerIp:$rtpport',
          format: 'alaw',
        );

        // Nested cleanup handlers for external channel
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
          // FIX: Ensure status is IDLE before releasing lock on failure (Status Reset)
          await DbQueries.updateAgentStatus(
              endpoint, AgentState.LOGGEDIN, AgentState.IDLE);
          releaseAgentLock(freeAgent);
          if (!dialCompleter.isCompleted) {
            dialCompleter.completeError(e);
            return;
          }
        }
      } else {
        try {
          await mixingBridge.addChannel(channels: [dialed.id]);
          await mixingBridge.addChannel(channels: [incoming.id]);
        } catch (e, st) {
          print("Error adding channels to bridge: $e, stacktrace: $st");
          await dialed.hangup();
          await mixingBridge.destroy();
          // FIX: Ensure status is IDLE before releasing lock on failure (Status Reset)
          await DbQueries.updateAgentStatus(
              endpoint, AgentState.LOGGEDIN, AgentState.IDLE);
          releaseAgentLock(freeAgent);
          if (!dialCompleter.isCompleted) {
            dialCompleter.completeError(e);
            return;
          }
        }
      }

      // Final action: Complete the Future successfully
      if (!dialCompleter.isCompleted) {
        dialCompleter.complete();
      }
    } catch (e) {
      // Handle errors during answer/bridge setup if they happen after StasisStart
      print("Error during StasisStart handler: $e");
      if (!dialCompleter.isCompleted) {
        dialCompleter.completeError(e);
      }
    }
  };
  dialed.on('StasisStart', stasisStartHandler);

  // RELEASE PATH 1: Dialed channel ends (Agent hangs up/ARI terminates call)
  dialed.on('StasisEnd', (ssEndevent) async {
    final (sEndEvent, _) = ssEndevent as (StasisEnd, Channel);

    // --- PATH A: Call was successful (Agent answered) ---
    if (dialCompleter.isCompleted) {
      // This is the correct path for call termination after the agent has answered.
      timer.cancel();

      if (voiceRecord != null) {
        voiceRecord!.hangupdate = sEndEvent.timestamp.toIso8601String();
        // CRITICAL: Insert the recording here when the successful call ends.
        await voiceRecord!.insertCallRecording();
        print(
            "Call record inserted successfully after agent hangup/termination.");
      }

      // CRITICAL GUARANTEE: Agent status updated to IDLE (Status Reset)
      await Future.delayed(Duration(seconds: 15)); // Wrap-up time
      await DbQueries.updateAgentStatus(
          endpoint, AgentState.LOGGEDIN, AgentState.IDLE);
      releaseAgentLock(freeAgent);
      return; // Exit the handler
    }

    // --- PATH B: Call failed (Dialing phase ended without answer) ---
    // This path handles when the agent hangs up/rejects BEFORE answering.
    timer.cancel();

    // CRITICAL GUARANTEE: Agent status updated to IDLE (Status Reset)
    await Future.delayed(Duration(seconds: 15)); // Wrap-up time
    await DbQueries.updateAgentStatus(
        endpoint, AgentState.LOGGEDIN, AgentState.IDLE);
    releaseAgentLock(freeAgent);

    if (!dialCompleter.isCompleted) {
      dialCompleter.completeError(Exception("Agent hung up before answering."));
    }
  });

  // FAILURE PATH 2: Incoming channel ends (Customer hangs up)
  incoming.on('StasisEnd', (_) async {
    print("Incoming channel (Caller) hung up. Initiating teardown.");

    // If the conversation was established (voiceRecord != null), we need to hang up the agent.
    if (voiceRecord != null) {
      try {
        // This triggers the dialed.on('StasisEnd') handler, which contains the IDLE status update and lock release.
        await dialed.hangup();
        await mixingBridge.destroy();
      } catch (e) {
        print("Error during established call hangup: $e");
      }
    }
    // If the caller hung up while dialing/queuing (dialCompleter not completed).
    else if (!dialCompleter.isCompleted) {
      timer.cancel();
      await mixingBridge.destroy();
      try {
        await dialed.hangup(); // Hang up agent's ringing channel
      } catch (_) {}

      // CRITICAL GUARANTEE: Agent status updated to IDLE (Status Reset)
      await DbQueries.updateAgentStatus(
          endpoint, AgentState.LOGGEDIN, AgentState.IDLE);
      releaseAgentLock(freeAgent);
      dialCompleter
          .completeError(Exception("Caller hung up during dialing/queue."));
    }
  });

  // FAILURE PATH 3: Dialed channel is destroyed
  dialed.on('ChannelDestroyed', (cdEvent) async {
    if (dialCompleter.isCompleted) return;
    timer.cancel();

    final (destroyedEvent, _) = cdEvent as (ChannelDestroyed, Channel);
    if (voiceRecord != null) {
      voiceRecord!
        ..duration_number = destroyedEvent.timestamp.toString()
        ..hangupdate = destroyedEvent.timestamp.toString();
    }

    // CRITICAL GUARANTEE: Agent status updated to IDLE (Status Reset)
    await Future.delayed(Duration(seconds: 15)); // Wrap-up time
    await DbQueries.updateAgentStatus(
        endpoint, AgentState.LOGGEDIN, AgentState.IDLE);
    releaseAgentLock(freeAgent);

    if (!dialCompleter.isCompleted) {
      dialCompleter
          .completeError(Exception("Dialed channel destroyed unexpectedly."));
    }
  });

  // --- Agent State Updates (Lock is KEPT) ---
  // These set transient states (RINGING, ONCONVERSATION) but rely on the
  // above StasisEnd/ChannelDestroyed handlers for the final IDLE state.
  dialed.on('ChannelStateChange', (event) async {
    final (_, dialChannel) = event as (ChannelStateChange, Channel);
    if (dialChannel.state == 'Up') {
      await holdingBridge.removeChannel(channel: [incoming.id]);
      await DbQueries.updateAgentStatus(
          endpoint, AgentState.LOGGEDIN, AgentState.ONCONVERSATION);
    } else if (dialChannel.state == 'Ringing') {
      await DbQueries.updateAgentStatus(
          endpoint, AgentState.LOGGEDIN, AgentState.RINGING);
    }
  });

  // Initiate the dial attempt.
  try {
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
  } catch (e, st) {
    // Catch errors during the initial ARI originate command execution itself.
    timer.cancel();
    // FIX: Ensure status is IDLE before releasing lock on command failure (Status Reset)
    await DbQueries.updateAgentStatus(
        endpoint, AgentState.LOGGEDIN, AgentState.IDLE);
    releaseAgentLock(freeAgent);
    if (!dialCompleter.isCompleted) {
      dialCompleter.completeError(Exception("Originate command failed: $e"));
    }
  }

  // CRITICAL: Wait for the result of the dial attempt (success or failure).
  return dialCompleter.future;
} // --- QUEUE MANAGER LOGIC ---
// --------------------------------------------------------------------------

Future<void> manageQueueAndOriginate(
  Channel incoming,
  Bridge holdingBridge,
  Duration maxQueueTime,
  Duration retryDelay,
) async {
  final Completer<void> completer = Completer<void>();

  // CRITICAL: Maintain state of agents already attempted for this caller.
  final Set<String> triedAgents = <String>{};

  void cleanupAndComplete() async {
    if (!completer.isCompleted) {
      try {
        await incoming.hangup();
        await holdingBridge.destroy();
      } catch (e) {
        print("Error during final cleanup: $e");
      }
      completer.complete();
    }
  }

  // Set up cleanup if the incoming channel (caller) hangs up while in the queue.
  incoming.on('StasisEnd', (_) {
    print(
        "Queue Manager: Incoming channel hung up (StasisEnd). Exiting queue.");
    cleanupAndComplete();
  });
  incoming.on('ChannelDestroyed', (_) {
    print("Queue Manager: Incoming channel destroyed. Exiting queue.");
    cleanupAndComplete();
  });

  // CRITICAL CHANGE: Loop to keep trying agents until successful, timeout, or caller hangs up.
  while (!completer.isCompleted) {
    try {
      print("Queue Manager: Starting attempt to pick a new agent.");

      // 1. ACQUIRE AGENT: Pass the triedAgents set.
      final freeAgent = await pickAgent(incoming, triedAgents);

      if (freeAgent.isEmpty) {
        // pickAgent completed due to 10-minute timeout or caller hangup (handled by cleanupAndComplete).
        print(
            "Originate: No agent picked due to queue timeout or caller hangup. Exiting.");
        cleanupAndComplete();
        break; // Exit the while loop
      }

      // Add the selected agent to the triedAgents list immediately
      // before attempting to originate. This prevents retrying them on the next loop.
      triedAgents.add(freeAgent);

      // 2. DIAL AGENT: Call the originate function with the locked agent.
      print("Queue Manager: Agent $freeAgent acquired. Starting dial attempt.");

      // originate will throw TimeoutException on dial failure.
      await originate(incoming, holdingBridge, freeAgent);

      // If originate returns successfully, the call is connected and
      // managed by internal event listeners.
      completer.complete();
      break; // Exit the while loop
    } on TimeoutException catch (e) {
      // <-- CRITICAL FIX: Explicitly catch the TimeoutException
      // Agent dial timed out. The lock was released inside originate.
      print(
          "Queue Manager: Dial attempt failed (${e.message}). Retrying agent search...");

      // The loop automatically continues to the next iteration to call pickAgent again.
    } catch (e, st) {
      // Catches other fatal errors (e.g., failed to create bridge, unexpected ARI errors).
      print("Queue Manager FATAL ERROR: $e\n$st. Stopping queue.");
      cleanupAndComplete();
      break; // Exit the while loop
    }
  }
}
// --------------------------------------------------------------------------
// --- BRIDGE SETUP & STASIS START ---
// --------------------------------------------------------------------------

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

  // Start the non-blocking queue management process.
  await manageQueueAndOriginate(
    channel,
    holdingBridge,
    const Duration(minutes: 10),
    const Duration(seconds: 2),
  );

  print("findOrCreateBridge finished execution.");
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
    try {
      await channel.hangup();
    } catch (_) {}
  }
}

// --------------------------------------------------------------------------
// --- MAIN APPLICATION ENTRY POINT ---
// --------------------------------------------------------------------------

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
