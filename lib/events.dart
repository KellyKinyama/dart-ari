final events = [
  {
    "type": "StasisStart",
    "timestamp": "2025-04-22T17:26:05.072+0200",
    "args": [],
    "channel": {
      "id": "1745335565.8964",
      "name": "PJSIP/mytrunk-0000051c",
      "state": "Ring",
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
  },
  {
    "type": "ChannelStateChange",
    "timestamp": "2025-04-22T17:26:05.234+0200",
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
  },
  {
    "type": "PlaybackStarted",
    "timestamp": "2025-04-22T17:26:05.286+0200",
    "playback": {
      "id": "1b597530-1f8e-11f0-a551-8dc1db2598bf",
      "media_uri": "sound:vm-dialout",
      "target_uri": "channel:1745335565.8964",
      "language": "en",
      "state": "playing"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "PlaybackFinished",
    "timestamp": "2025-04-22T17:26:07.467+0200",
    "playback": {
      "id": "1b597530-1f8e-11f0-a551-8dc1db2598bf",
      "media_uri": "sound:vm-dialout",
      "target_uri": "channel:1745335565.8964",
      "language": "en",
      "state": "done"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
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
  },
  {
    "variable": "RTPAUDIOQOS",
    "value":
        "ssrc=80413220;themssrc=23012889;lp=0;rxjitter=0.000125;rxcount=804;txjitter=0.000125;txcount=812;rlp=0;rtt=0.000854;rxmes=88.077270;txmes=88.076186",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:26:21.534+0200",
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
  },
  {
    "variable": "RTPAUDIOQOSJITTER",
    "value":
        "minrxjitter=000.000000;maxrxjitter=000.001000;avgrxjitter=000.000174;stdevrxjitter=000.000168;mintxjitter=000.000000;maxtxjitter=000.000250;avgtxjitter=000.000125;stdevtxjitter=000.000102;",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:26:21.534+0200",
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
  },
  {
    "variable": "RTPAUDIOQOSLOSS",
    "value":
        "  minrxlost=000.000000;  maxrxlost=000.000000;  avgrxlost=000.000000;  stdevrxlost=000.000000;  mintxlost=000.000000;  maxtxlost=000.000000;  avgtxlost=000.000000;  stdevtxlost=000.000000;",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:26:21.534+0200",
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
  },
  {
    "variable": "RTPAUDIOQOSRTT",
    "value":
        "     minrtt=000.000854;     maxrtt=000.001327;     avgrtt=000.001073;     stdevrtt=000.000195;",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:26:21.534+0200",
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
  },
  {
    "variable": "RTPAUDIOQOSMES",
    "value":
        "   minrxmes=088.074749;   maxrxmes=088.087887;   avgrxmes=088.079607;   stdevrxmes=000.000168;   mintxmes=088.074749;   maxtxmes=088.077270;   avgtxmes=088.076068;   stdevtxmes=000.001033;",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:26:21.534+0200",
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
  },
  {
    "cause": 16,
    "type": "ChannelHangupRequest",
    "timestamp": "2025-04-22T17:26:21.534+0200",
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
  },
  {
    "type": "ChannelLeftBridge",
    "timestamp": "2025-04-22T17:26:21.538+0200",
    "bridge": {
      "id": "65440fd3-991e-45e8-a92d-cea4f5991dd3",
      "technology": "holding_bridge",
      "bridge_type": "holding",
      "bridge_class": "stasis",
      "creator": "Stasis",
      "name": "",
      "channels": ["1745335565.8968"],
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
  },
  {
    "type": "StasisEnd",
    "timestamp": "2025-04-22T17:26:21.539+0200",
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
  },
  {
    "type": "StasisStart",
    "timestamp": "2025-04-22T17:28:24.283+0200",
    "args": [],
    "channel": {
      "id": "1745335704.8974",
      "name": "PJSIP/mytrunk-0000051d",
      "state": "Ring",
      "protocol_id": "714737594818e7a134e89a154edc34f1@10.44.0.56:5060",
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
      "creationtime": "2025-04-22T17:28:24.282+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "ChannelStateChange",
    "timestamp": "2025-04-22T17:28:24.559+0200",
    "channel": {
      "id": "1745335704.8974",
      "name": "PJSIP/mytrunk-0000051d",
      "state": "Up",
      "protocol_id": "714737594818e7a134e89a154edc34f1@10.44.0.56:5060",
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
      "creationtime": "2025-04-22T17:28:24.282+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "PlaybackStarted",
    "timestamp": "2025-04-22T17:28:24.666+0200",
    "playback": {
      "id": "6e6d9da0-1f8e-11f0-a551-8dc1db2598bf",
      "media_uri": "sound:vm-dialout",
      "target_uri": "channel:1745335704.8974",
      "language": "en",
      "state": "playing"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "PlaybackFinished",
    "timestamp": "2025-04-22T17:28:26.847+0200",
    "playback": {
      "id": "6e6d9da0-1f8e-11f0-a551-8dc1db2598bf",
      "media_uri": "sound:vm-dialout",
      "target_uri": "channel:1745335704.8974",
      "language": "en",
      "state": "done"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "ChannelEnteredBridge",
    "timestamp": "2025-04-22T17:28:26.847+0200",
    "bridge": {
      "id": "65440fd3-991e-45e8-a92d-cea4f5991dd3",
      "technology": "holding_bridge",
      "bridge_type": "holding",
      "bridge_class": "stasis",
      "creator": "Stasis",
      "name": "",
      "channels": ["1745335704.8974"],
      "creationtime": "2025-04-22T17:26:05.323+0200",
      "video_mode": "talker"
    },
    "channel": {
      "id": "1745335704.8974",
      "name": "PJSIP/mytrunk-0000051d",
      "state": "Up",
      "protocol_id": "714737594818e7a134e89a154edc34f1@10.44.0.56:5060",
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
      "creationtime": "2025-04-22T17:28:24.282+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "Dial",
    "timestamp": "2025-04-22T17:28:28.133+0200",
    "dialstatus": "",
    "forward": "",
    "dialstring": "6004",
    "peer": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Down",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "AppDial2",
        "app_data": "(Outgoing Line)"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "ChannelStateChange",
    "timestamp": "2025-04-22T17:28:28.206+0200",
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Ringing",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "AppDial2",
        "app_data": "(Outgoing Line)"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "Dial",
    "timestamp": "2025-04-22T17:28:28.206+0200",
    "dialstatus": "RINGING",
    "forward": "",
    "dialstring": "6004",
    "peer": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Ringing",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "AppDial2",
        "app_data": "(Outgoing Line)"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "ChannelStateChange",
    "timestamp": "2025-04-22T17:28:33.265+0200",
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "AppDial2",
        "app_data": "(Outgoing Line)"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "Dial",
    "timestamp": "2025-04-22T17:28:33.265+0200",
    "dialstatus": "ANSWER",
    "forward": "",
    "dialstring": "6004",
    "peer": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "AppDial2",
        "app_data": "(Outgoing Line)"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "STASISSTATUS",
    "value": "",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:33.266+0200",
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello,dialed,PJSIP/6004,channel1745335704.8974"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "StasisStart",
    "timestamp": "2025-04-22T17:28:33.266+0200",
    "args": ["dialed", "PJSIP/6004", "channel1745335704.8974"],
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello,dialed,PJSIP/6004,channel1745335704.8974"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "ChannelLeftBridge",
    "timestamp": "2025-04-22T17:28:33.292+0200",
    "bridge": {
      "id": "65440fd3-991e-45e8-a92d-cea4f5991dd3",
      "technology": "holding_bridge",
      "bridge_type": "holding",
      "bridge_class": "stasis",
      "creator": "Stasis",
      "name": "",
      "channels": [],
      "creationtime": "2025-04-22T17:26:05.323+0200",
      "video_mode": "talker"
    },
    "channel": {
      "id": "1745335704.8974",
      "name": "PJSIP/mytrunk-0000051d",
      "state": "Up",
      "protocol_id": "714737594818e7a134e89a154edc34f1@10.44.0.56:5060",
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
      "creationtime": "2025-04-22T17:28:24.282+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "Dial",
    "timestamp": "2025-04-22T17:28:33.390+0200",
    "dialstatus": "",
    "forward": "",
    "dialstring": "10.44.0.70:47029/c(alaw)",
    "peer": {
      "id": "1745335713.8986",
      "name": "UnicastRTP/10.44.0.70:47029-0x7f13282ca9e0",
      "state": "Down",
      "protocol_id": "",
      "caller": {"name": "", "number": ""},
      "connected": {"name": "", "number": ""},
      "accountcode": "",
      "dialplan": {
        "context": "default",
        "exten": "s",
        "priority": 1,
        "app_name": "AppDial2",
        "app_data": "(Outgoing Line)"
      },
      "creationtime": "2025-04-22T17:28:33.390+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "ChannelStateChange",
    "timestamp": "2025-04-22T17:28:33.390+0200",
    "channel": {
      "id": "1745335713.8986",
      "name": "UnicastRTP/10.44.0.70:47029-0x7f13282ca9e0",
      "state": "Up",
      "protocol_id": "",
      "caller": {"name": "", "number": ""},
      "connected": {"name": "", "number": ""},
      "accountcode": "",
      "dialplan": {
        "context": "default",
        "exten": "s",
        "priority": 1,
        "app_name": "AppDial2",
        "app_data": "(Outgoing Line)"
      },
      "creationtime": "2025-04-22T17:28:33.390+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "Dial",
    "timestamp": "2025-04-22T17:28:33.390+0200",
    "dialstatus": "ANSWER",
    "forward": "",
    "dialstring": "10.44.0.70:47029/c(alaw)",
    "peer": {
      "id": "1745335713.8986",
      "name": "UnicastRTP/10.44.0.70:47029-0x7f13282ca9e0",
      "state": "Up",
      "protocol_id": "",
      "caller": {"name": "", "number": ""},
      "connected": {"name": "", "number": ""},
      "accountcode": "",
      "dialplan": {
        "context": "default",
        "exten": "s",
        "priority": 1,
        "app_name": "AppDial2",
        "app_data": "(Outgoing Line)"
      },
      "creationtime": "2025-04-22T17:28:33.390+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "STASISSTATUS",
    "value": "",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:33.390+0200",
    "channel": {
      "id": "1745335713.8986",
      "name": "UnicastRTP/10.44.0.70:47029-0x7f13282ca9e0",
      "state": "Up",
      "protocol_id": "",
      "caller": {"name": "", "number": ""},
      "connected": {"name": "", "number": ""},
      "accountcode": "",
      "dialplan": {
        "context": "default",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello"
      },
      "creationtime": "2025-04-22T17:28:33.390+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "StasisStart",
    "timestamp": "2025-04-22T17:28:33.390+0200",
    "args": [],
    "channel": {
      "id": "1745335713.8986",
      "name": "UnicastRTP/10.44.0.70:47029-0x7f13282ca9e0",
      "state": "Up",
      "protocol_id": "",
      "caller": {"name": "", "number": ""},
      "connected": {"name": "", "number": ""},
      "accountcode": "",
      "dialplan": {
        "context": "default",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello"
      },
      "creationtime": "2025-04-22T17:28:33.390+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "ChannelEnteredBridge",
    "timestamp": "2025-04-22T17:28:33.475+0200",
    "bridge": {
      "id": "ec34542e-e16b-4955-bc48-37f7c347bfc5",
      "technology": "simple_bridge",
      "bridge_type": "mixing",
      "bridge_class": "stasis",
      "creator": "Stasis",
      "name": "",
      "channels": ["1745335704.8974"],
      "creationtime": "2025-04-22T17:28:33.362+0200",
      "video_mode": "talker"
    },
    "channel": {
      "id": "1745335704.8974",
      "name": "PJSIP/mytrunk-0000051d",
      "state": "Up",
      "protocol_id": "714737594818e7a134e89a154edc34f1@10.44.0.56:5060",
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
      "creationtime": "2025-04-22T17:28:24.282+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "ChannelEnteredBridge",
    "timestamp": "2025-04-22T17:28:33.476+0200",
    "bridge": {
      "id": "ec34542e-e16b-4955-bc48-37f7c347bfc5",
      "technology": "simple_bridge",
      "bridge_type": "mixing",
      "bridge_class": "stasis",
      "creator": "Stasis",
      "name": "",
      "channels": ["1745335704.8974", "1745335708.8978"],
      "creationtime": "2025-04-22T17:28:33.362+0200",
      "video_mode": "talker"
    },
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello,dialed,PJSIP/6004,channel1745335704.8974"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "BRIDGEPEER",
    "value": "PJSIP/6004-0000051f",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:33.476+0200",
    "channel": {
      "id": "1745335704.8974",
      "name": "PJSIP/mytrunk-0000051d",
      "state": "Up",
      "protocol_id": "714737594818e7a134e89a154edc34f1@10.44.0.56:5060",
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
      "creationtime": "2025-04-22T17:28:24.282+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "BRIDGEPVTCALLID",
    "value": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:33.476+0200",
    "channel": {
      "id": "1745335704.8974",
      "name": "PJSIP/mytrunk-0000051d",
      "state": "Up",
      "protocol_id": "714737594818e7a134e89a154edc34f1@10.44.0.56:5060",
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
      "creationtime": "2025-04-22T17:28:24.282+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "BRIDGEPEER",
    "value": "PJSIP/mytrunk-0000051d",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:33.476+0200",
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello,dialed,PJSIP/6004,channel1745335704.8974"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "BRIDGEPVTCALLID",
    "value": "714737594818e7a134e89a154edc34f1@10.44.0.56:5060",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:33.476+0200",
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello,dialed,PJSIP/6004,channel1745335704.8974"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "ChannelConnectedLine",
    "timestamp": "2025-04-22T17:28:33.477+0200",
    "channel": {
      "id": "1745335704.8974",
      "name": "PJSIP/mytrunk-0000051d",
      "state": "Up",
      "protocol_id": "714737594818e7a134e89a154edc34f1@10.44.0.56:5060",
      "caller": {"name": "", "number": "00260972462922"},
      "connected": {"name": "Conrad de Wet", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "6003",
        "priority": 2,
        "app_name": "Stasis",
        "app_data": "hello"
      },
      "creationtime": "2025-04-22T17:28:24.282+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "ChannelEnteredBridge",
    "timestamp": "2025-04-22T17:28:33.478+0200",
    "bridge": {
      "id": "ec34542e-e16b-4955-bc48-37f7c347bfc5",
      "technology": "simple_bridge",
      "bridge_type": "mixing",
      "bridge_class": "stasis",
      "creator": "Stasis",
      "name": "",
      "channels": ["1745335704.8974", "1745335708.8978", "1745335713.8986"],
      "creationtime": "2025-04-22T17:28:33.362+0200",
      "video_mode": "talker"
    },
    "channel": {
      "id": "1745335713.8986",
      "name": "UnicastRTP/10.44.0.70:47029-0x7f13282ca9e0",
      "state": "Up",
      "protocol_id": "",
      "caller": {"name": "", "number": ""},
      "connected": {"name": "", "number": ""},
      "accountcode": "",
      "dialplan": {
        "context": "default",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello"
      },
      "creationtime": "2025-04-22T17:28:33.390+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "BRIDGEPEER",
    "value": "PJSIP/mytrunk-0000051d,PJSIP/6004-0000051f",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:33.478+0200",
    "channel": {
      "id": "1745335713.8986",
      "name": "UnicastRTP/10.44.0.70:47029-0x7f13282ca9e0",
      "state": "Up",
      "protocol_id": "",
      "caller": {"name": "", "number": ""},
      "connected": {"name": "", "number": ""},
      "accountcode": "",
      "dialplan": {
        "context": "default",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello"
      },
      "creationtime": "2025-04-22T17:28:33.390+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "BRIDGEPEER",
    "value": "UnicastRTP/10.44.0.70:47029-0x7f13282ca9e0,PJSIP/6004-0000051f",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:33.478+0200",
    "channel": {
      "id": "1745335704.8974",
      "name": "PJSIP/mytrunk-0000051d",
      "state": "Up",
      "protocol_id": "714737594818e7a134e89a154edc34f1@10.44.0.56:5060",
      "caller": {"name": "", "number": "00260972462922"},
      "connected": {"name": "Conrad de Wet", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "6003",
        "priority": 2,
        "app_name": "Stasis",
        "app_data": "hello"
      },
      "creationtime": "2025-04-22T17:28:24.282+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "BRIDGEPVTCALLID",
    "value": "",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:33.478+0200",
    "channel": {
      "id": "1745335704.8974",
      "name": "PJSIP/mytrunk-0000051d",
      "state": "Up",
      "protocol_id": "714737594818e7a134e89a154edc34f1@10.44.0.56:5060",
      "caller": {"name": "", "number": "00260972462922"},
      "connected": {"name": "Conrad de Wet", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "6003",
        "priority": 2,
        "app_name": "Stasis",
        "app_data": "hello"
      },
      "creationtime": "2025-04-22T17:28:24.282+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "BRIDGEPEER",
    "value":
        "UnicastRTP/10.44.0.70:47029-0x7f13282ca9e0,PJSIP/mytrunk-0000051d",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:33.478+0200",
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello,dialed,PJSIP/6004,channel1745335704.8974"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "BRIDGEPVTCALLID",
    "value": "",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:33.478+0200",
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello,dialed,PJSIP/6004,channel1745335704.8974"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "RTPAUDIOQOS",
    "value":
        "ssrc=412479622;themssrc=171055185;lp=0;rxjitter=0.002250;rxcount=426;txjitter=0.000875;txcount=420;rlp=0;rtt=0.019515;rxmes=87.890996;txmes=88.087887",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:41.861+0200",
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello,dialed,PJSIP/6004,channel1745335704.8974"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "RTPAUDIOQOSJITTER",
    "value":
        "minrxjitter=000.000125;maxrxjitter=000.007500;avgrxjitter=000.001221;stdevrxjitter=000.001036;mintxjitter=000.002000;maxtxjitter=000.002250;avgtxjitter=000.002125;stdevtxjitter=000.000125;",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:41.861+0200",
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello,dialed,PJSIP/6004,channel1745335704.8974"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "RTPAUDIOQOSLOSS",
    "value":
        "  minrxlost=000.000000;  maxrxlost=000.000000;  avgrxlost=000.000000;  stdevrxlost=000.000000;  mintxlost=000.000000;  maxtxlost=000.000000;  avgtxlost=000.000000;  stdevtxlost=000.000000;",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:41.861+0200",
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello,dialed,PJSIP/6004,channel1745335704.8974"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "RTPAUDIOQOSRTT",
    "value":
        "     minrtt=000.019515;     maxrtt=000.019515;     avgrtt=000.019515;     stdevrtt=000.000000;",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:41.861+0200",
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello,dialed,PJSIP/6004,channel1745335704.8974"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "RTPAUDIOQOSMES",
    "value":
        "   minrxmes=088.087887;   maxrxmes=088.087887;   avgrxmes=088.087887;   stdevrxmes=000.001036;   mintxmes=087.890996;   maxtxmes=088.087887;   avgtxmes=087.989442;   stdevtxmes=000.098446;",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:41.861+0200",
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello,dialed,PJSIP/6004,channel1745335704.8974"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "cause": 16,
    "type": "ChannelHangupRequest",
    "timestamp": "2025-04-22T17:28:41.861+0200",
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello,dialed,PJSIP/6004,channel1745335704.8974"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "BRIDGEPEER",
    "value": "",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:41.862+0200",
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello,dialed,PJSIP/6004,channel1745335704.8974"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "ChannelLeftBridge",
    "timestamp": "2025-04-22T17:28:41.862+0200",
    "bridge": {
      "id": "ec34542e-e16b-4955-bc48-37f7c347bfc5",
      "technology": "softmix",
      "bridge_type": "mixing",
      "bridge_class": "stasis",
      "creator": "Stasis",
      "name": "",
      "channels": ["1745335704.8974", "1745335713.8986"],
      "creationtime": "2025-04-22T17:28:33.362+0200",
      "video_mode": "talker"
    },
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello,dialed,PJSIP/6004,channel1745335704.8974"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "BRIDGEPEER",
    "value": "PJSIP/mytrunk-0000051d",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:41.862+0200",
    "channel": {
      "id": "1745335713.8986",
      "name": "UnicastRTP/10.44.0.70:47029-0x7f13282ca9e0",
      "state": "Up",
      "protocol_id": "",
      "caller": {"name": "", "number": ""},
      "connected": {"name": "", "number": ""},
      "accountcode": "",
      "dialplan": {
        "context": "default",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello"
      },
      "creationtime": "2025-04-22T17:28:33.390+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "BRIDGEPVTCALLID",
    "value": "714737594818e7a134e89a154edc34f1@10.44.0.56:5060",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:41.862+0200",
    "channel": {
      "id": "1745335713.8986",
      "name": "UnicastRTP/10.44.0.70:47029-0x7f13282ca9e0",
      "state": "Up",
      "protocol_id": "",
      "caller": {"name": "", "number": ""},
      "connected": {"name": "", "number": ""},
      "accountcode": "",
      "dialplan": {
        "context": "default",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello"
      },
      "creationtime": "2025-04-22T17:28:33.390+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "BRIDGEPEER",
    "value": "UnicastRTP/10.44.0.70:47029-0x7f13282ca9e0",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:41.862+0200",
    "channel": {
      "id": "1745335704.8974",
      "name": "PJSIP/mytrunk-0000051d",
      "state": "Up",
      "protocol_id": "714737594818e7a134e89a154edc34f1@10.44.0.56:5060",
      "caller": {"name": "", "number": "00260972462922"},
      "connected": {"name": "Conrad de Wet", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "6003",
        "priority": 2,
        "app_name": "Stasis",
        "app_data": "hello"
      },
      "creationtime": "2025-04-22T17:28:24.282+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "StasisEnd",
    "timestamp": "2025-04-22T17:28:41.863+0200",
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello,dialed,PJSIP/6004,channel1745335704.8974"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "STASISSTATUS",
    "value": "SUCCESS",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:41.863+0200",
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello,dialed,PJSIP/6004,channel1745335704.8974"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "ChannelConnectedLine",
    "timestamp": "2025-04-22T17:28:41.864+0200",
    "channel": {
      "id": "1745335713.8986",
      "name": "UnicastRTP/10.44.0.70:47029-0x7f13282ca9e0",
      "state": "Up",
      "protocol_id": "",
      "caller": {"name": "", "number": ""},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "default",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello"
      },
      "creationtime": "2025-04-22T17:28:33.390+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "RTPAUDIOQOS",
    "value":
        "ssrc=412479622;themssrc=171055185;lp=0;rxjitter=0.002250;rxcount=426;txjitter=0.000875;txcount=420;rlp=0;rtt=0.019515;rxmes=87.890996;txmes=88.087887",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:41.864+0200",
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello,dialed,PJSIP/6004,channel1745335704.8974"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "RTPAUDIOQOSJITTER",
    "value":
        "minrxjitter=000.000125;maxrxjitter=000.007500;avgrxjitter=000.001221;stdevrxjitter=000.001036;mintxjitter=000.002000;maxtxjitter=000.002250;avgtxjitter=000.002125;stdevtxjitter=000.000125;",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:41.864+0200",
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello,dialed,PJSIP/6004,channel1745335704.8974"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "RTPAUDIOQOSLOSS",
    "value":
        "  minrxlost=000.000000;  maxrxlost=000.000000;  avgrxlost=000.000000;  stdevrxlost=000.000000;  mintxlost=000.000000;  maxtxlost=000.000000;  avgtxlost=000.000000;  stdevtxlost=000.000000;",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:41.864+0200",
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello,dialed,PJSIP/6004,channel1745335704.8974"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "RTPAUDIOQOSRTT",
    "value":
        "     minrtt=000.019515;     maxrtt=000.019515;     avgrtt=000.019515;     stdevrtt=000.000000;",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:41.864+0200",
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello,dialed,PJSIP/6004,channel1745335704.8974"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "RTPAUDIOQOSMES",
    "value":
        "   minrxmes=088.087887;   maxrxmes=088.087887;   avgrxmes=088.087887;   stdevrxmes=000.001036;   mintxmes=087.890996;   maxtxmes=088.087887;   avgtxmes=087.989442;   stdevtxmes=000.098446;",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:41.864+0200",
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello,dialed,PJSIP/6004,channel1745335704.8974"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "ChannelDestroyed",
    "timestamp": "2025-04-22T17:28:41.864+0200",
    "cause": 16,
    "cause_txt": "Normal Clearing",
    "channel": {
      "id": "1745335708.8978",
      "name": "PJSIP/6004-0000051f",
      "state": "Up",
      "protocol_id": "628bf32b-8ea8-47af-92b8-a83b03cb346d",
      "caller": {"name": "Conrad de Wet", "number": "00260972462922"},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "from-zesco",
        "exten": "s",
        "priority": 1,
        "app_name": "AppDial2",
        "app_data": "(Outgoing Line)"
      },
      "creationtime": "2025-04-22T17:28:28.132+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "ChannelConnectedLine",
    "timestamp": "2025-04-22T17:28:41.865+0200",
    "channel": {
      "id": "1745335704.8974",
      "name": "PJSIP/mytrunk-0000051d",
      "state": "Up",
      "protocol_id": "714737594818e7a134e89a154edc34f1@10.44.0.56:5060",
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
      "creationtime": "2025-04-22T17:28:24.282+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "BRIDGEPEER",
    "value": "",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:41.954+0200",
    "channel": {
      "id": "1745335713.8986",
      "name": "UnicastRTP/10.44.0.70:47029-0x7f13282ca9e0",
      "state": "Up",
      "protocol_id": "",
      "caller": {"name": "", "number": ""},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "default",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello"
      },
      "creationtime": "2025-04-22T17:28:33.390+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "BRIDGEPVTCALLID",
    "value": "",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:41.954+0200",
    "channel": {
      "id": "1745335713.8986",
      "name": "UnicastRTP/10.44.0.70:47029-0x7f13282ca9e0",
      "state": "Up",
      "protocol_id": "",
      "caller": {"name": "", "number": ""},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "default",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello"
      },
      "creationtime": "2025-04-22T17:28:33.390+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "variable": "BRIDGEPEER",
    "value": "",
    "type": "ChannelVarset",
    "timestamp": "2025-04-22T17:28:41.954+0200",
    "channel": {
      "id": "1745335704.8974",
      "name": "PJSIP/mytrunk-0000051d",
      "state": "Up",
      "protocol_id": "714737594818e7a134e89a154edc34f1@10.44.0.56:5060",
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
      "creationtime": "2025-04-22T17:28:24.282+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "ChannelLeftBridge",
    "timestamp": "2025-04-22T17:28:41.955+0200",
    "bridge": {
      "id": "ec34542e-e16b-4955-bc48-37f7c347bfc5",
      "technology": "simple_bridge",
      "bridge_type": "mixing",
      "bridge_class": "stasis",
      "creator": "Stasis",
      "name": "",
      "channels": ["1745335704.8974"],
      "creationtime": "2025-04-22T17:28:33.362+0200",
      "video_mode": "talker"
    },
    "channel": {
      "id": "1745335713.8986",
      "name": "UnicastRTP/10.44.0.70:47029-0x7f13282ca9e0",
      "state": "Up",
      "protocol_id": "",
      "caller": {"name": "", "number": ""},
      "connected": {"name": "", "number": "00260972462922"},
      "accountcode": "",
      "dialplan": {
        "context": "default",
        "exten": "s",
        "priority": 1,
        "app_name": "Stasis",
        "app_data": "hello"
      },
      "creationtime": "2025-04-22T17:28:33.390+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "ChannelLeftBridge",
    "timestamp": "2025-04-22T17:28:41.956+0200",
    "bridge": {
      "id": "ec34542e-e16b-4955-bc48-37f7c347bfc5",
      "technology": "simple_bridge",
      "bridge_type": "mixing",
      "bridge_class": "stasis",
      "creator": "Stasis",
      "name": "",
      "channels": [],
      "creationtime": "2025-04-22T17:28:33.362+0200",
      "video_mode": "talker"
    },
    "channel": {
      "id": "1745335704.8974",
      "name": "PJSIP/mytrunk-0000051d",
      "state": "Up",
      "protocol_id": "714737594818e7a134e89a154edc34f1@10.44.0.56:5060",
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
      "creationtime": "2025-04-22T17:28:24.282+0200",
      "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  },
  {
    "type": "BridgeDestroyed",
    "timestamp": "2025-04-22T17:28:41.956+0200",
    "bridge": {
      "id": "ec34542e-e16b-4955-bc48-37f7c347bfc5",
      "technology": "simple_bridge",
      "bridge_type": "mixing",
      "bridge_class": "stasis",
      "creator": "Stasis",
      "name": "",
      "channels": [],
      "creationtime": "2025-04-22T17:28:33.362+0200",
      "video_mode": "talker"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
  }
];


//Call journey:

Message from server: {
    "type": "Dial",
    "timestamp": "2025-04-24T11:29:38.005+0200",
    "dialstatus": "",
    "forward": "",
    "dialstring": "6004",
    "peer": {
        "id": "1745486977.9352",
        "name": "PJSIP/6004-00000552",
        "state": "Down",
        "protocol_id": "3ec39dc1-b056-40f5-90e7-7c03cbd643be",
        "caller": {
            "name": "Conrad de Wet",
            "number": "00260972462922"
        },
        "connected": {
            "name": "",
            "number": "00260972462922"
        },
        "accountcode": "",
        "dialplan": {
            "context": "from-zesco",
            "exten": "s",
            "priority": 1,
            "app_name": "AppDial2",
            "app_data": "(Outgoing Line)"
        },
        "creationtime": "2025-04-24T11:29:38.004+0200",
        "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
}
Message from server: {
    "type": "Dial",
    "timestamp": "2025-04-24T11:29:38.066+0200",
    "dialstatus": "RINGING",
    "forward": "",
    "dialstring": "6004",
    "peer": {
        "id": "1745486977.9352",
        "name": "PJSIP/6004-00000552",
        "state": "Ringing",
        "protocol_id": "3ec39dc1-b056-40f5-90e7-7c03cbd643be",
        "caller": {
            "name": "Conrad de Wet",
            "number": "00260972462922"
        },
        "connected": {
            "name": "",
            "number": "00260972462922"
        },
        "accountcode": "",
        "dialplan": {
            "context": "from-zesco",
            "exten": "s",
            "priority": 1,
            "app_name": "AppDial2",
            "app_data": "(Outgoing Line)"
        },
        "creationtime": "2025-04-24T11:29:38.004+0200",
        "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
}
Message from server: {
    "type": "Dial",
    "timestamp": "2025-04-24T11:29:45.122+0200",
    "dialstatus": "ANSWER",
    "forward": "",
    "dialstring": "6004",
    "peer": {
        "id": "1745486977.9352",
        "name": "PJSIP/6004-00000552",
        "state": "Up",
        "protocol_id": "3ec39dc1-b056-40f5-90e7-7c03cbd643be",
        "caller": {
            "name": "Conrad de Wet",
            "number": "00260972462922"
        },
        "connected": {
            "name": "",
            "number": "00260972462922"
        },
        "accountcode": "",
        "dialplan": {
            "context": "from-zesco",
            "exten": "s",
            "priority": 1,
            "app_name": "AppDial2",
            "app_data": "(Outgoing Line)"
        },
        "creationtime": "2025-04-24T11:29:38.004+0200",
        "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
}


Message from server: {
    "type": "StasisEnd",
    "timestamp": "2025-04-24T14:49:32.755+0200",
    "channel": {
        "id": "1745498961.9572",
        "name": "PJSIP/6004-0000056b",
        "state": "Up",
        "protocol_id": "811e83fd-f7f1-44fd-97a2-98fd89bed47f",
        "caller": {
            "name": "Conrad de Wet",
            "number": "00260972462922"
        },
        "connected": {
            "name": "",
            "number": ""
        },
        "accountcode": "",
        "dialplan": {
            "context": "from-zesco",
            "exten": "s",
            "priority": 1,
            "app_name": "Stasis",
            "app_data": "hello,dialed,PJSIP/6004,channel1745498957.9566,00260972462922,8d5dce10-210a-11f0-bc91-dd0a2a110acc"
        },
        "creationtime": "2025-04-24T14:49:21.270+0200",
        "language": "en"
    },
    "asterisk_id": "00:15:5d:00:2a:0d",
    "application": "hello"
}