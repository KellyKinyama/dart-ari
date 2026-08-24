# ARI call recorder

Standalone binary that connects to a live Asterisk ARI, answers incoming
`Stasis(hello)` calls, dials a peer endpoint, forks the mixed RTP to an
external recorder daemon via `externalMedia`, and drops a JSON sidecar per
call tagged with the SDP-negotiated IPs from both legs.

Entry point: [bin/record_calls.dart](../../bin/record_calls.dart).

## Docs in this folder

- [how-to-run.md](how-to-run.md) — prerequisites, Asterisk config, `.env`,
  running from source, native compile, systemd, troubleshooting.
- [daemon-protocol.md](daemon-protocol.md) — the wire contract your
  recorder daemon must speak, plus the JSON sidecar schema.
- [library-api.md](library-api.md) — additions to the `dart_ari` library
  (`Channel.record`, `Bridge.record`, `Channel.sdpEndpoints`,
  `CallRecording` fields + `buildFilename`) with a Stasis-app wire-up
  example for the native `bridge.record()` code path.
- [agent-identification.md](agent-identification.md) — deriving the
  physical agent's SDP endpoint from the sidecar's `caller_sip` /
  `peer_sip` correlation IDs (for B2BUA trunks like Alcatel OXE that
  hide the agent behind a media anchor).
- [implementation-notes.md](implementation-notes.md) — non-obvious
  Asterisk / ARI quirks we hit while building this. Read first if the
  recorder is misbehaving.

## Quick start (details in how-to-run.md)

```powershell
dart pub get
# populate .env — see how-to-run.md §3
dart run bin/record_calls.dart
```

Then dial an extension whose dialplan reaches `Stasis(hello)`. A JSON
sidecar lands in `RECORDINGS_DIR` per call, and the audio file lands
wherever the daemon writes it.
