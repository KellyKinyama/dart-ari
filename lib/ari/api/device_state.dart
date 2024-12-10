import 'dart:io';
import 'dart:convert';

class DeviceStateApi {
  static late String scheme;
  static late String apiKey;
  static late String host;
  static late int port;

  DeviceStateApi() {}

// Future<HttpClientResponse> get(String name) async {
//     var uri = Uri.http(baseUrl, '/deviceStates/${name}');
//     HttpClientRequest request = await client.getUrl(uri);
//     HttpClientResponse response = await request.close();
//     print(response);
//     final String stringData = await response.transform(utf8.decoder).join();
//     print(response.statusCode);
//     //print(stringData);
//     return response;
//   }
  // Future<HttpClientResponse> list(String name) async {
  //   var uri = Uri.http(baseUrl, '/deviceStates/');
  //   HttpClientRequest request = await client.getUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }
  // Future<HttpClientResponse> update(String name) async {
  //   var uri = Uri.http(baseUrl, '/deviceStates/${name}');
  //   HttpClientRequest request = await client.putUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  // Params params;
}

class DeviceState {}
