import 'dart:async';

import 'package:dart_ari/webserver/models/base.dart';

import '../../ari/api/enums.dart';
import '../../ari/api/push/aors.dart';

class AgentLockManager {
  final Set<String> lockedAgents = {};

  bool isLocked(String agent) => lockedAgents.contains(agent);

  bool tryLock(String agent) {
    if (lockedAgents.contains(agent)) {
      return false;
    }
    lockedAgents.add(agent);
    return true;
  }

  void unlock(String agent) {
    lockedAgents.remove(agent);
  }
}

final agentLockManager = AgentLockManager();

class Recordings extends Model {
  static String table = 'recordings';
}

Future<Map<String, AgentState>> idleAgents() async {
  Map<String, AgentState> agentsStates = {};
  String table = 'agents';

  final db = await Model.getDbConnection();
  final eightHoursAgo =
      DateTime.now().subtract(Duration(hours: 48)).toIso8601String();

  List<Map<String, dynamic>> res = await db
      .table(table)
      .select(['endpoint', 'state', 'status', 'updated_at'])
      // .whereIn('agent_number', loggedInAgents)
      .where('updated_at', '>=', eightHoursAgo)
      .whereIn('status', ['IDLE', 'AgentState.IDLE'])
      .whereIn('user_status', ['IDLE', 'AgentState.IDLE'])
      .groupBy('endpoint')
      .orderBy('updated_at', 'asc')
      // .limit(1)
      .get();

  print("Idle agents before checking contact: $res");

  await db.disconnect();
  for (var element in res) {
    if (await Aor.contact(element['endpoint'])) {
      agentsStates["PJSIP/${element['endpoint']}"] = AgentState.LOGGEDIN;
    }
    // }
  }
  print("idle agents after checking contact: $res");
  return agentsStates;
}

// --------------------------------------------------------------------------
// --- REFACTORED FUNCTION: longestWaiting ---
// --------------------------------------------------------------------------
Future<String?> longestWaiting({Set<String>? triedAgents}) async {
  final Set<String> excludedAgents = triedAgents ?? <String>{};

  // 1. Get snapshot of agents currently IDLE in the database
  // This gives us a list of potential candidates to try.
  final idleMap = await idleAgents();

  // Filter candidates: ignore those we already tried or those currently locked in local memory
  List<String> candidates = idleMap.keys.where((agent) {
    return !excludedAgents.contains(agent) && !agentLockManager.isLocked(agent);
  }).toList();

  if (candidates.isEmpty) {
    print("longestWaiting: No idle candidates found in DB/Memory.");
    return null;
  }

  // 2. Selection Logic (Prioritize based on history)
  // Create a map to link clean database numbers to full ARI PJSIP strings
  final Map<String, String> cleanToFull = {
    for (var full in candidates)
      (full.contains('/') ? full.split('/')[1] : full): full
  };

  final db = await Model.getDbConnection();
  // Find which agents have recent recording records to determine who has been idle the longest
  final records = await db
      .table('recordings')
      .selectRaw('agent_number, MAX(updated_at) as last_call')
      .whereRaw(
          "agent_number IN (${cleanToFull.keys.map((e) => "'$e'").join(',')})")
      .groupBy('agent_number')
      .orderByRaw('MAX(updated_at) ASC')
      .get();
  await db.disconnect();

  final Set<String> withRecords =
      records.map((e) => e['agent_number'] as String).toSet();

  // Create priority list: Agents with NO records first (truest idle), then by oldest record
  List<String> sortedClean = [
    ...cleanToFull.keys.where((e) => !withRecords.contains(e)),
    ...records.map((e) => e['agent_number'] as String)
  ];

  // 3. THE ATOMIC ATTEMPT LOOP
  // This loop is critical: it prevents the "Search Overlap" from failing
  for (String clean in sortedClean) {
    String fullAgent = cleanToFull[clean]!;

    // Final guard: check memory lock one last time before hitting the DB
    if (agentLockManager.isLocked(fullAgent)) continue;

    // ATOMIC CLAIM:
    // This function tries to UPDATE the status to 'RINGING' only if it is still 'IDLE'.
    // If it returns true, this process officially "owns" this agent.
    if (await claimAgentAtomic(fullAgent)) {
      // Set the local memory lock as a secondary layer of protection
      agentLockManager.tryLock(fullAgent);

      print("longestWaiting: Successfully claimed and locked $fullAgent");
      return fullAgent;
    }

    // If claimAgentAtomic returned false, it means another call (or instance)
    // changed that agent's status to RINGING/BUSY just now.
    // We don't return null; we stay in the loop and try the next best agent.
    print(
        "longestWaiting: Conflict detected. $fullAgent was already taken. Trying next candidate...");
  }

  // Only return null if we exhausted the entire list and couldn't claim anyone
  return null;
}

/// Unlocks a specific agent that was previously locked.
/// This function should be called when the selected agent is no longer needed
/// or the operation involving them has completed/failed.
void releaseAgentLock(String agentFullString) {
  // If we unlock the second the call ends,
  // longestWaiting() might pick them again before Asterisk
  // has fully torn down the previous channel.

  print("Holding memory lock for $agentFullString for 3s (Cooldown)...");

  // Timer(Duration(seconds: 3), () {
  agentLockManager.unlock(agentFullString);
  print("Agent $agentFullString is now truly available in memory.");
  // });
}

Future<bool> claimAgentAtomic(String endpoint) async {
  final db = await Model.getDbConnection();
  final cleanEndpoint =
      endpoint.contains('/') ? endpoint.split('/')[1] : endpoint;

  try {
    // This query is atomic. Only one process can update 'IDLE' to 'RINGING'.
    final affectedRows = await db
        .table('agents')
        .where('endpoint', '=', cleanEndpoint)
        .whereIn('status', ['IDLE', 'AgentState.IDLE'])
        .lockForUpdate()
        .update({
          'status': AgentState.RINGING.toString(),
          'updated_at': DateTime.now().toIso8601String(),
        });

    return (affectedRows ?? 0) > 0;
  } catch (e) {
    return false;
  } finally {
    await db.disconnect();
  }
}

Future<void> main() async {
  String? free;

  // Example usage demonstrating exclusion:
  final excluded = <String>{'PJSIP/7000', 'PJSIP/8000'};

  // You would need to ensure your idleAgents function returns some values for this test to work.
  // Assuming 'PJSIP/9000' is available.

  // free = await longestWaiting(triedAgents: excluded);
  free = await longestWaiting();

  print("Agents locked: ${agentLockManager.lockedAgents}");
  print("Free agent: $free");

  // Example of how to use the new releaseAgentLock function:
  if (free != null) {
    // Simulate some work with the agent
    print("Performing work with agent: $free...");
    await Future.delayed(Duration(seconds: 2)); // Simulate work
    releaseAgentLock(free); // Release the lock when done
  }
}
