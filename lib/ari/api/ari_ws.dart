part of 'ari.dart';

extension ARIPart1 on ARI {
  void listen(WebSocket ws) {
    Command? command;
    final env = DotEnv(includePlatformEnvironment: true)..load();
    final serverIp = env['SERVER_IP']!;
    RedisConnection().connect(serverIp, 6379).then((connection) {
      connection.send_object(["AUTH", "zsco@123deraboof"]).then((var response) {
        //print(response);
        command = connection;
      });
      // connection.send_object(["PUBLISH", "monkey", onData]);
    });

    ws.listen((onData) {
      // Guard the Redis publish: on WS reconnect (ApplicationReplaced etc.)
      // events can arrive before Redis auth completes; silently skip publish
      // in that window rather than crashing the whole recorder.
      command?.send_object(["PUBLISH", "monkey", onData]);

      var e = json.decode(onData);

      print("Event type: ${e['type']}");

      switch (e['type']) {
        case 'StasisStart':
          {
            StasisStart stasisStartEvent = StasisStart.fromJson(e);
            Channel ch = channelFactory(e);
            stasisStart(stasisStartEvent, ch);
            ch.emit(e['type'], (stasisStartEvent, ch));
          }

        case 'StasisEnd':
          {
            StasisEnd stasisEndEvent = StasisEnd.fromJson(e);
            Channel ch = channelFactory(e);
            stasisEnd(stasisEndEvent, ch);
            ch.emit(e['type'], (stasisEndEvent, ch));

            setTimeout(() {
              //print("Removing channel: ${ch.id} from stasis app");
              channels.remove(ch.id);
            }, 5000);
          }

        case 'ChannelDestroyed':
          {
            ChannelDestroyed channelDestroyedEvent =
                ChannelDestroyed.fromJson(e);
            Channel ch = channelFactory(e);

            ch.emit(e['type'], (channelDestroyedEvent, ch));

            setTimeout(() {
              //print("Removing channel: ${ch.id} from stasis app");
              channels.remove(ch.id);
            }, 10000);
          }
        case 'ChannelStateChange':
          {
            ChannelStateChange channelStateChangeEvent =
                ChannelStateChange.fromJson(e);
            Channel ch = channelFactory(e);

            ch.emit(e['type'], (channelStateChangeEvent, ch));
          }

        case 'ChannelDtmfReceived':
          {}

        case 'PlaybackFinished':
          {}
        default:
          {
            // print("Unhandled event: ${e['type']}");
          }
      }
    }, onError: (err, stackTrace) async {
      print("Error: $err, stacktrace: $stackTrace");
      await Future.delayed(Duration(seconds: 5));
      await connect();
    }, onDone: () async {
      print("Websocket closed");
      await Future.delayed(Duration(seconds: 5));
      await connect();
      // Reconnect logic can be added here if needed
    });
    print("Connected to websocket");
  }

  Channel channelFactory(dynamic jsonEventData) {
    // Single source of truth for caching channels by id. Guarantees one
    // instance per channel id so event listeners attached anywhere in the
    // codebase keep firing for subsequent WS events on the same channel.
    return cacheChannel(jsonEventData['channel']);
  }

  void updateChannel(Channel ch, jsonChannelData) {
    //print(json);
    // final creationtime = DateTime.parse(json['creationtime']); // 8:18pm
    // var caller = CallerID.fromJson(json['caller']);
    print("Updating channel: ${ch.id} in stasis app");

    ch.id = jsonChannelData['id'];
    ch.name = jsonChannelData['name'];
    ch.accountcode = jsonChannelData['accountcode'];
    ch.state = jsonChannelData['state'];
    ch.dialplan = jsonChannelData['dialplan'];
    ch.channelvars = jsonChannelData['channelvars'];
  }
}
