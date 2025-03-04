import 'dart:convert';

// import 'package:dart_ari/ari/api/utils.dart';
import 'package:dart_ari/dart_ari.dart';

import 'enums.dart';
// import 'globals.dart';
import 'package:eloquent/eloquent.dart';

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

  static Future<bool> updateAgentStatus(
      String endpoint, AgentState state, AgentState status) async {
    bool successful = false;
    final db = await getDbConnection();

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
}
