# How to run `bin/record_calls.dart`

Standalone binary that connects to a live Asterisk ARI, answers incoming
Stasis calls, dials a peer, forks the mixed RTP to an external recorder
daemon (which you provide), and drops a JSON sidecar per call with the
SDP-negotiated IPs from both legs.

## 1. Prerequisites

- Dart SDK 3.6+ on the host that will run the binary.
- A reachable Asterisk 16+ with `res_ari` and `res_pjsip` loaded.
- A running recorder daemon that speaks the wire protocol (see
  [daemon-protocol.md](daemon-protocol.md)).
- Network path: Asterisk → daemon on UDP (RTP), this binary → daemon on
  TCP (HTTP control), and Asterisk → this binary host on TCP 8088
  (ARI + WebSocket).

## 2. Configure Asterisk (once, on the Asterisk box)

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

## 3. Create `.env` next to the binary

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

## 4. Fetch deps and run

From the repo root:

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

## 5. Compile to a native exe (optional)

For deployment without a Dart SDK on the target host:

```powershell
# Windows exe
dart compile exe bin/record_calls.dart -o build/record_calls.exe
./build/record_calls.exe

# Linux exe (cross-compile from Windows)
dart compile exe bin/record_calls.dart --target-os=linux -o build/record_calls
scp build/record_calls user@host:/opt/recorder/
```

Then on the Linux host, drop the same `.env` next to the exe and run it.

## 6. systemd unit (Linux deployment)

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

## 7. Make a test call

From any registered PJSIP endpoint, dial an extension that reaches
`Stasis(hello)`. Expected log per call:

```
[recorder] StasisStart caller=PJSIP/6001-0000001c id=1735938011.123
[recorder] caller SDP: SdpEndpoints(pjsipRemote=..., rtpSrc=..., rtpDest=...)
[recorder] peer PJSIP/7000-0000001d entered Stasis
[recorder] externalMedia leg=UnicastRTP/... -> 10.43.0.55:41230 (alaw)
[recorder] mixing bridge=... has caller+peer+extMedia; recording 41230 -> <basename>.alaw
[recorder] peer SDP resolved: SdpEndpoints(rtpSrc=..., rtpDest=...)
[recorder] wrote ./recordings_out/<basename>.json (StasisEnd, billsec=N)
```

Verify:

- Sidecar file present: `Get-ChildItem recordings_out\*.json`.
- Audio file on the daemon side (path is daemon-specific).
- Asterisk CLI shows the ext-media channel during the call:
  `sudo asterisk -rx "core show channels concise" | grep UnicastRTP`.

## 8. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `AriException ... 401` on startup | wrong `ARI_USERNAME`/`PASSWORD` or user not in `ari.conf` | fix creds, reload `res_ari.so` |
| WebSocket connects but no `StasisStart` fires | dialplan not sending calls to `Stasis(hello)` | check `dialplan show` in Asterisk CLI |
| `recorder alloc failed: HTTP 000` | daemon down or wrong `RECORDER_HTTP_HOST/PORT` | curl the alloc path manually |
| `recorder alloc returned no rtp_port` | daemon returned different JSON shape | daemon MUST return `{"rtp_port": <int>}` |
| Sidecar has `peer_rtp_remote: null` | trunk-side `CHANNEL(rtp,*)` returned 500 — see [implementation-notes.md](implementation-notes.md) §3 | benign; audio still records |
| Agent phone never rings, caller hears silence | forgot the `POST /channels/{id}/dial` after `create` — see [implementation-notes.md](implementation-notes.md) §1 | ensure `ChannelsApi.dial()` is called |
| Peer never enters Stasis | dialed endpoint not registered / not reachable | `sudo asterisk -rx "pjsip show endpoint 7000"` |
| Audio silent on daemon | codec mismatch — Asterisk transcodes to `RECORDER_FORMAT` but daemon expects something else | match `RECORDER_FORMAT` on both sides |

## 9. Change the Stasis app name

The name `hello` is hardcoded in three places that must all match — see
[implementation-notes.md](implementation-notes.md) §5.
