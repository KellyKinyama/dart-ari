 sudo journalctl -u ari_proxy.service -r

 dart compile exe  bin/dart_ari.dart --target-os=linux  

  sudo asterisk -rx "core show channels"

  

   sudo asterisk -rx "dialplan show globals"

---

## Recording a bridged call + tagging by SDP IP

Full-call audio (both legs mixed) via ARI + IP tagging from the SDP.

### 1. Recording files land in

Asterisk writes bridge/channel recordings under
`/var/spool/asterisk/recording/<name>.<format>` by default (no leading path
in `name`, no extension in `name`). Subdirectories are allowed in `name`.

### 2. Extra columns to add on the `recordings` table

`CallRecording.insertCallRecording()` now writes these — add them to your
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
  // 1. Collect SDP-negotiated IPs from BOTH legs. rtp,dest = the IP the
  //    peer announced in its SDP m=/c= line — that's the "IP in the SDP".
  final callerSdp = await caller.sdpEndpoints();
  final peerSdp = await peer.sdpEndpoints();

  // 2. Build a self-labeling filename: <ts>_<callerIp>_<peerIp>_<uid>
  final uid = Uuid().v1();
  final baseName = CallRecording.buildFilename(
    uniqueId: uid,
    callerIp: callerSdp.remoteRtpIp,
    peerIp: peerSdp.remoteRtpIp,
  );

  // 3. Kick off the ARI bridge recording (mixed both-sides audio).
  final live = await mixingBridge.record(
    name: baseName,
    format: 'wav',
    ifExists: 'overwrite',
  );
  print('Recording started: ${live['name']}.${live['format']}');

  // 4. Stash the DB row so RecordingFinished/StasisEnd can complete it.
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

Then on `StasisEnd` (or the `RecordingFinished` event), fill in
`hangupdate` / `duration` / `billsec` and call
`voiceRecords[caller.id]!.insertCallRecording()`.

### 4. Single-leg recording (rarely what you want)

`POST /channels/{id}/record` only captures audio coming FROM the channel,
not audio sent TO it. Available via `caller.record(name: ..., format: ...)`
for cases where a mixing bridge doesn't exist yet.

### 5. What each SDP field actually is

| Field                         | Asterisk source           | Meaning                                   |
| ----------------------------- | ------------------------- | ----------------------------------------- |
| `SdpEndpoints.rtpDest`        | `CHANNEL(rtp,dest)`       | Remote RTP endpoint from negotiated SDP   |
| `SdpEndpoints.rtpSrc`         | `CHANNEL(rtp,src)`        | Local RTP endpoint Asterisk is bound to   |
| `SdpEndpoints.pjsipRemote`    | `CHANNEL(pjsip,remote_addr)` | SIP signaling peer (not necessarily RTP) |
| `SdpEndpoints.pjsipLocal`     | `CHANNEL(pjsip,local_addr)`  | Local SIP signaling address              |

Note: `CHANNEL(rtp,dest)` is only populated once SDP negotiation has
completed. Read it after `ChannelStateChange -> Up`, not on
`StasisStart` for outbound legs.


---

## How to run `bin/record_calls.dart`

Standalone binary that connects to a live Asterisk ARI, answers incoming
Stasis calls, dials a peer, forks the mixed RTP to an external recorder
daemon (which you provide), and drops a JSON sidecar per call with the
SDP-negotiated IPs from both legs.

### 1. Prerequisites

- Dart SDK 3.6+ on the host that will run the binary.
- A reachable Asterisk 16+ with `res_ari` and `res_pjsip` loaded.
- A running recorder daemon that speaks the wire protocol below
  (see "Externalmedia daemon protocol").
- Network path: Asterisk → daemon on UDP (RTP) and this binary → daemon
  on TCP (HTTP control), and Asterisk → this binary host on TCP 8088
  (ARI + WebSocket).

### 2. Configure Asterisk (once, on the Asterisk box)

`/etc/asterisk/ari.conf`:

```ini
[general]
enabled = yes
pretty = yes
allowed_origins = *

[ariuser]
type = user
read_only = no
password = arisecret
```

`/etc/asterisk/http.conf`:

```ini
[general]
enabled = yes
bindaddr = 0.0.0.0
bindport = 8088
```

`/etc/asterisk/extensions.conf` — route calls into Stasis:

```ini
[from-internal]
exten => _X.,1,NoOp(ari-recorder inbound ${CALLERID(num)} -> ${EXTEN})
 same =>   n,Stasis(hello)
 same =>   n,Hangup()
```

Reload:

```bash
sudo asterisk -rx "module reload res_ari.so"
sudo asterisk -rx "module reload res_http_websocket.so"
sudo asterisk -rx "dialplan reload"
```

Verify ARI is reachable from where the binary runs:

```bash
curl -u ariuser:arisecret http://<asterisk-host>:8088/ari/asterisk/info
```

Should return JSON, not 401.

### 3. Create `.env` next to the binary

The binary reads env vars from process environment OR a `.env` file in the
current working directory (via `package:dotenv`).

```env
# --- Asterisk ARI ---
ASTERISK_ARI_SCHEME=http
ASTERISK_ARI_HOST=10.0.0.10
ASTERISK_ARI_PORT=8088
ASTERISK_ARI_USERNAME=ariuser
ASTERISK_ARI_PASSWORD=arisecret

# --- Call routing ---
PHONE_ENDPOINT=PJSIP/7000

# --- Recorder daemon ---
RECORDER_HTTP_HOST=10.43.0.55
RECORDER_HTTP_PORT=8080
RECORDER_RTP_HOST=10.43.0.55        # default: same as RECORDER_HTTP_HOST
RECORDER_ALLOC_PATH=/               # default: /
RECORDER_STOP_PATH=/stop            # optional; unset = no stop hook
RECORDER_FORMAT=alaw                # alaw|ulaw|slin16 — must match daemon

# --- Local metadata sink ---
RECORDINGS_DIR=./recordings_out
```

Env-var reference:

| Var | Required | Default | Notes |
|-----|----------|---------|-------|
| `ASTERISK_ARI_SCHEME` | no | `http` | `https` if TLS termination in front of ARI |
| `ASTERISK_ARI_HOST` | **yes** | — | ARI host/IP |
| `ASTERISK_ARI_PORT` | no | `8088` | |
| `ASTERISK_ARI_USERNAME` | **yes** | — | matches `ari.conf` user block |
| `ASTERISK_ARI_PASSWORD` | **yes** | — | |
| `PHONE_ENDPOINT` | **yes** | — | e.g. `PJSIP/7000` — the agent leg to dial |
| `RECORDER_HTTP_HOST` | **yes** | — | daemon HTTP control host |
| `RECORDER_HTTP_PORT` | no | `8080` | daemon HTTP control port |
| `RECORDER_RTP_HOST` | no | = `RECORDER_HTTP_HOST` | where Asterisk sends RTP |
| `RECORDER_ALLOC_PATH` | no | `/` | POST path for port allocation |
| `RECORDER_STOP_PATH` | no | (unset) | if set, POSTed on call end |
| `RECORDER_FORMAT` | no | `alaw` | RTP payload format |
| `RECORDINGS_DIR` | no | `./recordings_out` | where JSON sidecars are written |

Missing any required var → the binary prints `FATAL: env var X is required`
to stderr and exits with code 2.

### 4. Fetch deps and run

From the repo root (`c:\www\dart\dart-ari`):

```powershell
dart pub get
dart run bin/record_calls.dart
```

Expected startup output:

```
[recorder] connecting to http://10.0.0.10:8088 ari/events (app=hello, dial=PJSIP/7000, recorder=10.43.0.55:<alloc>, format=alaw, out=./recordings_out)
[recorder] ready — waiting for Stasis(hello) calls
```

Ctrl+C to stop. The binary handles SIGINT cleanly.

### 5. Compile to a native exe (optional)

For deployment without a Dart SDK on the target host:

```powershell
# Windows exe
dart compile exe bin/record_calls.dart -o build/record_calls.exe
./build/record_calls.exe

# Linux exe (from Windows, cross-compile)
dart compile exe bin/record_calls.dart --target-os=linux -o build/record_calls
scp build/record_calls user@host:/opt/recorder/
```

Then on the Linux host, drop the same `.env` next to the exe and run it.

### 6. systemd unit (Linux deployment)

`/etc/systemd/system/ari-recorder.service`:

```ini
[Unit]
Description=ARI externalMedia call recorder
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=recorder
WorkingDirectory=/opt/recorder
EnvironmentFile=/opt/recorder/.env
ExecStart=/opt/recorder/record_calls
Restart=on-failure
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now ari-recorder
sudo journalctl -u ari-recorder -f
```

### 7. Make a test call

From any registered PJSIP endpoint, dial an extension that matches
`_X.` in `[from-internal]`. Expected log per call:

```
[recorder] StasisStart caller=PJSIP/6001-0000001c id=1735938011.123
[recorder] peer PJSIP/7000-0000001d entered Stasis
[recorder] externalMedia leg=UnicastRTP/10.43.0.55:41230-0000001e -> 10.43.0.55:41230 (alaw)
[recorder] mixing bridge=abcd... has caller+peer+extMedia; recording 41230 -> 20260824-153000_unknown_unknown_<uuid>.alaw
[recorder] wrote ./recordings_out/20260824-153000_192.168.1.42_10.0.0.55_<uuid>.json (StasisEnd, billsec=128)
```

Verify:

- Sidecar file present: `Get-ChildItem recordings_out\*.json`
- Audio file on the daemon side (path is daemon-specific).
- Asterisk CLI shows the ext-media channel during the call:
  `sudo asterisk -rx "core show channels concise" | grep UnicastRTP`

### 8. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `AriException ... 401` on startup | wrong `ARI_USERNAME`/`PASSWORD` or user not in `ari.conf` | fix creds, reload `res_ari.so` |
| WebSocket connects but no `StasisStart` fires | dialplan not sending calls to `Stasis(hello)` | check `dialplan show` in Asterisk CLI |
| `recorder alloc failed: HTTP 000` | daemon down or wrong `RECORDER_HTTP_HOST/PORT` | curl the alloc path manually |
| `recorder alloc returned no rtp_port` | daemon returned different JSON shape | daemon MUST return `{"rtp_port": <int>}` |
| Sidecar has `caller_rtp_remote: null` | SDP not yet negotiated when we asked | expected on very short calls; not fatal |
| Peer never enters Stasis | dialed endpoint not registered / not reachable | `sudo asterisk -rx "pjsip show endpoint 7000"` |
| Two sidecars per call | duplicate `StasisEnd` (peer + caller) | benign; both are guarded by `_calls.remove()` — should not happen |
| Audio silent on daemon | codec mismatch — Asterisk transcodes to `RECORDER_FORMAT` but daemon expects something else | match `RECORDER_FORMAT` on both sides |

### 9. Change the Stasis app name

The name `hello` is hardcoded inside [lib/ari/api/ari.dart](lib/ari/api/ari.dart#L214) —
grep for `'app': 'hello'` in `ARI.connect()` and change to whatever you
use in `Stasis(...)`. Then update the `app:` values in
[bin/record_calls.dart](bin/record_calls.dart) (originate + externalMedia
calls) to match.


---

## Externalmedia daemon protocol (what `bin/record_calls.dart` expects)

The binary now forks RTP to an external recorder daemon (like the old
`dart-ari-proxy/bridge_dial2.dart` did). The daemon owns the audio file;
Asterisk itself never writes to disk. This binary only writes the JSON
sidecar with the per-call metadata + SDP IPs.

### Wire protocol the daemon must speak

**Port allocation** (per call, at StasisStart of the peer leg):

```
POST http://<RECORDER_HTTP_HOST>:<RECORDER_HTTP_PORT><RECORDER_ALLOC_PATH>?filename=<basename>
=> 200 OK
=> {"rtp_port": <int>}
```

Contract:

- Daemon opens a UDP socket on the returned port.
- Daemon starts writing incoming RTP payload (format determined by
  `RECORDER_FORMAT`, default `alaw`) to a file it names using `<basename>`.
- The binary passes a UUID-derived, timestamp-prefixed basename (see
  `CallRecording.buildFilename`). It does NOT know or care where the
  daemon puts the file.

**Call end** (optional, only sent if `RECORDER_STOP_PATH` is set):

```
POST http://<RECORDER_HTTP_HOST>:<RECORDER_HTTP_PORT><RECORDER_STOP_PATH>?filename=<basename>
```

Response body is ignored; failures are logged and swallowed.

### Env (add these; drop `RECORDING_FORMAT` from the old section)

```env
RECORDER_HTTP_HOST=10.43.0.55
RECORDER_HTTP_PORT=8080
RECORDER_RTP_HOST=10.43.0.55        # default: same as RECORDER_HTTP_HOST
RECORDER_ALLOC_PATH=/               # default: /
RECORDER_STOP_PATH=/stop            # optional, unset = no stop hook
RECORDER_FORMAT=alaw                # alaw|ulaw|slin16 � must match daemon
```

### Per-call flow (with the daemon)

1. Caller enters `Stasis(hello)` ? binary answers, originates PEER endpoint.
2. Peer enters Stasis with arg `dialed` ? binary calls
   `POST http://.../?filename=<basename>` to reserve a UDP port.
3. Binary creates an ARI `externalMedia` UnicastRTP channel pointed at
   `RECORDER_RTP_HOST:<rtp_port>` in `RECORDER_FORMAT`.
4. Binary creates a mixing bridge, adds caller + peer + externalMedia leg.
5. RTP flows from Asterisk ? daemon; daemon writes the file.
6. On StasisEnd (or peer ChannelDestroyed) the binary:
   - Writes `${RECORDINGS_DIR}/<ipTaggedBasename>.json` with SDP IPs
     from both legs (via `CHANNEL(rtp,dest)` etc.), timing, disposition.
   - `POST`s the stop hook if configured.
   - Deletes the externalMedia channel, destroys the bridge, hangs up
     the peer.

### JSON sidecar shape

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

`daemon_basename` is what the daemon was told to name the file; the
`ip_tagged_basename` embeds the SDP peer IPs so operators can grep the
sidecar directory by IP without joining against a DB.


---

## Implementation notes (things future-you will thank present-you for)

### 1. `POST /channels/create` does NOT dial. Follow it with `POST /channels/{id}/dial`.

The two-step ARI pattern is required. `create` allocates a shell channel and
places it in the Stasis app in **pre-dial state** � no SIP INVITE is sent to
the endpoint. StasisStart still fires on it, which is misleading; you can add
it to a mixing bridge and RTP will flow, but only silence � the far side was
never rung.

Symptom: "the recorder picks up the call but the agent phone never rings" and
the caller hears nothing but silence for the whole call duration.

Fix: `ChannelsApi.dial(channelId: peer.id, caller: incoming.id, timeout: 30)`
immediately after `ari.channel(...)` returns. See
[bin/record_calls.dart](bin/record_calls.dart#L207-L232) `_originatePeer`.

### 2. SDP capture timing per leg

| Leg | Read at | Why |
|-----|---------|-----|
| Caller (inbound) | Right after `channel.answer()` returns | Caller SDP was in the initial INVITE; by the time our 200 OK goes out, `CHANNEL(rtp,dest)` is populated. Attaching a `ChannelStateChange` listener AFTER `answer()` races with the `Up` transition and misses it. |
| Peer (outbound) | With a short retry loop after `bridge.addChannel()` | Trunk-side SDP negotiation completes ~200�800ms after Stasis entry. A single read at peer's `StasisStart` returns all nulls. |

We poll with backoff `[200, 400, 800, 1600]` ms and stop early once
`rtpDest` is populated. See
[bin/record_calls.dart](bin/record_calls.dart) `_capturePeerSdp`.

### 3. Trunk-originated PJSIP channels return HTTP 500 for `CHANNEL(pjsip,*)`

On outbound legs like `PJSIP/mytrunk-*` (created via
`POST /channels/create` ? `POST /channels/{id}/dial`), these return HTTP 500:

- `CHANNEL(pjsip,remote_addr)`
- `CHANNEL(pjsip,local_addr)`
- `CHANNEL(rtp,them)` / `CHANNEL(rtp,us)`

These DO work (returning `IP:PORT`):

- `CHANNEL(rtp,src)` � Asterisk's local RTP endpoint
- `CHANNEL(rtp,dest)` � the peer's negotiated RTP endpoint from SDP

`GET /channels/{id}/rtp_statistics` returns `404 "RTP info not found"` on the
same channel � but audio is definitely flowing (the file on the daemon
records fine, `billsec > 0`). This is an Asterisk-side quirk with
trunk-originated PJSIP channels; treat any HTTP 500 from these vars as
"unavailable" and rely on `rtp,src` / `rtp,dest` instead. Our
`_debugSdp` helper logs the raw statuses so it's easy to see what the
current Asterisk build supports.

### 4. Never propagate error markers into SdpEndpoints or filenames

An early version of `_debugSdp` returned `'<500>'` string markers for failed
variable reads, and those markers ended up in the sidecar filename as
`..._<500>_...json` ? `PathNotFoundException` on Windows because `<` and `>`
aren't valid filename characters. Fix: keep the marker in a separate log
map only; the SdpEndpoints producer treats non-empty real values or null
(no markers). Filename builder also strips `<>"|?*` as a safety net.

### 5. Stasis app name is hardcoded

`'app': 'hello'` appears in three places that must all match:

- Asterisk dialplan: `Stasis(hello)` in your inbound context.
- [lib/ari/api/ari.dart](lib/ari/api/ari.dart#L214) `ARI.connect()` � the WebSocket subscribes as app `hello`.
- [bin/record_calls.dart](bin/record_calls.dart) � passed as `app:` to
  `ari.channel(...)` and `ari.externalMedia(...)` on the peer + extMedia
  legs so those channels enter the same Stasis app.

To rename, grep for `'hello'` in the repo and update all three sites.

### 6. Recorder daemon protocol reminder

The daemon MUST:

- Accept `POST http://<host>:<port><RECORDER_ALLOC_PATH>?filename=<basename>`
  and return JSON `{"rtp_port": <int>}`.
- Open a UDP listener on that port and write incoming RTP payload (in the
  `RECORDER_FORMAT` codec) to a file it names using `<basename>`.
- Optionally accept `POST .../<RECORDER_STOP_PATH>?filename=<basename>` to
  close the file.

The old `dart-ari-proxy/bridge_dial2.dart` daemon on port `8085` at the
CCIVR box speaks this protocol. See
[commands.md](commands.md#externalmedia-daemon-protocol-what-binrecord_callsdart-expects).

### 7. `.env` is tracked in git despite being in `.gitignore`

Pre-existing issue: `.env` was committed before `.gitignore` was set up,
and contains real credentials (`asterisk/asterisk`, `dashboard.123`,
`REDIS_PASSWORD`). To clean up:

```powershell
git rm --cached .env
git commit -m "Untrack .env (contains credentials)"
# then rotate credentials since they are already in git history
```
