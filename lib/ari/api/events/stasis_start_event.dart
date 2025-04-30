class StasisStartEvent {
  final String type;
  final DateTime timestamp;
  final List<String> args;
  final Channel channel;
  final String asteriskId;
  final String application;

  StasisStartEvent({
    required this.type,
    required this.timestamp,
    required this.args,
    required this.channel,
    required this.asteriskId,
    required this.application,
  });

  factory StasisStartEvent.fromJson(Map<String, dynamic> json) {
    return StasisStartEvent(
      type: json['type'],
      timestamp: DateTime.parse(json['timestamp']),
      args: List<String>.from(json['args']),
      channel: Channel.fromJson(json['channel']),
      asteriskId: json['asterisk_id'],
      application: json['application'],
    );
  }
}

class Channel {
  final String id;
  final String name;
  final String state;
  final String protocolId;
  final Caller caller;
  final Caller connected;
  final String accountCode;
  final Dialplan dialplan;
  final DateTime creationTime;
  final String language;

  Channel({
    required this.id,
    required this.name,
    required this.state,
    required this.protocolId,
    required this.caller,
    required this.connected,
    required this.accountCode,
    required this.dialplan,
    required this.creationTime,
    required this.language,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'],
      name: json['name'],
      state: json['state'],
      protocolId: json['protocol_id'],
      caller: Caller.fromJson(json['caller']),
      connected: Caller.fromJson(json['connected']),
      accountCode: json['accountcode'],
      dialplan: Dialplan.fromJson(json['dialplan']),
      creationTime: DateTime.parse(json['creationtime']),
      language: json['language'],
    );
  }
}

class Caller {
  final String name;
  final String number;

  Caller({required this.name, required this.number});

  factory Caller.fromJson(Map<String, dynamic> json) {
    return Caller(
      name: json['name'],
      number: json['number'],
    );
  }
}

class Dialplan {
  final String context;
  final String exten;
  final int priority;
  final String appName;
  final String appData;

  Dialplan({
    required this.context,
    required this.exten,
    required this.priority,
    required this.appName,
    required this.appData,
  });

  factory Dialplan.fromJson(Map<String, dynamic> json) {
    return Dialplan(
      context: json['context'],
      exten: json['exten'],
      priority: json['priority'],
      appName: json['app_name'],
      appData: json['app_data'],
    );
  }
}
