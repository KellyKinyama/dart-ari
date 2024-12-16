import 'dart:convert';

import 'package:dart_ari/ari/api/enums.dart';
import 'package:dart_ari/dart_ari.dart';

import 'globals.dart';
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

  static Future<void> updateAgentStatus(
      String endpoint, String state, String status) async {
    final db = await getDbConnection();

    try {
      await db
          .table('agents')
          .where('endpoint', '=', endpoint)
          .update({'state': state, 'status': status});
    } catch (e) {
      print('Error: $e');
      // Handle reconnection logic if needed
    } finally {
      await db.disconnect();
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
}
