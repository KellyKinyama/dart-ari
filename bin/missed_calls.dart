import 'dart:convert';
import 'dart:io';

import 'package:dart_ari/ari/api/events/dial_event.dart';
import 'package:dart_ari/dart_ari.dart';
import 'package:dotenv/dotenv.dart';

class WsClient {
  static Future<void> handleMessage(String message) async {
    // print('📩 Received from server: $message');
    var jsonData = jsonDecode(message);

    if (jsonData['type'] != null && jsonData['type'] == 'Dial') {
      print("Json: $jsonData");

      final dialEvent = DialEvent.fromJson(jsonData);
      print('Dial status: ${dialEvent.dialstatus}');

      await DbQueries.insertDialEvent(jsonData);
    }
    if (jsonData['type'] != null && jsonData['type'] == 'StasisEnd') {
      print("Json: $jsonData");

      // final stasisEndEvent = StasisEndEvent.fromJson(jsonData);
      // print('Dial status: ${dialEvent.dialstatus}');

      await DbQueries.insertStasisEndEvent(jsonData);
    }
    if (jsonData['type'] != null && jsonData['type'] == 'StasisStart') {
      print("Json: $jsonData");

      // final stasisEndEvent = StasisEndEvent.fromJson(jsonData);
      // print('Dial status: ${dialEvent.dialstatus}');
      print("inserting in db");
      await DbQueries.insertStasisStartEvent(jsonData);
    }
  }

  static void connect() async {
    final env = DotEnv(includePlatformEnvironment: true)..load();
    final serverIp = env['SERVER_IP']!;
    final serverPort = int.parse(env['SERVER_PORT']!);

    final url = 'ws://$serverIp:$serverPort/ws';
    final socket = await WebSocket.connect(url);
    print('🔌 Connected to $url');

    // Listen for messages from the server
    socket.listen((message) {
      // print('📩 Received from server: $message');
      handleMessage(message);
    }, onDone: () async {
      print('❌ Connection closed by server.');
      await Future.delayed(Duration(seconds: 5));
      connect(); // Reconnect
    }, onError: (error) async {
      print('❌ Connection error: $error');
      await Future.delayed(Duration(seconds: 5));
      connect(); // Reconnect
    });

    // Send a message to the server
    // socket.add('Hello from client 👋');

    // Optionally, interact with stdin
    // stdin.listen((input) {
    //   final msg = String.fromCharCodes(input).trim();
    //   if (msg == 'exit') {
    //     socket.close();
    //   } else {
    //     socket.add(msg);
    //   }
    // });
  }
}
