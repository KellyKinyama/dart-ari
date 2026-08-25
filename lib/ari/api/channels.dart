import 'dart:io';
import 'dart:convert';

import 'ari_exception.dart';
import 'globals.dart';

//import 'package:dart_ari_proxy/ari_client/PlaybackApi.dart';
//import 'package:dart_ari_proxy/ari_client/events/channel_destroyed.dart';
//import 'package:dart_ari_proxy/ari_client/events/channel_state_change.dart';
//import 'package:dart_ari_proxy/ari_client/events/stasis_end.dart';
import 'misc.dart';
import 'playbacks.dart';
import 'resource.dart';
//import 'package:dart_ari_proxy/globals.dart';

//import 'events/event.dart';
//import 'events/stasis_start.dart';
//import 'misc.dart';
//import 'models.dart';

class ChannelsApi {
  /// Create an instance of the Bridges API client, providing access to the
  /// `/bridges` endpoint.
  ///
  /// @param {object} params
  /// @param {string} username The username to send with the request.
  /// @param {string} password The password to send with the request.
  /// @param {string} baseUrl The base url, without trailing slash,
  ///  of the root Asterisk ARI endpoint. i.e. 'http://myserver.local:8088/ari'.
  ChannelsApi() {}

  static late String scheme;
  static late String apiKey;
  static late String host;
  static late int port;

  static Future<dynamic> list() async {
    // baseUrl.path = baseUrl.path + '/channels';
    var uri = Uri(
        scheme: scheme,
        userInfo: "",
        host: host,
        port: port,
        path: "ari/channels",
        //Iterable<String>? pathSegments,
        query: "",
        queryParameters: {'api_key': apiKey}
        //String? fragment
        );
    //var uri = Uri.http(baseUrl);
    final request = await client.getUrl(uri);
    return await sendAriRequest(request);
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
          'timeout': timeout != null ? timeout.toString() : "-1",
          // 'timeout': "-1",
          'channelId': channelId ?? "",
          'otherChannelId': otherChannelId ?? "",
          'originator': originator ?? "",
        }
        //String? fragment
        );

    //dsvar uri = Uri.http(baseUrl, '/channels', qParams);
    final request = await client.postUrl(uri);
    return await sendAriRequest(request);
  }

  static Future<dynamic> create(
      {String? endpoint,
      String? extension,
      String? context,
      String? priority,
      String? label,
      String? app,
      List<String>? appArgs,
      String? callerId,
      String? timeout,
      String? channelId,
      String? otherChannelId,
      String? originator,
      dynamic variables}) async {
    // var uri = Uri.http(baseUrl, '/channels/create', query: "",
    //     queryParameters: {
    //   'api_key': api_key,
    //   'endpoint': queryParams.endpoint,
    //   'extension': queryParams.extension,
    //   'context': queryParams.context,
    //   'priority': queryParams.priority,
    //   'label': queryParams.label,
    //   'app': queryParams.app,
    //   'appArgs': queryParams.appArgs,
    //   'callerId': queryParams.callerId,
    //   'timeout': queryParams.timeout,
    //   'channelId': queryParams.channelId,
    //   'otherChannelId': queryParams.otherChannelId,
    //   'originator': queryParams.originator,
    // });

    var uri = Uri(
        scheme: scheme,
        userInfo: "",
        host: host,
        port: port,
        path: 'ari/channels/create',
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
          'variables': variables ?? ""
        });

    final request = await client.postUrl(uri);
    return await sendAriRequest(request);
  }

  static Future<dynamic> createWithId(
      {String? endpoint,
      String? extension,
      String? context,
      String? priority,
      String? label,
      String? app,
      List<String>? appArgs,
      String? callerId,
      String? timeout,
      String? channelId,
      String? otherChannelId,
      String? originator}) async {
    // var uri = Uri.http(baseUrl, '/channels/create', query: "",
    //     queryParameters: {
    //   'api_key': api_key,
    //   'endpoint': queryParams.endpoint,
    //   'extension': queryParams.extension,
    //   'context': queryParams.context,
    //   'priority': queryParams.priority,
    //   'label': queryParams.label,
    //   'app': queryParams.app,
    //   'appArgs': queryParams.appArgs,
    //   'callerId': queryParams.callerId,
    //   'timeout': queryParams.timeout,
    //   'channelId': queryParams.channelId,
    //   'otherChannelId': queryParams.otherChannelId,
    //   'originator': queryParams.originator,
    // });

    var uri = Uri(
        scheme: scheme,
        userInfo: "",
        host: host,
        port: port,
        path: 'ari/channels/create',
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
        });

    final request = await client.postUrl(uri);
    return await sendAriRequest(request);
  }

  static Future<HttpClientResponse> get(String channelId) async {
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
      path: 'ari/channels/$channelId',
      //Iterable<String>? pathSegments,
    );
    HttpClientRequest request = await client.getUrl(uri);
    HttpClientResponse response = await request.close();
    //print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    //print(response.statusCode);
    //print(stringData);
    return response;
  }

  // static Future<HttpClientResponse> originateWithId(
  //     String channelId, dynamic queryParams, qParams) async {
  //   // params: {
  //   //     'endpoint':,
  //   //     'extension':,
  //   //     'context':,
  //   //     'priority':,
  //   //     'label':,
  //   //     'app':,
  //   //     'appArgs':,
  //   //     'callerId':,
  //   //     'timeout':,
  //   //     'channelId':,
  //   //     'otherChannelId':,
  //   //     'originator':,
  //   //     'formats': [].concat(formats).join(","),
  //   //   },
  //   //   data: { variables },

  //   var uri = Uri.http(baseUrl, '/channels/${channelId}', qParams);
  //   HttpClientRequest request = await client.postUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   //print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   //print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  static Future<dynamic> hangup(String channelId) async {
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
        path: "ari/channels/$channelId",
        //Iterable<String>? pathSegments,
        query: "",
        queryParameters: {'api_key': apiKey}
        //String? fragment
        );
    //var uri = Uri.http(baseUrl, '/channels/${channelId}');

    final request = await client.deleteUrl(uri);
    return await sendAriRequest(request);
  }

  static Future<dynamic> continueInDialplan(String channelId,
      {String? context,
      String? extension,
      num? priority,
      String? label}) async {
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
        path: "ari/channels/$channelId/continue",
        //Iterable<String>? pathSegments,
        query: "",
        queryParameters: {
          'api_key': apiKey,
          'context': context ?? "",
          'extension': extension ?? "",
          'priority': priority != null ? priority.toString() : "",
          'label': label ?? "",
        }
        //String? fragment
        );

    //var uri = Uri.http(baseUrl, '/channels/${channelId}/continue', qParams);
    final request = await client.postUrl(uri);
    return await sendAriRequest(request);
  }

  // static Future<HttpClientResponse> redirect(
  //     String channelId, dynamic queryParams, qParams) async {
  //   // params: {
  //   //     'endpoint':,
  //   //     'extension':,
  //   //     'context':,
  //   //     'priority':,
  //   //     'label':,
  //   //     'app':,
  //   //     'appArgs':,
  //   //     'callerId':,
  //   //     'timeout':,
  //   //     'channelId':,
  //   //     'otherChannelId':,
  //   //     'originator':,
  //   //     'formats': [].concat(formats).join(","),
  //   //   },
  //   //   data: { variables },

  //   var uri = Uri.http(baseUrl, '/channels/${channelId}/redirect', qParams);
  //   HttpClientRequest request = await client.postUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   //print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   //print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  static Future<dynamic> answer(String channelId,
      {dynamic queryParams, dynamic qParams}) async {
    // baseUrl.path = baseUrl.path + '/channels';
    var uri = Uri(
        scheme: scheme,
        userInfo: "",
        host: host,
        port: port,
        path: "ari/channels/$channelId/answer",
        //Iterable<String>? pathSegments,
        query: "",
        queryParameters: {'api_key': apiKey}
        //String? fragment
        );

//HttpClientRequest request = await client.getUrl(uri);
    //var uri = Uri.http(baseUrl, '/channels/${channelId}/answer', qParams);
    final request = await client.postUrl(uri);
    return await sendAriRequest(request);
  }

  // static Future<HttpClientResponse> ring(
  //     String channelId, dynamic queryParams, qParams) async {
  //   // params: {
  //   //     'endpoint':,
  //   //     'extension':,
  //   //     'context':,
  //   //     'priority':,
  //   //     'label':,
  //   //     'app':,
  //   //     'appArgs':,
  //   //     'callerId':,
  //   //     'timeout':,
  //   //     'channelId':,
  //   //     'otherChannelId':,
  //   //     'originator':,
  //   //     'formats': [].concat(formats).join(","),
  //   //   },
  //   //   data: { variables },

  //   var uri = Uri.http(baseUrl, '/channels/${channelId}/ring', qParams);
  //   HttpClientRequest request = await client.postUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   //print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   //print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  // static Future<HttpClientResponse> ringStop(
  //     String channelId, dynamic queryParams, qParams) async {
  //   // params: {
  //   //     'endpoint':,
  //   //     'extension':,
  //   //     'context':,
  //   //     'priority':,
  //   //     'label':,
  //   //     'app':,
  //   //     'appArgs':,
  //   //     'callerId':,
  //   //     'timeout':,
  //   //     'channelId':,
  //   //     'otherChannelId':,
  //   //     'originator':,
  //   //     'formats': [].concat(formats).join(","),
  //   //   },
  //   //   data: { variables },

  //   var uri = Uri.http(baseUrl, '/channels/${channelId}/ring', qParams);
  //   HttpClientRequest request = await client.deleteUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   //print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   //print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  // static Future<HttpClientResponse> sendDTMF(
  //     String channelId, dynamic queryParams, qParams) async {
  //   // params: {
  //   //     'endpoint':,
  //   //     'extension':,
  //   //     'context':,
  //   //     'priority':,
  //   //     'label':,
  //   //     'app':,
  //   //     'appArgs':,
  //   //     'callerId':,
  //   //     'timeout':,
  //   //     'channelId':,
  //   //     'otherChannelId':,
  //   //     'originator':,
  //   //     'formats': [].concat(formats).join(","),
  //   //   },
  //   //   data: { variables },

  //   var uri = Uri.http(baseUrl, '/channels/${channelId}/dtmf', qParams);
  //   HttpClientRequest request = await client.postUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   //print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   //print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  // static Future<HttpClientResponse> mute(
  //     String channelId, dynamic queryParams, qParams) async {
  //   // params: {
  //   //     'endpoint':,
  //   //     'extension':,
  //   //     'context':,
  //   //     'priority':,
  //   //     'label':,
  //   //     'app':,
  //   //     'appArgs':,
  //   //     'callerId':,
  //   //     'timeout':,
  //   //     'channelId':,
  //   //     'otherChannelId':,
  //   //     'originator':,
  //   //     'formats': [].concat(formats).join(","),
  //   //   },
  //   //   data: { variables },

  //   var uri = Uri.http(baseUrl, '/channels/${channelId}/mute', qParams);
  //   HttpClientRequest request = await client.postUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   //print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   //print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  // static Future<HttpClientResponse> unmute(
  //     String channelId, dynamic queryParams, qParams) async {
  //   // params: {
  //   //     'endpoint':,
  //   //     'extension':,
  //   //     'context':,
  //   //     'priority':,
  //   //     'label':,
  //   //     'app':,
  //   //     'appArgs':,
  //   //     'callerId':,
  //   //     'timeout':,
  //   //     'channelId':,
  //   //     'otherChannelId':,
  //   //     'originator':,
  //   //     'formats': [].concat(formats).join(","),
  //   //   },
  //   //   data: { variables },

  //   var uri = Uri.http(baseUrl, '/channels/${channelId}/mute', qParams);
  //   HttpClientRequest request = await client.deleteUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   //print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   //print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  // static Future<HttpClientResponse> hold(
  //     String channelId, dynamic queryParams, qParams) async {
  //   // params: {
  //   //     'endpoint':,
  //   //     'extension':,
  //   //     'context':,
  //   //     'priority':,
  //   //     'label':,
  //   //     'app':,
  //   //     'appArgs':,
  //   //     'callerId':,
  //   //     'timeout':,
  //   //     'channelId':,
  //   //     'otherChannelId':,
  //   //     'originator':,
  //   //     'formats': [].concat(formats).join(","),
  //   //   },
  //   //   data: { variables },

  //   var uri = Uri.http(baseUrl, '/channels/${channelId}/hold', qParams);
  //   HttpClientRequest request = await client.postUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   //print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   //print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  // static Future<HttpClientResponse> unhold(
  //     String channelId, dynamic queryParams, qParams) async {
  //   // params: {
  //   //     'endpoint':,
  //   //     'extension':,
  //   //     'context':,
  //   //     'priority':,
  //   //     'label':,
  //   //     'app':,
  //   //     'appArgs':,
  //   //     'callerId':,
  //   //     'timeout':,
  //   //     'channelId':,
  //   //     'otherChannelId':,
  //   //     'originator':,
  //   //     'formats': [].concat(formats).join(","),
  //   //   },
  //   //   data: { variables },

  //   var uri = Uri.http(baseUrl, '/channels/${channelId}/hold', qParams);
  //   HttpClientRequest request = await client.deleteUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   //print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   //print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  // static Future<HttpClientResponse> startMusicOnHold(
  //     String channelId, dynamic queryParams, qParams) async {
  //   // params: {
  //   //     'endpoint':,
  //   //     'extension':,
  //   //     'context':,
  //   //     'priority':,
  //   //     'label':,
  //   //     'app':,
  //   //     'appArgs':,
  //   //     'callerId':,
  //   //     'timeout':,
  //   //     'channelId':,
  //   //     'otherChannelId':,
  //   //     'originator':,
  //   //     'formats': [].concat(formats).join(","),
  //   //   },
  //   //   data: { variables },

  //   var uri = Uri.http(baseUrl, '/channels/${channelId}/moh', qParams);
  //   HttpClientRequest request = await client.postUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   //print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   //print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  // static Future<HttpClientResponse> stopMusicOnHold(
  //     String channelId, dynamic queryParams, qParams) async {
  //   // params: {
  //   //     'endpoint':,
  //   //     'extension':,
  //   //     'context':,
  //   //     'priority':,
  //   //     'label':,
  //   //     'app':,
  //   //     'appArgs':,
  //   //     'callerId':,
  //   //     'timeout':,
  //   //     'channelId':,
  //   //     'otherChannelId':,
  //   //     'originator':,
  //   //     'formats': [].concat(formats).join(","),
  //   //   },
  //   //   data: { variables },

  //   var uri = Uri.http(baseUrl, '/channels/${channelId}/moh', qParams);
  //   HttpClientRequest request = await client.deleteUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   //print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   //print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  // static Future<HttpClientResponse> startSilence(
  //     String channelId, dynamic queryParams, qParams) async {
  //   // params: {
  //   //     'endpoint':,
  //   //     'extension':,
  //   //     'context':,
  //   //     'priority':,
  //   //     'label':,
  //   //     'app':,
  //   //     'appArgs':,
  //   //     'callerId':,
  //   //     'timeout':,
  //   //     'channelId':,
  //   //     'otherChannelId':,
  //   //     'originator':,
  //   //     'formats': [].concat(formats).join(","),
  //   //   },
  //   //   data: { variables },

  //   var uri = Uri.http(baseUrl, '/channels/${channelId}/silence', qParams);
  //   HttpClientRequest request = await client.postUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   //print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   //print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  // static Future<HttpClientResponse> stopSilence(
  //     String channelId, dynamic queryParams, qParams) async {
  //   // params: {
  //   //     'endpoint':,
  //   //     'extension':,
  //   //     'context':,
  //   //     'priority':,
  //   //     'label':,
  //   //     'app':,
  //   //     'appArgs':,
  //   //     'callerId':,
  //   //     'timeout':,
  //   //     'channelId':,
  //   //     'otherChannelId':,
  //   //     'originator':,
  //   //     'formats': [].concat(formats).join(","),
  //   //   },
  //   //   data: { variables },

  //   var uri = Uri.http(baseUrl, '/channels/${channelId}/silence', qParams);
  //   HttpClientRequest request = await client.deleteUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   //print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   //print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  ///
  /// POST /channels/{channelId}/play
  ///
  /// Start playback of media. The media URI may be any of a number of URIs.
  /// `sound:`, `recording:`, `number:`, `digits:`, `characters:`, and `tone:`
  /// URIs are supported. This operation creates a playback resource that can
  /// be used to control the playback of media (pause, rewind, fast forward, etc.)
  ///
  /// *'tone:' playback URI added in Asterisk 12.3*
  ///
  /// @param {object} params
  /// @param {string} params.channelId the id of the channel to play the media
  ///  to.
  /// @param {string|Array.<string>} params.media The media's URI to play.
  ///  *Allows multiple media to be passed since Asterisk 14.0*
  /// @param {string} [params.lang] For sounds, the language for the sound.
  /// @param {number} [params.offsetms=0] The number of milliseconds to skip
  ///  before playing the media URI. Allowed range: 0+
  /// @param {number} [params.skipms=3000] The number of milliseconds to
  ///  skip for forward/reverse operations. Allowed range: 0+
  /// @param {string} [params.playbackId] The identifier of the playback that
  ///  is started. *Param available since Asterisk 12.2*
  /// @returns {Promise.<Playback>} Resolves with the details of the started
  ///  playback.
  ///

  static Future<dynamic> play({
    required String channelId,
    required List<String> media,
    String? lang,
    num offsetms = 0,
    num skipms = 3000,
    String? playbackId,
  }) async {
    var uri = Uri(
        scheme: scheme,
        userInfo: "",
        host: host,
        port: port,
        path: "ari/channels/$channelId/play",
        //Iterable<String>? pathSegments,
        query: "",
        queryParameters: {
          'api_key': apiKey,
          'media': media.join(","),
          'lang': "en",
          'offsetms': '0',
          'skipms': '3000',
          'playbackId': playbackId
        }
        //String? fragment
        );

    //var uri = Uri(baseUrl);
    final request = await client.postUrl(uri);
    return await sendAriRequest(request);
  }

  static Future<dynamic> playWithId(
      String channelId, String playbackId, List<String> media) async {
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
        path: "ari/channels/$channelId/play/$playbackId'",
        //Iterable<String>? pathSegments,
        query: "",
        queryParameters: {
          'api_key': apiKey,
          'media': media.join(","),
          'lang': "en",
          'offsetms': '0',
          'skipms': '3000'
        }
        //String? fragment
        );

    final request = await client.postUrl(uri);
    return await sendAriRequest(request);
  }

  /// POST /channels/{channelId}/record
  ///
  /// Start recording audio FROM a channel (this leg only; will NOT capture
  /// audio sent TO the channel — use [BridgesAPI.record] on the mixing bridge
  /// for a full both-sides recording).
  ///
  /// [name] and [format] are required by ARI. [ifExists] must be one of
  /// `fail` (default), `overwrite`, `append`. [terminateOn] must be one of
  /// `none` (default), `any`, `*`, `#`.
  static Future<({int statusCode, String resp})> record({
    required String channelId,
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
      path: "ari/channels/$channelId/record",
      queryParameters: qp,
    );

    final request = await client.postUrl(uri);
    return await sendAriRequest(request);
  }

  /// GET /channels/{channelId}/rtp_statistics
  ///
  /// Returns the RTP stats block for a channel. Useful for grabbing the
  /// negotiated local/remote RTP endpoints once media has been flowing.
  static Future<({int statusCode, String resp})> rtpStatistics(
      String channelId) async {
    final uri = Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: "ari/channels/$channelId/rtp_statistics",
      queryParameters: {'api_key': apiKey},
    );

    final request = await client.getUrl(uri);
    return await sendAriRequest(request);
  }

  /// POST /channels/{channelId}/dial
  ///
  /// Actually dial a channel that was previously allocated via
  /// `POST /channels/create`. Without this call, a create-only channel sits
  /// in the Stasis app in "pre-dial" state — no SIP INVITE is sent, so the
  /// far end never rings.
  static Future<({int statusCode, String resp})> dial({
    required String channelId,
    String? caller,
    int? timeout,
  }) async {
    final qp = <String, String>{'api_key': apiKey};
    if (caller != null && caller.isNotEmpty) qp['caller'] = caller;
    if (timeout != null) qp['timeout'] = timeout.toString();

    final uri = Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: "ari/channels/$channelId/dial",
      queryParameters: qp,
    );

    final request = await client.postUrl(uri);
    return await sendAriRequest(request);
  }

  static Future<dynamic> getChannelVariable(
      String channelId, String variable) async {
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
        path: "ari/channels/${channelId}/variable",
        //Iterable<String>? pathSegments,
        query: "",
        queryParameters: {'api_key': apiKey, 'variable': variable}
        //String? fragment
        );

    final request = await client.getUrl(uri);
    return await sendAriRequest(request);
  }

  // static Future<HttpClientResponse> setChannelVariable(
  //     String channelId, String playId, dynamic queryParams, qParams) async {
  //   // params: {
  //   //     'endpoint':,
  //   //     'extension':,
  //   //     'context':,
  //   //     'priority':,
  //   //     'label':,
  //   //     'app':,
  //   //     'appArgs':,
  //   //     'callerId':,
  //   //     'timeout':,
  //   //     'channelId':,
  //   //     'otherChannelId':,
  //   //     'originator':,
  //   //     'formats': [].concat(formats).join(","),
  //   //   },
  //   //   data: { variables },

  //   var uri = Uri.http(baseUrl, '/channels/${channelId}/variable', qParams);
  //   HttpClientRequest request = await client.postUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   //print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   //print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  // static Future<HttpClientResponse> snoopChannel(
  //     String channelId, String sid, dynamic queryParams, qParams) async {
  //   // params: {
  //   //     'endpoint':,
  //   //     'extension':,
  //   //     'context':,
  //   //     'priority':,
  //   //     'label':,
  //   //     'app':,
  //   //     'appArgs':,
  //   //     'callerId':,
  //   //     'timeout':,
  //   //     'channelId':,
  //   //     'otherChannelId':,
  //   //     'originator':,
  //   //     'formats': [].concat(formats).join(","),
  //   //   },
  //   //   data: { variables },

  //   var uri = Uri.http(baseUrl, '/channels/${channelId}/snoop/${sid}', qParams);
  //   HttpClientRequest request = await client.postUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   //print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   //print(response.statusCode);
  //   //print(stringData);
  //   return response;
  // }

  static Future<dynamic> externalMedia({
    required String app, //: string;
    dynamic variables, //?: Containers;
    required String external_host, //: string;
    String? encapsulation, //?: string;
    String? transport, //?: string;
    String? connection_type, //?: string;
    required String format, //: string;
    String? direction, //?: string;
  }) async {
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
    //POST /channels/externalMedia?app=MyApp&external_host=127.0.0.1%3A60000&format=ulaw
    //print(variables);

    var uri = Uri(
      scheme: scheme,
      userInfo: "",
      host: host,
      port: port,
      path: "ari/channels/externalMedia",
      //Iterable<String>? pathSegments,
      query: "",
      queryParameters: {
        'api_key': apiKey,
        'app': app,
        'variables': jsonEncode(variables),
        'external_host': external_host,
        'encapsulation': encapsulation,
        'transport': transport,
        'connection_type': connection_type,
        'format': format,
        'direction': direction
      },
      //String? fragment
    );

    final request = await client.postUrl(uri);
    return await sendAriRequest(request);
  }

  static Future<dynamic> externalMediaDelete(String id) async {
    var uri = Uri(
      scheme: scheme,
      userInfo: "",
      host: host,
      port: port,
      path: "ari/channels/$id",
      queryParameters: {'api_key': apiKey},
    );

    final request = await client.deleteUrl(uri);
    return await sendAriRequest(request);
  }
  // static Future<dynamic> externalMediaDelete(String channelId) async {
  //   // params: {
  //   //     'endpoint':,
  //   //     'extension':,
  //   //     'context':,
  //   //     'priority':,
  //   //     'label':,
  //   //     'app':,
  //   //     'appArgs':,
  //   //     'callerId':,
  //   //     'timeout':,
  //   //     'channelId':,
  //   //     'otherChannelId':,
  //   //     'originator':,
  //   //     'formats': [].concat(formats).join(","),
  //   //   },
  //   //   data: { variables },
  //   //POST /channels/externalMedia?app=MyApp&external_host=127.0.0.1%3A60000&format=ulaw
  //   //print(variables);

  //   var uri = Uri(
  //     scheme: "http",
  //     userInfo: "",
  //     host: "10.44.0.55",
  //     port: 8088,
  //     path: "ari/channels/externalMedia/$channelId",
  //     //Iterable<String>? pathSegments,
  //     query: "",
  //     queryParameters: {'api_key': api_key},
  //     //String? fragment
  //   );
  //   HttpClientRequest request = await client.deleteUrl(uri);
  //   HttpClientResponse response = await request.close();
  //   print(response);
  //   final String stringData = await response.transform(utf8.decoder).join();
  //   print(response.statusCode);
  //   //print(stringData);
  //   return (statusCode: response.statusCode, resp: stringData);
  // }

//   static Future<HttpClientResponse> dial(
//       String channelId, String sid, dynamic queryParams, qParams) async {
//     // params: {
//     //     'endpoint':,
//     //     'extension':,
//     //     'context':,
//     //     'priority':,
//     //     'label':,
//     //     'app':,
//     //     'appArgs':,
//     //     'callerId':,
//     //     'timeout':,
//     //     'channelId':,
//     //     'otherChannelId':,
//     //     'originator':,
//     //     'formats': [].concat(formats).join(","),
//     //   },
//     //   data: { variables },

//     var uri = Uri.http(baseUrl, '/channels/${channelId}/dial', qParams);
//     HttpClientRequest request = await client.postUrl(uri);
//     HttpClientResponse response = await request.close();
//     //print(response);
//     final String stringData = await response.transform(utf8.decoder).join();
//     //print(response.statusCode);
//     //print(stringData);
//     return response;
//   }

//   //Params params;
}

//typedef MyCallback = void Function(int value);

class Channel extends Resource {
  Channel(
      this.id,
      this.name,
      this.accountcode,
      this.state,
      this.caller,
      this.dialplan,
      this.creationtime,
      this.language,
      this.channelvars,
      this.json); // {}
  String id;
  String name;
  String state; //: string;
  CallerID caller; //: CallerID;

  void stasisStart(stasisStart, channel) {
    emit('StasisStart', (stasisStart, channel));
  }

  void stasisEnd(stasisEnd, channel) => emit('StasisEnd', (stasisEnd, channel));

  void channelDestroyed(channelDestroyed, channel) =>
      emit('channelDestroyed', (channelDestroyed, channel));

  void channelStateChange(channelStateChange, channel) =>
      emit('ChannelStateChange', (channelStateChange, channel));

  /// Connected.
  dynamic connected; //: CallerID;

  /// Accountcode.
  String accountcode; //: string;

  /// Current location in the dialplan.
  dynamic dialplan; //: DialplanCEP;

  /// Timestamp when channel was created.
  DateTime creationtime; //: Date;

  /// The default spoken language.
  String language; //: string;

  /// Channel variables.
  dynamic channelvars; //?: IndexableObject;

  dynamic json;

  factory Channel.fromJson(dynamic json, {Channel? channel}) {
    //print(json);
    if (json['error'] != null) {
      print(json);
      throw "Error: ${json['error']}";
    }

    final creationtime = DateTime.parse(json['creationtime']); // 8:18pm
    var caller = CallerID.fromJson(json['caller']);

    if (channel != null) {
      // Refresh mutable fields in place. `id` is intentionally NOT updated:
      // channel ids are immutable and a different id implies a different
      // channel entirely (caller of cacheChannel guarantees id match).
      channel.name = json['name'] as String? ?? channel.name;
      channel.accountcode =
          json['accountcode'] as String? ?? channel.accountcode;
      channel.state = json['state'] as String? ?? channel.state;
      channel.caller = caller;
      channel.dialplan = json['dialplan'];
      channel.language = json['language'] as String? ?? channel.language;
      channel.channelvars = json['channelvars'];
      channel.json = json;
      return channel;
    }

    return Channel(
        json['id'] as String,
        json['name'] as String,
        json['accountcode'] as String,
        json['state'] as String,
        caller,
        json['dialplan'] as dynamic,
        creationtime,
        json['language'] as String,
        json['channelvars'] as dynamic,
        json as dynamic);
  }

//final void Function(Error) callback;

  Future<bool> answer() async {
    var resp = await ChannelsApi.answer(id);
    //resp.then((value) {
    print("Status code: ${resp.statusCode}");
    bool err = resp.statusCode == 404 ||
        resp.statusCode == 409 ||
        resp.statusCode == 412;

    return err;
    //});
  }

  // @override
  // String toString() {
  //   return json;
  // }

  Map<String, Function(dynamic event, Channel channel)> handlers = {};

  // void on(String event, Function(dynamic event, Channel channel) callback) {
  //   //print("Adding channel event handler for $event");
  //   handlers[event] = callback;
  // }

  // void emit(data) {
  //   //print(data);

  //   if (handlers[data['type']] != null) {
  //     switch (data['type']) {
  //       case "StasisStart":
  //         {
  //           print("Executing channel event ${data['type']}");
  //           Channel channel = Channel.fromJson(data['channel']);
  //           StasisStart stasisStart = StasisStart.fromJson(data);
  //           handlers[data['type']]!(stasisStart, channel);
  //         }

  //       case "StasisEnd":
  //         {
  //           print("Executing channel event ${data['type']}");
  //           Channel channel = Channel.fromJson(data['channel']);
  //           StasisEnd stasisEnd = StasisEnd.fromJson(data);
  //           handlers[data['type']]!(stasisEnd, channel);
  //         }
  //       default:
  //         {
  //           print("unhandled channel event: ${data['type']}");
  //         }
  //     }
  //     //handlers[data['type']]!(data);
  //   } else {
  //     {
  //       print("unhandled channel event: ${data['type']}");
  //     }
  //   }
  // }

  //removeAllListeners(String event) {}

  Future<void> continueInDialplan(
      {String? context,
      String? extension,
      num? priority,
      String? label}) async {
    ChannelsApi.continueInDialplan(id,
        context: context, extension: extension, priority: priority);
  }

  Future<void> originate(
      {required String endpoint, //: string;
      String? extension, //?: string;
      String? context, //?: string;
      String? priority, //?: number;
      String? label, //?: string;
      String? app, //?: string;
      List<String>? appArgs, //?: string;
      String? callerId, //?: string;
      num? timeout, //?: number;
      dynamic? variables, //?: Containers;
      String? otherChannelId, //?: string;
      String? originator, //?: string;
      String? formats //?: string;
      }) async {
    await ChannelsApi.originate(
        endpoint: endpoint, //: string;
        extension: extension, //?: string;
        context: context, //?: string;
        priority: priority, //?: number;
        label: label, //?: string;
        app: app, //?: string;
        appArgs: appArgs, //?: string;
        callerId: callerId, //?: string;
        timeout: timeout, //?: number;
        //variables:variables, //?: Containers;
        otherChannelId: otherChannelId, //?: string;
        originator: originator, //?: string;
        channelId: id
        //formats:formats //?: string;
        );
  }

  Future<bool> hangup() async {
    var resp = await ChannelsApi.hangup(id);
    return true;
  }

  // {
  //   required String channelId,
  //   required List<String> media,
  //   String? lang,
  //   num offsetms = 0,
  //   num skipms = 3000,
  //   String? playbackId,
  // }

  Future<Playback> play(
    Playback play, {
    required List<String> media,
    String? lang,
    num offsetms = 0,
    num skipms = 3000,
    String? playbackId,
  }) async {
    var resp = await ChannelsApi.play(
        channelId: id, media: media, playbackId: play.id);
    // resp.then((playReturned) {
    //   Playback playback = Playback.fromJson(jsonDecode(playReturned.resp));

    //   callback(false, playback);
    // });
    return Playback.fromJson(jsonDecode(resp.resp));
  }

  // Future<Channel> externalMedia(
  //   Function(bool, Channel) callback, {
  //   required String app, //: string;
  //   dynamic variables, //?: Containers;
  //   required external_host, //: string;
  //   String? encapsulation, //?: string;
  //   String? transport, //?: string;
  //   String? connection_type, //?: string;
  //   required String format, //: string;
  //   String? direction, //?: string;
  // }) async {
  //   var resp = await ChannelsApi.externalMedia(
  //       app: app,
  //       variables: variables,
  //       external_host: external_host,
  //       encapsulation: encapsulation,
  //       transport: transport,
  //       connection_type: connection_type,
  //       format: format,
  //       direction: direction);

  //   print(resp.resp);

  //   var channelJson = resp.resp;

  //   Channel channel = Channel.fromJson(jsonDecode(channelJson));

  //   statisChannels[channel.id] = channel;
  //   return channel;

  //   // resp.then((value) {
  //   //   if (value.statusCode == 200 || value.statusCode == 204)
  //   //     callback(false, this);
  //   //   else
  //   //     callback(true, this);
  //   // });
  // }

  // removeListener(String event, Function(dynamic, Channel) callback) {
  //   callback(false, this);
  // }

  getChannelVar(Function(bool, dynamic) callback, String variable) {
    var resp = ChannelsApi.getChannelVariable(id, variable);
    resp.then((value) {
      print("Channel variable: ${value.resp}");
      //var varJson = jsonDecode(value.resp);
      //throw "You need to see cahnnel Variable";
      if (value.resp == '{"message":"Provided variable was not found"}') {
        callback(true, value.resp);
      } else {
        //callback(false, value.resp);
        throw value.resp;
      }
    });
  }

  /// Start a channel-leg recording. Returns the raw LiveRecording JSON.
  /// Prefer [Bridge.record] for full-call (both-sides) audio.
  Future<Map<String, dynamic>> record({
    required String name,
    String format = 'wav',
    int? maxDurationSeconds,
    int? maxSilenceSeconds,
    String ifExists = 'overwrite',
    bool beep = false,
    String terminateOn = 'none',
  }) async {
    final resp = await ChannelsApi.record(
      channelId: id,
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

  /// GET /channels/{id}/rtp_statistics — raw RTPstat JSON.
  Future<Map<String, dynamic>> rtpStatistics() async {
    final resp = await ChannelsApi.rtpStatistics(id);
    return jsonDecode(resp.resp) as Map<String, dynamic>;
  }

  /// Fetch the SDP-negotiated media endpoints for this channel via the
  /// `CHANNEL()` dialplan function. Also grabs the SIP signaling peer via
  /// `CHANNEL(pjsip,remote_addr)` / `CHANNEL(pjsip,local_addr)`.
  ///
  /// Each field is null if the variable isn't set (e.g. non-PJSIP channels,
  /// or media not yet negotiated).
  ///
  /// The RTP fields come from the SDP, so they reflect what was announced
  /// in the m=/c= lines — that's what "IPs in the SDP" refers to.
  Future<SdpEndpoints> sdpEndpoints() async {
    Future<String?> readVar(String v) async {
      try {
        final resp = await ChannelsApi.getChannelVariable(id, v);
        final decoded = jsonDecode(resp.resp) as Map<String, dynamic>;
        final value = decoded['value'] as String?;
        return (value == null || value.isEmpty) ? null : value;
      } on AriException {
        return null;
      }
    }

    final results = await Future.wait([
      readVar('CHANNEL(pjsip,remote_addr)'),
      readVar('CHANNEL(pjsip,local_addr)'),
      readVar('CHANNEL(rtp,src)'),
      readVar('CHANNEL(rtp,dest)'),
    ]);

    return SdpEndpoints(
      pjsipRemote: results[0],
      pjsipLocal: results[1],
      rtpSrc: results[2],
      rtpDest: results[3],
    );
  }

  @override
  String toString() {
    return jsonEncode(json);
  }

  String toJson() {
    return jsonEncode(json);
  }
}

/// SDP-negotiated media endpoints for a single channel, plus the SIP
/// signaling peer address for reference.
///
/// Values are strings in `IP:PORT` form as Asterisk emits them. Any field
/// may be null when the variable is unavailable (non-PJSIP channel, media
/// not yet negotiated, or CHANNEL() returned empty).
class SdpEndpoints {
  final String? pjsipRemote;
  final String? pjsipLocal;
  final String? rtpSrc;
  final String? rtpDest;

  const SdpEndpoints({
    this.pjsipRemote,
    this.pjsipLocal,
    this.rtpSrc,
    this.rtpDest,
  });

  /// IP portion of [rtpDest] — the remote SDP RTP endpoint. This is the
  /// "peer IP from the SDP" callers usually mean when they say "mark the
  /// call by IP".
  String? get remoteRtpIp => _ipOf(rtpDest);

  /// IP portion of [rtpSrc] — Asterisk's local RTP endpoint.
  String? get localRtpIp => _ipOf(rtpSrc);

  /// IP portion of [pjsipRemote] — the SIP signaling peer.
  String? get remoteSipIp => _ipOf(pjsipRemote);

  static String? _ipOf(String? addr) {
    if (addr == null || addr.isEmpty) return null;
    // Bracketed IPv6: [::1]:5060
    if (addr.startsWith('[')) {
      final end = addr.indexOf(']');
      if (end < 0) return addr;
      return addr.substring(1, end);
    }
    final colon = addr.lastIndexOf(':');
    if (colon < 0) return addr;
    return addr.substring(0, colon);
  }

  Map<String, String?> toMap() => {
        'pjsip_remote': pjsipRemote,
        'pjsip_local': pjsipLocal,
        'rtp_src': rtpSrc,
        'rtp_dest': rtpDest,
      };

  @override
  String toString() =>
      'SdpEndpoints(pjsipRemote=$pjsipRemote, pjsipLocal=$pjsipLocal, rtpSrc=$rtpSrc, rtpDest=$rtpDest)';
}
