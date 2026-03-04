
Agent PJSIP/8708 is now truly available in memory.
Event type: ChannelStateChange
Channel id: 1770900866.1694
Updating channel: 1770900866.1694 in stasis app
Event type: Dial
Event type: ChannelVarset
Event type: StasisStart
Channel id: 1770900866.1694
Updating channel: 1770900866.1694 in stasis app
Channel 1770900866.1694 entered application
Unhandled exception:
Exception: Incoming channel: 1770900858.1637 was deleted
#0      originate.<anonymous closure> (file:///c:/www/dart/dart-ari/bin/queue_app_main.dart:312)
#1      EventListener.call (package:events_emitter/listener.dart:61)
#2      EventEmitter.emitEvent (package:events_emitter/emitters/event_emitter.dart:93)
#3      EventEmitter.emit (package:events_emitter/emitters/event_emitter.dart:113)
#4      ARIPart1.listen.<anonymous closure> (package:dart_ari/ari/api/ari_ws.dart:37)
#5      _RootZone.runUnaryGuarded (dart:async/zone.dart:891)
#6      _BufferingStreamSubscription._sendData (dart:async/stream_impl.dart:381)
#7      _BufferingStreamSubscription._add (dart:async/stream_impl.dart:312)
#8      _SyncStreamControllerDispatch._sendData (dart:async/stream_controller.dart:798)
#9      _StreamController._add (dart:async/stream_controller.dart:663)
#10     _StreamController.add (dart:async/stream_controller.dart:618)
#11     new _WebSocketImpl._fromSocket.<anonymous closure> (dart:_http/websocket_impl.dart:1252)
#12     _RootZone.runUnaryGuarded (dart:async/zone.dart:891)
#13     _BufferingStreamSubscription._sendData (dart:async/stream_impl.dart:381)
#14     _BufferingStreamSubscription._add (dart:async/stream_impl.dart:312)
#15     _SinkTransformerStreamSubscription._add (dart:async/stream_transformers.dart:67)
#16     _EventSinkWrapper.add (dart:async/stream_transformers.dart:13)
#17     _WebSocketProtocolTransformer._messageFrameEnd (dart:_http/websocket_impl.dart:348)
#18     _WebSocketProtocolTransformer.add (dart:_http/websocket_impl.dart:238)
#19     _SinkTransformerStreamSubscription._handleData (dart:async/stream_transformers.dart:115)
#20     _RootZone.runUnaryGuarded (dart:async/zone.dart:891)
#21     _BufferingStreamSubscription._sendData (dart:async/stream_impl.dart:381)
#22     _BufferingStreamSubscription._add (dart:async/stream_impl.dart:312)
#23     _SyncStreamControllerDispatch._sendData (dart:async/stream_controller.dart:798)
#24     _StreamController._add (dart:async/stream_controller.dart:663)
#25     _StreamController.add (dart:async/stream_controller.dart:618)
#26     _Socket._onData (dart:io-patch/socket_patch.dart:2874)
#27     _RootZone.runUnaryGuarded (dart:async/zone.dart:891)
#28     _BufferingStreamSubscription._sendData (dart:async/stream_impl.dart:381)
#29     _BufferingStreamSubscription._add (dart:async/stream_impl.dart:312)
#30     _SyncStreamControllerDispatch._sendData (dart:async/stream_controller.dart:798)
#31     _StreamController._add (dart:async/stream_controller.dart:663)
#32     _StreamController.add (dart:async/stream_controller.dart:618)
#33     new _RawSocket.<anonymous closure> (dart:io-patch/socket_patch.dart:2312)
#34     _NativeSocket.issueReadEvent.issue (dart:io-patch/socket_patch.dart:1647)
#35     _microtaskLoop (dart:async/schedule_microtask.dart:40)
#36     _startMicrotaskLoop (dart:async/schedule_microtask.dart:49)
#37     _runPendingImmediateCallback (dart:isolate-patch/isolate_patch.dart:127)
#38     _RawReceivePort._handleMessage (dart:isolate-patch/isolate_patch.dart:194)
2026-02-12_14-54-29: Application **CRASHED** or exited with status: 255