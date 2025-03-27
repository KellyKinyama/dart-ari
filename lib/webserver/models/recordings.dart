import 'dart:async';
import 'dart:convert';

import 'package:dart_ari/webserver/models/base.dart';
import 'package:events_emitter/events_emitter.dart';

import '../../ari/api/enums.dart';

class Recordings extends Model {
  static String table = 'recordings';

  /// Fetches the longest idle agent from a given list of logged-in agents based on the oldest updated_at timestamp.
  /// Only considers records updated within the last 8 hours.
  static Future<Map<String, dynamic>?> getLongestIdleAgent(
      List<String> loggedInAgents) async {
    if (loggedInAgents.isEmpty) {
      throw ArgumentError('No agents provided.');
    } else {
      // if (loggedInAgents.length == 1) {
      print("Probbing for agents: $loggedInAgents");
      // return {'agent_number': loggedInAgents.first, 'updated_at': null};
    }

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
  // final bestAgent = await longestWaiting(agentsStates);
  // print("Best agent: $bestAgent");
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
    agentsStates["PJSIP/${element['endpoint']}"] = AgentState.LOGGEDIN;
    // agentsStates[element['endpoint']] = AgentState.LOGGEDIN;
    // print("Response: ${element['endpoint']}");
  }
  // print("records: ${res}");
  return agentsStates;
}

Future<String> longestWaiting(EventEmitter event) async {
  // Filter only idle agents
  bool stopQuery = false;
  event.on('stopquery', (event) {
    stopQuery = true;
  });
  Completer<bool> freeAgentCompleter = Completer();
  List<String> loggedInAgents = (await idleAgents())
      // .where((entry) => entry.value == AgentState.IDLE)
      .entries
      .where((entry) {
        return entry.value == AgentState.LOGGEDIN;
      })
      .map((entry) => entry.key)
      .toList();

  // if (loggedInAgents.length == 1) {
  //   // print("No idle agents available.");
  //   return loggedInAgents[0];
  // }

  if (loggedInAgents.isEmpty) {
    print("No idle agents available.");
    if (!stopQuery) {
      await Future.delayed(Duration(seconds: 4));
      if(event.listeners.isNotEmpty) {
        await longestWaiting(event);
      }
    }
  }

  final longestIdleAgent = await Recordings.getLongestIdleAgent(loggedInAgents);

  if (longestIdleAgent != null) {
    print(
        "Longest Idle Agent: ${longestIdleAgent['agent_number']} (Last Call: ${longestIdleAgent['updated_at']})");
    freeAgentCompleter.complete(true);
    return longestIdleAgent['agent_number'];
  } else {
    if (loggedInAgents.length > 1) {
      return loggedInAgents[0];
    }
    print("No idle agents found in the database.");
    // return loggedInAgents[0];

    if (!stopQuery) {
      await Future.delayed(Duration(seconds: 4));
      event.off();
      await longestWaiting(event);
    }
  }
  throw ("No idle agents found.");
}

// static Future<Map<String, dynamic>?> getLongestIdleAgent(List<String> loggedInAgents) async {
//   if (loggedInAgents.isEmpty) return null;

//   final db = await Model.getDbConnection();

//   // Get all agent_number and their last updated_at from recordings (if any)
//   final recordings = await db
//       .table(table)
//       .select(['agent_number', 'updated_at'])
//       .whereIn('agent_number', loggedInAgents)
//       .get();
 
//   await db.disconnect();

//   // Create a map of agent_number to updated_at
//   final Map<String, String> agentUpdatedMap = {
//     for (var row in recordings) row['agent_number']: row['updated_at']
//   };

//   // Separate agents with no recordings
//   final agentsWithNoRecordings = loggedInAgents.where((a) => !agentUpdatedMap.containsKey(a)).toList();

//   if (agentsWithNoRecordings.isNotEmpty) {
//     // If some agents have no recordings, return the first one (or sort them by whatever other criteria)
//     return {
//       'agent_number': agentsWithNoRecordings.first,
//       'updated_at': null,
//       'note': 'No recordings yet'
//     };
//   }

//   // Else, get the one with the oldest updated_at
//   final sorted = agentUpdatedMap.entries.toList()
//     ..sort((a, b) => a.value.compareTo(b.value));

//   return {
//     'agent_number': sorted.first.key,
//     'updated_at': sorted.first.value
//   };
// }

Future<void> main() async {
  // Map<String, AgentState> agentsStates = {
  //   'SIP/7000/6003': AgentState.LOGGEDIN,
  //   'SIP/7000/8923': AgentState.LOGGEDIN,
  //   'SIP/7000/1061': AgentState.LOGGEDIN
  // };
  // final bestAgent = await longestWaiting(agentsStates);
  // print("Best agent: $bestAgent");
  //  await idleAgents();
 
  final events = EventEmitter();
  // final agent = await longestWaiting(events);

  // Recordings.getLongestIdleAgent();
  // print("Best agent: $agent");
}
