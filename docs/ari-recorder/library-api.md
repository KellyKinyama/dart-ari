# Library API additions (dart_ari)

The `dart_ari` package gained a few things while building the recorder.
These are usable independently of `bin/record_calls.dart` — if you'd
rather record via Asterisk's native `POST /bridges/{id}/record` and store
metadata in the `recordings` DB table, wire them up as shown below.

## New surface

- `ChannelsApi.record(...)` — `POST /channels/{id}/record` (single-leg).
- `ChannelsApi.rtpStatistics(id)` — `GET /channels/{id}/rtp_statistics`.
- `ChannelsApi.dial({channelId, caller, timeout})` — `POST /channels/{id}/dial`.
  Required after `POST /channels/create` to actually initiate the outbound
  INVITE.
- `Channel.record(...)`, `Channel.rtpStatistics()`, `Channel.sdpEndpoints()`
  — instance-side wrappers.
- `BridgesAPI.record(...)` and `Bridge.record(...)` — the mixed-audio
  bridge recording via `POST /bridges/{id}/record`.
- `SdpEndpoints` class with `remoteRtpIp` / `localRtpIp` / `remoteSipIp`
  accessors that split `IP:PORT` (IPv4 and bracketed IPv6 handled).
- `CallRecording` fields: `caller_rtp_local/remote/sip_remote`,
  `peer_rtp_local/remote/sip_remote`.
- `CallRecording.buildFilename(uniqueId, callerIp, peerIp, timestamp)` —
  emits `YYYYMMDD-HHMMSS_<callerIp>_<peerIp>_<uid>`; IPv6 colons replaced
  with `-`; filesystem-illegal chars stripped.

## Recording a bridged call + tagging by SDP IP (native path)

Full-call audio (both legs mixed) via ARI native `bridge.record()` + IP
tagging from the SDP.

### 1. Where files land

Asterisk writes bridge/channel recordings under
`/var/spool/asterisk/recording/<name>.<format>` by default (no leading
path in `name`, no extension in `name`). Subdirectories are allowed
in `name`.

### 2. Extra columns to add on the `recordings` table

`CallRecording.insertCallRecording()` writes these — add them to your
schema:

```sql
ALTER TABLE recordings
  ADD COLUMN caller_rtp_local  VARCHAR(64) NULL,
  ADD COLUMN caller_rtp_remote VARCHAR(64) NULL,
  ADD COLUMN caller_sip_remote VARCHAR(64) NULL,
  ADD COLUMN peer_rtp_local    VARCHAR(64) NULL,
  ADD COLUMN peer_rtp_remote   VARCHAR(64) NULL,
  ADD COLUMN peer_sip_remote   VARCHAR(64) NULL,
  ADD INDEX idx_recordings_peer_rtp_remote (peer_rtp_remote),
  ADD INDEX idx_recordings_caller_rtp_remote (caller_rtp_remote);
```

### 3. Wire-up inside your Stasis app (after both channels are up in the mixing bridge)

```dart
import 'package:dart_ari/dart_ari.dart';
import 'package:uuid/uuid.dart';

Future<void> startCallRecording({
  required Channel caller,
  required Channel peer,
  required Bridge mixingBridge,
  required String agentEndpoint,
}) async {
  final callerSdp = await caller.sdpEndpoints();
  final peerSdp = await peer.sdpEndpoints();

  final uid = Uuid().v1();
  final baseName = CallRecording.buildFilename(
    uniqueId: uid,
    callerIp: callerSdp.remoteRtpIp,
    peerIp: peerSdp.remoteRtpIp,
  );

  final live = await mixingBridge.record(
    name: baseName,
    format: 'wav',
    ifExists: 'overwrite',
  );
  print('Recording started: ${live['name']}.${live['format']}');

  voiceRecords[caller.id] = CallRecording(
    agent_number: agentEndpoint,
    phone_number: caller.caller.number,
    file_name: '$baseName.wav',
    file_path: '/var/spool/asterisk/recording/$baseName.wav',
    caller_rtp_local: callerSdp.rtpSrc,
    caller_rtp_remote: callerSdp.rtpDest,
    caller_sip_remote: callerSdp.pjsipRemote,
    peer_rtp_local: peerSdp.rtpSrc,
    peer_rtp_remote: peerSdp.rtpDest,
    peer_sip_remote: peerSdp.pjsipRemote,
    calldate: DateTime.now().toIso8601String(),
  );
}
```

On `StasisEnd` (or the `RecordingFinished` event), fill in `hangupdate` /
`duration` / `billsec` and call `voiceRecords[caller.id]!.insertCallRecording()`.

### 4. Single-leg recording (rarely what you want)

`POST /channels/{id}/record` only captures audio coming FROM the channel,
not audio sent TO it. Available via `caller.record(name: ..., format: ...)`
for cases where a mixing bridge doesn't exist yet.

### 5. What each SDP field actually is

| Field                         | Asterisk source              | Meaning                                   |
| ----------------------------- | ---------------------------- | ----------------------------------------- |
| `SdpEndpoints.rtpDest`        | `CHANNEL(rtp,dest)`          | Remote RTP endpoint from negotiated SDP   |
| `SdpEndpoints.rtpSrc`         | `CHANNEL(rtp,src)`           | Local RTP endpoint Asterisk is bound to   |
| `SdpEndpoints.pjsipRemote`    | `CHANNEL(pjsip,remote_addr)` | SIP signaling peer (not necessarily RTP)  |
| `SdpEndpoints.pjsipLocal`     | `CHANNEL(pjsip,local_addr)`  | Local SIP signaling address               |

Note: `CHANNEL(rtp,dest)` is only populated once SDP negotiation has
completed. Read it after `ChannelStateChange -> Up` for the caller and
after bridge assembly (with retry) for the peer — see
[implementation-notes.md](implementation-notes.md) §2.
