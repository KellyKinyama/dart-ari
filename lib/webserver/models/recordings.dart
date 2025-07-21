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

Future<String?> longestWaiting() async {
  List<String> loggedInAgents = (await idleAgents())
      .entries
      .where((entry) {
        if (entry.value == AgentState.LOGGEDIN) {
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

  final longestIdleAgent = await Recordings.getLongestIdleAgent(loggedInAgents);

  for (String loggedInAgent in loggedInAgents) {
    agentLockManager.unlock(loggedInAgent);
  }

  if (longestIdleAgent != null) {
    print(
        "Longest Idle Agent: ${longestIdleAgent['agent_number']} (Last Call: ${longestIdleAgent['updated_at']})");

    dynamic bestAgent;

    loggedInAgents.reversed.forEach((agentNum) {
      int index = agentNum.indexOf("/");
      if (agentNum.substring(index + 1) != longestIdleAgent['agent_number']) {
        bestAgent = agentNum;
      }
    });

    if (bestAgent != null) {
      print("Best agent: $bestAgent");
      return bestAgent;
    } else {
      return longestIdleAgent['agent_number'];
    }
  } else {
    if (loggedInAgents.isNotEmpty) {
      return loggedInAgents[0];
    }
    print("No idle agents found in the database.");
  }
  return null;
}

Future<void> main() async {
  String? free;
  // Timer.periodic(Duration(seconds: 3), (timer) async {
  //   // channel.on('StasisEnd', (event) {
  //   timer.cancel();
  // channel.off();
  // });

  free = await longestWaiting();
  print("Free agent: $free");
  //   if (free != null) timer.cancel();
  // });
}

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
