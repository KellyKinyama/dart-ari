import '../channels.dart';
import 'event.dart';

class ChannelStateChange extends Event {
  ChannelStateChange(this.channel, this.timestamp, this.json)
      : super('ChannelStateChange');

  /// Channel.
  DateTime timestamp;
  Channel channel; //: Channel;
  dynamic json;

  factory ChannelStateChange.fromJson(dynamic json, {Channel? channel}) {
    Channel newChannel = Channel.fromJson(json['channel'], channel: channel);

    DateTime timestamp = DateTime.parse(json['timestamp']);
    return ChannelStateChange(newChannel, timestamp, json as dynamic);
  }
}
