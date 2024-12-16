import 'package:dart_ari/dart_ari.dart';
import 'package:eloquent/eloquent.dart';

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
      this.disposition});

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

  Map<String, String> parse() {
    return {
      "agent_number": agent_number ?? "",
      "phone_number": phone_number ?? "",
      "duration_number": duration_number ?? "",
      "file_name": file_name ?? "",
      "file_path": file_path ?? "",
      "transcription": transcription ?? "",
    };
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
      "created_at": DateTime.now().toString(),
      "updated_at": DateTime.now().toString(),
    });
    await db.disconnect();
  }
}
