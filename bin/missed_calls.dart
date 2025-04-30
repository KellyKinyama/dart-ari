import 'dart:convert';
import 'dart:io';

import 'package:dart_ari/ari/api/events/dial_event.dart';
import 'package:dart_ari/ari/api/events/stasis_end_event.dart';
import 'package:dart_ari/dart_ari.dart';

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

      await DbQueries.insertStasisStartEvent(jsonData);
    }
  }

  static void connect() async {
    const url = 'ws://localhost:8001/ws';
    final socket = await WebSocket.connect(url);
    print('🔌 Connected to $url');

    // Listen for messages from the server
    socket.listen((message) {
      // print('📩 Received from server: $message');
      handleMessage(message);
    }, onDone: () {
      print('❌ Connection closed by server.');
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
