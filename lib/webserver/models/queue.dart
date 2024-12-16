import 'package:dart_ari/webserver/models/base.dart';

class Queue extends Model {
  static String table = 'queues';

  static Future<List<Map<String, dynamic>>> get() async {
    final db = await Model.getDbConnection();
    List<Map<String, dynamic>> res = await db.table(table).get();
    return res;
  }
}
