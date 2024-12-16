import '../playbacks.dart';

import 'event.dart';

class PlaybackFinished extends Event {
  PlaybackFinished(this.playback, this.timestamp, this.json)
      : super('PlaybackFinished');
  /**
     * Channel.
     */
  DateTime timestamp;
  Playback playback; //: Channel;
  dynamic json;

  factory PlaybackFinished.fromJson(dynamic json) {
    Playback playback = Playback.fromJson(json['playback']);

    DateTime timestamp = DateTime.parse(json['timestamp']);
    return PlaybackFinished(playback, timestamp, json as dynamic);
  }
}
