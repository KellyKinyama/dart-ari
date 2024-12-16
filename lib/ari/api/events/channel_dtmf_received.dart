import '../channels.dart';
import 'event.dart';

class ChannelDtmfReceived extends Event {
  ChannelDtmfReceived(
      this.digit, this.duration_ms, this.channel, this.timestamp, this.json)
      : super('StasisEnd');

  /// DTMF digit received (0-9, A-E, # or *).
  String digit; //: string;

  /// Number of milliseconds DTMF was received.
  num duration_ms; //: number;

  /// The channel on which DTMF was received.
  Channel channel;

  DateTime timestamp;
  dynamic json;

  factory ChannelDtmfReceived.fromJson(dynamic json) {
    Channel channel = Channel.fromJson(json['channel']);

    DateTime timestamp = DateTime.parse(json['timestamp']);
    return ChannelDtmfReceived(json['digit'] as String,
        json['duration_ms'] as num, channel, timestamp, json as dynamic);
  }
}
