# SIP timeline publisher (`publish_sip_timeline`)

Standalone daemon that enriches recorded calls with SIP-level facts pulled
from Homer / heplify-server's TimescaleDB, and writes them into the
CCIVRDashboard Laravel MySQL table `recording_sip_timeline`.

Entry point: [bin/publish_sip_timeline.dart](../../bin/publish_sip_timeline.dart).
Library it builds on: [lib/ari/homer/homer_client.dart](../../lib/ari/homer/homer_client.dart)
and [lib/ari/homer/sip_timeline.dart](../../lib/ari/homer/sip_timeline.dart).

> The Laravel side (table migration, Eloquent model, Livewire views,
> frontend navigation) is documented in the CCIVRDashboard repo at
> `docs/recording-sip-timeline.md`. This file covers only the Dart daemon
> and library.

---

## 1. Where it sits in the pipeline

```
record_calls.dart      → writes  RECORDINGS_DIR/<basename>.json  (ARI-derived sidecar)
enrich_from_homer.dart → adds    legs[]  (SIP Call-IDs looked up in Homer)
publish_to_mysql.dart  → upserts `recordings` row in Laravel MySQL
publish_sip_timeline.dart → upserts `recording_sip_timeline` row      ← THIS
```

The daemon only processes sidecars that already have a `legs[]` array (i.e.
`enrich_from_homer` has finished with them), and only after the matching
`recordings` row exists (i.e. `publish_to_mysql` has caught up). If either
is not yet true it logs a `skip … (… may not have caught up yet)` line and
retries on the next poll. This is normal and self-correcting.

---

## 2. What it does per sidecar

1. Read the enriched JSON sidecar; require a non-empty `legs[]`.
2. Resolve the audio filename `<daemon_basename>.<PUBLISH_AUDIO_EXT>` and
   look up the matching `recordings` row (natural key `file_name`) to get
   `recordings.id`, `src`, `dst`.
3. Load **every** SIP message for the sidecar's Call-IDs from Homer's
   `hep_proto_1_call` (INVITE / 1xx / 2xx / 4xx / BYE / CANCEL and their
   responses) via `HomerClient.loadMessagesForSids`.
4. Reduce the primary dialog's messages to a timeline with
   `SipTimeline.reduce` (see §5).
5. Compute the real agent phone IP from the SDP anchors, excluding the
   B2BUA / Asterisk prefixes (`PUBLISH_AGENT_IP_EXCLUDE`).
6. Upsert one row into `recording_sip_timeline` keyed on `recording_id`.

---

## 3. Configuration (`.env`)

Reuses the same Homer + MySQL credentials as the sibling daemons.

| Var | Default | Purpose |
|-----|---------|---------|
| `PUBLISH_SIDECARS_DIR` | `ENRICHED_DIR` → `RECORDINGS_DIR` → `./recordings_enriched` | Input dir of enriched sidecars |
| `PUBLISH_AUDIO_EXT` | `wav` | Extension used to resolve the `recordings.file_name` lookup |
| `TIMELINE_POLL_SECS` | `30` | Poll interval |
| `TIMELINE_LOOKBACK_MINUTES` | `120` | Only scan sidecars modified within this window |
| `TIMELINE_EVENT_LIMIT` | `100` | Cap on the `events[]` JSON blob length |
| `PUBLISH_AGENT_IP_EXCLUDE` | `10.1.8.,10.1.101.` | Comma-separated IP prefixes treated as B2BUA/Asterisk anchors |
| `HOMER_PG_HOST` / `_PORT` / `_DB` / `_USER` / `_PASS` | — / 5432 / homer_data / root / — | Homer TimescaleDB (Postgres) |
| `DASHBOARD_MYSQL_HOST` / `_PORT` / `_DB` / `_USER` / `_PASSWORD` | falls back to `AST_DB_*` | Laravel dashboard MySQL |
| `DASHBOARD_MYSQL_POOL_SIZE` | `3` | Connection pool size |

Flags:

| Flag | Effect |
|------|--------|
| `--once` | Run one scan and exit (cron / manual) |
| `--backfill` | Ignore `TIMELINE_LOOKBACK_MINUTES`; scan everything |
| `--refresh` | Re-process sidecars even if a timeline row already exists |
| `--dry-run` | Log what would be written; write nothing |

---

## 4. Build & deploy

The production box (Oracle Linux 8, glibc 2.28, PHP 7.4) has **no Dart
SDK**. Cross-compile a Linux binary from a workstation that does:

```powershell
# from the repo root
dart compile exe --target-os linux --target-arch x64 `
  bin/publish_sip_timeline.dart -o bin/publish_sip_timeline.linux.exe

# deploy + restart the service
scp bin/publish_sip_timeline.linux.exe ccivr:/usr/src/ari_proxy/publish_sip_timeline.exe
ssh ccivr 'systemctl restart publish_sip_timeline'
```

Cross-compile requires Dart SDK ≥ 3.5 (`--target-os`). Verified with 3.11.5.
The produced binary is a normal ELF x86-64, dynamically linked against
glibc ≥ 2.6.32 — loads fine on OL8.

### Wrapper + systemd

- Wrapper: `/usr/src/ari_proxy/publish_sip_timeline.sh` — same
  log-rotation pattern as `enrich_from_homer.sh` (backs up the previous
  `sip_timeline.log` into `logs/` on each start, then execs the binary).
- Unit: `/etc/systemd/system/publish_sip_timeline.service`
  ```ini
  [Unit]
  Description=SIP-timeline enricher for CCIVR (writes recording_sip_timeline from Homer HEP data)
  After=network-online.target mariadb.service mysqld.service
  Wants=network-online.target

  [Service]
  ExecStart=/usr/src/ari_proxy/publish_sip_timeline.sh
  Restart=on-failure
  RestartSec=10
  LimitNOFILE=65536

  [Install]
  WantedBy=multi-user.target
  ```

Operate it like the siblings:

```bash
systemctl status  publish_sip_timeline
systemctl restart publish_sip_timeline
journalctl -u publish_sip_timeline -f          # start/stop/crash events
tail -f /usr/src/ari_proxy/sip_timeline.log     # application log
```

---

## 5. Library additions

### `HomerClient.loadMessagesForSids` — [lib/ari/homer/homer_client.dart](../../lib/ari/homer/homer_client.dart)

Loads every SIP message for a set of Call-IDs (`sid`) within a time window,
grouped by `sid`, ordered chronologically. Returns `HomerMessage` objects
carrying `method` (request verb, or numeric response code as a string),
`fromUser`, `toUser`, `cseq`, `userAgent`, `createDate`, and the raw SIP
for SDP parsing. `HomerMessage.isResponse` / `statusCode` classify a row as
a request vs a response.

heplify-server encodes SIP **responses** with the numeric status code in
`data_header->>'method'` (e.g. `"180"`, `"200"`, `"487"`). The reducer
relies on that convention; if your install differs, adjust the parsing in
`loadMessagesForSids` and `SipTimeline.reduce`.

### `SipTimeline.reduce` — [lib/ari/homer/sip_timeline.dart](../../lib/ari/homer/sip_timeline.dart)

Walks one dialog's chronological message list and produces the timeline
columns plus two hangup classifications:

- **`hangupInitiator`** — raw SIP-side semantics:
  - BYE.From == INVITE.From → `caller`, else `callee`
  - CANCEL → `caller`
  - only a 4xx/5xx/6xx final → `system`
  - otherwise `unknown`
- **`hangupBy`** — business meaning, topology-independent. Given the known
  customer number, it digit-suffix-matches the party that sent BYE:
  `customer` | `agent` | `system` | `unknown`.

The distinction matters because of the **B2BUA inversion**: in the ZESCO
setup the Alcatel OXE originates the INVITE toward Asterisk *from the agent
side*, so the raw SIP "caller" is actually the agent. Verified over 125
real calls: `hangupInitiator=callee` ≈ `hangupBy=customer` (92) and
`hangupInitiator=caller` ≈ `hangupBy=agent` (26). Prefer `hangupBy` for any
human-facing report.

### Why the latest INVITE

`HomerClient.findLegs` (used by `enrich_from_homer`) selects
`DISTINCT ON (sid) … ORDER BY create_date DESC` — the **latest** INVITE per
dialog. Behind a B2BUA the initial INVITE anchors media at the B2BUA
(e.g. `10.1.8.226`); a later re-INVITE carries the real agent phone IP in
`c=IN IP4 …`. Surfacing the latest is what makes `agent_phone_ip` useful.

---

## 6. Output row (written to `recording_sip_timeline`)

`recording_id`, `caller_number`, `callee_extension`, `primary_sip_call_id`,
`invite_at`, `ringing_at`, `answered_at`, `bye_at`, `cancel_at`,
`terminated_at`, `hangup_initiator`, `hangup_method`, `hangup_status_code`,
`hangup_by`, `caller_user_agent`, `callee_user_agent`, `caller_media_ip/port`,
`callee_media_ip/port`, `agent_phone_ip`, `leg_count`, `legs` (JSON),
`events` (JSON). Column meanings live in the CCIVRDashboard doc.

Timestamps are converted from UTC (Homer) to server-local before writing,
so they line up with the Laravel app's `config('app.timezone')` on display
— same convention as `publish_to_mysql.dart`.

---

## 7. Manual runs

```bash
cd /usr/src/ari_proxy

# dry-run the last 2h, write nothing
./publish_sip_timeline.exe --once --dry-run

# backfill everything, write nothing (inspect first)
./publish_sip_timeline.exe --once --backfill --dry-run

# re-process rows already in the table (e.g. after a schema change)
./publish_sip_timeline.exe --once --backfill --refresh
```

A full `--backfill` scan is O(one Homer query per sidecar) and can take a
while with tens of thousands of sidecars; narrow it with
`TIMELINE_LOOKBACK_MINUTES=<n>` when iterating.
