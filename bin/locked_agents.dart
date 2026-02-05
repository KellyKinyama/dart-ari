import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

Future<void> main() async {
  // 1. Create a custom HttpClient that ignores certificate errors
  final HttpClient httpClient = HttpClient()
    ..badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;

  // 2. Wrap it in an IOClient from the http package
  final IOClient client = IOClient(httpClient);

  const String serverUrl = 'http://10.44.0.56:8001/locked/endpoints';

  print('--- Agent Lock Checker (SSL Bypass) ---');
  print('Target: $serverUrl');
  print('---------------------------------------');

  try {
    // 3. Use the custom client to make the request
    final response = await client.get(Uri.parse(serverUrl));

    if (response.statusCode == 200) {
      final List<dynamic> lockedAgents = jsonDecode(response.body);

      if (lockedAgents.isEmpty) {
        print('✅ No agents are currently locked.');
      } else {
        print('⚠️  Found ${lockedAgents.length} Locked Agent(s):');
        for (var i = 0; i < lockedAgents.length; i++) {
          print('   ${i + 1}. ${lockedAgents[i]}');
        }
      }
    } else {
      print('❌ Server returned error: ${response.statusCode}');
      print('Body: ${response.body}');
    }
  } catch (e) {
    print('❌ Connection Error: $e');
  } finally {
    client.close(); // Clean up the client
  }

  print('---------------------------------------');
  print('Check complete. Press any key to exit.');
  stdin.readLineSync();
}
