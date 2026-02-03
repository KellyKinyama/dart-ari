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
  // Declare these variables OUTSIDE the loop so they persist when the loop breaks.
  List<String> loggedInAgents = [];
  final Map<String, String> cleanToFullAgentMap = {};

  Set<String> excludedAgents = triedAgents ?? <String>{};
  String? finalBestAgentFullString;
  bool isFirstPass = true;

  do {
    // --- Step 1: Get all currently logged-in and idle agents ---
    loggedInAgents = (await idleAgents()) // ASSIGNMENT, NOT DECLARATION
        .entries
        .where((entry) {
          final agentFullString = entry.key;

          if (isFirstPass && excludedAgents.contains(agentFullString)) {
            return false;
          }

          if (entry.value == AgentState.LOGGEDIN) {
            // Attempt to lock the agent; only consider if successful
            return agentLockManager.tryLock(agentFullString);
          }
          return false;
        })
        .map((entry) => entry.key)
        .toList();

    if (loggedInAgents.isEmpty) {
      if (isFirstPass && excludedAgents.isNotEmpty) {
        print(
            "No available agents found after excluding tried agents. Resetting exclusion list and trying all agents again.");
        isFirstPass = false;
        excludedAgents = <String>{};
        continue;
      } else {
        print("No idle agents available or all are currently locked/excluded.");
        finalBestAgentFullString = null;
        break; // Exit the do-while loop
      }
    }

    // --- Steps 2-5: Selection Logic (Only runs if loggedInAgents is NOT empty) ---

    // Prepare clean agent numbers (without PJSIP/ prefix) for database queries
    cleanToFullAgentMap.clear(); // Clear for the current loop run
    final List<String> cleanAgentNumbers =
        loggedInAgents.map((fullAgentString) {
      int index = fullAgentString.indexOf("/");
      String cleanNumber =
          index != -1 ? fullAgentString.substring(index + 1) : fullAgentString;
      cleanToFullAgentMap[cleanNumber] = fullAgentString;
      return cleanNumber;
    }).toList();

    print("Probbing Recordings table with agent numbers: $cleanAgentNumbers");

    // Step 2: Find which of these agents have recent records in the 'recordings' table
    List<Map<String, dynamic>> agentsWithRecentRecords = [];
    final dbRecordings = await Model.getDbConnection();
    final eightHoursAgo =
        DateTime.now().subtract(Duration(hours: 8)).toIso8601String();

    agentsWithRecentRecords = await dbRecordings
        .table(Recordings.table)
        .selectRaw('agent_number, MAX(updated_at) as updated_at')
        .whereRaw(
            "agent_number IN (${cleanAgentNumbers.map((e) => "'$e'").join(', ')}) "
            "AND updated_at >= '$eightHoursAgo'")
        .groupBy('agent_number')
        .orderByRaw('MAX(updated_at) ASC')
        .get();
    await dbRecordings.disconnect();

    print("records: $agentsWithRecentRecords");

    // Step 3: Categorize agents into those with and without recent records
    final Set<String> cleanAgentsWithRecordsSet =
        agentsWithRecentRecords.map((e) => e['agent_number'] as String).toSet();

    final List<String> cleanAgentsWithoutRecentRecords = cleanAgentNumbers
        .where((agentNum) => !cleanAgentsWithRecordsSet.contains(agentNum))
        .toList();

    // Step 4: Prioritize agents who have no recent records (truest longest idle)
    if (cleanAgentsWithoutRecentRecords.isNotEmpty) {
      print(
          "Candidates with no recent records: $cleanAgentsWithoutRecentRecords");

      final dbAgents = await Model.getDbConnection();
      List<Map<String, dynamic>> trulyLongestIdleFromAgents = await dbAgents
          .table('agents')
          .select(['endpoint', 'updated_at'])
          .whereIn('endpoint', cleanAgentsWithoutRecentRecords)
          .orderBy('updated_at', 'asc')
          .limit(1)
          .get();
      await dbAgents.disconnect();

      if (trulyLongestIdleFromAgents.isNotEmpty) {
        String bestCleanAgent = trulyLongestIdleFromAgents.first['endpoint'];
        finalBestAgentFullString = cleanToFullAgentMap[bestCleanAgent];
        print(
            "Selected agent (no recent recording history, oldest agent table update): $finalBestAgentFullString");
      } else {
        finalBestAgentFullString =
            cleanToFullAgentMap[cleanAgentsWithoutRecentRecords.first];
        print(
            "Selected agent (no recent recording history, first in list as fallback): $finalBestAgentFullString");
      }
    } else if (agentsWithRecentRecords.isNotEmpty) {
      // Step 5: Fallback to agent with oldest record if all agents have records
      print("All agents have recent records. Selecting oldest record holder.");
      String bestCleanAgent = agentsWithRecentRecords.first['agent_number'];
      finalBestAgentFullString = cleanToFullAgentMap[bestCleanAgent];
      print(
          "Selected agent (longest idle from recordings): $finalBestAgentFullString");
    } else {
      print("No suitable idle agents found based on any criteria.");
    }

    // Break the loop since a candidate was found
    break;
  } while (!isFirstPass);

  // --- Final Cleanup (Accesses loggedInAgents and finalBestAgentFullString) ---

  // Unlock only the agents that were considered (and potentially locked) but *not* selected.
  // loggedInAgents retains the list from the last successful loop iteration.
  for (String agentToUnlock in loggedInAgents) {
    if (agentToUnlock != finalBestAgentFullString) {
      agentLockManager.unlock(agentToUnlock);
    }
  }

  return finalBestAgentFullString;
}

/// Unlocks a specific agent that was previously locked.
/// This function should be called when the selected agent is no longer needed
/// or the operation involving them has completed/failed.
void releaseAgentLock(String agentFullString) {
  // If we unlock the second the call ends,
  // longestWaiting() might pick them again before Asterisk
  // has fully torn down the previous channel.

  print("Holding memory lock for $agentFullString for 3s (Cooldown)...");

  Timer(Duration(seconds: 3), () {
    agentLockManager.unlock(agentFullString);
    print("Agent $agentFullString is now truly available in memory.");
  });
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
