import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

class WebServer {
  String serverIp;
  int serverPort;

  WebServer(this.serverIp, this.serverPort) {
    server();
  }
  void server() async {
    final router = Router();

    router.get('/api/user/<id>', (Request request, String id) {
      final response = {'id': id, 'name': 'User $id'};
      return Response.ok(jsonEncode(response),
          headers: {'Content-Type': 'application/json'});
    });

    final handler =
        Pipeline().addMiddleware(logRequests()).addHandler(router.call);

    final server = await io.serve(handler, serverIp, serverPort);
    print('Server running on localhost:${server.port}');
  }
}
