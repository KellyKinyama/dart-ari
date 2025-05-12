import 'dart:convert';

// import 'package:dart_ari/ari/api/utils.dart';
import 'package:dart_ari/dart_ari.dart';

import 'enums.dart';
// import 'globals.dart';
import 'package:eloquent/eloquent.dart';

String formatDateTime(String input) {
  try {
    final dt = DateTime.parse(input);
    return dt
        .toLocal()
        .toIso8601String()
        .split('.')
        .first
        .replaceFirst('T', ' ');
  } catch (_) {
    return DateTime.now()
        .toIso8601String()
        .split('.')
        .first
        .replaceFirst('T', ' ');
  }
}

// Declarations

class DbQueries {
  static Future<Connection> getDbConnection() async {
    var manager = Manager();
    if (true) {
      manager.addConnection({
        'driver': 'mysql',
        'host': config.dbConfigs[AST_DB_HOST],
        'port': config.dbConfigs[AST_DB_PORT],
        'database': config.dbConfigs[AST_DB_DATABASE],
        'username': config.dbConfigs[AST_DB_USERNAME],
        'password': config.dbConfigs[AST_DB_PASSWORD],
      });
      manager.setAsGlobal();
    }
    final db = await manager.connection();
    return db;
  }

  static Future<bool> updateInactiveAgentStatuses(
      AgentState state, AgentState status) async {
    bool successful = false;

    final db = await getDbConnection();

    print("Updating agent status: $state, $status");
    final eightHoursAgo =
        DateTime.now().subtract(Duration(hours: 24)).toIso8601String();

    try {
      await db
          .table('agents')
          .where('updated_at', '<=', eightHoursAgo)
          .update({'state': state.toString(), 'status': status.toString()});
      successful = true;
    } catch (e) {
      print('Error: $e');
      // Handle reconnection logic if needed
      successful = false;
    } finally {
      await db.disconnect();
      // ignore: control_flow_in_finally
      return successful;
    }
  }

  static Future<bool> updateAgentStatus(
      String endpoint, AgentState state, AgentState status) async {
    bool successful = false;

    final db = await getDbConnection();

    final index = endpoint.indexOf('/');
    endpoint = endpoint.substring(index + 1);

    print("Updating agent status: $endpoint, $state, $status");

    try {
      await db
          .table('agents')
          .where('endpoint', '=', endpoint)
          .update({'state': state.toString(), 'status': status.toString()});
      successful = true;
    } catch (e) {
      print('Error: $e');
      // Handle reconnection logic if needed
      successful = false;
    } finally {
      await db.disconnect();
      // ignore: control_flow_in_finally
      return successful;
    }
  }

  static Future<dynamic> agents() async {
    final db = await getDbConnection();
    var res = await db.table('agents').get();

    final resp = json.encode(res);
    db.disconnect();
    return resp;
  }

  static Future<dynamic> freeAgents() async {
    final db = await getDbConnection();
    var res = await db
        .table('agents')
        .where("state", '=', AgentState.LOGGEDIN)
        .where("status", '=', AgentState.IDLE)
        .get();

    final resp = json.encode(res);
    db.disconnect();
    return resp;
  }

  // Function to check if an agent's status is IDLE
  static Future<bool> isAgentIdle(String endpoint) async {
    final db = await getDbConnection();

    try {
      // Query the agent's state and status based on the endpoint
      var agent =
          await db.table('agents').where('endpoint', '=', endpoint).first();

      // Check if the agent's status is IDLE
      if (agent != null) {
        return agent['state'] == AgentState.LOGGEDIN &&
            agent['status'] == AgentState.IDLE;
      } else {
        // Agent not found
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false; // Return false in case of error
    } finally {
      await db.disconnect();
    }
  }

  static Future<bool> insertDialEvent(Map<String, dynamic> event) async {
    final db = await getDbConnection();
    bool success = false;

    try {
      final peer = event['peer'] ?? {};
      final dialplan = peer['dialplan'] ?? {};
      final caller = peer['caller'] ?? {};
      final connected = peer['connected'] ?? {};

      await db.table('dial_event_logs').insert({
        'event_type': event['type'],
        'event_timestamp': formatDateTime(event['timestamp']),
        'dialstatus': event['dialstatus'],
        'forward': event['forward'],
        'dialstring': event['dialstring'],
        'asterisk_id': event['asterisk_id'],
        'application': event['application'],
        'peer_id': peer['id'],
        'peer_name': peer['name'],
        'peer_state': peer['state'],
        'peer_protocol_id': peer['protocol_id'],
        'peer_accountcode': peer['accountcode'],
        'peer_creationtime': formatDateTime(peer['creationtime']),
        'peer_language': peer['language'],
        'caller_name': caller['name'],
        'caller_number': caller['number'],
        'connected_name': connected['name'],
        'connected_number': connected['number'],
        'dialplan_context': dialplan['context'],
        'dialplan_exten': dialplan['exten'],
        'dialplan_priority': dialplan['priority'],
        'dialplan_app_name': dialplan['app_name'],
        'dialplan_app_data': dialplan['app_data'],
        'created_at': DateTime.now()
            .toIso8601String()
            .split('.')
            .first
            .replaceFirst('T', ' '),
        'updated_at': DateTime.now()
            .toIso8601String()
            .split('.')
            .first
            .replaceFirst('T', ' '),
      });

      success = true;
    } catch (e, st) {
      print('Insert Dial Event Error: $e, Stack trace: $st');
      success = false;
    } finally {
      await db.disconnect();
      return success;
    }
  }

  static Future<bool> insertStasisEndEvent(Map<String, dynamic> event) async {
    final db = await getDbConnection();
    bool success = false;

    try {
      final channel = event['channel'] ?? {};
      final caller = channel['caller'] ?? {};
      final connected = channel['connected'] ?? {};
      final dialplan = channel['dialplan'] ?? {};

      await db.table('stasis_end_events').insert({
        'type': event['type'],
        'timestamp': formatDateTime(event['timestamp']),
        'asterisk_id': event['asterisk_id'],
        'application': event['application'],
        'channel_id': channel['id'],
        'channel_name': channel['name'],
        'channel_state': channel['state'],
        'channel_protocol_id': channel['protocol_id'],
        'caller_name': caller['name'],
        'caller_number': caller['number'],
        'connected_name': connected['name'],
        'connected_number': connected['number'],
        'accountcode': channel['accountcode'],
        'dialplan_context': dialplan['context'],
        'dialplan_exten': dialplan['exten'],
        'dialplan_priority': dialplan['priority'],
        'dialplan_app_name': dialplan['app_name'],
        'dialplan_app_data': dialplan['app_data'],
        'channel_creationtime': formatDateTime(channel['creationtime']),
        'channel_language': channel['language'],
        'created_at': DateTime.now()
            .toIso8601String()
            .split('.')
            .first
            .replaceFirst('T', ' '),
        'updated_at': DateTime.now()
            .toIso8601String()
            .split('.')
            .first
            .replaceFirst('T', ' '),
      });

      success = true;
    } catch (e, st) {
      print('Insert StasisEnd Event Error: $e\nStack trace: $st');
      success = false;
    } finally {
      await db.disconnect();
      return success;
    }
  }

  static Future<bool> insertStasisStartEvent(Map<String, dynamic> event) async {
    final db = await getDbConnection();
    bool success = false;

    try {
      final channel = event['channel'] ?? {};
      final caller = channel['caller'] ?? {};
      final connected = channel['connected'] ?? {};
      final dialplan = channel['dialplan'] ?? {};
      final args = event['args'];

      await db.table('stasis_start_events').insert({
        'type': event['type'],
        'timestamp': formatDateTime(event['timestamp']),
        'asterisk_id': event['asterisk_id'],
        'application': event['application'],
        'args': args != null ? jsonEncode(args) : null,
        'channel_id': channel['id'],
        'channel_name': channel['name'],
        'channel_state': channel['state'],
        'channel_protocol_id': channel['protocol_id'],
        'caller_name': caller['name'],
        'caller_number': caller['number'],
        'connected_name': connected['name'],
        'connected_number': connected['number'],
        'accountcode': channel['accountcode'],
        'dialplan_context': dialplan['context'],
        'dialplan_exten': dialplan['exten'],
        'dialplan_priority': dialplan['priority'],
        'dialplan_app_name': dialplan['app_name'],
        'dialplan_app_data': dialplan['app_data'],
        'channel_creationtime': formatDateTime(channel['creationtime']),
        'channel_language': channel['language'],
        'created_at': DateTime.now()
            .toIso8601String()
            .split('.')
            .first
            .replaceFirst('T', ' '),
        'updated_at': DateTime.now()
            .toIso8601String()
            .split('.')
            .first
            .replaceFirst('T', ' '),
      });

      success = true;
    } catch (e, st) {
      print('Insert StasisStart Event Error: $e\nStack trace: $st');
      success = false;
    } finally {
      await db.disconnect();
      return success;
    }
  }
}
