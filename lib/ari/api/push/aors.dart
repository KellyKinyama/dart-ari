import 'dart:io';
import 'dart:convert';

import '../globals.dart';

class AorAPI {
  AorAPI();

  static String scheme = "http";
  static late String apiKey = "asterisk:asterisk";
  static late String host = "10.1.101.155";
  static late int port = 8088;

  // static Future<dynamic> get(String endpoint) async {
  //   // baseUrl.path = baseUrl.path + '/channels';
  //   // http://10.44.0.70:8088/ari/asterisk/config/dynamic/res_pjsip/aor/6004?api_key=asterisk:asterisk
  //   var uri = Uri(
  //       scheme: scheme,
  //       userInfo: "",
  //       host: host,
  //       port: port,
  //       path: "ari/asterisk/config/dynamic/res_pjsip/aor/$endpoint",
  //       //Iterable<String>? pathSegments,
  //       query: "",
  //       queryParameters: {'api_key': apiKey}
  //       //String? fragment
  //       );
  //   //var uri = Uri.http(baseUrl);
  //   HttpClientRequest request = await client.getUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   //print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   //print(response.statusCode);
  //   //print(stringData);
  //   return (statusCode: response.statusCode, resp: stringData);
  // }

  static Future<dynamic> get(String endpoint) async {
    // baseUrl.path = baseUrl.path + '/channels';
    // http://10.44.0.70:8088/ari/asterisk/config/dynamic/res_pjsip/aor/6004?api_key=asterisk:asterisk
    var uri = Uri(
        scheme: scheme,
        userInfo: "",
        host: host,
        port: port,
        path: "/ari/endpoints/PJSIP/$endpoint",
        //Iterable<String>? pathSegments,
        query: "",
        queryParameters: {'api_key': apiKey}
        //String? fragment
        );
    //var uri = Uri.http(baseUrl);
    HttpClientRequest request = await client.getUrl(uri);
    HttpClientResponse response = await request.close();
    //print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    //print(response.statusCode);
    //print(stringData);
    return (statusCode: response.statusCode, resp: stringData);
  }

  static Future<dynamic> originate(
      {String? endpoint,
      String? extension,
      String? context,
      String? priority,
      String? label,
      String? app,
      List<String>? appArgs,
      String? callerId,
      num? timeout,
      String? channelId,
      String? otherChannelId,
      String? originator}) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },
    var uri = Uri(
        scheme: scheme,
        userInfo: "",
        host: host,
        port: port,
        path: "ari/channels",
        //Iterable<String>? pathSegments,
        query: "",
        queryParameters: {
          'api_key': apiKey,
          'endpoint': endpoint ?? "",
          'extension': extension ?? "",
          'context': context ?? "",
          'priority': priority ?? "",
          'label': label ?? "",
          'app': app ?? "",
          'appArgs': appArgs != null ? appArgs.join(",") : "",
          'callerId': callerId ?? "",
          'timeout': timeout ?? "",
          'channelId': channelId ?? "",
          'otherChannelId': otherChannelId ?? "",
          'originator': originator ?? "",
        }
        //String? fragment
        );

    //dsvar uri = Uri.http(baseUrl, '/channels', qParams);
    try {
      HttpClientRequest request = await client.postUrl(uri);
      HttpClientResponse response = await request.close();
      //print(response);
      final String stringData = await response.transform(utf8.decoder).join();
      //print(response.statusCode);
      //print(stringData);
      return (statusCode: response.statusCode, resp: stringData);
    } catch (err, stackTrace) {
      // logger.severe('Caught an error', err, stackTrace);
      print("Error: $err, $stackTrace");
      return (statusCode: null, resp: null, err: err);
    }
  }
}

class Aor {
  static Future<dynamic> get(String endpoint) async {
    var resp = await AorAPI.get(endpoint);
    //resp.then((value) {
    print("Status code: ${resp.statusCode}");
    bool err = resp.statusCode == 404 ||
        resp.statusCode == 409 ||
        resp.statusCode == 412;

    return resp.resp;
    //});
  }

  // static Future<bool> contact(String endpoint) async {
  //   final aor = jsonDecode(await Aor.get(endpoint));
  //   for (var item in aor) {
  //     if (item["state"] == "online") {
  //       print("value: ${item["value"]}");

  //       return item["value"].length > 0;
  //     }
  //   }
  //   return false;
  // }

  static Future<bool> contact(String endpoint) async {
    final aor = jsonDecode(await Aor.get(endpoint));
    print("object: $aor");
    // for (var item in aor) {
    if (aor["state"] == "online") {
      print("state: ${aor["state"]}");

      return true;
    }
    // }
    return false;
  }
}

Future<void> main() async {
  final aor = await Aor.get("6003");
  print("Aor: $aor");
}
