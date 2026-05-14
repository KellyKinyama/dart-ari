library ari_client;

import 'package:dotenv/dotenv.dart';
import 'package:redis/redis.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dart_ari/ari/api/events/channel_destroyed.dart';
import 'package:dart_ari/ari/api/events/channel_state_change.dart';
import 'package:dart_ari/ari/api/events/stasis_end.dart';
import 'package:dart_ari/ari/api/events/stasis_start.dart';
import 'package:dart_ari/ari/api/misc.dart';
import 'package:events_emitter/events_emitter.dart';

import '../config/constants.dart';
import 'bridges.dart';
import 'channels.dart';
import 'device_state.dart';
import 'endpoints.dart';
import 'ari_exception.dart';
import 'globals.dart';
import 'playbacks.dart';

part 'ari_ws.dart';

class ARI extends EventEmitter {
  /// Creates a new awry API instance, providing clients for all available
  /// Asterisk ARI endpoints.
  ///
  /// @param {object} params
  /// @param {string} params.username The username to send with the request.
  /// @param {string} params.password The password to send with the request.
  /// @param {string} params.baseUrl The base url, without trailing slash,
  ///  of the root Asterisk ARI endpoint. i.e. 'http://myserver.local:8088/ari'.

  String scheme;
  String apiKey;
  String host;
  int port;

  ARI(this.scheme, this.host, this.port, this.apiKey) {
    ChannelsApi.scheme = scheme;
    ChannelsApi.host = host;
    ChannelsApi.port = port;
    ChannelsApi.apiKey = apiKey;

    BridgesAPI.scheme = scheme;
    BridgesAPI.host = host;
    BridgesAPI.port = port;
    BridgesAPI.apiKey = apiKey;

    PlaybackApi.scheme = scheme;
    PlaybackApi.host = host;
    PlaybackApi.port = port;
    PlaybackApi.apiKey = apiKey;

    DeviceStateApi.scheme = scheme;
    DeviceStateApi.host = host;
    DeviceStateApi.port = port;
    DeviceStateApi.apiKey = apiKey;

    // Register the cache helpers globally so static list/factory methods on
    // Bridge and Channel (e.g. Bridge.list()) can dedupe against this
    // instance's cache instead of returning fresh objects with ids we
    // already track.
    bridgeDeduper = cacheBridge;
    channelDeduper = cacheChannel;
  }

  factory ARI.fromConfigs() {
    String scheme = config.ariConfigs[ASTERISK_ARI_SCHEME]!;

    String host = config.ariConfigs[ASTERISK_ARI_HOST]!;
    int port = int.parse(config.ariConfigs[ASTERISK_ARI_PORT]!);
    String apiKey =
        "${config.ariConfigs[ASTERISK_ARI_USERNAME]!}:${config.ariConfigs[ASTERISK_ARI_PASSWORD]!}";

    return (ARI(scheme, host, port, apiKey));
  }
  /** @type {ApplicationsAPI} */
  // static ApplicationsApi applications = ApplicationsApi();

  /** @type {AsteriskAPI} */
  //this.asterisk = new AsteriskAPI(params);

  /// @type {BridgesAPI}
  Map<String, Bridge> bridges = {};

  /// @type {DeviceStatesAPI}
  Map<String, DeviceState> deviceStates = {};

  /// @type {EndpointsAPI}
  Map<String, Endpoint> endpoints = {};

  /** @type {EventsAPI} */
  //this.events = new EventsAPI(params);

  /** @type {MailboxesAPI} */
  //this.mailboxes = new MailboxesAPI(params);

  /// @type {PlaybacksAPI}
  Map<String, Playback> playbacks = {};

  /** @type {RecordingsAPI} */
  //late RecordingsApi recordings = RecordingsApi();

  /** @type {SoundsAPI} */
  //late SoundsApi sounds = new SoundsApi();

  /// @type {ChannelsAPI}
  Map<String, Channel> channels = {};

  Channel? stsisChannel(Channel channel) {
    // TODO: implement stsisChannet
    return channels[channel.id];
  }

  /// Cache (or refresh) a Channel by id, guaranteeing a single instance per
  /// channel id across the whole client.
  ///
  /// If a Channel with the same id already exists, its mutable fields are
  /// updated in place from [channelJson] and the existing instance is
  /// returned. This preserves every event listener (`.on('StasisStart', …)`,
  /// `.on('StasisEnd', …)`, etc.) attached to the prior instance.
  ///
  /// If no instance exists, a new one is created from [channelJson] and
  /// cached.
  Channel cacheChannel(dynamic channelJson) {
    final id = channelJson['id'] as String;
    final existing = channels[id];
    if (existing != null) {
      Channel.fromJson(channelJson, channel: existing);
      return existing;
    }
    final created = Channel.fromJson(channelJson);
    channels[id] = created;
    return created;
  }

  /// Cache (or refresh) a Bridge by id, guaranteeing a single instance per
  /// bridge id and preserving previously attached event listeners. See
  /// [cacheChannel] for the rationale.
  Bridge cacheBridge(dynamic bridgeJson) {
    final id = bridgeJson['id'] as String;
    final existing = bridges[id];
    if (existing != null) {
      existing.updateFromJson(bridgeJson);
      return existing;
    }
    final created = Bridge.fromJson(bridgeJson);
    bridges[id] = created;
    return created;
  }

  //Params params = Params('asterisk', 'asterisk', '10.44.0.55');

  // String username;
  // String password;
  // String baseUrl;
  // HttpClient client = HttpClient();

  void stasisStart(StasisStart stasisStart, Channel channel) {
    emit('StasisStart', (stasisStart, channel));
  }

  void stasisEnd(StasisEnd stasisEnd, Channel channel) {
    emit('StasisEnd', (stasisEnd, channel));
  }

  void channelDestroyed(ChannelDestroyed channelDestroyed, Channel channel) {
    emit('channelDestroyed', (channelDestroyed, channel));
  }

  void channelStateChange(
      ChannelStateChange channelStateChange, Channel channel) {
    emit('ChannelStateChange', (channelStateChange, channel));
  }

  Future<void> connect() async {
    // Random r = new Random();
    final int key = 758485960049485;
// Random r = new Random();
//   String key = base64.encode(List<int>.generate(8, (_) => r.nextInt(256)));

//   HttpClient client = HttpClient(/* optional security context here */);
//   HttpClientRequest request = await client.get('echo.websocket.org', 80,
//       '/foo/ws?api_key=myapikey'); // form the correct url here
//   request.headers.add('Connection', 'upgrade');
//   request.headers.add('Upgrade', 'websocket');
//   request.headers.add('sec-websocket-version', '13'); // insert the correct version here
//   request.headers.add('sec-websocket-key', key);

//   HttpClientResponse response = await request.close();
//   // todo check the status code, key etc
//   Socket socket = await response.detachSocket();

//   WebSocket ws = WebSocket.fromUpgradedSocket(
//     socket,
//     serverSide: false,
//   );

// HttpClient clientLearn = HttpClient(/* optional security context here */);
// HttpClientRequest requestLearn = await clientLearn.get('echo.websocket.org', 80,
//        '/foo/ws?api_key=myapikey'); // form the correct url here

    var uri = Uri(
        scheme: scheme,
        userInfo: "",
        host: host,
        port: port,
        path: "ari/events",
        //Iterable<String>? pathSegments,
        query: "",
        queryParameters: {
          'api_key': apiKey,
          'app': 'hello',
          'subscribe_all': 'true'
        }
        //String? fragment
        );

    HttpClientRequest request = await client.getUrl(uri);
    request.headers.add('connection', 'Upgrade');
    //print('Hello');
    request.headers.add('upgrade', 'websocket');
    request.headers.add('Sec-WebSocket-Version', '13');
//request.headers.add('WebSocket-Version', '13');
    request.headers.add('Sec-WebSocket-Key', key);
    //HttpClientResponse response = await request.close();
    HttpClientResponse response = await request.close();
    //print(response);

    // Socket socket = await response.detachSocket();

    Socket socket = await response.detachSocket();

    WebSocket ws = WebSocket.fromUpgradedSocket(socket, serverSide: false);

    // ws.listen((event) {
    //   var e = json.decode(event);
    //   //print(e['type']);

    //   Function? func = app[e['type']];
    //   func!.call(e);
    // });
    //ws.listen(onData(//), onMessage, onDone: connectonClosed);
    // void on("StasisStart") {
    //   print("Hello");
    // }
    // ws.listen((event) {
    //   var e = json.decode(event);
    //   on(app[e['type']]);
    // },onError: on);
    //return ws;
    listen(ws);
  }

  Playback playback(
      {String? id,
      // ignore: non_constant_identifier_names
      String? media_uri,
      // ignore: non_constant_identifier_names
      String? next_media_uri,
      // ignore: non_constant_identifier_names
      String? target_uri,
      String? language,
      String? state}) {
    var uuid = Uuid();
    var pbId = uuid.v1();

    var playBack = Playback(id: pbId);
    playbacks[pbId] = playBack;

    return playBack;
  }

  Future<Channel> channel(
      {required String endpoint,
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
    // print("application: $app");
    // print("endpoint: $app");
    var resp = await ChannelsApi.create(
        endpoint: endpoint,
        extension: extension,
        context: context,
        priority: priority,
        label: label,
        app: app,
        appArgs: appArgs,
        callerId: callerId,
        timeout: timeout,
        channelId: channelId,
        otherChannelId: otherChannelId,
        originator: originator,
        variables: variables);
    //resp.then((value) {
    //print(resp.resp);
    final channelJson = json.decode(resp.resp);
    // Use cacheChannel so we never replace an existing instance — keeping
    // any event listeners the caller already attached intact.
    return cacheChannel(channelJson);
    //});
    //return null;
  }

  Future<Bridge> bridge(
      {String? name, String? bridgeId, List<String>? type}) async {
    var resp = await BridgesAPI.createOrUpdate(
        name: name, bridgeId: bridgeId, type: type);
    //print(resp.resp);
    final bridgeJson = jsonDecode(resp.resp);
    // Asterisk's createOrUpdate may return an existing bridge with the same
    // id — go through cacheBridge so we don't lose listeners on it.
    return cacheBridge(bridgeJson);
  }

  Future<Channel> externalMedia(
    Function(bool, Channel) callback, {
    required String app, //: string;
    dynamic variables, //?: Containers;
    required external_host, //: string;
    String? encapsulation, //?: string;
    String? transport, //?: string;
    String? connection_type, //?: string;
    required String format, //: string;
    String? direction, //?: string;
  }) async {
    var resp = await ChannelsApi.externalMedia(
        app: app,
        variables: variables,
        external_host: external_host,
        encapsulation: encapsulation,
        transport: transport,
        connection_type: connection_type,
        format: format,
        direction: direction);

    print("External media: ${resp.resp}");

    final channelJson = jsonDecode(resp.resp);
    return cacheChannel(channelJson);

    // resp.then((value) {
    //   if (value.statusCode == 200 || value.statusCode == 204)
    //     callback(false, this);
    //   else
    //     callback(true, this);
    // });
  }
}
