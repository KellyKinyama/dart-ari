import 'dart:convert';
import 'package:dart_ari/webserver/controllers/agent_controller.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

class WebServer {
  String serverIp;
  int serverPort;

  WebServer(this.serverIp, this.serverPort) {
    // server();
  }
  void server() async {
    final router = Router();

    router.get('/api/user/<id>', (Request request, String id) {
      final response = {'id': id, 'name': 'User $id'};
      return Response.ok(jsonEncode(response),
          headers: {'Content-Type': 'application/json'});
    });

    router.get('/api/agent/<agentid>/<command>',
        (Request request, String agentId, String command) {
      final response = {'agentid': agentId, 'command': command};
      return Response.ok(jsonEncode(response),
          headers: {'Content-Type': 'application/json'});
    });

    router.post('/api/agent/<agentid>/<state>/<status>',
        (Request request, String agentId, String state, String status) {
      AgentController.excecuteCommand(agentId, state, state);
      final response = {'agentid': agentId, 'state': state, 'status': status};
      return Response.ok(jsonEncode(response),
          headers: {'Content-Type': 'application/json'});
    });

    final handler =
        Pipeline().addMiddleware(logRequests()).addHandler(router.call);

    final server = await io.serve(handler, serverIp, serverPort);
    print('Server running on localhost:${server.port}');
  }
}
