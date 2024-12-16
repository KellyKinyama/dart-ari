import 'dart:convert';

import 'package:dart_ari/webserver/models/queue_member.dart';
import 'package:shelf/shelf.dart';

class AgentController {
  Future<String> agents() async {
    var agents = await QueueMember.get();
    return json.encode(agents);
  }

  Future<String> login(Request request) async {
    final String query = await request.readAsString();
    Map queryParams = Uri(query: query).queryParameters;
    // print(queryParams);
    // print(queryParams['id']);

    return await QueueMember.logIn(queryParams['queue'], queryParams['id']);
  }

  Future<String> logout(Request request) async {
    final String query = await request.readAsString();
    Map queryParams = Uri(query: query).queryParameters;
    // print(queryParams);
    // print(queryParams['id']);

    return await QueueMember.logOut(queryParams['queue'], queryParams['id']);
  }

  Future<String> withdraw(Request request) async {
    final String query = await request.readAsString();
    Map queryParams = Uri(query: query).queryParameters;
    // print(queryParams);
    // print(queryParams['id']);

    return await QueueMember.logOut(queryParams['queue'], queryParams['id']);
  }
}
