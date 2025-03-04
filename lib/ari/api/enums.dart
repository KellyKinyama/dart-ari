import 'package:dart_ari/dart_ari.dart';

enum AgentState {
  LOGGEDIN,
  LOGGEDOUT,
  ONWITHDRAW,
  ONCONVERSATION,
  IDLE,
  WRAPPINGUP,
  ONPRIVATECALL,
  RINGING,
  UNKNOWN;

  factory AgentState.fromString(String state) {
    switch (state) {
      case "LOGGEDIN":
        return AgentState.LOGGEDIN;
      case "LOGGEDOUT":
        return AgentState.LOGGEDOUT;
      case "ONWITHDRAW":
        return AgentState.ONWITHDRAW;
      case "ONCONVERSATION":
        return AgentState.ONCONVERSATION;
      case "IDLE":
        return AgentState.IDLE;
      case "WRAPPINGUP":
        return AgentState.WRAPPINGUP;
      case "ONPRIVATECALL":
        return AgentState.ONPRIVATECALL;
      case "RINGING":
        return AgentState.RINGING;
      case "UNKNOWN":
        return AgentState.UNKNOWN;

      default:
        {
          throw "bad state: $state";
        }
    }
  }
}

Map<String, CallRecording> voiceRecords = {};
