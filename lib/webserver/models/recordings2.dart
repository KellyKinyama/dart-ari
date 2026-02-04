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
  final idleMap = await idleAgents();

  // Filter candidates that aren't in the exclusion list and aren't locally locked
  List<String> candidates = idleMap.keys.where((agent) {
    return !excludedAgents.contains(agent) && !agentLockManager.isLocked(agent);
  }).toList();

  if (candidates.isEmpty) {
    print("longestWaiting: No valid idle candidates found.");
    return null;
  }

  // Map for translation between clean endpoint and full ARI endpoint
  final Map<String, String> cleanToFull = {
    for (var full in candidates)
      (full.contains('/') ? full.split('/')[1] : full): full
  };

  // 2. Selection Logic: Determine priority based on recording history
  final db = await Model.getDbConnection();
  final records = await db
      .table(Recordings.table)
      .selectRaw('agent_number, MAX(updated_at) as last_call')
      .whereRaw(
          "agent_number IN (${cleanToFull.keys.map((e) => "'$e'").join(',')})")
      .groupBy('agent_number')
      .orderByRaw('MAX(updated_at) ASC')
      .get();
  await db.disconnect();

  final Set<String> withRecords =
      records.map((e) => e['agent_number'] as String).toSet();

  // Sort: Agents with NO records (longest idle) first, then by oldest record
  List<String> sortedCleanNumbers = [
    ...cleanToFull.keys.where((e) => !withRecords.contains(e)),
    ...records.map((e) => e['agent_number'] as String)
  ];

  // 3. THE ATOMIC CLAIM LOOP
  for (String cleanNumber in sortedCleanNumbers) {
    String fullAgent = cleanToFull[cleanNumber]!;

    // Final memory lock check
    if (agentLockManager.isLocked(fullAgent)) continue;

    // Try to claim the agent globally in the DB
    bool success = await claimAgentAtomic(fullAgent);

    if (success) {
      // If DB claim succeeds, set the local memory lock and return
      agentLockManager.tryLock(fullAgent);
      print("longestWaiting: Agent $fullAgent claimed and locked.");
      return fullAgent;
    }

    // If claim returns false, another instance grabbed them. Move to next.
    print("longestWaiting: $fullAgent was snatched. Trying next candidate...");
  }

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

  // Normalize endpoint (strip PJSIP/ prefix for DB lookup)
  final cleanEndpoint =
      endpoint.contains('/') ? endpoint.split('/')[1] : endpoint;

  try {
    // ATOMIC UPDATE: The 'whereIn' ensures we only succeed if the agent is still IDLE.
    final affectedRows = await db
        .table('agents')
        .where('endpoint', '=', cleanEndpoint)
        .whereIn('status', ['IDLE', 'AgentState.IDLE']).whereNotIn(
            'user_status', ['ON_BREAK', 'AgentState.ON_BREAK']).update({
      'state': AgentState.LOGGEDIN.toString(),
      'status': AgentState.RINGING.toString(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    return (affectedRows ?? 0) > 0;
  } catch (e) {
    print("Atomic Claim Error: $e");
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

  free = await longestWaiting(triedAgents: excluded);

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
