import 'package:postgres/postgres.dart';

/// Thin client over Homer's TimescaleDB. Returns per-dialog SIP metadata
/// (Call-ID, endpoints, SDP anchor IP) for a given call.
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

  /// Return every distinct SIP dialog Homer saw within [from]..[to] that
  /// involved the customer number ([fromUser]) or the agent extension
  /// ([toUser]). One [HomerLeg] per Call-ID. A call through a B2BUA
  /// typically produces 2-3 legs — customer→OXE, OXE→agent (and the
  /// OXE→Asterisk callback whose SDP carries the *real* agent IP behind
  /// the B2BUA anchor).
  ///
  /// [fromUser] matches by last-N-digit suffix if it looks like a phone
  /// number (trunks/B2BUAs often reformat country-code prefixes);
  /// [toUser] matches exactly.
  Future<List<HomerLeg>> findLegs({
    required String fromUser,
    required String toUser,
    required DateTime from,
    required DateTime to,
  }) async {
    final conn = await _connect();
    final fromSuffix = _phoneSuffix(fromUser);
    final fromLike = fromSuffix == null ? fromUser : '%$fromSuffix';
    // For each dialog (sid) we want the *latest* INVITE's SDP, not the
    // first. The initial INVITE anchors media at the B2BUA (e.g. OXE at
    // 10.1.8.226); when OXE later transfers the call to a physical agent
    // it sends a re-INVITE with the agent's phone IP in c=IN IP4 ...,
    // and that's the value we actually want to surface.
    //
    // Both parties must be on the dialog: customer (fromLike) AND agent
    // (toUser). Without the AND the hunt-group extension (3636) would
    // match every concurrent call in the time window.
    final rows = await conn.execute(
      Sql.named('''
        SELECT DISTINCT ON (sid)
               sid,
               data_header->>'from_user'  AS from_user,
               data_header->>'to_user'    AS to_user,
               data_header->>'user_agent' AS user_agent,
               raw
          FROM $sipTable
         WHERE create_date BETWEEN @from AND @to
           AND data_header->>'method' = 'INVITE'
           AND (
             data_header->>'from_user' LIKE @fromLike
             OR data_header->>'to_user' LIKE @fromLike
           )
           AND (
             data_header->>'to_user'   = @toUser
             OR data_header->>'from_user' = @toUser
           )
         ORDER BY sid, create_date DESC
      '''),
      parameters: {
        'from': TypedValue(Type.timestampWithoutTimezone, from),
        'to': TypedValue(Type.timestampWithoutTimezone, to),
        'toUser': toUser,
        'fromLike': fromLike,
      },
    );
    return [
      for (final row in rows)
        if (row[0] is String)
          HomerLeg(
            callid: row[0] as String,
            fromUser: row[1] as String?,
            toUser: row[2] as String?,
            userAgent: row[3] as String?,
            sdp: _parseSdp(row[4] as String?),
          ),
    ];
  }

  /// If [v] contains ≥7 digits, return the last 9 (or all digits, if
  /// fewer). Used to match phone numbers regardless of country-code prefix.
  static String? _phoneSuffix(String v) {
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return null;
    return digits.length <= 9 ? digits : digits.substring(digits.length - 9);
  }

  /// Best-effort SDP parse. Returns null if [raw] has no SDP body or
  /// neither a `c=` nor `m=audio` line is present.
  static SdpAnchor? _parseSdp(String? raw) {
    if (raw == null) return null;
    final cLine =
        RegExp(r'^c=IN\s+IP4\s+([\d.]+)', multiLine: true).firstMatch(raw);
    final mLine = RegExp(r'^m=audio\s+(\d+)', multiLine: true).firstMatch(raw);
    if (cLine == null && mLine == null) return null;
    return SdpAnchor(
      ip: cLine?.group(1),
      port: mLine == null ? null : int.tryParse(mLine.group(1)!),
    );
  }

  Future<void> close() async {
    await _conn?.close();
    _conn = null;
  }
}

class HomerLeg {
  HomerLeg({
    required this.callid,
    this.fromUser,
    this.toUser,
    this.userAgent,
    this.sdp,
  });

  final String callid;
  final String? fromUser;
  final String? toUser;
  final String? userAgent;
  final SdpAnchor? sdp;

  Map<String, dynamic> toJson() => {
        'callid': callid,
        if (fromUser != null) 'from_user': fromUser,
        if (toUser != null) 'to_user': toUser,
        if (userAgent != null) 'user_agent': userAgent,
        if (sdp != null) 'sdp': sdp!.toJson(),
      };
}

class SdpAnchor {
  SdpAnchor({this.ip, this.port});

  /// `c=IN IP4 …` — the media anchor IP the SDP is offering/answering.
  /// Behind a B2BUA this is usually the agent's phone IP, not the B2BUA.
  final String? ip;

  /// `m=audio <port> …` — RTP port paired with [ip].
  final int? port;

  Map<String, dynamic> toJson() => {
        if (ip != null) 'ip': ip,
        if (port != null) 'port': port,
      };
}
