import 'package:dart_ari/webserver/models/base.dart';

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
        .where('updated_at', '>=', eightHoursAgo)
        .groupBy('agent_number')
        .orderBy('updated_at', 'asc')
        .limit(1)
        .get();

    await db.disconnect();

    return res.isNotEmpty ? res.first : null;
  }
}

Future<String> longestWaiting() async {
  List<String> loggedInAgents = [
    'SIP/7000/6003',
    'SIP/7000/8923',
    'SIP/7000/1061'
  ];
  final longestIdleAgent = await Recordings.getLongestIdleAgent(loggedInAgents);
  if (longestIdleAgent != null) {
    print(
        "Longest Idle Agent: ${longestIdleAgent['agent_number']} (Last Call: ${longestIdleAgent['updated_at']})");
    return longestIdleAgent['agent_number'];
  } else {
    print("No idle agents found.");
    return loggedInAgents[0];
  }
}

Future<void> main() async {
  final bestAgent = await longestWaiting();
  print("Best agent: $bestAgent");
}
