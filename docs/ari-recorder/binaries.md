# CCIVR Recording Pipeline — Binaries Reference

This is the operational reference for every runnable binary under `bin/`
that makes up the CCIVR recording + reporting pipeline. Follow the flow
diagram below; each stage links to its section.

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ record_calls    │───▶│ enrich_from_    │───▶│ publish_to_     │
│ (§1)            │    │ homer  (§2)     │    │ mysql  (§3)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       ▲                       ▲
        ▼                       │                       │
  recordings_out/         Homer TimescaleDB    Laravel CCIVRDashboard
  (raw sidecars +         (SIP capture)        (MySQL: recordings
   audio via daemon)                            table)

        Guardrail running under all of the above:
        ┌─────────────────┐
        │ cleanup_disk    │  monitors disk %, prunes oldest data
        │ (§4)            │  when the fs crosses a high-water mark
        └─────────────────┘
```

All four binaries:

- Read config from the process env and (if present) `.env` in the
  working directory (via `package:dotenv`).
- Support `--once` to run one pass and exit (for cron).
- Log to stdout — designed to be captured by `journalctl` when run
  under systemd (see §5).

---

## 1. `bin/record_calls.dart` — ARI recorder

**What it does.** Subscribes to Asterisk ARI over WebSocket for the
`hello` Stasis app. For every inbound Stasis entry it answers the caller,
originates a peer leg to `PHONE_ENDPOINT` (typically the OXE hunt-group
`PJSIP/3636@mytrunk`), joins caller + peer + an `externalMedia`
UnicastRTP leg into a mixing bridge, and forks the mixed RTP to the
recorder daemon on `:8085`. At StasisEnd it writes a JSON sidecar per
call into `RECORDINGS_DIR`.

**Reads.** Asterisk ARI, recorder-daemon HTTP allocation endpoint.

**Writes.** One `.json` sidecar per call under `RECORDINGS_DIR`. The
audio itself is written by the separate recorder daemon (not this
binary).

**Sidecar fields** (excerpt — see the source for the full list):

```json
{
  "daemon_basename": "...uuid...",
  "ip_tagged_basename": "20260827-141247_10.1.8.226_10.1.8.226_<uuid>",
  "src": "+00260955405069",
  "dst": "PJSIP/3636@mytrunk",
  "clid": "<caller ID>",
  "calldate": "2026-08-27T14:12:47.100Z",
  "answerdate": "2026-08-27T14:12:48.220Z",
  "hangupdate": "2026-08-27T14:15:03.910Z",
  "duration": "137",
  "billsec": "134",
  "disposition": "ANSWERED",
  "caller_rtp_local": "...", "caller_rtp_remote": "...",
  "peer_rtp_local":   "...", "peer_rtp_remote":   "..."
}
```

**Key env.** `ASTERISK_ARI_*`, `PHONE_ENDPOINT`, `RECORDER_HTTP_*`,
`RECORDER_FORMAT`, `RECORDINGS_DIR`. Full list at the top of
`bin/record_calls.dart`.

**Notes.**

- Two-step ARI dial: `POST /channels/create` allocates + parks the
  channel in Stasis pre-dial state; `POST /channels/{id}/dial` actually
  sends INVITE. Both are done inside the recorder — do not skip one.
- Reconnects to the ARI WebSocket automatically after
  `ApplicationReplaced`.
- Historical bug fixed here: the underlying ARI client's
  `externalMediaDelete()` omitted `?api_key=…` — causing every
  externalMedia leg to leak. The recorder now hangs up the leg via the
  (correctly authed) `ChannelsApi.hangup(id)`.

---

## 2. `bin/enrich_from_homer.dart` — SIP-Call-ID enricher

**What it does.** Watches `RECORDINGS_DIR` for the sidecars produced by
§1 and, for each one, queries Homer's TimescaleDB to find the SIP
dialog(s) that carried the call. Writes an enriched copy of the sidecar
(with a `legs[]` array) either back to the same file or into
`ENRICHED_DIR` if set.

**Reads.** Sidecars in `RECORDINGS_DIR` and the `hep_proto_1_call`
hypertable in Homer's Postgres.

**Writes.** Same sidecar shape as §1 plus:

```json
"callid": "<primary Call-ID>",
"legs": [
  {
    "callid": "2d626261-051a-45ee-8b9e-9f863a019abf",
    "from_user": "3636",
    "to_user": "+00260974868299",
    "user_agent": "OmniPCX Enterprise R101.1 n4.205.38",
    "sdp": { "ip": "10.100.37.70", "port": 32514 }
  }
]
```

The critical field is `legs[i].sdp.ip`. For calls that transferred to a
physical agent it's the agent phone's real IP (e.g. `10.100.37.30`),
not the OXE anchor (`10.1.8.226`). That's the "which agent physically
took this call" answer.

**Key env.**

| Var | Default | Purpose |
|---|---|---|
| `HOMER_PG_HOST` | *(required)* | Homer Postgres host — typically `127.0.0.1` on the co-located box |
| `HOMER_PG_PORT` | 5432 | must be exposed to the host by the Homer compose |
| `HOMER_PG_DB` | `homer_data` | |
| `HOMER_PG_USER` | `root` | matches `HEPLIFYSERVER_DBUSER` |
| `HOMER_PG_PASS` | *(required)* | matches `HEPLIFYSERVER_DBPASS` |
| `RECORDINGS_DIR` | `./recordings_out` | input |
| `ENRICHED_DIR` | (unset) | if set, write enriched copies here; else in-place |
| `POLL_INTERVAL_SECS` | 5 | |
| `LOOKBACK_MINUTES` | 60 | ignored with `--backfill` |
| `MIN_AGE_SECS` | 15 | wait N seconds so heplify has flushed |
| `RETRY_UNTIL_MINUTES` | 15 | retry empty results until N min old |

**Flags.** `--once` (cron), `--backfill` (ignore `LOOKBACK_MINUTES`).

**Notes.**

- The Homer join uses `(src customer number ↔ dst=3636 hunt group,
  ± time window)`. Customer number matched by last 9 digits so B2BUA
  prefix rewrites (`+000260…` vs `+00260…`) don't miss.
- INVITEs live in `hep_proto_1_call`, OPTIONS keepalives in
  `_default`. The client hits `_call`.
- We take the *latest* INVITE per Call-ID (not the first) because OXE
  re-INVITEs mid-dialog with the physical agent SDP after the hunt-group
  transfer completes.
- Query requires **both** parties to be present in the dialog to avoid
  matching unrelated concurrent calls to the same hunt group.

---

## 3. `bin/publish_to_mysql.dart` — dashboard publisher

**What it does.** Watches `PUBLISH_SIDECARS_DIR` (default `ENRICHED_DIR`,
falls back to `RECORDINGS_DIR`) and upserts one row per call into the
Laravel CCIVRDashboard's `recordings` table on MySQL. Idempotent: keyed
on `file_name` (which the dashboard already indexes).

**Reads.** Sidecar JSON files.

**Writes.** Rows into the `recordings` table.

### 3.1 Column mapping

| MySQL column | Source | Notes |
|---|---|---|
| `agent_number` | `dst`, normalised | `PJSIP/3636@mytrunk` → `3636` |
| `phone_number` | `src` | customer number as delivered by the trunk |
| `duration_number` | `duration` | legacy string field on the table |
| `file_name` | `<daemon_basename>.<PUBLISH_AUDIO_EXT>` | matches the audio the daemon wrote, e.g. `20260825-073255_unknown_unknown_<uuid>.wav`. `daemon_basename` is fixed at StasisStart before SDPs resolve, so it's `unknown_unknown` even when the sidecar JSON's own name (`ip_tagged_basename`) has real IPs. |
| `file_path` | `<PUBLISH_AUDIO_DIR>/<file_name>` | default `/u01/recordings/<file_name>` |
| `src` | `src` | |
| `dst` | `dst`, normalised | |
| `clid` | `clid` | |
| `calldate` | `calldate` | ISO → `YYYY-MM-DD HH:MM:SS` UTC |
| `answerdate` | `answerdate` | |
| `hangupdate` | `hangupdate` | |
| `duration` | `duration` | cast to int |
| `billsec` | `billsec` | cast to int |
| `disposition` | `disposition` | |
| `agent_no` | first non-B2BUA / non-Asterisk `legs[i].sdp.ip` | best-guess physical agent IP; Laravel's IP-agent map can override |
| `user_id`, `session_id`, `transaction_code` | *(null)* | owned by the Laravel side |
| `created_at`, `updated_at` | *(auto)* | current UTC |

The natural key `file_name` is already indexed by the dashboard migration
`2026_03_26_135926_add_indexes_to_recordings_table.php`, so
check-then-insert is a single indexed lookup per sidecar.

### 3.2 Env

| Var | Default | Purpose |
|---|---|---|
| `PUBLISH_SIDECARS_DIR` | `ENRICHED_DIR` → `RECORDINGS_DIR` → `./recordings_enriched` | input |
| `PUBLISH_AUDIO_DIR` | `/u01/recordings` | where the recorder daemon writes audio |
| `PUBLISH_AUDIO_EXT` | `wav` | audio-file extension (independent of `RECORDER_FORMAT`, which is the RTP payload) |
| `PUBLISH_POLL_SECS` | 30 | |
| `PUBLISH_LOOKBACK_MINUTES` | 120 | ignored with `--backfill` |
| `PUBLISH_AGENT_IP_EXCLUDE` | `10.1.8.,10.1.101.` | comma-separated IP prefixes for OXE anchor + Asterisk |
| `DASHBOARD_MYSQL_HOST` | falls back to `AST_DB_HOST` | |
| `DASHBOARD_MYSQL_PORT` | falls back to `AST_DB_PORT` (3306) | |
| `DASHBOARD_MYSQL_DB` | falls back to `AST_DB_DATABASE` | |
| `DASHBOARD_MYSQL_USER` | falls back to `AST_DB_USERNAME` | |
| `DASHBOARD_MYSQL_PASSWORD` | falls back to `AST_DB_PASSWORD` | |
| `DASHBOARD_MYSQL_POOL_SIZE` | 3 | keep small — Laravel shares this DB |

**Flags.** `--once`, `--backfill`, `--dry-run`.

**Notes.**

- The old `bin/queue_app*.dart` binaries called
  `CallRecording.insertCallRecording()` inline as the call ended.
  The current `bin/record_calls.dart` does **not** — it writes only the
  sidecar JSON. This publisher is what closes the loop.
- If you extend the migration with a `sip_legs` related table later,
  extend the publisher's `_publishOne` to also `insert` into it.

---

## 4. `bin/cleanup_disk.dart` — disk-space guardian

**What it does.** Watches a filesystem (`CLEANUP_MONITOR_PATH`, default
`/`) and, when usage rises above `DISK_HIGH_WATERMARK_PCT`, prunes the
oldest data across a prioritised list of targets until usage drops below
`DISK_LOW_WATERMARK_PCT`. Nothing younger than `CLEANUP_MIN_AGE_DAYS`
(default 14) is ever touched, regardless of disk pressure.

This is a safety valve. Homer already auto-rotates via
`HEPLIFYSERVER_DBDROPDAYS=5` (see `docker/docker-compose.yml`), and
Asterisk's logrotate covers `/var/log/asterisk`. This daemon only wakes
up when normal retention isn't keeping up.

### 4.1 Prune order (least valuable → most valuable)

1. **`recordings_enriched/*.json`** — cheap to regenerate from raw
   sidecars if you ever need them back.
2. **`recordings_out/*.json`** — original sidecars.
3. **`/u01/recordings/*.{wav,alaw,g729,ulaw}`** — audio
   files (biggest byte savings; recursive).
4. **`/var/log/asterisk/{full.*,messages.*,*.gz}`** — only rotated
   Asterisk logs. **Never** the live `full` file (it has an open FD
   from Asterisk — deleting it wouldn't free space anyway).
5. **Homer `hep_proto_1_default`** — OPTIONS keepalives.
6. **Homer `hep_proto_1_call`** — INVITE/BYE dialogs (highest-value SIP
   data, pruned last).

Between each target the daemon re-runs `df` and stops as soon as usage
drops below the low mark.

Homer pruning uses TimescaleDB `SELECT drop_chunks(...)` which
immediately frees space; falls back to `DELETE` if the target isn't a
hypertable.

### 4.2 Env

| Var | Default | Purpose |
|---|---|---|
| `CLEANUP_MONITOR_PATH` | `/` | the mount whose `df%` drives the decisions |
| `DISK_HIGH_WATERMARK_PCT` | 85 | start pruning at/above this |
| `DISK_LOW_WATERMARK_PCT` | 75 | stop when back under this |
| `CLEANUP_MIN_AGE_DAYS` | 14 | hard safety gate — never delete anything younger |
| `CLEANUP_SKIP_RECENT_SECS` | 60 | skip files modified in the last N seconds (writes in flight) |
| `CLEANUP_MAX_DELETES_PER_RUN` | 5000 | per-target cap per pass |
| `CLEANUP_POLL_MINUTES` | 15 | |
| `CLEANUP_DRY_RUN` | `false` | flip to `true` to preview |
| `CLEANUP_ENRICHED_DIR` / `CLEANUP_SIDECARS_DIR` / `CLEANUP_AUDIO_DIR` / `CLEANUP_ASTERISK_LOG_DIR` | see `.env` | override target paths |
| `CLEANUP_AUDIO_GLOB` / `CLEANUP_ASTERISK_LOG_GLOB` | see `.env` | which files inside each path are eligible |
| `HOMER_PRUNE_ENABLED` | `true` | if false, Homer is left alone |
| `HOMER_PRUNE_MIN_AGE_DAYS` | 14 | independent of the file min-age |
| `HOMER_PG_*` | (reuses enricher creds) | |

**Flags.** `--once`, `--dry-run`.

---

## 5. Running under systemd

All four binaries follow the same wrapper pattern. Example for the
publisher:

`/etc/systemd/system/publish_to_mysql.service`:

```ini
[Unit]
Description=CCIVR sidecar publisher (JSON -> MySQL recordings)
After=network-online.target mysqld.service
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/usr/src/ari_proxy
ExecStart=/usr/src/ari_proxy/publish_to_mysql.sh
Restart=on-failure
RestartSec=10
LimitNOFILE=65536
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

`/usr/src/ari_proxy/publish_to_mysql.sh`:

```bash
#!/bin/sh
set -e
cd /usr/src/ari_proxy
exec ./publish_to_mysql.exe
```

```bash
chmod +x /usr/src/ari_proxy/publish_to_mysql.{sh,exe}
sudo systemctl daemon-reload
sudo systemctl enable --now publish_to_mysql.service
sudo journalctl -u publish_to_mysql.service -f
```

Repeat the same shape for `enrich_from_homer` and `cleanup_disk`
(and for the recorder itself if it isn't already systemd-managed).
`WorkingDirectory=/usr/src/ari_proxy` is critical for every binary
because the defaults reference relative paths like `./recordings_out`.

### 5.1 Ordering

The three post-recording services can run in any order — each is a poll
loop with its own safety gates:

- `record_calls` writes sidecars.
- `enrich_from_homer` waits `MIN_AGE_SECS`, retries empty results,
  and eventually writes enriched copies.
- `publish_to_mysql` reads the enriched copies (or raw sidecars if
  `ENRICHED_DIR` isn't set) and upserts on MySQL. It's idempotent, so
  it can re-publish the same file after the enricher adds `legs`.
- `cleanup_disk` runs independently; only reacts to disk pressure.

If your ops team prefers explicit dependencies, add
`After=enrich_from_homer.service` to the publisher unit, but it's not
required.

---

## 6. Compile + deploy

From the Windows dev box:

```powershell
dart compile exe bin/record_calls.dart       --target-os=linux -o bin/record_calls.exe
dart compile exe bin/enrich_from_homer.dart  --target-os=linux -o bin/enrich_from_homer.exe
dart compile exe bin/publish_to_mysql.dart   --target-os=linux -o bin/publish_to_mysql.exe
dart compile exe bin/cleanup_disk.dart       --target-os=linux -o bin/cleanup_disk.exe
```

Then rsync/scp all four `.exe`s and the `.env` to
`/usr/src/ari_proxy/` on `ccivr.zesco.co.zm`.

---

## 7. Troubleshooting quickstart

| Symptom | Look here |
|---|---|
| `UnicastRTP` channels piling up in `core show channels` | fixed by the `externalMediaDelete → hangup` swap in the recorder; see `docs/ari-recorder/ops-orphan-cleanup.md` for the historical runbook |
| Enricher writes `legs=0` on every recording | check Homer is receiving HEP: `sudo tcpdump -ni lo -c 10 udp port 9060` during a live call, then `podman logs heplify-server` |
| Enricher writes `legs=<huge number>` with mixed SDP IPs | pre-`f7c6e2c` binary; recompile — the query since that commit requires both parties to be on the dialog |
| Enricher connects but returns `not-found` on everything | check `HOMER_PG_*` credentials in `.env` match `HEPLIFYSERVER_DBUSER/DBPASS` in the Homer compose |
| Publisher errors `access denied for user` | `DASHBOARD_MYSQL_USER` needs `SELECT, INSERT, UPDATE` on the `recordings` table (and only that) |
| Cleanup daemon logs "still X% after all targets exhausted" | means `MIN_AGE_DAYS` is holding back everything; either legitimately need more disk, or lower `CLEANUP_MIN_AGE_DAYS` for a controlled emergency prune |
| systemd service exits immediately | wrapper script backgrounded the exe instead of `exec`-ing it; see §5 for the correct wrapper |
