import 'package:dart_ari/ari/api/enums.dart';
import 'package:dart_ari/dart_ari.dart';
import 'package:dart_ari/webserver/routes/api2.dart';
import 'queue_app_final.dart';
import 'missed_calls.dart';

void main(List<String> arguments) async {
  ARI ari = ARI.fromConfigs();

  await DbQueries.updateInactiveAgentStatuses(
      AgentState.LOGGEDOUT, AgentState.LOGGEDOUT);

  await ari.connect();
  queueApp(ari);

  final apiServer = WebServer("10.44.0.56", 8001);

  await apiServer.serve();

  WsClient.connect();
  //listen(ws);
}
