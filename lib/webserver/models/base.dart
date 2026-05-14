import 'package:eloquent/eloquent.dart';

import '../../ari/api/database.dart';

abstract class Model {
  /// Backwards-compatible accessor. Now returns the process-wide pooled
  /// connection from [Database.connection] instead of opening a fresh
  /// MySQL socket per call.
  ///
  /// IMPORTANT: callers must NOT call `db.disconnect()` on the returned
  /// connection — that closes the shared pool. Use [Database.release]
  /// (currently a no-op) to mark "I'm done" without tearing the pool down.
  static Future<Connection> getDbConnection() => Database.connection();
}
