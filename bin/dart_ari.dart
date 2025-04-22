import 'package:dart_ari/ari/api/enums.dart';
import 'package:dart_ari/dart_ari.dart';
import 'package:dart_ari/webserver/routes/api.dart';
import 'queue_app.dart';
// import 'webserver.dart';

void main(List<String> arguments) async {
  ARI ari = ARI.fromConfigs();

  //DbQueries.setAgentStatuses(AgentState.LOGGEDIN, AgentState.IDLE);

  await ari.connect();
  queueApp(ari);

  final apiServer = WebServer("localhost", 8001);

  await apiServer.serve();
  //listen(ws);
}
