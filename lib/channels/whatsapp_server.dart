import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

// To use this code, add these packages to your pubspec.yaml file:
// dependencies:
//   shelf: ^1.4.1
//   shelf_router: ^1.1.4
//
// Then, run 'dart pub get' in your terminal.

void main() async {
  // Define the router to handle incoming requests.
  final app = Router();

  // Create a POST endpoint for the webhook.
  // The path 'infobip-webhook' should be the same as the URL you configure in Infobip's portal.
  app.post('/infobip-webhook', (Request request) async {
    try {
      // Read the entire request body as a string.
      final String requestBody = await request.readAsString();
      // Parse the JSON string into a Dart Map.
      final Map<String, dynamic> data = json.decode(requestBody);

      // Extract the relevant information from the Infobip payload.
      final List messages = data['results'] ?? [];
      if (messages.isNotEmpty) {
        // Assuming a single message for simplicity.
        final message = messages[0];
        final String sender = message['from'] ?? 'Unknown Sender';
        final String messageText =
            message['message']['text'] ?? 'No text content';

        // Print the received message to the console for demonstration.
        print('New WhatsApp message from $sender:');
        print('Message content: $messageText');
        print('Full payload: ${json.encode(message)}');

        // You would typically add your business logic here, e.g.,
        // - Save the message to a database
        // - Send an automated reply
        // - Trigger an internal process
      }

      // Infobip expects a 200 OK status to confirm the message was received.
      return Response.ok('Webhook received successfully');
    } catch (e) {
      // In a real-world scenario, you might want to log this error.
      print('Error processing webhook: $e');
      return Response.internalServerError(body: 'Error processing webhook.');
    }
  });

  // Serve the router using an HTTP server.
  final ip = InternetAddress.anyIPv4;
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await io.serve(app, ip, port);

  print('Server listening on port ${server.port}');
  print(
      'To test, send a POST request to http://$ip:${server.port}/infobip-webhook');
}
