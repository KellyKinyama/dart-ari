import 'package:dart_ari/webserver/models/base.dart';

class QueueMember extends Model {
  static String table = 'queue_members';
  static Future<List<Map<String, dynamic>>> get() async {
    final db = await Model.getDbConnection();
    List<Map<String, dynamic>> res = await db.table(table).get();
    return res;
  }

  static Future<dynamic> logIn(String queueName, String interface) async {
    final db = await Model.getDbConnection();

    var res = await db
        .table(table)
        .where(queueName, '=', 'inbound')
        .where(interface, '=', interface)
        .update({'paused': 'N'});

    return res;
  }

  static Future<dynamic> logOut(String queueName, String interface) async {
    final db = await Model.getDbConnection();

    var res = await db
        .table(table)
        .where('queue_name', queueName, interface)
        .where(interface, '=', interface)
        .update({'paused': 'Y'});

    return res;
  }
}
