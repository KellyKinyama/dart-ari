import 'dart:convert';
import 'package:http/http.dart' as http;

// To use this code, add the http package to your pubspec.yaml file:
// dependencies:
//   http: ^0.13.3
//
// Then, run 'dart pub get' in your terminal.

void main() async {
  // Define the API endpoint URL.
  final url =
      Uri.parse('https://lqp3v5.api.infobip.com/whatsapp/1/message/template');

// deaa1ba1e75bc0c69fffb8a7ff6670a3-0cc2a916-400f-421c-a13d-602031f14f00
  // Define the request headers, including the Authorization token and Content-Type.
  final headers = {
    'Authorization':
        'App deaa1ba1e75bc0c69fffb8a7ff6670a3-0cc2a916-400f-421c-a13d-602031f14f00',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Define the request body as a Dart Map, which will be converted to JSON.
  final body = json.encode({
    "messages": [
      {
        "from": "447860088970",
        "to": "260972462922",
        "messageId": "a4a30efc-ab01-4e8d-9561-292119dc4fc6",
        "content": {
          "templateName": "test_whatsapp_template_en",
          "templateData": {
            "body": {
              "placeholders": ["Kelly"]
            }
          },
          "language": "en"
        }
      }
    ]
  });

  try {
    // Send the POST request.
    final response = await http.post(
      url,
      headers: headers,
      body: body,
    );

    // Check the status code and print the result.
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Request successful!');
      print('Response Body: ${response.body}');
    } else {
      print('Request failed with status: ${response.statusCode}');
      print('Response Body: ${response.body}');
    }
  } catch (e) {
    // Handle any network or other errors.
    print('An error occurred: $e');
  }
}
