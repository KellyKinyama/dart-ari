import 'dart:io';
import 'dart:convert';

import 'ari_exception.dart';
import 'globals.dart';
import 'resource.dart';

// import 'package:dart_ari_proxy/ari_client/ChannelsApi.dart';
// import 'package:dart_ari_proxy/ari_client/resource.dart';
// import 'package:dart_ari_proxy/globals.dart';

// import 'models.dart';

class BridgesAPI {
  /// Create an instance of the Bridges API client, providing access to the
  /// `/bridges` endpoint.
  ///
  /// @param {object} params
  /// @param {string} username The username to send with the request.
  /// @param {string} password The password to send with the request.
  /// @param {string} baseUrl The base url, without trailing slash,
  ///  of the root Asterisk ARI endpoint. i.e. 'http://myserver.local:8088/ari'.
  BridgesAPI() {}

  static late String scheme;
  static late String apiKey;
  static late String host;
  static late int port;

  static Future<dynamic> list() async {
    //   var uri = Uri.http(baseUrl, '/bridges');

    var uri = Uri(
        scheme: scheme,
        userInfo: "",
        host: host,
        port: port,
        path: "ari/bridges",
        queryParameters: {'api_key': apiKey}
        //String? fragment
        );

    final request = await client.getUrl(uri);
    return await sendAriRequest(request);
  }

  static Future<dynamic> create(
      String? name, String? bridgeId, List<String>? type) async {
    var queryParams = {
      'name': name,
      'bridgeId': bridgeId,
      'type': type != null ? type.join(',') : "",
    };

    var path = bridgeId != null ? "ari/bridges/${bridgeId}" : "ari/bridges";
    var uri = Uri(
        scheme: scheme,
        userInfo: "",
        host: host,
        port: port,
        path: path,
        queryParameters: {
          'api_key': apiKey,
          'bridgeId': bridgeId,
          'type': type != null ? type.join(',') : ""
        }
        //String? fragment
        );
    //var uri = Uri.http(baseUrl, '/bridges', queryParams);

    final request = await client.postUrl(uri);
    return await sendAriRequest(request);
  }

  static Future<dynamic> createOrUpdate(
      {String? name, String? bridgeId, List<String>? type}) async {
    var uri = Uri(
        scheme: scheme,
        userInfo: "",
        host: host,
        port: port,
        path: bridgeId != null ? "ari/bridges/$bridgeId" : "ari/bridges",
        // path: "ari/bridges${bridgeId!=null?bridgeId: ""}",
        queryParameters: {
          'api_key': apiKey,
          'bridgeId': bridgeId,
          'type': type != null ? type.join(',') : ""
        }
        //String? fragment
        );

    //var queryParams = {'bridgeId': bridgeId, 'type': type.join(',')};

    // var uri = Uri.http(baseUrl, '/bridges/${bridgeId}', queryParams);

    final request = await client.postUrl(uri);
    return await sendAriRequest(request);
  }

  // static Future<HttpClientResponse> get(String bridgeId) async {
  //   var queryParams = {
  //     'bridgeId': bridgeId,
  //     //'type': type.join(',')
  //   };

  //   var uri = Uri.http(baseUrl, '/bridges/${bridgeId}', queryParams);

  //   /// print(uri); // http://example.org/path?q=dart
  //   HttpClientRequest request = await client.getUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   //print(response);

  //   final String stringData = await response.transform(utf8.decoder).join();
  //   //print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  static Future<dynamic> destroy(String bridgeId) async {
    // var queryParams = {
    //   'bridgeId': bridgeId,
    //   //'type': type.join(',')
    // };

    var uri = Uri(
        scheme: scheme,
        userInfo: "",
        host: host,
        port: port,
        path: "ari/bridges/${bridgeId}",
        queryParameters: {'api_key': apiKey}
        //String? fragment
        );

    //var uri = Uri.http(baseUrl, '/bridges/${bridgeId}', queryParams);

    final request = await client.deleteUrl(uri);
    return await sendAriRequest(request);
  }

  static Future<dynamic> addChannel(
      String bridgeId, List<String> channels) async {
    var queryParams = {
      //'bridgeId': bridgeId,
      'channel': channels.join(','),
      'role': ""
    };

    var uri = Uri(
        scheme: scheme,
        userInfo: "",
        host: host,
        port: port,
        path: "ari/bridges/$bridgeId/addChannel",
        queryParameters: {'api_key': apiKey, 'channel': channels.join(',')}
        //String? fragment
        );

    //var uri = Uri.http(baseUrl, '/bridges/${bridgeId}/addChannel', queryParams);

    final request = await client.postUrl(uri);
    try {
      return await sendAriRequest(request);
    } on AriException catch (e) {
      // Promote the well-known ARI status codes to descriptive errors so
      // call sites can react to specific failure modes if they care to.
      switch (e.statusCode) {
        case 400:
          throw Exception("Channel: $channels not found");
        case 404:
          throw Exception("Bridge: $bridgeId not found");
        case 409:
          throw Exception(
              "Channel: $channels Bridge not in Stasis application; Channel currently recording");
        case 422:
          throw Exception("Channel: $channels not in Stasis application");
        default:
          rethrow;
      }
    }
  }

  static Future<dynamic> removeChannel(
      String bridgeId, List<String> channels) async {
    var queryParams = {
      //'bridgeId': bridgeId,
      'channel': channels.join(','),
      //'role':""
    };

    var uri = Uri(
        scheme: scheme,
        userInfo: "",
        host: host,
        port: port,
        path: "ari/bridges/${bridgeId}/removeChannel",
        queryParameters: {'api_key': apiKey, 'channel': channels.join(',')}
        //String? fragment
        );
    //var uri =
    //    Uri.http(baseUrl, '/bridges/${bridgeId}/removeChannel', queryParams);

    final request = await client.postUrl(uri);
    return await sendAriRequest(request);
  }

  static Future<dynamic> startMusicOnHold(String bridgeId) async {
    // var queryParams = {
    //   //'bridgeId': bridgeId,
    //   'channel': channels.join(','),
    //   //'role':""
    // };

    var uri = Uri(
        scheme: scheme,
        userInfo: "",
        host: host,
        port: port,
        path: "ari/bridges/$bridgeId/moh",
        //String? fragment
        queryParameters: {'api_key': apiKey});

    //var uri = Uri.http(baseUrl, '/bridges/${bridgeId}/moh', queryParams);

    final request = await client.postUrl(uri);
    return await sendAriRequest(request);
  }

  // static Future<HttpClientResponse> stopMusicOnHold(
  //     String bridgeId, List<String> channels) async {
  //   var queryParams = {
  //     //'bridgeId': bridgeId,
  //     'channel': channels.join(','),
  //     //'role':""
  //   };

  //   var uri = Uri.http(baseUrl, '/bridges/${bridgeId}/moh', queryParams);

  //   /// print(uri); // http://example.org/path?q=dart
  //   HttpClientRequest request = await client.deleteUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   //print(response);

  //   final String stringData = await response.transform(utf8.decoder).join();
  //   //print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  //   play(params = {}) {
  //   const {
  //     bridgeId,
  //     media,
  //     playbackId,
  //     lang,
  //     offsetms = 0,
  //     skipms = 3000,
  //   } = params;

  //   const id = encodeURIComponent(bridgeId);

  //   return this._request({
  //     method: "POST",
  //     url: `${this._baseUrl}/bridges/${id}/play`,
  //     params: {
  //       media: [].concat(media).join(","),
  //       lang,
  //       offsetms,
  //       skipms,
  //       playbackId,
  //     },
  //   });
  // }

  // static Future<HttpClientResponse> play(
  //     String bridgeId, dynamic queryParams) async {
  //   var qParams = {
  //     'bridgeId': queryParams.bridgeId,
  //     'media': queryParams.media.join(','),
  //     'playbackId': "",
  //     'lang': "",
  //     'offsetms': "",
  //     'skipms': ""
  //   };

  //   var uri = Uri.http(
  //       baseUrl, '/bridges/${bridgeId}/play/${queryParams.playId}', qParams);

  //   /// print(uri); // http://example.org/path?q=dart
  //   HttpClientRequest request = await client.postUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   //print(response);

  //   final String stringData = await response.transform(utf8.decoder).join();
  //   //print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  /// POST /bridges/{bridgeId}/record
  ///
  /// Record all audio on a bridge (all participating channels mixed). This
  /// is what you almost always want when "recording a call" — it captures
  /// both legs unlike the per-channel record which only captures inbound
  /// audio from one leg.
  ///
  /// [name] and [format] are required by ARI. [ifExists] is one of `fail`
  /// (default), `overwrite`, `append`. [terminateOn] is one of `none`
  /// (default), `any`, `*`, `#`.
  static Future<({int statusCode, String resp})> record({
    required String bridgeId,
    required String name,
    String format = 'wav',
    int? maxDurationSeconds,
    int? maxSilenceSeconds,
    String ifExists = 'fail',
    bool beep = false,
    String terminateOn = 'none',
  }) async {
    final qp = <String, String>{
      'api_key': apiKey,
      'name': name,
      'format': format,
      'ifExists': ifExists,
      'beep': beep.toString(),
      'terminateOn': terminateOn,
    };
    if (maxDurationSeconds != null) {
      qp['maxDurationSeconds'] = maxDurationSeconds.toString();
    }
    if (maxSilenceSeconds != null) {
      qp['maxSilenceSeconds'] = maxSilenceSeconds.toString();
    }

    final uri = Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: "ari/bridges/$bridgeId/record",
      queryParameters: qp,
    );

    final request = await client.postUrl(uri);
    return await sendAriRequest(request);
  }

  //Params params;
}

class Bridge extends Resource {
  Bridge(
      this.id,
      this.technology,
      this.bridge_type,
      this.bridge_class,
      this.creator,
      this.name,
      this.channels,
      this.video_mode,
      this.video_source_id,
      this.creationtime,
      this.jsonData);

  /// Unique identifier for this bridge.
  String id; //: string;

  /// Name of the current bridging technology.
  String technology; //: string;

  /// Type of bridge technology.
  String bridge_type; //: string;

  /// Bridging class.
  String bridge_class; //: string;

  /// Entity that created the bridge.
  String creator; //: string;

  /// Name the creator gave the bridge.
  String name; //: string;

  /// Ids of channels participating in this bridge.
  List<dynamic> channels; //: string | string[];

  /// The video mode the bridge is using. One of none, talker, or single.
  String? video_mode; //?: string;

  /// The ID of the channel that is the source of video in this bridge, if one exists.
  String? video_source_id; //?: string;

  /// Timestamp when bridge was created.
  DateTime creationtime; //: Date;
  dynamic jsonData;

  factory Bridge.fromJson(dynamic json) {
    //print(json['creationtime']);
    final creationtime = DateTime.parse(json['creationtime']); // 8:18pm
    return Bridge(
        json['id'] as String,
        json['technology'] as String,
        json['bridge_type'] as String,
        json['bridge_class'] as String,
        json['creator'] as String,
        json['name'] as String,
        json['channels'] as List<dynamic>,
        json['video_mode'] as String,
        json['video_source_id'] as String?,
        creationtime,
        json as dynamic);
  }

  Future<bool> addChannel(
      {required List<String> channels,
      String? role,
      bool? absorbDTMF,
      bool? mute}) async {
    var resp = await BridgesAPI.addChannel(id, channels);
    return false;
  }

  Future<bool> startMoh() async {
    var resp = await BridgesAPI.startMusicOnHold(id);
    return false;
  }

  static Future<List<Bridge>> list() async {
    var resp = await BridgesAPI.list();

    //resp.then((value) {
    //print(value.resp);
    List<Bridge> varBridges = [];
    if (resp.statusCode != 404) {
      var bridgesJson = json.decode(resp.resp);
      final dedup = bridgeDeduper;
      //print("Bridges: ${value.resp.runtimeType}");
      for (final e in bridgesJson) {
        // Route through the cache so we return the live cached instance for
        // any bridge id we already know about (preserves listeners).
        Bridge brige = dedup != null ? dedup(e) as Bridge : Bridge.fromJson(e);
        varBridges.add(brige);
      }
      //print("Bridges: ${varBridges.length}");
      //callback(false, varBridges);
    } else {
      //callback(true, varBridges);
    }
    //});
    return varBridges;
  }

  Future<Bridge> create(
      {required List<String> type, String? bridgeId, String? name}) async {
    // List<String> types = [];
    // if (type != null) types = type.split(',');

    var resp = await BridgesAPI.create(name, id, type);
    //resp.then((value) {
    print(resp.resp);
    //var bridgesJson = json.decode(value.resp);
    //brg = Bridge.fromJson(bridgesJson);
    var bridgesJson = json.decode(resp.resp);
    final dedup = bridgeDeduper;
    return dedup != null
        ? dedup(bridgesJson) as Bridge
        : Bridge.fromJson(bridgesJson);
    //if (resp.statusCode == 200) {
    //var bridgesJson = json.decode(value.resp);
    //brg = Bridge.fromJson(bridgesJson);
    //callback(false, this);
    //} else {
    // callback(true, brg!);
    //}
    //});
  }

  Future<bool> removeChannel({required List<String> channel}) async {
    var resp = await BridgesAPI.removeChannel(id, channel);
    // resp.then((value) {
    //   if (value.statusCode != 404) {
    //     callback(false);
    //   }
    // });
    return false;
  }

  Future<void> destroy() async {
    var resp = await BridgesAPI.destroy(id);
    // resp.then((value) {
    //   if (value.statusCode != 200 || value.statusCode != 204)
    //     callback(false);
    //   else
    //     callback(true);
    // });
    //return;
  }

  /// Start recording this bridge (mixed audio from all participating
  /// channels). Returns the raw LiveRecording JSON.
  Future<Map<String, dynamic>> record({
    required String name,
    String format = 'wav',
    int? maxDurationSeconds,
    int? maxSilenceSeconds,
    String ifExists = 'overwrite',
    bool beep = false,
    String terminateOn = 'none',
  }) async {
    final resp = await BridgesAPI.record(
      bridgeId: id,
      name: name,
      format: format,
      maxDurationSeconds: maxDurationSeconds,
      maxSilenceSeconds: maxSilenceSeconds,
      ifExists: ifExists,
      beep: beep,
      terminateOn: terminateOn,
    );
    return jsonDecode(resp.resp) as Map<String, dynamic>;
  }

  /// Refresh this bridge's mutable fields from a freshly fetched JSON
  /// payload, preserving the existing instance identity (and therefore
  /// every event listener already registered on it).
  ///
  /// `id` is intentionally NOT updated — bridge ids are immutable, and a
  /// differing id signals a programming error (a different bridge entirely).
  void updateFromJson(dynamic json) {
    if (json['id'] != null && json['id'] != id) {
      throw StateError(
          "Bridge.updateFromJson: id mismatch ($id != ${json['id']})");
    }
    technology = json['technology'] as String? ?? technology;
    bridge_type = json['bridge_type'] as String? ?? bridge_type;
    bridge_class = json['bridge_class'] as String? ?? bridge_class;
    creator = json['creator'] as String? ?? creator;
    name = json['name'] as String? ?? name;
    if (json['channels'] is List) {
      channels = json['channels'] as List<dynamic>;
    }
    video_mode = json['video_mode'] as String? ?? video_mode;
    video_source_id = json['video_source_id'] as String? ?? video_source_id;
    jsonData = json;
  }

  @override
  String toString() {
    // TODO: implement toString
    return "Bridge: {$id, $name, $bridge_type, $technology, $creationtime, channels: $channels}";
  }
}

class Bridges {
  static Future<List<Bridge>> list() async {
    var resp = await BridgesAPI.list();

    //resp.then((value) {
    //print(value.resp);
    List<Bridge> varBridges = [];
    if (resp.statusCode != 404) {
      var bridgesJson = json.decode(resp.resp);
      final dedup = bridgeDeduper;
      for (final e in bridgesJson) {
        Bridge brige = dedup != null ? dedup(e) as Bridge : Bridge.fromJson(e);
        varBridges.add(brige);
      }
      //print("Bridges: ${varBridges.length}");
      //callback(false, varBridges);
    } else {
      //callback(true, varBridges);
    }
    //});
    return varBridges;
  }

  Future<Bridge> create({String? type, String? bridgeId, String? name}) async {
    List<String> types = [];
    if (type != null) types = type.split(',');

    var resp = await BridgesAPI.create(name, bridgeId, types);
    var bridgesJson = json.decode(resp.resp);
    final dedup = bridgeDeduper;
    return dedup != null
        ? dedup(bridgesJson) as Bridge
        : Bridge.fromJson(bridgesJson);
  }
}
