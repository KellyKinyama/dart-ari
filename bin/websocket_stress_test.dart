import 'dart:io';

// A simple class to hold the result of a connection attempt
class ConnectionResult {
  final bool success;
  final WebSocket? socket;

  ConnectionResult(this.success, {this.socket});
}

// Function to connect a single WebSocket and handle its lifecycle
Future<ConnectionResult> connectSingleWebSocket(String url, int id) async {
  try {
    // Attempt to connect
    final socket = await WebSocket.connect(url);

    // Optional: Add listeners if you want the sockets to do something
    socket.listen(
      (message) {
        // This will likely never be called in this test, but it's good practice
        // print('Socket $id received: $message');
      },
      onDone: () {
        // print('Socket $id closed.');
      },
      onError: (error) {
        // print('Error on socket $id: $error');
      },
    );

    // Return a success result with the connected socket
    return ConnectionResult(true, socket: socket);
  } catch (e) {
    // If connection fails, print the error and return a failure result
    print('Failed to connect socket #$id: $e');
    return ConnectionResult(false);
  }
}

Future<void> main() async {
  // --- Configuration ---
  // const String serverUrl = 'ws://10.44.0.56:8001/ws';
  const String serverUrl = 'wss://ivr.zesco.co.zm/ws';
  const int numberOfSocketsToOpen = 65536; // Your target limit
  const int progressUpdateFrequency = 500; // How often to print progress

  print('--- WebSocket Stress Test ---');
  print('Targeting $numberOfSocketsToOpen connections to $serverUrl');
  print('-----------------------------');

  // Lists to hold the futures of our connection attempts and the successful sockets
  final List<Future<ConnectionResult>> connectionFutures = [];
  final List<WebSocket> successfulSockets = [];

  // Launch all connection attempts concurrently
  for (int i = 1; i <= numberOfSocketsToOpen; i++) {
    connectionFutures.add(connectSingleWebSocket(serverUrl, i));
  }

  int successfulConnections = 0;
  int failedConnections = 0;

  // Await all connection attempts and process the results
  final results = await Future.wait(connectionFutures);

  for (int i = 0; i < results.length; i++) {
    final result = results[i];
    if (result.success && result.socket != null) {
      successfulConnections++;
      successfulSockets.add(result.socket!);
      if (successfulConnections % progressUpdateFrequency == 0) {
        print('✅ Successfully connected socket #$successfulConnections...');
      }
    } else {
      failedConnections++;
    }
  }

  print('\n--- Test Complete ---');
  print('✅ Successful connections: $successfulConnections');
  print('❌ Failed connections:     $failedConnections');
  print(
      '✅ Percent success:        ${(successfulConnections / (successfulConnections + failedConnections)) * 100}%');
  print('-----------------------');

  // Keep the script running to hold the sockets open
  print('All sockets are open. Press CTRL+C to close the application.');

  // This will prevent the script from exiting immediately
  await ProcessSignal.sigint.watch().first;

  print('\nClosing all sockets...');
  for (var socket in successfulSockets) {
    socket.close();
  }
  print('Done.');
}
