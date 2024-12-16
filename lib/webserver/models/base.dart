import '../../ari/api/globals.dart';
import 'package:eloquent/eloquent.dart';

import '../../ari/config/constants.dart';

abstract class Model {
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
}
