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
    if (loggedInAgents.isEmpty) return null;

    final db = await Model.getDbConnection();
    final eightHoursAgo =
        DateTime.now().subtract(Duration(hours: 8)).toIso8601String();

    List<Map<String, dynamic>> res = await db
        .table(table)
        .select(['agent_number', 'updated_at'])
        .whereIn('agent_number', loggedInAgents)
        // .where('updated_at', '>=', eightHoursAgo)
        .groupBy('agent_number')
        .orderBy('updated_at', 'asc')
        .limit(1)
        .get();

    await db.disconnect();

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
      DateTime.now().subtract(Duration(hours: 8)).toIso8601String();

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
    agentsStates["SIP/7000/${element['endpoint']}"] = AgentState.LOGGEDIN;
    print("Response: ${element['endpoint']}");
  }
  print("Agents: ${agentsStates}");
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
      .where((entry) => entry.value == AgentState.LOGGEDIN)
      .map((entry) => entry.key)
      .toList();

  if (loggedInAgents.length == 1) {
    // print("No idle agents available.");
    return loggedInAgents[0];
  }

  if (loggedInAgents.isEmpty) {
    // print("No idle agents available.");
    if (!stopQuery) {
      await Future.delayed(Duration(seconds: 4));
      event.off();
      await longestWaiting(event);
    }
  }

  final longestIdleAgent = await Recordings.getLongestIdleAgent(loggedInAgents);

  if (longestIdleAgent != null) {
    print(
        "Longest Idle Agent: ${longestIdleAgent['agent_number']} (Last Call: ${longestIdleAgent['updated_at']})");
    freeAgentCompleter.complete(true);
    return longestIdleAgent['agent_number'];
  } else {
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

// Future<String> longestWaiting(Map<String, AgentState> agentsStates) async {
//   List<String> loggedInAgents = [
//     'SIP/7000/6003',
//     'SIP/7000/8923',
//     'SIP/7000/1061'
//   ];
//   final longestIdleAgent = await Recordings.getLongestIdleAgent(loggedInAgents);
//   if (longestIdleAgent != null) {
//     print(
//         "Longest Idle Agent: ${longestIdleAgent['agent_number']} (Last Call: ${longestIdleAgent['updated_at']})");
//     return longestIdleAgent['agent_number'];
//   } else {
//     print("No idle agents found.");
//     return loggedInAgents[0];
//   }
// }

Future<void> main() async {
  // Map<String, AgentState> agentsStates = {
  //   'SIP/7000/6003': AgentState.LOGGEDIN,
  //   'SIP/7000/8923': AgentState.LOGGEDIN,
  //   'SIP/7000/1061': AgentState.LOGGEDIN
  // };
  // final bestAgent = await longestWaiting(agentsStates);
  // print("Best agent: $bestAgent");
  await idleAgents();
  // await longestWaiting();
}
