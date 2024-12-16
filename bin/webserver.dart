import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

void main() async {
  final router = Router();

  router.get('/api/user/<id>', (Request request, String id) {
    final response = {'id': id, 'name': 'User $id'};
    return Response.ok(jsonEncode(response),
        headers: {'Content-Type': 'application/json'});
  });

  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(router.call);

  final server = await io.serve(handler, 'localhost', 8080);
  print('Server running on localhost:${server.port}');
}
