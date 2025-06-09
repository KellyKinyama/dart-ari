import 'dart:io';
import 'dart:convert'; // For jsonEncode if you send JSON

void main() async {
  // Nginx is listening on 10.44.0.70:8089
  // The WebSocket path on Nginx is /ws/
  // So the full URL for the WebSocket is ws://10.44.0.70:8089/ws/

  String websocketUrl = 'wss://ivr.zesco.co.zm:8001/ws/';

  try {
    // WebSocket.connect performs the HTTP handshake for WebSockets
    WebSocket socket = await WebSocket.connect(websocketUrl);
    print('Connected to WebSocket: ${socket}');

    socket.listen(
      (dynamic message) {
        // Handle incoming data from the server
        print('Received: $message');
      },
      onDone: () {
        print('WebSocket connection closed.');
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
    );

    // Example: Send a message to the server
    // socket.add(jsonEncode({'type': 'hello', 'message': 'Hello from Dart client!'}));

    // Keep the main function running for a bit to allow messages
    // await Future.delayed(Duration(seconds: 10)); // Adjust as needed
    // socket.close(); // Close the connection when done
    print('Client exiting.');
  } catch (e) {
    print('Failed to connect to WebSocket: $e');
  }
}
