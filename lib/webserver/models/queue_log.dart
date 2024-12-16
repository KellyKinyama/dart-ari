import 'package:dart_ari/webserver/models/base.dart';

class QueueLog extends Model {
  static String table = 'queue_log';

  static Future<List<Map<String, dynamic>>> get() async {
    final db = await Model.getDbConnection();
    List<Map<String, dynamic>> res = await db.table(table).get();
    return res;
  }
}
