import '../channels.dart';
import 'event.dart';

class StasisEnd extends Event {
  StasisEnd(this.channel, this.timestamp, this.json) : super('StasisEnd');

  /// Channel.
  DateTime timestamp;
  Channel channel; //: Channel;
  dynamic json;

  factory StasisEnd.fromJson(dynamic json, {Channel? channel}) {
    Channel newChannel = Channel.fromJson(json['channel'], channel: channel);
    DateTime timestamp = DateTime.parse(json['timestamp']);

    return StasisEnd(newChannel, timestamp, json as dynamic);
  }
}
