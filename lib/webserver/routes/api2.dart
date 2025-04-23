import 'package:dotenv/dotenv.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:redis/redis.dart';

class WebServer {
  String serverIp;
  int serverPort;

  late String redisIp;
  late int redisPort;
  late String redisPassword;

  WebServer(this.serverIp, this.serverPort) {
    final env = DotEnv(includePlatformEnvironment: true)..load();
    redisIp = env['REDIS_ADDRESS']!;
    redisPort = int.parse(env['REDIS_PORT']!);
    redisPassword = env['REDIS_PASSWORD']!;
  }

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
    router.get('/ws',
        webSocketHandler((WebSocketChannel webSocket, path) async {
      print("Connected to WebSocket: $path");

      // final localEventEmitter = EventEmitter();

      // localEventEmitter.on("proxy", (String event) {
      //   print("Event: $event");
      //   webSocket.sink.add(event);
      // });

      // eventEmitterProxy.on("proxy", (String event) {
      //   print("Event: $event");
      //   // webSocket.sink.add(event);
      //   localEventEmitter.emit("proxy", event);
      // });

      final connection = RedisConnection();
      Command command = await connection.connect(redisIp, redisPort);

      final result = await command.send_object(["AUTH", redisPassword]);

      PubSub pubsub = PubSub(command);
      pubsub.subscribe(["monkey"]);

      webSocket.stream.listen((message) {
        print('Received: $message');
        // webSocket.sink.add('Echo: $message');
      }, onDone: () {
        print('Client disconnected.');
      });

      final stream = pubsub.getStream();
      var streamWithoutErrors = stream.handleError((e) => print("error $e"));

      await for (final msg in streamWithoutErrors) {
        var kind = msg[0];
        var food = msg[2];
        if (kind == "message") {
          //print("monkey got ${food}");
          webSocket.sink.add(food);
        } else {
          print("received non-message $msg");
        }
      }
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
