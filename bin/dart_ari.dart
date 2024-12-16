import 'package:dart_ari/dart_ari.dart';
import 'queue_app.dart';

void main(List<String> arguments) async {
  ARI ari = ARI.fromConfigs();

  await ari.connect();
  queueApp(ari);
  //listen(ws);
}
