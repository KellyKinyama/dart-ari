import 'dart:io';
import 'dart:convert';

import 'resource.dart';
import 'globals.dart';

// import 'models.dart';

class PlaybackApi {
  static late String scheme;
  static late String apiKey;
  static late String host;
  static late int port;
  PlaybackApi() {}

  // Future<HttpClientResponse> get(String id) async {
  //   var uri = Uri.http(baseUrl, '/playbacks/${id}');
  //   HttpClientRequest request = await client.getUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  static Future<dynamic> stop(String playbackId) async {
    var uri = Uri(
        scheme: scheme,
        userInfo: "",
        host: host,
        port: port,
        path: "ari/playbacks/$playbackId",
        //Iterable<String>? pathSegments,
        query: "",
        queryParameters: {'api_key': apiKey}
        //String? fragment
        );
    try {
      //var uri = Uri.http(baseUrl, '/playbacks/${id}');
      HttpClientRequest request = await client.deleteUrl(uri);
      HttpClientResponse response = await request.close();
      print(response);
      final String stringData = await response.transform(utf8.decoder).join();
      print(response.statusCode);
      //print(stringData);
      return (statusCode: response.statusCode, resp: stringData);
    } catch (err, stackTrace) {
      // logger.severe('Caught an error', err, stackTrace);
      print("Error: $err, stacktrace: $stackTrace");
      return (statusCode: null, resp: null, err: err);
    }
  }

  // Future<HttpClientResponse> control(String id) async {
  //   var uri = Uri.http(baseUrl, '/playbacks/${id}/control');
  //   HttpClientRequest request = await client.postUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  //Params params;
}

class Playback extends Resource {
  Playback(
      {this.id,
      this.media_uri,
      this.next_media_uri,
      this.target_uri,
      this.language,
      this.state,
      this.json});

  /// ID for this playback operation.
  String? id; //: string;

  /// The URI for the media currently being played back.
  String? media_uri; //: string;

  /// If a list of URIs is being played, the next media URI to be played back.
  String? next_media_uri; //?: string;

  /// URI for the channel or bridge to play the media on.
  String? target_uri; //: string;

  /// For media types that support multiple languages, the language requested for playback.
  String? language; //: string;

  /// Current state of the playback operation.
  String? state; //: string;

  dynamic json;

  Map<String, Function(dynamic event, Playback playback)> handlers = {};

  // void on(String event, Function(dynamic event, Playback playback) callback) {
  //   //print("Adding channel event handler for $event");
  //   handlers[event] = callback;
  // }

  /// Get a playbacks details.
  void get(Function(Error, Playback) callback) {}

  /**
     * Get a playbacks details.
     */
  //get(): Promise<Playback>;

  /// Stop a playback.
  void stop(Function(bool) callback) {
    var resp = PlaybackApi.stop(id!);
    resp.then((value) {
      //print(value.resp);
      callback(false);
    });
  }

  /**
     * Stop a playback.
     */
  //stop(): Promise<void>;

  /// Control a playback.
  ///
  /// @param params.operation - Operation to perform on the playback.
  control(Function(Error) callback, {required String operation}) {}

  /// Control a playback.
  ///
  /// @param params.operation - Operation to perform on the playback.
  //control(params: { operation: string }): Promise<void>;

  factory Playback.fromJson(dynamic json) {
    //Channel channel = Channel.fromJson(json['channel']);
    String? next_media_uri;
    if (json['next_media_uri'] != null) next_media_uri = json['next_media_uri'];
    // print(json);
    return Playback(
        id: json['id'] as String,
        media_uri: json['media_uri'] as String,
        next_media_uri: next_media_uri,
        target_uri: json['target_uri'] as String,
        language: json['language'],
        state: json['state'] as String,
        json: json);
  }
}
