import 'dart:io';

import 'package:dart_ari/dart_ari.dart';
import 'ari_ws.dart';

void main(List<String> arguments) async {
  ARI ari = ARI.fromConfigs();

  WebSocket ws = await ari.connect();
  listen(ws);
}
