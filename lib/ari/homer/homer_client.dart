import 'package:postgres/postgres.dart';

/// Thin client over Homer's TimescaleDB. Only capability: look up the SIP
/// Call-ID that carried a call, keyed by (from_user, to_user, time window).
class HomerClient {
  HomerClient({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    this.sipTable = 'hep_proto_1_call',
  });

  final String host;
  final int port;
  final String database;
  final String username;
  final String password;

  /// heplify-server buckets SIP by method: INVITE/BYE/CANCEL go into
  /// `hep_proto_1_call`, keepalives (OPTIONS/NOTIFY) into `_default`,
  /// REGISTER into `_registration`. Time-partitioned children query
  /// transparently through the parent.
  final String sipTable;

  Connection? _conn;

  Future<Connection> _connect() async {
    final c = _conn;
    if (c != null && c.isOpen) return c;
    final fresh = await Connection.open(
      Endpoint(
        host: host,
        port: port,
        database: database,
        username: username,
        password: password,
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
    _conn = fresh;
    return fresh;
  }

  /// Return the SIP Call-ID for the dialog that carried this call, or null
  /// if Homer didn't capture it. [fromUser] is matched loosely (last-N-digit
  /// suffix if it looks like a phone number) because trunks and B2BUAs
  /// often reformat prefixes; [toUser] is matched exactly since the agent
  /// extension is stable end-to-end. Only INVITEs are considered — that's
  /// the one dialog-forming message per call.
  Future<String?> findCallId({
    required String fromUser,
    required String toUser,
    required DateTime from,
    required DateTime to,
  }) async {
    final conn = await _connect();
    final fromSuffix = _phoneSuffix(fromUser);
    final rows = await conn.execute(
      Sql.named('''
        SELECT sid
          FROM $sipTable
         WHERE create_date BETWEEN @from AND @to
           AND data_header->>'method' = 'INVITE'
           AND data_header->>'to_user' = @toUser
           AND data_header->>'from_user' LIKE @fromLike
         ORDER BY create_date ASC
         LIMIT 1
      '''),
      parameters: {
        'from': TypedValue(Type.timestampWithoutTimezone, from),
        'to': TypedValue(Type.timestampWithoutTimezone, to),
        'toUser': toUser,
        'fromLike': fromSuffix == null ? fromUser : '%$fromSuffix',
      },
    );
    if (rows.isEmpty) return null;
    return rows.first[0] as String?;
  }

  /// If [v] contains ≥7 digits, return the last 9 (or all digits, if
  /// fewer). Used to match phone numbers regardless of country-code prefix.
  static String? _phoneSuffix(String v) {
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return null;
    return digits.length <= 9 ? digits : digits.substring(digits.length - 9);
  }

  Future<void> close() async {
    await _conn?.close();
    _conn = null;
  }
}
