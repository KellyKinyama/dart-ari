import 'package:eloquent/eloquent.dart';

import '../config/constants.dart';
import 'globals.dart';

/// Shared, pooled access to the application database.
///
/// IMPORTANT: This database is also used by the Laravel dashboard. We must
/// be a polite client:
///   * Open as few sockets as possible (use the eloquent connection pool).
///   * NEVER open + close a connection per query — that hammered MySQL with
///     a continuous connect/auth/disconnect storm and consumed slots that
///     Laravel needs.
///   * Keep transactions short.
///
/// All DB access in this codebase MUST go through [Database.connection].
/// The legacy `Model.getDbConnection()` and `DbQueries.getDbConnection()`
/// helpers now delegate here so older call sites benefit automatically.
class Database {
  /// Pool size used when [AST_DB_POOL_SIZE] is not provided in the env.
  /// Tuned conservatively so we don't crowd out the Laravel dashboard.
  static const int defaultPoolSize = 5;

  static Manager? _manager;
  static Connection? _connection;
  static Future<Connection>? _initFuture;

  /// Returns the process-wide pooled [Connection]. The first call lazily
  /// builds the [Manager] with `pool: true` and a small `poolsize`. All
  /// subsequent calls reuse it.
  static Future<Connection> connection() async {
    if (_connection != null) return _connection!;
    // Coalesce concurrent first-time callers onto the same init future so
    // we never build two managers in parallel.
    return _initFuture ??= _initialize();
  }

  /// Returns the singleton [Manager] (after [connection] has been called
  /// at least once). Useful for callers that need to open additional
  /// query builders / schema operations through the same pool.
  static Manager? get manager => _manager;

  static Future<Connection> _initialize() async {
    final poolSize = _resolvePoolSize();
    final manager = Manager();
    manager.addConnection({
      'driver': 'mysql',
      'host': config.dbConfigs[AST_DB_HOST],
      'port': config.dbConfigs[AST_DB_PORT],
      'database': config.dbConfigs[AST_DB_DATABASE],
      'username': config.dbConfigs[AST_DB_USERNAME],
      'password': config.dbConfigs[AST_DB_PASSWORD],
      // Eloquent forwards these into the underlying MySQL DSN, which
      // switches mysql_client to MySQLConnectionPool. Connections inside
      // the pool are kept alive and reused across queries.
      'pool': 'true',
      'poolsize': '$poolSize',
      'allowreconnect': 'true',
      'application_name': 'dart-ari',
    });
    manager.setAsGlobal();

    final conn = await manager.connection();
    _manager = manager;
    _connection = conn;
    print(
        'Database: pooled MySQL connection ready (poolsize=$poolSize, host=${config.dbConfigs[AST_DB_HOST]}, db=${config.dbConfigs[AST_DB_DATABASE]}).');
    return conn;
  }

  static int _resolvePoolSize() {
    final raw = config.dbConfigs['AST_DB_POOL_SIZE'];
    if (raw == null) return defaultPoolSize;
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= 0) return defaultPoolSize;
    return parsed;
  }

  /// Per-query callers used to call `db.disconnect()` after every statement.
  /// With pooling that would close the pool — exactly what we don't want.
  /// Use this no-op everywhere instead so the intent ("I'm done with the
  /// connection") is preserved while the pool stays alive.
  static Future<void> release(Connection _) async {
    // Intentionally no-op. The connection lives inside the pool.
  }

  /// Graceful shutdown hook (call once on application exit). Tests and
  /// CLI tools can invoke this to free the underlying socket(s).
  static Future<void> close() async {
    final conn = _connection;
    _connection = null;
    _manager = null;
    _initFuture = null;
    if (conn != null) {
      try {
        await conn.disconnect();
      } catch (e) {
        print('Database.close: error while closing pool: $e');
      }
    }
  }
}
