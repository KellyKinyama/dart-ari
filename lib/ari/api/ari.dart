import 'dart:io';
import 'package:events_emitter/events_emitter.dart';

import '../config/ari_config.dart';
import '../config/constants.dart';
import 'bridges.dart';
import 'channels.dart';
import 'device_state.dart';
import 'endpoints.dart';
import 'globals.dart';
import 'playbacks.dart';

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
  }

  factory ARI.fromConfigs() {
    Config config = Config();
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

  //Params params = Params('asterisk', 'asterisk', '10.44.0.55');

  // String username;
  // String password;
  // String baseUrl;
  // HttpClient client = HttpClient();

  void stasisStart(stasisStart, channel) {
    emit('StasisStart', (stasisStart, channel));
  }

  void stasisEnd(stasisEnd, channel) {
    emit('StasisEnd', (stasisEnd, channel));
  }

  void channelDestroyed(channelDestroyed, channel) {
    emit('channelDestroyed', (channelDestroyed, channel));
  }

  void channelStateChange(channelStateChange, channel) {
    emit('ChannelStateChange', (channelStateChange, channel));
  }

  Future<WebSocket> connect() async {
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
    return ws;
  }
}
