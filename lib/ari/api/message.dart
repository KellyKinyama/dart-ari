class Message {
  Message(String type) : type = type {}

  /// Indicates the type of this message.
  String type; //: string;

  /// The unique ID for the Asterisk instance that raised this event.
  String? asterisk_id; //?: string;
}
