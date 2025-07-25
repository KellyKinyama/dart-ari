import 'dart:async';
import 'dart:convert';

import 'package:dart_ari/webserver/models/base.dart';

import '../../ari/api/enums.dart';
import '../../ari/api/push/aors.dart';

class AgentLockManager {
  final Set<String> _lockedAgents = {};

  bool isLocked(String agent) => _lockedAgents.contains(agent);

  bool tryLock(String agent) {
    if (_lockedAgents.contains(agent)) {
      return false;
    }
    _lockedAgents.add(agent);
    return true;
  }

  void unlock(String agent) {
    _lockedAgents.remove(agent);
  }
}

final agentLockManager = AgentLockManager();

class Recordings extends Model {
  static String table = 'recordings';

  /// Fetches the longest idle agent from a given list of logged-in agents based on the oldest updated_at timestamp.
  /// Only considers records updated within the last 8 hours.
  static Future<Map<String, dynamic>?> getLongestIdleAgent(
      List<String> loggedInAgents) async {
    if (loggedInAgents.isEmpty) {
      throw ArgumentError('No agents provided.');
    } else {
      if (loggedInAgents.length == 1) {
        print("Probbing for agents: $loggedInAgents");
        return {'agent_number': loggedInAgents.first, 'updated_at': null};
      }
    }
    print("Probbing for agents: $loggedInAgents");

    final db = await Model.getDbConnection();
    final eightHoursAgo =
        DateTime.now().subtract(Duration(hours: 48)).toIso8601String();

    List<Map<String, dynamic>> res = await db
        .table(table)
        .select(['agent_number', 'updated_at'])
        .whereIn('agent_number', loggedInAgents)
        .where('updated_at', '>=', eightHoursAgo)
        .groupBy('agent_number')
        .orderBy('updated_at', 'asc')
        // .limit(2)
        .get();

    await db.disconnect();

    print("records: ${res}");

    return res.isNotEmpty ? res.first : null;
  }
}

Future<Map<String, AgentState>> idleAgents() async {
  Map<String, AgentState> agentsStates = {
    // 'SIP/7000/6003': AgentState.LOGGEDIN,
    // 'SIP/7000/8923': AgentState.LOGGEDIN,
    // 'SIP/7000/1061': AgentState.LOGGEDIN
  };
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
      // .orWhere('status', '=', 'AgentState.IDLE')
      .groupBy('endpoint')
      .orderBy('updated_at', 'asc')
      // .limit(1)
      .get();

  await db.disconnect();
  for (var element in res) {
    // final aor = jsonDecode(await Aor.get(element['endpoint']));
    // for (var item in aor) {
    if (await Aor.contact(element['endpoint'])) {
      agentsStates["PJSIP/${element['endpoint']}"] = AgentState.LOGGEDIN;
    }
    // }
  }
  print("idle agents: $res");
  return agentsStates;
}

Future<Map<String, AgentState>> inactiveAgents() async {
  Map<String, AgentState> agentsStates = {
    // 'SIP/7000/6003': AgentState.LOGGEDIN,
    // 'SIP/7000/8923': AgentState.LOGGEDIN,
    // 'SIP/7000/1061': AgentState.LOGGEDIN
  };
  String table = 'agents';

  final db = await Model.getDbConnection();
  final eightHoursAgo =
      DateTime.now().subtract(Duration(hours: 24)).toIso8601String();

  List<Map<String, dynamic>> res = await db
      .table(table)
      .select(['endpoint', 'state', 'status', 'updated_at'])
      // .whereIn('agent_number', loggedInAgents)
      .where('updated_at', '<=', eightHoursAgo)
      .whereIn('state', ['IDLE', 'AgentState.IDLE'])
      // .orWhere('status', '=', 'AgentState.IDLE')
      .groupBy('endpoint')
      .orderBy('updated_at', 'asc')
      // .limit(1)
      .get();

  await db.disconnect();
  for (var element in res) {
    // final aor = jsonDecode(await Aor.get(element['endpoint']));
    // for (var item in aor) {
    if (await Aor.contact(element['endpoint'])) {
      agentsStates["PJSIP/${element['endpoint']}"] = AgentState.LOGGEDIN;
    }
    // }
  }
  print("idle agents: $res");
  return agentsStates;
}

// Future<String?> longestWaiting() async {
//   List<String> loggedInAgents = (await idleAgents())
//       .entries
//       .where((entry) {
//         if (entry.value == AgentState.LOGGEDIN) {
//           // Attempt to lock the agent; only consider if successful
//           return agentLockManager.tryLock(entry.key);
//         }
//         return false;
//       })
//       .map((entry) => entry.key)
//       .toList();

//   if (loggedInAgents.isEmpty) {
//     print("No idle agents available.");
//     return null;
//   }

//   // --- Step 1: Prepare agent numbers for recordings table query ---
//   final cleanAgentNumbers = loggedInAgents.map((agent) {
//     int index = agent.indexOf("/");
//     return index != -1 ? agent.substring(index + 1) : agent;
//   }).toList();

//   print("Probbing Recordings table with agent numbers: $cleanAgentNumbers");

//   // --- Step 2: Attempt to find the longest idle agent from recordings ---
//   final longestIdleAgentFromRecordings =
//       await Recordings.getLongestIdleAgent(cleanAgentNumbers);

//   // Unlock all agents initially locked, regardless of outcome
//   // This is crucial to prevent deadlocks if an agent isn't picked for a call.
//   for (String loggedInAgent in loggedInAgents) {
//     agentLockManager.unlock(loggedInAgent);
//   }

//   // --- Step 3: Prioritize agent from recordings if found ---
//   if (longestIdleAgentFromRecordings != null) {
//     print(
//         "Longest Idle Agent from Recordings: ${longestIdleAgentFromRecordings['agent_number']} (Last Call: ${longestIdleAgentFromRecordings['updated_at']})");

//     // Find the original PJSIP/ prefixed string for the agent found in recordings
//     String? bestAgentFullString;
//     for (String agentNum in loggedInAgents) {
//       if (agentNum
//           .endsWith('/${longestIdleAgentFromRecordings['agent_number']}')) {
//         bestAgentFullString = agentNum;
//         break;
//       }
//     }

//     if (bestAgentFullString != null) {
//       print("Best agent (longest idle from recordings): $bestAgentFullString");
//       return bestAgentFullString;
//     } else {
//       // Fallback: If for some reason the full PJSIP string couldn't be reconstructed,
//       // return the raw agent number from recordings. This scenario should be rare
//       // if `loggedInAgents` contains what's expected.
//       return longestIdleAgentFromRecordings['agent_number'];
//     }
//   } else {
//     // --- Step 4: Fallback - No agents found in recordings table within the time frame ---
//     print(
//         "No idle agents found with recent recordings in the database. Falling back to an agent with no recent record.");

//     // In this scenario, all agents in `loggedInAgents` are "idle" from `agents` table
//     // but have no recent entries in `recordings`.
//     // You'll need a strategy to pick one of these.
//     //
//     // Option A: Pick the first available agent (simplest)
//     if (loggedInAgents.isNotEmpty) {
//       print(
//           "Returning first available agent (no recent recording history): ${loggedInAgents[0]}");
//       // You might want to lock this agent again here if you plan to use them immediately
//       // and prevent others from picking them up simultaneously.
//       // However, since we unlocked all, this would require re-locking for the chosen one.
//       // Or, the calling function should handle the locking.
//       return loggedInAgents[0];
//     } else {
//       // This should ideally not be reached if `loggedInAgents` was not empty initially.
//       print("No idle agents available after all checks.");
//       return null;
//     }

//     // Option B (More complex): If you want the "longest idle" from the `agents` table
//     // when no recordings are found, you'd need to re-query the `agents` table,
//     // potentially ordering by `updated_at` (from `agents` table) in ascending order,
//     // but *excluding* agents that *do* have recent recordings (which you've already
//     // determined are none, but it's good to be explicit for robust logic).
//     // For simplicity, Option A (first available) is used above.
//   }
// }

Future<String?> longestWaiting() async {
  // Step 1: Get all currently logged-in and idle agents
  List<String> loggedInAgents = (await idleAgents())
      .entries
      .where((entry) {
        if (entry.value == AgentState.LOGGEDIN) {
          // Attempt to lock the agent; only consider if successful
          return agentLockManager.tryLock(entry.key);
        }
        return false;
      })
      .map((entry) => entry.key)
      .toList();

  if (loggedInAgents.isEmpty) {
    print("No idle agents available.");
    return null;
  }

  // Prepare clean agent numbers (without PJSIP/ prefix) for database queries
  final Map<String, String> cleanToFullAgentMap =
      {}; // Map clean_number -> PJSIP/clean_number
  final List<String> cleanAgentNumbers = loggedInAgents.map((fullAgentString) {
    int index = fullAgentString.indexOf("/");
    String cleanNumber =
        index != -1 ? fullAgentString.substring(index + 1) : fullAgentString;
    cleanToFullAgentMap[cleanNumber] = fullAgentString; // Store mapping
    return cleanNumber;
  }).toList();

  print("Probbing Recordings table with agent numbers: $cleanAgentNumbers");

  // Step 2: Find which of these agents have recent records in the 'recordings' table
  // This will return only agents that have records within the 48-hour window.
  List<Map<String, dynamic>> agentsWithRecentRecords = [];
  final dbRecordings = await Model.getDbConnection();
  // Using DateTime.now() to ensure it's current time for 48 hours ago calculation
  final fortyEightHoursAgo =
      DateTime.now().subtract(Duration(hours: 8)).toIso8601String();

  // Query recordings for agents within the valid list and time range
  agentsWithRecentRecords = await dbRecordings
      .table(Recordings.table) // Use Recordings.table
      .select(['agent_number', 'updated_at'])
      .whereIn('agent_number', cleanAgentNumbers) // Use clean numbers
      .where('updated_at', '>=', fortyEightHoursAgo)
      .groupBy('agent_number')
      .orderBy('updated_at', 'asc') // Oldest record first
      .get();
  await dbRecordings.disconnect();

  print("records: $agentsWithRecentRecords");

  // Step 3: Categorize agents into those with and without recent records
  final Set<String> cleanAgentsWithRecordsSet =
      agentsWithRecentRecords.map((e) => e['agent_number'] as String).toSet();

  final List<String> cleanAgentsWithoutRecentRecords = cleanAgentNumbers
      .where((agentNum) => !cleanAgentsWithRecordsSet.contains(agentNum))
      .toList();

  String? finalBestAgentFullString;

  // Step 4: Prioritize agents who have no recent records (truest longest idle)
  if (cleanAgentsWithoutRecentRecords.isNotEmpty) {
    print(
        "Candidates with no recent records: $cleanAgentsWithoutRecentRecords");

    // To pick the "longest idle" among those with no recent records,
    // we need to look at their `updated_at` in the `agents` table.
    final dbAgents = await Model.getDbConnection();
    List<Map<String, dynamic>> trulyLongestIdleFromAgents = await dbAgents
        .table('agents') // Assuming 'agents' is the table for agent status
        .select(['endpoint', 'updated_at'])
        .whereIn('endpoint', cleanAgentsWithoutRecentRecords)
        .orderBy('updated_at', 'asc') // Oldest update in 'agents' table
        .limit(1) // Just need the single longest
        .get();
    await dbAgents.disconnect();

    if (trulyLongestIdleFromAgents.isNotEmpty) {
      String bestCleanAgent = trulyLongestIdleFromAgents.first['endpoint'];
      finalBestAgentFullString = cleanToFullAgentMap[bestCleanAgent];
      print(
          "Selected agent (no recent recording history, oldest agent table update): $finalBestAgentFullString");
    } else {
      // Fallback if query on agents table fails for some reason, pick first.
      finalBestAgentFullString =
          cleanToFullAgentMap[cleanAgentsWithoutRecentRecords.first];
      print(
          "Selected agent (no recent recording history, first in list as fallback): $finalBestAgentFullString");
    }
  } else if (agentsWithRecentRecords.isNotEmpty) {
    // Step 5: Fallback to agent with oldest record if all agents have records
    print("All agents have recent records. Selecting oldest record holder.");
    // `agentsWithRecentRecords` is already sorted by `updated_at` ascending.
    String bestCleanAgent = agentsWithRecentRecords.first['agent_number'];
    finalBestAgentFullString = cleanToFullAgentMap[bestCleanAgent];
    print(
        "Selected agent (longest idle from recordings): $finalBestAgentFullString");
  } else {
    // This case should only happen if loggedInAgents was not empty, but neither
    // categories yielded any results, which implies `idleAgents` returned agents
    // that couldn't be matched in either db table queries (highly unlikely).
    print("No suitable idle agents found based on any criteria.");
  }

  // Always unlock agents after determining the candidate
  // for (String agentToUnlock in loggedInAgents) {
  //   agentLockManager.unlock(agentToUnlock);
  // }

  // Unlock only the agents that were considered but *not* selected.
  // The selected agent should remain locked by this function.
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
  print("Releasing lock for agent: $agentFullString");
  agentLockManager.unlock(agentFullString);
}

Future<void> main() async {
  String? free;
  free = await longestWaiting();
  print("Free agent: $free");

  // Example of how to use the new releaseAgentLock function:
  if (free != null) {
    // Simulate some work with the agent
    print("Performing work with agent: $free...");
    await Future.delayed(Duration(seconds: 2)); // Simulate work
    releaseAgentLock(free); // Release the lock when done
  }
}

// Future<String?> longestWaiting() async {
//   // Step 1: Get all currently logged-in and idle agents
//   List<String> loggedInAgents = (await idleAgents())
//       .entries
//       .where((entry) {
//         if (entry.value == AgentState.LOGGEDIN) {
//           // Attempt to lock the agent; only consider if successful
//           return agentLockManager.tryLock(entry.key);
//         }
//         return false;
//       })
//       .map((entry) => entry.key)
//       .toList();

//   if (loggedInAgents.isEmpty) {
//     print("No idle agents available.");
//     return null;
//   }

//   // Prepare clean agent numbers (without PJSIP/ prefix) for database queries
//   final Map<String, String> cleanToFullAgentMap =
//       {}; // Map clean_number -> PJSIP/clean_number
//   final List<String> cleanAgentNumbers = loggedInAgents.map((fullAgentString) {
//     int index = fullAgentString.indexOf("/");
//     String cleanNumber =
//         index != -1 ? fullAgentString.substring(index + 1) : fullAgentString;
//     cleanToFullAgentMap[cleanNumber] = fullAgentString; // Store mapping
//     return cleanNumber;
//   }).toList();

//   print("Probbing Recordings table with agent numbers: $cleanAgentNumbers");

//   // Step 2: Find which of these agents have recent records in the 'recordings' table
//   // This will return only agents that have records within the 48-hour window.
//   List<Map<String, dynamic>> agentsWithRecentRecords = [];
//   final dbRecordings = await Model.getDbConnection();
//   final fortyEightHoursAgo = DateTime.now()
//       .subtract(Duration(hours: 48))
//       .toIso8601String(); // Current time: 2025-07-22 11:29:13 AM CAT

//   // Query recordings for agents within the valid list and time range
//   agentsWithRecentRecords = await dbRecordings
//       .table(Recordings.table) // Use Recordings.table
//       .select(['agent_number', 'updated_at'])
//       .whereIn('agent_number', cleanAgentNumbers) // Use clean numbers
//       .where('updated_at', '>=', fortyEightHoursAgo)
//       .groupBy('agent_number')
//       .orderBy('updated_at', 'asc') // Oldest record first
//       .get();
//   await dbRecordings.disconnect();

//   print("records: $agentsWithRecentRecords");

//   // Step 3: Categorize agents into those with and without recent records
//   final Set<String> cleanAgentsWithRecordsSet =
//       agentsWithRecentRecords.map((e) => e['agent_number'] as String).toSet();

//   final List<String> cleanAgentsWithoutRecentRecords = cleanAgentNumbers
//       .where((agentNum) => !cleanAgentsWithRecordsSet.contains(agentNum))
//       .toList();

//   String? finalBestAgentFullString;

//   // Step 4: Prioritize agents who have no recent records (truest longest idle)
//   if (cleanAgentsWithoutRecentRecords.isNotEmpty) {
//     print(
//         "Candidates with no recent records: $cleanAgentsWithoutRecentRecords");

//     // To pick the "longest idle" among those with no recent records,
//     // we need to look at their `updated_at` in the `agents` table.
//     final dbAgents = await Model.getDbConnection();
//     List<Map<String, dynamic>> trulyLongestIdleFromAgents = await dbAgents
//         .table('agents') // Assuming 'agents' is the table for agent status
//         .select(['endpoint', 'updated_at'])
//         .whereIn('endpoint', cleanAgentsWithoutRecentRecords)
//         .orderBy('updated_at', 'asc') // Oldest update in 'agents' table
//         .limit(1) // Just need the single longest
//         .get();
//     await dbAgents.disconnect();

//     if (trulyLongestIdleFromAgents.isNotEmpty) {
//       String bestCleanAgent = trulyLongestIdleFromAgents.first['endpoint'];
//       finalBestAgentFullString = cleanToFullAgentMap[bestCleanAgent];
//       print(
//           "Selected agent (no recent recording history, oldest agent table update): $finalBestAgentFullString");
//     } else {
//       // Fallback if query on agents table fails for some reason, pick first.
//       finalBestAgentFullString =
//           cleanToFullAgentMap[cleanAgentsWithoutRecentRecords.first];
//       print(
//           "Selected agent (no recent recording history, first in list as fallback): $finalBestAgentFullString");
//     }
//   } else if (agentsWithRecentRecords.isNotEmpty) {
//     // Step 5: Fallback to agent with oldest record if all agents have records
//     print("All agents have recent records. Selecting oldest record holder.");
//     // `agentsWithRecentRecords` is already sorted by `updated_at` ascending.
//     String bestCleanAgent = agentsWithRecentRecords.first['agent_number'];
//     finalBestAgentFullString = cleanToFullAgentMap[bestCleanAgent];
//     print(
//         "Selected agent (longest idle from recordings): $finalBestAgentFullString");
//   } else {
//     // This case should only happen if loggedInAgents was not empty, but neither
//     // categories yielded any results, which implies `idleAgents` returned agents
//     // that couldn't be matched in either db table queries (highly unlikely).
//     print("No suitable idle agents found based on any criteria.");
//   }

//   // Always unlock agents after determining the candidate
//   for (String agentToUnlock in loggedInAgents) {
//     agentLockManager.unlock(agentToUnlock);
//   }

//   return finalBestAgentFullString;
// }

// Future<void> main() async {
//   String? free;
//   // Timer.periodic(Duration(seconds: 3), (timer) async {
//   //   // channel.on('StasisEnd', (event) {
//   //   timer.cancel();
//   // channel.off();
//   // });

//   free = await longestWaiting();
//   print("Free agent: $free");
//   //   if (free != null) timer.cancel();
//   // });
// }

// Future<void> main() async {
//   final aor = jsonDecode(await Aor.get("6004"));
//   // print("Aor: $aor");

//   for (var item in aor) {
//     if (item["attribute"] == "contact") {
//       print("Aor attribute: ${item["attribute"]}");
//       print("Aor: ${await Aor.contact("6004")}");
//     }
//   }
// }
