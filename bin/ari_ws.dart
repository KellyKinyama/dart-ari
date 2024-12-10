import 'dart:io';

void listen(WebSocket ws) {
  ws.listen((onData) {}, onError: (err, stackTrace) {
    print("Error: $err, stacktrace: $stackTrace");
  });
  print("Connected to websocket");
}
