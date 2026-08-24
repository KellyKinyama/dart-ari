# Externalmedia daemon protocol

The binary forks RTP to an external recorder daemon (same pattern as
`dart-ari-proxy/bridge_dial2.dart`). The daemon owns the audio file;
Asterisk itself never writes to disk. The binary only writes the JSON
sidecar with per-call metadata + SDP IPs.

## Wire protocol the daemon must speak

### Port allocation (per call, at StasisStart of the peer leg)

```
POST http://<RECORDER_HTTP_HOST>:<RECORDER_HTTP_PORT><RECORDER_ALLOC_PATH>?filename=<basename>
=> 200 OK
=> {"rtp_port": <int>}
```

Contract:

- Daemon opens a UDP socket on the returned port.
- Daemon starts writing incoming RTP payload (in the codec identified by
  `RECORDER_FORMAT`, default `alaw`) to a file it names using `<basename>`.
- The binary passes a UUID-derived, timestamp-prefixed basename (see
  `CallRecording.buildFilename`). It does NOT know or care where the
  daemon puts the file.

### Call end (optional, only sent if `RECORDER_STOP_PATH` is set)

```
POST http://<RECORDER_HTTP_HOST>:<RECORDER_HTTP_PORT><RECORDER_STOP_PATH>?filename=<basename>
```

Response body is ignored; failures are logged and swallowed.

## Per-call flow

1. Caller enters `Stasis(hello)` → binary answers, originates peer endpoint.
2. Peer enters Stasis with arg `dialed` → binary `POST`s the alloc path
   to reserve a UDP port.
3. Binary creates an ARI `externalMedia` UnicastRTP channel pointed at
   `RECORDER_RTP_HOST:<rtp_port>` in `RECORDER_FORMAT`.
4. Binary creates a mixing bridge, adds caller + peer + externalMedia leg.
5. RTP flows from Asterisk → daemon; daemon writes the file.
6. On StasisEnd (or peer ChannelDestroyed) the binary:
   - Writes `${RECORDINGS_DIR}/<ipTaggedBasename>.json` with SDP IPs
     from both legs (via `CHANNEL(rtp,dest)` etc.), timing, disposition.
   - `POST`s the stop hook if configured.
   - Deletes the externalMedia channel, destroys the bridge, hangs up
     the peer.

## JSON sidecar shape

```json
{
  "reason": "StasisEnd",
  "daemon_basename": "20260824-153000_unknown_unknown_<uuid>",
  "ip_tagged_basename": "20260824-153000_192.168.1.42_10.0.0.55_<uuid>",
  "recorder_rtp_host": "10.43.0.55",
  "recorder_rtp_port": 41230,
  "recorder_format": "alaw",
  "agent_number": "PJSIP/7000",
  "phone_number": "+15551234567",
  "file_name": "20260824-153000_unknown_unknown_<uuid>",
  "file_path": "20260824-153000_unknown_unknown_<uuid>",
  "caller_rtp_local": "10.0.0.10:14022",
  "caller_rtp_remote": "192.168.1.42:5004",
  "caller_sip_remote": "192.168.1.42:5060",
  "peer_rtp_local": "10.0.0.10:16104",
  "peer_rtp_remote": "10.0.0.55:5004",
  "peer_sip_remote": "10.0.0.55:5060",
  "calldate": "2026-08-24T15:30:00.000Z",
  "answerdate": "2026-08-24T15:30:03.412Z",
  "hangupdate": "2026-08-24T15:32:11.981Z",
  "duration": "131",
  "billsec": "128",
  "disposition": "ANSWERED"
}
```

`daemon_basename` is what the daemon was told to name the file;
`ip_tagged_basename` embeds the SDP peer IPs so operators can grep the
sidecar directory by IP without joining against a DB.
