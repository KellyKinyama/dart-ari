class DialEvent {
  final String type;
  final DateTime timestamp;
  final String dialstatus;
  final String forward;
  final String dialstring;
  final Peer peer;
  final String asteriskId;
  final String application;

  DialEvent({
    required this.type,
    required this.timestamp,
    required this.dialstatus,
    required this.forward,
    required this.dialstring,
    required this.peer,
    required this.asteriskId,
    required this.application,
  });

  factory DialEvent.fromJson(Map<String, dynamic> json) {
    return DialEvent(
      type: json['type'],
      timestamp: DateTime.parse(json['timestamp']),
      dialstatus: json['dialstatus'] ?? '',
      forward: json['forward'] ?? '',
      dialstring: json['dialstring'],
      peer: Peer.fromJson(json['peer']),
      asteriskId: json['asterisk_id'],
      application: json['application'],
    );
  }
}

class Peer {
  final String id;
  final String name;
  final String state;
  final String protocolId;
  final Party caller;
  final Party connected;
  final String accountcode;
  final Dialplan dialplan;
  final DateTime creationTime;
  final String language;

  Peer({
    required this.id,
    required this.name,
    required this.state,
    required this.protocolId,
    required this.caller,
    required this.connected,
    required this.accountcode,
    required this.dialplan,
    required this.creationTime,
    required this.language,
  });

  factory Peer.fromJson(Map<String, dynamic> json) {
    return Peer(
      id: json['id'],
      name: json['name'],
      state: json['state'],
      protocolId: json['protocol_id'],
      caller: Party.fromJson(json['caller']),
      connected: Party.fromJson(json['connected']),
      accountcode: json['accountcode'] ?? '',
      dialplan: Dialplan.fromJson(json['dialplan']),
      creationTime: DateTime.parse(json['creationtime']),
      language: json['language'],
    );
  }
}

class Party {
  final String name;
  final String number;

  Party({
    required this.name,
    required this.number,
  });

  factory Party.fromJson(Map<String, dynamic> json) {
    return Party(
      name: json['name'] ?? '',
      number: json['number'] ?? '',
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
