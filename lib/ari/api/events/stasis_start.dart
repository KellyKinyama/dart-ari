import 'event.dart';

import '../Channels.dart';

class StasisStart extends Event {
  StasisStart(this.args, this.timestamp, this.channel, this.json)
      : super("StasisStart");

  /// Arguments to the application.
  dynamic args; //: string | string[];

  /// Channel.
  Channel channel;

  /// Replace_channel.
  DateTime timestamp;
  Channel? replace_channel;
  dynamic json;

  factory StasisStart.fromJson(dynamic json, {Channel? channel}) {
    Channel newChannel = Channel.fromJson(json['channel'], channel: channel);
    DateTime timestamp = DateTime.parse(json['timestamp']);
    return StasisStart(
        json['args'] as dynamic, timestamp, newChannel, json as dynamic);
  }

  // @override
  // String toString() {
  //   return json;
  // }
}
