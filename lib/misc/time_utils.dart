import 'dart:convert';

void main() {
  final jsonString = """
  {
    "type": "ChannelEnteredBridge",
    "timestamp": "2025-04-22T17:26:07.467+0200",
    "bridge": {
      "id": "65440fd3-991e-45e8-a92d-cea4f5991dd3",
      "technology": "holding_bridge",
      "bridge_type": "holding",
      "bridge_class": "stasis",
      "creator": "Stasis",
      "name": "",
      "channels": ["1745335565.8964"],
      "creationtime": "2025-04-22T17:26:05.323+0200",
      "video_mode": "talker"
    },
    "channel": {
      "id": "1745335565.8964",
      "name": "PJSIP/mytrunk-0000051c",
      "state": "Up",
      "protocol_id": "4c02827b6ff6cc3023e7767b7d0546db@10.44.0.56:5060",
      "caller": {"name": "", "number": "00260972462922"},
      "connected": {"name": "", "number": ""},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "6003",
        "priority": 2,
        "app_name": "Stasis",
        "app_data": "hello"
      },
      "creationtime": "2025-04-22T17:26:05.072+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  }
  """;

  // First, parse the JSON string into a Dart Map

  final Map<String, dynamic> data = json.decode(jsonString);

  // Extract the time strings
  final String timestampString = data['timestamp'];
  final String bridgeCreationTimeString = data['bridge']['creationtime'];
  final String channelCreationTimeString = data['channel']['creationtime'];

  // Convert to DateTime objects
  final DateTime timestamp = DateTime.parse(timestampString);
  final DateTime bridgeCreationTime = DateTime.parse(bridgeCreationTimeString);
  final DateTime channelCreationTime =
      DateTime.parse(channelCreationTimeString);

  // Print the DateTime objects
  print('Timestamp: $timestamp');
  print('Bridge Creation Time: $bridgeCreationTime');
  print('Channel Creation Time: $channelCreationTime');

  // You can also access properties of the DateTime object
  print('Timestamp Year: ${timestamp.year}');
  print('Timestamp Month: ${timestamp.month}');
  print('Timestamp Day: ${timestamp.day}');
  print(
      'Timestamp Hour (UTC): ${timestamp.toUtc().hour}'); // Convert to UTC first for consistent hour
  print('Timestamp Hour (Local): ${timestamp.hour}');
  print('Timestamp Time Zone Offset: ${timestamp.timeZoneOffset}');
}
