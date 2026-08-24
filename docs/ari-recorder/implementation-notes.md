# Implementation notes (things future-you will thank present-you for)

## 1. `POST /channels/create` does NOT dial. Follow it with `POST /channels/{id}/dial`

The two-step ARI pattern is required. `create` allocates a shell channel
and places it in the Stasis app in **pre-dial state** — no SIP INVITE is
sent to the endpoint. StasisStart still fires on it, which is misleading;
you can add it to a mixing bridge and RTP will flow, but only silence —
the far side was never rung.

Symptom: "the recorder picks up the call but the agent phone never rings"
and the caller hears nothing but silence for the whole call duration.

Fix: `ChannelsApi.dial(channelId: peer.id, caller: incoming.id, timeout: 30)`
immediately after `ari.channel(...)` returns. See
[bin/record_calls.dart](../../bin/record_calls.dart) `_originatePeer`.

## 2. SDP capture timing per leg

| Leg | Read at | Why |
|-----|---------|-----|
| Caller (inbound) | Right after `channel.answer()` returns | Caller SDP was in the initial INVITE; by the time our 200 OK goes out, `CHANNEL(rtp,dest)` is populated. Attaching a `ChannelStateChange` listener AFTER `answer()` races with the `Up` transition and misses it. |
| Peer (outbound) | With a short retry loop after `bridge.addChannel()` | Trunk-side SDP negotiation completes ~200–800ms after Stasis entry. A single read at peer's `StasisStart` returns all nulls. |

We poll with backoff `[200, 400, 800, 1600]` ms and stop early once
`rtpDest` is populated. See
[bin/record_calls.dart](../../bin/record_calls.dart) `_capturePeerSdp`.

## 3. Trunk-originated PJSIP channels return HTTP 500 for `CHANNEL(pjsip,*)`

On outbound legs like `PJSIP/mytrunk-*` (created via
`POST /channels/create` → `POST /channels/{id}/dial`), these return HTTP 500:

- `CHANNEL(pjsip,remote_addr)`
- `CHANNEL(pjsip,local_addr)`
- `CHANNEL(rtp,them)` / `CHANNEL(rtp,us)`

These DO work (returning `IP:PORT`):

- `CHANNEL(rtp,src)` — Asterisk's local RTP endpoint
- `CHANNEL(rtp,dest)` — the peer's negotiated RTP endpoint from SDP

`GET /channels/{id}/rtp_statistics` returns `404 "RTP info not found"` on
the same channel — but audio is definitely flowing (the file on the
daemon records fine, `billsec > 0`). This is an Asterisk-side quirk with
trunk-originated PJSIP channels; treat any HTTP 500 from these vars as
"unavailable" and rely on `rtp,src` / `rtp,dest` instead. The
`_debugSdp` helper in the binary logs the raw statuses so it's easy to
see what the current Asterisk build supports.

## 4. Never propagate error markers into SdpEndpoints or filenames

An early version of `_debugSdp` returned `'<500>'` string markers for
failed variable reads, and those markers ended up in the sidecar filename
as `..._<500>_...json` → `PathNotFoundException` on Windows because `<`
and `>` aren't valid filename characters. Fix: keep the marker in a
separate log map only; the SdpEndpoints producer treats non-empty real
values or null (no markers). Filename builder also strips `<>"|?*` as a
safety net.

## 5. Stasis app name is hardcoded

`'app': 'hello'` appears in three places that must all match:

- Asterisk dialplan: `Stasis(hello)` in your inbound context.
- [lib/ari/api/ari.dart](../../lib/ari/api/ari.dart) `ARI.connect()` — the WebSocket
  subscribes as app `hello`.
- [bin/record_calls.dart](../../bin/record_calls.dart) — passed as `app:` to
  `ari.channel(...)` and `ari.externalMedia(...)` on the peer + extMedia
  legs so those channels enter the same Stasis app.

To rename, grep for `'hello'` in the repo and update all three sites.

## 6. Recorder daemon protocol reminder

The daemon MUST:

- Accept `POST http://<host>:<port><RECORDER_ALLOC_PATH>?filename=<basename>`
  and return JSON `{"rtp_port": <int>}`.
- Open a UDP listener on that port and write incoming RTP payload (in the
  `RECORDER_FORMAT` codec) to a file it names using `<basename>`.
- Optionally accept `POST .../<RECORDER_STOP_PATH>?filename=<basename>` to
  close the file.

The old `dart-ari-proxy/bridge_dial2.dart` daemon on port `8085` at the
CCIVR box speaks this protocol. See [daemon-protocol.md](daemon-protocol.md).

## 7. `.env` is tracked in git despite being in `.gitignore`

Pre-existing issue: `.env` was committed before `.gitignore` was set up,
and contains real credentials (`asterisk/asterisk`, `dashboard.123`,
`REDIS_PASSWORD`). To clean up:

```powershell
git rm --cached .env
git commit -m "Untrack .env (contains credentials)"
# then rotate credentials since they are already in git history
```
