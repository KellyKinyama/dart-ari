import 'dart:io';

void main() async {
  const url = 'ws://localhost:8001/ws';
  final socket = await WebSocket.connect(url);
  print('🔌 Connected to $url');

  // Listen for messages from the server
  socket.listen((message) {
    print('📩 Received from server: $message');
  }, onDone: () {
    print('❌ Connection closed by server.');
  });

  // Send a message to the server
  socket.add('Hello from client 👋');

  // Optionally, interact with stdin
  stdin.listen((input) {
    final msg = String.fromCharCodes(input).trim();
    if (msg == 'exit') {
      socket.close();
    } else {
      socket.add(msg);
    }
  });
}
