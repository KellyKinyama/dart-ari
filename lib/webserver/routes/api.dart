import 'dart:convert';
import 'package:dart_ari/ari/api/events/event.dart';
import 'package:dart_ari/ari/api/globals.dart';
import 'package:dart_ari/webserver/controllers/agent_controller.dart';
import 'package:events_emitter/events_emitter.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

EventEmitter eventEmitterProxy = EventEmitter();

class WebServer {
  String serverIp;
  int serverPort;

  WebServer(this.serverIp, this.serverPort);

  // CORS helper
  // Response addCorsHeaders(Response res) => res.change(headers: {
  //       'Access-Control-Allow-Origin': '*',
  //       'Access-Control-Allow-Headers': '*',
  //       'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  //       ...res.headers,
  //     });
  Response addCorsHeaders(Response res) {
    return res.change(headers: {
      'Access-Control-Allow-Origin': '*', // Allow all origins
      'Access-Control-Allow-Methods':
          'GET, POST, OPTIONS', // Allow necessary methods
      'Access-Control-Allow-Headers': 'Content-Type', // Allow headers
      ...res.headers,
    });
  }

  Future<void> serve() async {
    final router = Router();

    // WebSocket endpoint
    router.get('/ws', webSocketHandler((WebSocketChannel webSocket, path) {
      print("Connected to WebSocket: $path");

      final localEventEmitter = EventEmitter();

      localEventEmitter.on("proxy", (String event) {
        print("Event: $event");
        webSocket.sink.add(event);
      });

      eventEmitterProxy.on("proxy", (String event) {
        print("Event: $event");
        // webSocket.sink.add(event);
        localEventEmitter.emit("proxy", event);
      });

      webSocket.stream.listen((message) {
        print('Received: $message');
        // webSocket.sink.add('Echo: $message');
      }, onDone: () {
        print('Client disconnected.');
      });
    }));

    // CORS-aware pipeline
    final handler =
        Pipeline().addMiddleware(logRequests()).addHandler((Request req) async {
      // Handle CORS preflight
      if (req.method == 'OPTIONS') {
        return addCorsHeaders(Response.ok(''));
      }

      final res = await router(req);
      return addCorsHeaders(res);
    });

    final server = await io.serve(handler, serverIp, serverPort);
    print('Server running on $serverIp:${server.port}');
  }
}
