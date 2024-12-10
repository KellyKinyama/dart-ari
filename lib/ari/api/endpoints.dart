import 'dart:io';
import 'dart:convert';

class EndpointsAPI {
  EndpointsAPI() {}

  // Future<HttpClientResponse> list() async {
  //   var uri = Uri.http(baseUrl, '/endpoints');

  //   HttpClientRequest request = await client.getUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  // Future<HttpClientResponse> sendMessage(dynamic queryParams, qParams) async {
  //   var uri = Uri.http(baseUrl, '/endpoints/sendMessage', qParams);
  //   HttpClientRequest request = await client.putUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  // Future<HttpClientResponse> listByTechnology(String tech) async {
  //   var uri = Uri.http(baseUrl, '/endpoints/${tech}');
  //   HttpClientRequest request = await client.getUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  // Future<HttpClientResponse> get(String tech, String res) async {
  //   var uri = Uri.http(baseUrl, '/endpoints/${tech}/${res}');
  //   HttpClientRequest request = await client.getUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  // Future<HttpClientResponse> sendMessageToEndpoint(
  //     String tech, String res, qParams) async {
  //   var uri = Uri.http(
  //       baseUrl, '/endpoints/${tech}/${res}/sendMessage', qParams);
  //   HttpClientRequest request = await client.putUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  //Params params;
}

class Endpoint {}
