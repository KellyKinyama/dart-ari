import 'package:dart_ari/dart_ari.dart';
import 'package:dart_ari/webserver/routes/api.dart';
import 'queue_app.dart';
import 'webserver.dart';

void main(List<String> arguments) async {
  ARI ari = ARI.fromConfigs();

  await ari.connect();
  queueApp(ari);

  final apiServer = WebServer("localhost", 8000);

  apiServer.server();
  //listen(ws);
}
