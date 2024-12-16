import '../Channels.dart';
import 'event.dart';

class ChannelDestroyed extends Event {
  ChannelDestroyed(
      this.cause, this.cause_txt, this.channel, this.timestamp, this.json)
      : super("ChannelDestroyed");

  /// Integer representation of the cause of the hangup.
  num cause; //: number;

  /// Text representation of the cause of the hangup.
  String cause_txt; //: string;

  /// Channel.
  DateTime timestamp;
  Channel channel; //: Channel;

  dynamic json;

  factory ChannelDestroyed.fromJson(dynamic json, {Channel? channel}) {
    Channel newChannel = Channel.fromJson(json['channel'], channel: channel);

    DateTime timestamp = DateTime.parse(json['timestamp']);
    return ChannelDestroyed(json['cause'] as num, json['cause_txt'] as String,
        newChannel, timestamp, json as dynamic);
  }
}
