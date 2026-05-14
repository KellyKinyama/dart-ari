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

/// Maps `agent endpoint -> incoming.id` for the agent currently being dialed.
/// This is a SECONDARY in-process guard on top of [agentLockManager] and the
/// atomic DB claim. Only the call that successfully inserts itself owns the
/// agent and is allowed to release it.
Map<String, String> dialedAgents = {};

/// Tracks customer (incoming) channels that already have an active
/// `originate()` flow in progress. Prevents a single customer channel from
/// triggering multiple parallel agent picks (e.g. on Stasis re-entry,
/// duplicate StasisStart events, etc.) which is a major source of
/// "concurrent calls" complaints.
final Set<String> _activeIncomingCalls = <String>{};

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
    // Any ARI HTTP failure (now surfaced as AriException) or unexpected
    // error during call setup ends up here. Hang up the customer channel
    // so they don't sit silently in Stasis with no progress.
    print("StasisStart Error: $e\n$st");
    try {
      await channel.hangup();
    } catch (hangupErr) {
      print("StasisStart: hangup after error also failed: $hangupErr");
    }
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

Future<String> pickAgent(Channel incoming, {Set<String>? triedAgents}) async {
  Completer<String> completer = Completer<String>();
  Timer? searchTimer;
  Timer? timeoutTimer;
  bool isSearching = false;

  const maxDuration = Duration(minutes: 10);
  const checkInterval = Duration(seconds: 2);

  void cleanupAndComplete(String result) {
    if (!completer.isCompleted) {
      searchTimer?.cancel();
      timeoutTimer?.cancel();
      // incoming.off();
      completer.complete(result);
    }
  }

  timeoutTimer = Timer(maxDuration, () => cleanupAndComplete(""));
  incoming.on('StasisEnd', (_) => cleanupAndComplete(""));

  Future<void> startSearch() async {
    if (completer.isCompleted || isSearching) return;

    // PRE-CLAIM CHECK
    if (!client.channels.containsKey(incoming.id)) {
      print("pickAgent: Incoming channel ${incoming.id} gone. Aborting.");
      cleanupAndComplete("");
      return;
    }

    isSearching = true;
    try {
      // 1. Attempt Atomic DB Claim
      final freeAgent = await longestWaiting(triedAgents: triedAgents);

      // === NEW HIGHLIGHTED LOGIC: THE LATE-CANCEL GUARD ===
      // Check if the search was cancelled (timeout or hangup)
      // WHILE longestWaiting() was awaiting the database response.
      if (freeAgent != null &&
          (completer.isCompleted ||
              !client.channels.containsKey(incoming.id))) {
        print(
            "pickAgent: LATE CATCH! Caller left during DB claim. Releasing $freeAgent.");

        try {
          await DbQueries.updateAgentStatus(
                  freeAgent, AgentState.LOGGEDIN, AgentState.IDLE)
              .timeout(Duration(seconds: 5));
        } catch (e) {
          print("Rollback DB Error: $e");
        } finally {
          releaseAgentLock(freeAgent); // Clear memory lock
        }

        cleanupAndComplete("");
        return;
      }
      // ===================================================

      if (freeAgent != null) {
        // Double-check one last time before finalizing
        if (client.channels.containsKey(incoming.id)) {
          print("pickAgent: Agent $freeAgent claimed. Customer still active.");
          cleanupAndComplete(freeAgent);
        } else {
          // Fallback if the first guard missed it
          print("pickAgent: Customer left. Releasing $freeAgent.");
          try {
            await DbQueries.updateAgentStatus(
                    freeAgent, AgentState.LOGGEDIN, AgentState.IDLE)
                .timeout(Duration(seconds: 5));
          } finally {
            releaseAgentLock(freeAgent);
          }
          cleanupAndComplete("");
        }
      } else {
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
      isSearching = false;
    }
  }

  startSearch();
  return completer.future;
}

Future<void> originate(Channel incoming, Bridge holdingBridge,
    {Set<String>? triedAgents}) async {
  if (!client.channels.containsKey(incoming.id)) return;

  // Re-entry guard: only one originate flow per customer channel at a time.
  // Recursive retries from within cleanUp pass the same incoming.id, so we
  // allow them by removing the marker in cleanUp BEFORE re-invoking.
  if (!_activeIncomingCalls.add(incoming.id)) {
    print(
        "originate: skip duplicate flow for incoming ${incoming.id} (already active).");
    return;
  }

  Channel? externalChannel; // ADD THIS: track the recording channel

  // NOTE: Do NOT call `incoming.off()` here. It removes ALL listeners on the
  // incoming channel, including ones registered by the previous originate()
  // attempt's cleanup paths and pickAgent's StasisEnd guard. Listeners
  // attached below are scoped to this attempt and will be no-ops once
  // cleanUp's `isReleased` flag is set.
  bool lockedAgent = false;

  final freeAgent = await pickAgent(incoming, triedAgents: triedAgents);
  if (freeAgent.isEmpty) {
    _activeIncomingCalls.remove(incoming.id);
    return;
  }

  final filename = Uuid().v1();
  final rtpport = await rtpPort(filename);

  final endpoint = freeAgent;
  String dst = endpoint.startsWith("PJSIP/") ? endpoint.substring(6) : endpoint;

  Bridge? mixingBridge;
  bool isReleased = false;
  bool wasConnected = false;

  Future<void> cleanUp({bool isSuccess = false}) async {
    if (isReleased) return;
    isReleased = true;

    try {
      // 1. Kill the recording channel immediately if it exists
      if (externalChannel != null) {
        await externalChannel!.hangup().catchError((e) => null);
        print("Finalizer: Recording channel for $endpoint disconnected.");
      }
      if (isSuccess) {
        print("Finalizer: Success for $endpoint. 15s breathing space.");
        await Future.delayed(Duration(seconds: 15));
      } else {
        // Even on failure we MUST wait briefly before flipping the agent
        // back to IDLE. Asterisk needs time to fully tear down the SIP
        // dialog; flipping IDLE immediately allows the next pickAgent to
        // re-dial a phone that is still ringing/clearing → concurrent ring.
        print("Finalizer: Call failed for $endpoint. 5s breathing space.");
        await Future.delayed(Duration(seconds: 5));
      }

      if (mixingBridge != null) {
        await mixingBridge!.destroy().catchError((e) => null);
      }
    } catch (e) {
      print("Finalizer Error: $e");
    } finally {
      // Always clear the per-incoming guard so retries (or the next call on
      // this customer channel) can proceed.
      _activeIncomingCalls.remove(incoming.id);

      // CRITICAL: Only touch the agent's DB status / in-memory lock /
      // dialedAgents map if THIS originate attempt actually owned the agent.
      // If `lockedAgent` is false we never got past the dialedAgents
      // ownership check, which means another in-flight call owns this
      // agent — touching it here would force-release a busy agent and is a
      // primary cause of "agent receives concurrent calls".
      if (lockedAgent) {
        await DbQueries.updateAgentStatus(
                endpoint, AgentState.LOGGEDIN, AgentState.IDLE)
            .catchError((e) => null);

        dialedAgents.remove(freeAgent);
        // releaseAgentLock applies its own cooldown timer before the
        // in-memory lock is actually cleared.
        releaseAgentLock(freeAgent);
      } else {
        print(
            "Finalizer: agent $endpoint not owned by this attempt — skipping DB/lock release.");
      }

      if (triedAgents == null) {
        triedAgents = {freeAgent};
      } else {
        triedAgents!.add(freeAgent);
      }

      if (!isSuccess && client.channels.containsKey(incoming.id)) {
        await Future.delayed(Duration(seconds: 5));
        print("Retry: Attempting next agent for customer ${incoming.id}...");
        unawaited(originate(incoming, holdingBridge, triedAgents: triedAgents));
      }
    }
  }

  try {
    if (dialedAgents[freeAgent] == null) {
      dialedAgents[freeAgent] = incoming.id;
      lockedAgent = true;
    } else {
      throw Exception(
          "dialed agent: $freeAgent is already taken by: ${dialedAgents[freeAgent]}");
    }

    final dialed = await client.channel(endpoint: endpoint);
    mixingBridge = await client.bridge(type: ['mixing']);
    CallRecording? voiceRecord;

    Timer watchdog = Timer(Duration(seconds: 60), () async {
      if (!isReleased) {
        print("Watchdog: Agent $endpoint timeout. Retrying.");
        await dialed.hangup().catchError((e) => null);
        await cleanUp(isSuccess: false);
      }
    });

    dialed.on('StasisEnd', (event) async {
      watchdog.cancel();
      try {
        if (wasConnected) {
          final (sEnd, _) = event as (StasisEnd, Channel);
          await incoming.hangup().catchError((e) => null);
          if (voiceRecord != null) {
            voiceRecord!.hangupdate = sEnd.timestamp.toIso8601String();
            await voiceRecord!.insertCallRecording();
          }
        }
      } finally {
        await cleanUp(isSuccess: wasConnected);
      }
    });

    incoming.on('StasisEnd', (_) async {
      watchdog.cancel();
      await dialed.hangup().catchError((e) => null);
      await cleanUp(isSuccess: wasConnected);
    });

    dialed.on('ChannelDestroyed',
        (_) async => await cleanUp(isSuccess: wasConnected));
    incoming.on('ChannelDestroyed',
        (_) async => await cleanUp(isSuccess: wasConnected));

    dialed.on('ChannelStateChange', (event) async {
      final (_, dialChannel) = event as (ChannelStateChange, Channel);
      if (dialChannel.state == 'Up') {
        watchdog.cancel();
        await holdingBridge
            .removeChannel(channel: [incoming.id]).catchError((e) => null);
        // NOTE: We do NOT update to ONCONVERSATION here to prevent race conditions
      } else if (dialChannel.state == 'Ringing') {
        await DbQueries.updateAgentStatus(
            endpoint, AgentState.LOGGEDIN, AgentState.RINGING);
      }
    });

    dialed.on('StasisStart', (event) async {
      watchdog.cancel();

      wasConnected = true;

      if (!client.channels.containsKey(incoming.id)) {
        // throw Exception("Incoming channel: ${incoming.id} was deleted");
        await cleanUp(isSuccess: true);
        return;
      }

      // Update to ONCONVERSATION only when they successfully enter Stasis
      await DbQueries.updateAgentStatus(
          endpoint, AgentState.LOGGEDIN, AgentState.ONCONVERSATION);

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

      // 3. BRIDGING (Critical: Humans must talk)
      try {
        if (mixingBridge != null) {
          if (client.channels.containsKey(incoming.id)) {
            await holdingBridge
                .removeChannel(channel: [incoming.id]).catchError((e) => null);
            await Future.delayed(const Duration(milliseconds: 200));
            await mixingBridge!.addChannel(channels: [dialed.id, incoming.id]);
          } else {
            throw Exception("Incoming channel lost before bridge");
          }
        }
      } catch (e) {
        print("CRITICAL: Human bridging failed: $e");
        await dialed.hangup().catchError((e) => null);
        await cleanUp(isSuccess: false);
        return; // Stop execution here
      }

      // 4. RECORDING (Non-Critical: Failure should NOT hang up the call)
      try {
        if (rtpport != null) {
          externalChannel = await client
              .externalMedia(
                (err, _) => err
                    ? throw Exception("ExternalMedia callback error")
                    : null,
                app: 'hello',
                variables: {'CALLERID(name)': endpoint, 'recording': 'yes'},
                external_host: '$voiceLoggerIp:$rtpport',
                format: 'alaw',
              )
              .timeout(const Duration(seconds: 3));

          if (mixingBridge != null) {
            await mixingBridge!.addChannel(channels: [externalChannel!.id]);

            dialed.on('StasisEnd', (_) async {
              await externalChannel!.hangup().catchError((e) => null);
            });
          }
        }
      } catch (e) {
        // We catch this error, print it, but DO NOT call dialed.hangup()
        print("NON-CRITICAL: Recording setup failed (Call continuing): $e");
      }
    });

    if (!client.channels.containsKey(incoming.id)) {
      throw Exception("Incoming channel: ${incoming.id} was deleted");
    }

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
        timeout: 10);
  } catch (e) {
    print("Originate Fatal Error: $e");
    await cleanUp(isSuccess: false);
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
