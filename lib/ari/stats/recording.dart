import 'package:dart_ari/dart_ari.dart';
import 'package:eloquent/eloquent.dart';

import '../api/database.dart';

class CallRecording {
  CallRecording(
      {required this.agent_number,
      required this.phone_number,
      required this.file_path,
      required this.file_name,
      this.src,
      this.dst,
      this.clid,
      this.calldate,
      this.answerdate,
      this.hangupdate,
      this.duration,
      this.billsec,
      this.disposition,
      this.caller_rtp_local,
      this.caller_rtp_remote,
      this.caller_sip_remote,
      this.peer_rtp_local,
      this.peer_rtp_remote,
      this.peer_sip_remote});

  String? agent_number; //?: string;
  String? phone_number; //?: string;
  String? duration_number; //?: Ari.CallerID;
  String? file_name; //?: string;
  String? file_path; //?: Ari.CallerID;
  String? transcription; //?: string;

  String? src;
  String? dst;
  String? clid;
  String? calldate;
  String? answerdate;
  String? hangupdate;
  String? duration;
  String? billsec;
  String? disposition;

  /// Local RTP endpoint (Asterisk side) for the caller/inbound leg, IP:PORT.
  String? caller_rtp_local;

  /// Remote RTP endpoint (as announced in the SDP) for the caller leg.
  String? caller_rtp_remote;

  /// SIP signaling peer address for the caller leg.
  String? caller_sip_remote;

  /// Local RTP endpoint for the peer/dialed leg, IP:PORT.
  String? peer_rtp_local;

  /// Remote RTP endpoint (as announced in the SDP) for the peer leg.
  String? peer_rtp_remote;

  /// SIP signaling peer address for the peer leg.
  String? peer_sip_remote;

  Map<String, String> parse() {
    return {
      "agent_number": agent_number ?? "",
      "phone_number": phone_number ?? "",
      "duration_number": duration_number ?? "",
      "file_name": file_name ?? "",
      "file_path": file_path ?? "",
      "transcription": transcription ?? "",
      "caller_rtp_local": caller_rtp_local ?? "",
      "caller_rtp_remote": caller_rtp_remote ?? "",
      "caller_sip_remote": caller_sip_remote ?? "",
      "peer_rtp_local": peer_rtp_local ?? "",
      "peer_rtp_remote": peer_rtp_remote ?? "",
      "peer_sip_remote": peer_sip_remote ?? "",
    };
  }

  /// Build a filename that embeds the SDP peer IPs so the recording is
  /// self-labeling: `<timestamp>_<callerIp>_<peerIp>_<uniqueId>`.
  ///
  /// Colons and dots are preserved for IPv4 but colons in IPv6 addresses
  /// are replaced with `-` to keep the filename filesystem-safe. Pass just
  /// the IP (no port); use [SdpEndpoints.remoteRtpIp] to extract it.
  static String buildFilename({
    required String uniqueId,
    String? callerIp,
    String? peerIp,
    DateTime? timestamp,
  }) {
    final ts = (timestamp ?? DateTime.now()).toUtc();
    final stamp =
        '${ts.year.toString().padLeft(4, '0')}${ts.month.toString().padLeft(2, '0')}${ts.day.toString().padLeft(2, '0')}-'
        '${ts.hour.toString().padLeft(2, '0')}${ts.minute.toString().padLeft(2, '0')}${ts.second.toString().padLeft(2, '0')}';
    // Strip any filesystem-illegal chars (Windows: <>:"/\|?*), keep colons
    // in IPv4/IPv6 addresses converted to '-' for cross-platform safety.
    String s(String? ip) {
      if (ip == null || ip.isEmpty) return 'unknown';
      final cleaned =
          ip.replaceAll(':', '-').replaceAll(RegExp(r'[<>"/\\|?*\s]'), '');
      return cleaned.isEmpty ? 'unknown' : cleaned;
    }

    return '${stamp}_${s(callerIp)}_${s(peerIp)}_$uniqueId';
  }

  Future<void> insertCallRecording() async {
    final manager = Manager();
    manager.addConnection({
      'driver': 'mysql',
      'host': config.dbConfigs[AST_DB_HOST],
      'port': config.dbConfigs[AST_DB_PORT],
      'database': config.dbConfigs[AST_DB_DATABASE],
      'username': config.dbConfigs[AST_DB_USERNAME],
      'password': config.dbConfigs[AST_DB_PASSWORD],
    });
    manager.setAsGlobal();
    final db = await manager.connection();
    await db.table('recordings').insert({
      "agent_number": agent_number ?? "",
      "phone_number": phone_number ?? "",
      "duration_number": duration_number ?? "",
      "file_name": file_name ?? "",
      "file_path": file_path ?? "",

      'src': src ?? "",
      'dst': dst ?? "",
      'clid': clid ?? "",
      'calldate': calldate ?? "",
      'answerdate': answerdate ?? "",
      'hangupdate': hangupdate ?? "",
      'duration': duration ?? "",
      'billsec': billsec ?? "",
      'disposition': disposition ?? "",
      //"transcription": transcription ?? "",
      'caller_rtp_local': caller_rtp_local ?? "",
      'caller_rtp_remote': caller_rtp_remote ?? "",
      'caller_sip_remote': caller_sip_remote ?? "",
      'peer_rtp_local': peer_rtp_local ?? "",
      'peer_rtp_remote': peer_rtp_remote ?? "",
      'peer_sip_remote': peer_sip_remote ?? "",
      "created_at": DateTime.now().toString(),
      "updated_at": DateTime.now().toString(),
    });
    // Pool stays open; release is a no-op that documents the intent.
    await Database.release(db);
  }
}
