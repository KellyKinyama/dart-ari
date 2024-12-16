import '../message.dart';

class Event extends Message {
  Event(String type) : super(type) {}
}

enum EventType {
  APILoadErrorEventType('APILoadError'),
  EventsEventType('Events'),
  MessageEventType('Message'),
  MissingParamsEventType('MissingParams'),
  EventEventType('Event'),
  ContactInfoEventType('ContactInfo'),
  PeerEventType('Peer'),
  DeviceStateChangedEventType('DeviceStateChanged'),
  PlaybackStartedEventType('PlaybackStarted'),
  PlaybackContinuingEventType('PlaybackContinuing'),
  PlaybackFinishedEventType('PlaybackFinished'),
  RecordingStartedEventType('RecordingStarted'),
  RecordingFinishedEventType('RecordingFinished'),
  RecordingFailedEventType('RecordingFailed'),
  ApplicationMoveFailedEventType('ApplicationMoveFailed'),
  ApplicationReplacedEventType('ApplicationReplaced'),
  BridgeCreatedEventType('BridgeCreated'),
  BridgeDestroyedEventType('BridgeDestroyed'),
  BridgeMergedEventType('BridgeMerged'),
  BridgeVideoSourceChangedEventType('BridgeVideoSourceChanged'),
  BridgeBlindTransferEventType('BridgeBlindTransfer'),
  BridgeAttendedTransferEventType('BridgeAttendedTransfer'),
  ChannelCreatedEventType('ChannelCreated'),
  ChannelDestroyedEventType('ChannelDestroyed'),
  ChannelEnteredBridgeEventType('ChannelEnteredBridge'),
  ChannelLeftBridgeEventType('ChannelLeftBridge'),
  ChannelStateChangeEventType('ChannelStateChange'),
  ChannelDtmfReceivedEventType('ChannelDtmfReceived'),
  ChannelDialplanEventType('ChannelDialplan'),
  ChannelCallerIdEventType('ChannelCallerId'),
  ChannelUsereventEventType('ChannelUserevent'),
  ChannelHangupRequestEventType('ChannelHangupRequest'),
  ChannelVarsetEventType('ChannelVarset'),
  ChannelHoldEventType('ChannelHold'),
  ChannelUnholdEventType('ChannelUnhold'),
  ChannelTalkingStartedEventType('ChannelTalkingStarted'),
  ChannelTalkingFinishedEventType('ChannelTalkingFinished'),
  ContactStatusChangeEventType('ContactStatusChange'),
  PeerStatusChangeEventType('PeerStatusChange'),
  EndpointStateChangeEventType('EndpointStateChange'),
  DialEventType('Dial'),
  StasisEndEventType('StasisEnd'),
  StasisStartEventType('StasisStart'),
  TextMessageReceivedEventType('TextMessageReceived'),
  ChannelConnectedLineEventType('ChannelConnectedLine');

  const EventType(this.StrValue);

  final String StrValue;
}
