
import 'package:dart_ari/webserver/models/base.dart';

class Agent extends Model {
  static String table = 'agents';
  static Future<void> updateAgentStatus(
      String endpoint, String state, String status) async {
    final db = await Model.getDbConnection();

    try {
      await db
          .table(table)
          .where('endpoint', '=', endpoint)
          .update({'state': state, 'status': status});
    } catch (e) {
      print('Error: $e');
      // Handle reconnection logic if needed
    } finally {
      await db.disconnect();
    }
  }

  static Future<dynamic> get({String? interface}) async {
    var res;
    final db = await Model.getDbConnection();
    try {
      var query = interface == null
          ? db.table(table)
          : db.table(table).where('interface', '=', interface);
      res = await query.get();
    } catch (e, stackTrace) {
      print('Error: $e');
      res = "{'error: $e', stacktrace: $stackTrace}";
      // Handle reconnection logic if needed
    } finally {
      await db.disconnect();
    }
    return res;
  }
}
