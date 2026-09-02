# Scope of Works — Call-Recording Dashboard (Laravel)

**Project:** CCIVR Contact-Centre Recording Reporting Module
**Backend platform:** Asterisk 22.10.1 + custom Dart ARI recorder + Homer 7 SIP capture
**New deliverable:** Laravel 11 dashboard for search, playback, reporting, and Veeam-aware archive of call recordings
**Timeline:** 14 working days from kick-off — see §7 for the day-by-day plan
**Prepared:** 2026-09-02

---

## 1. Executive summary

A working recording pipeline already produces one audio file plus one JSON metadata sidecar per call, and enriches each sidecar with the physical-agent IP taken from Homer's SIP capture. The pipeline is running in production on `ccivr.zesco.co.zm` behind an Alcatel-Lucent OmniPCX Enterprise B2BUA and generates ~thousands of recordings per day.

This SOW covers the **Laravel-based dashboard** that will (a) ingest those sidecars into a searchable database, (b) present an operator/QA-friendly web UI for reviewing recordings, (c) integrate with Homer for on-demand SIP-ladder viewing, and (d) participate correctly in the existing Veeam-based backup/restore rotation so the DB keeps a full audit history even after audio files roll off primary storage.

---

## 2. Current state — what has been delivered

### 2.1 Recording capture (`bin/record_calls.dart`)

Runnable Dart binary compiled to a native Linux exe, deployed as a systemd service on the Asterisk box.

- Subscribes to Asterisk ARI over WebSocket for the `hello` Stasis app.
- On inbound Stasis entry: answers the caller, originates the peer leg to `PJSIP/3636@mytrunk` (the OXE hunt-group DID), joins caller + peer + an `externalMedia` UnicastRTP fork into a mixing bridge.
- Streams the mixed RTP via the externalMedia leg to a separate recorder daemon on `:8085` which writes the audio file (alaw/g729/wav depending on `RECORDER_FORMAT`).
- Writes a JSON sidecar per call into `recordings_out/` at StasisEnd. Fields include: `src`, `dst`, `clid`, `calldate`, `answerdate`, `hangupdate`, `duration`, `billsec`, `disposition`, `caller_rtp_local/remote`, `peer_rtp_local/remote`, `caller_sip_remote`, `peer_sip_remote`, `daemon_basename`, `ip_tagged_basename`.
- Reconciles cleanly on `StasisEnd` / peer `ChannelDestroyed` / setup-failure paths; hangs up the externalMedia leg and destroys the bridge (bug in the underlying ARI client where `externalMediaDelete` omitted `api_key` was fixed here, eliminating the orphan-UnicastRTP leak that had accumulated 297 dead channels in production).
- Auto-reconnects to the ARI WebSocket after `ApplicationReplaced`.

### 2.2 SIP-wire capture (Homer 7)

- Deployed Homer 7 (TimescaleDB flavour) as a Podman-Compose stack on the Asterisk box (`/opt/homer7-docker/heplify-server/hom7-timescaledb-all/`).
- Enabled Asterisk's `res_hep` + `res_hep_pjsip` + `res_hep_rtcp` modules; every SIP message and RTCP report now goes to `heplify-server` over HEP UDP/9060 and is stored in `timescale/timescaledb:latest-pg11`.
- Homer web UI at `:9080` provides search + ladder diagrams keyed on Call-ID.
- Retention default `DBDropDays=5` — configurable.

### 2.3 Call-ID enrichment (`bin/enrich_from_homer.dart`)

Second Dart binary, also runnable as a systemd service, which reads sidecars from `recordings_out/`, queries Homer's Postgres directly, and writes an enriched copy to `recordings_enriched/`.

- Cross-references each recording's `(src customer number, dst=3636 hunt group, time window)` against `hep_proto_1_call`.
- Fuzzy-matches the customer number by its last 9 digits so B2BUA prefix rewrites (`+000260…` vs `+00260…`) don't miss.
- Extracts every distinct SIP dialog (Call-ID) that involved both parties, picks the **latest** INVITE per Call-ID (so the OXE re-INVITE with the physical agent's SDP wins over the initial hunt-group answer), and appends a `legs[]` array containing `{callid, from_user, to_user, user_agent, sdp: {ip, port}}` for each.
- The critical field is `sdp.ip` — for calls that successfully transferred to a physical agent it's the agent phone's real IP (e.g. `10.100.37.30`), not the OXE anchor (`10.1.8.226`). This is the "which agent physically took this call" answer the project set out to produce on day one.
- Race gates: `MIN_AGE_SECS` skips too-fresh sidecars so `heplify-server` has time to flush; `RETRY_UNTIL_MINUTES` re-queries empty results in case OXE's re-INVITE trails the initial answer.
- Idempotent (skips sidecars whose enriched copy already exists) with `--once` for cron and `--backfill` for historic runs.

### 2.4 Sanitised production `.env` template

`.env.example` committed to git, real `.env` untracked. Production credentials (`ASTERISK_ARI_PASSWORD`, `AST_DB_PASSWORD`, `REDIS_PASSWORD`) still present in git *history* — rotation is a pending TODO.

### 2.5 Ops docs

- `docs/ari-recorder/ops-orphan-cleanup.md` — dry-run + safe-kill commands for orphaned `UnicastRTP` legs (obsolete once the `externalMediaDelete` fix landed, kept as a runbook).
- Existing `docs/ari-recorder/*.md` — how-to-run, daemon protocol, library API, implementation notes, agent-identification design.

### 2.6 Data on disk (input for the dashboard)

Per call, on `ccivr.zesco.co.zm`:

| File | Location | Notes |
|------|----------|-------|
| Audio | `<VOICE_LOGGER>/…<daemon_basename>.alaw` | Written by the recorder daemon, ~1–3 MB per 5-min call in alaw |
| Sidecar | `/usr/src/ari_proxy/recordings_out/<basename>.json` | 1–3 KB, written at StasisEnd |
| Enriched sidecar | `/usr/src/ari_proxy/recordings_enriched/<basename>.json` | Same file plus `legs[]` |

---

## 3. Scope — what still needs to be built

### 3.1 High-level goals

- Give supervisors, QA, and support staff a **web dashboard** to find, listen to, tag, and export recordings.
- Enrich each recording with **agent identity** — resolve the `sdp.ip` in each `legs[]` entry to a human agent name via a mapping table maintained inside the dashboard.
- Provide standard **contact-centre reports** — call volume by day/hour/agent/queue, abandon rate, average handle time, disposition breakdown.
- Support **long-term retention** in a way that keeps every DB row forever while allowing audio files to roll into Veeam and be restored on demand.

### 3.2 Functional scope

1. **Sidecar ingestion daemon**
   - Laravel scheduled command (`php artisan recordings:ingest`) runs every N seconds via `schedule:run`.
   - Reads new `*.json` files in `ENRICHED_DIR` (mount point on the Laravel host), upserts one row per recording into the DB keyed by `daemon_basename`.
   - Normalises `legs[]` into a related table (one row per SIP leg).
   - Optionally moves processed JSONs into a `processed/` folder so the working set stays small.
   - Idempotent — re-ingesting the same file must not create duplicates.

2. **Data model** (proposed, subject to review)
   - `recordings` — one row per call: id, uid (from filename), src, dst, clid, calldate, answerdate, hangupdate, duration, billsec, disposition, audio_path, audio_format, audio_size_bytes, storage_state (`online`/`archived`/`restore_pending`/`purged`), created_at, updated_at.
   - `sip_legs` — one row per Call-ID: id, recording_id, callid, from_user, to_user, user_agent, sdp_ip, sdp_port.
   - `agents` — id, extension, name, email, active, notes.
   - `agent_ip_map` — id, ip, agent_id, valid_from, valid_to (so the same IP can belong to different agents over time as desks rotate).
   - `tags` — id, name, colour.
   - `recording_tags` — pivot for QA labelling.
   - `restore_requests` — id, recording_id, requested_by, requested_at, veeam_job_id (nullable), state (`pending`/`in_progress`/`completed`/`failed`), notes.
   - `users` — Laravel default plus a `role` (`admin`/`supervisor`/`qa`/`viewer`).

3. **Web UI**
   - **Login** with Laravel Fortify or Breeze; SSO out of scope for phase 1.
   - **Search page** — filters for date range, agent, extension, caller number, minimum duration, disposition, tag, storage state; server-side pagination.
   - **Recording detail page** — playback (HTML5 `<audio>` with waveform via wavesurfer.js), full sidecar JSON viewer, SIP-legs table with a deep-link to the corresponding Homer ladder (`https://<homer-host>:9080/#/search/result?callid=<callid>&…`), tag editor, notes.
   - **Agent management** — CRUD for agents and IP↔agent mappings; a bulk import from CSV for the phone-directory rollout.
   - **Dashboards / reports** — daily call volume chart, agent leaderboard (calls handled, avg handle time), abandonment funnel, top callers; export to CSV and PDF.
   - **Restore-request workflow** — for `archived` recordings, a "Request restore" button that creates a `restore_requests` row and (optionally) POSTs to Veeam's REST API (see §3.5).
   - Everything behind the standard Laravel auth middleware; role-based gates on destructive actions.

4. **API**
   - Read-only JSON API mirroring the UI (Sanctum tokens) so future mobile / QA-tool integrations can consume it without scraping the UI.

### 3.3 Deployment target

- **Production host:** the Laravel app is co-located on **`ccivr.zesco.co.zm`** (Oracle Linux 8) alongside the existing Asterisk 22.10.1 + Dart recorder + enricher + Homer 7 (Podman) stack. **No new VM is provisioned.** Extra services to install on the box: PHP 8.3, PHP-FPM, Nginx, Redis (queues + cache), Node 20 (build only), `oci8` PHP extension, `yajra/laravel-oci8`.
- **Development / staging:** identical stack **except MySQL 8** in place of Oracle DB, so devs can spin up locally without needing an Oracle instance. Schema is portable; production migrations are validated against Oracle before go-live (see below).
- **Laravel ↔ Oracle:** stock Laravel ships MySQL/Postgres drivers only. Oracle support is via the community `yajra/laravel-oci8` package plus the `oci8` PHP extension. This is a phase-0 install task on `ccivr.zesco.co.zm`; dev boxes don't need it.
- **Schema-portability rules:**
  - No MySQL-only column types (avoid `enum`; use `varchar` + Laravel casts).
  - No auto-`updated_at` triggers — Eloquent handles it in userland.
  - Case-sensitive identifiers: Oracle folds unquoted identifiers to upper-case; standardise on all-lower-case snake_case for tables and columns and let Laravel quote them.
  - Full-text search on caller number / notes: keep it to `LIKE '%…%'` in phase 1; MySQL FT indexes and Oracle Text differ enough that we'll add a search-engine layer (Meilisearch / OpenSearch) in phase 2 if needed.
- **Co-location constraints on `ccivr.zesco.co.zm`:**
  - Ports already in use on the box: Asterisk ARI `8088`, Homer web `9080`, Grafana `3000`, HEP ingest `9060/udp`, Homer Postgres `127.0.0.1:5432`, recorder daemon `8085`, custom Redis `6379`, and the existing internal API on `8001` (see `SERVER_PORT` in `.env`). Nginx for the dashboard needs an unused port — propose `8443` for HTTPS (behind a corporate reverse-proxy if the LAN needs `443`).
  - **Sidecars and audio files are already on this host** — no NFS/CIFS mount required. Laravel reads directly from `/usr/src/ari_proxy/recordings_enriched/` and the recorder daemon's audio output path.
  - Recorder and enricher already run as systemd services. Laravel adds three more: `laravel-queue.service`, `laravel-schedule.service` (or a single one-shot per minute unit), and the storage-watcher command.
  - **Host capacity:** `ccivr.zesco.co.zm` is a 44-core physical machine, so resource contention between the Laravel stack and the real-time SIP/RTP pipeline is not a practical concern at expected load. Standard PHP-FPM defaults are fine; `queue:work` gets 2 workers.
- HTTPS via Let's Encrypt / ZESCO internal CA.

### 3.4 Homer integration

- Store the Homer base URL in `config/services.php`.
- Each SIP-leg row renders a link like `${homer_url}/#/search/result?param=callid&value=${leg.callid}&fromts=${calldate-30s}&tots=${hangupdate+30s}` so the QA reviewer can jump straight to the ladder diagram.
- No writes to Homer; read-only reference.

### 3.5 Veeam backup / restore integration

Veeam Backup & Replication **is already installed** for this environment and is actively backing up the recordings on `ccivr.zesco.co.zm`. The dashboard therefore treats Veeam as an existing, healthy repository and focuses on the *restore* path — when audio has rolled off primary storage, the dashboard lets an authorised user request that Veeam bring it back.

**Design principles:**

- **DB rows are permanent.** A recording row is *never* deleted just because its audio was archived. A row is only ever soft-deleted by an admin via the UI.
- **Storage state per row.** A `storage_state` enum tracks whether the audio is available now:
  - `online` — the file exists on the local recordings path and is playable.
  - `archived` — the file is no longer on the local recordings path; Veeam still has it. The player replaces the audio element with a "Request restore" panel.
  - `restore_pending` — a `restore_requests` row is in flight.
  - `purged` — audio is intentionally gone (e.g. GDPR request, retention policy). The row keeps the metadata but the file is not restorable.
- **Storage watcher.** A scheduled command scans the recordings path, flips rows to `online` when the file reappears (Veeam finished a restore) or to `archived` when a rolling retention policy sweeps it off primary.
- **Retention policy config.** Admin-settable "Files older than N days move to `archived` state (metadata kept)"; the storage watcher enforces it.
- **Veeam REST API hooks** (Enterprise Manager v12 REST endpoints) — delivered day 11:
  - `GET /api/v1/backupObjects/{id}` to locate which backup contains a given audio file (by path).
  - `POST /api/v1/restoreSessions` to submit a file-level restore back to the primary recordings path.
  - Poll the returned session id until completion; update `restore_requests.state`.
  - Credentials in `.env` (`VEEAM_ENT_MGR_URL`, `VEEAM_USER`, `VEEAM_PASSWORD`, `VEEAM_REPO_ID`). Rotate before go-live.
- **Manual fallback.** If the REST endpoint is not exposed to the app for policy reasons, or ops prefer to keep restores under human review, the same `restore_requests` row + email-to-ops workflow is a config toggle and remains supported.

### 3.6 Non-functional requirements

- **Retention of metadata:** indefinite (keep every row forever).
- **Retention of audio on primary:** configurable, default 90 days.
- **Backup of the dashboard DB:** nightly `mysqldump` / `expdp` into a path that Veeam is already sweeping on `ccivr.zesco.co.zm`, so the DB is picked up by the existing rotation with no new job to configure.
- **Auth:** password + optional TOTP. LDAP/AD SSO is out of scope for phase 1, in scope for phase 2.
- **Audit:** log every playback, download, tag change, restore request, and admin action into an `activity_log` table (spatie/laravel-activitylog).
- **Performance:** search page returns first 25 results in ≤ 500 ms for a DB with 12 months (~1 M rows) of recordings.
- **Browser support:** current Chrome, Edge, Firefox. IE unsupported.
- **Accessibility:** WCAG 2.1 AA for the playback and search pages.

### 3.7 Security

- CSRF tokens on all state-changing endpoints (Laravel default).
- Downloads of audio files stream through a signed short-lived URL (Laravel `URL::temporarySignedRoute`) so raw file paths are never exposed.
- All API tokens scoped and expirable via Sanctum.
- Rate-limit login and API endpoints.
- OWASP Top 10 review before go-live.

---

## 4. Assumptions

- The Homer web UI is reachable from the QA-team workstations (i.e. corporate LAN can hit `ccivr.zesco.co.zm:9080`).
- **Veeam is already installed and actively backing up the recordings on `ccivr.zesco.co.zm`.** The dashboard consumes this as a fact and only needs a service account + REST endpoint URL for the automated restore path (day 11); no new backup jobs are set up.
- Agent-directory data (extension ↔ name ↔ IP) will be provided by ZESCO in a CSV for the initial rollout.
- Alcatel OXE call-flow remains as documented: customer → OXE → `3636` hunt group → agent, with the re-INVITE carrying the agent's SDP.
- The recorder daemon on `:8085` continues to write files under a stable path scheme.

---

## 5. Out of scope (phase 1)

- Real-time (< 30 s) call visibility — dashboard is post-hangup only.
- Live listen-in / whisper / barge.
- Speech-to-text transcription.
- Sentiment analysis or PCI/PII redaction of audio.
- LDAP/AD SSO — deferred to phase 2.
- Mobile app.
- Multi-tenancy — single call centre only.
- Migrating existing legacy recordings that predate the sidecar format.

---

## 6. Deliverables

1. Laravel application source in a new git repo.
2. Database migrations + seeders (including a default admin user).
3. `docker-compose.yml` for local dev.
4. Systemd units for `queue:work`, `schedule:run`, and the ingest command.
5. Nginx site config template.
6. `README.md` covering install, `.env` reference, first-run steps, Veeam credential setup, and NFS-mount example.
7. This SOW updated with any scope changes agreed during development.

---

## 7. Timeline — 14 working days

Total: **14 working days** (roughly three calendar weeks depending on public holidays). The 14-day window absorbs the previously deferred items — Veeam REST integration, PDF export, waveform — and adds explicit hardening and handover days at the end. Nothing in §3 stays deferred.

### 7.1 Week 1 (days 1–5) — foundation & core UI

| Day | Deliverable |
|---|---|
| 1 | Repo bootstrap (Laravel 11, Breeze auth, Sanctum). CI. **Local dev stack: MySQL 8** via docker-compose. **On `ccivr.zesco.co.zm`:** install PHP 8.3, PHP-FPM, Nginx (bound to the agreed unused port), Redis, `oci8` PHP extension, `yajra/laravel-oci8`; prove `php artisan tinker` can connect to the Oracle DB. Empty admin user seeded. |
| 2 | DB migrations for `recordings`, `sip_legs`, `agents`, `agent_ip_map`, `tags`, `recording_tags`, `restore_requests`, `users.role`, `activity_log`. Model + factory + seed data. |
| 3 | Ingest command (`recordings:ingest`) that reads `ENRICHED_DIR`, upserts one recording + N sip_legs per JSON, moves processed files to `processed/`. Idempotent. Backfill a week of production sidecars into dev DB. |
| 4 | Search page: filters (date range, agent, extension, caller, disposition, tag, storage state), server-side pagination, sort. |
| 5 | Recording detail page: signed-URL streaming audio player (wavesurfer.js), sidecar JSON viewer, SIP-legs table with Homer deep-link. |

### 7.2 Week 2 (days 6–10) — agents, reports, storage, auth

| Day | Deliverable |
|---|---|
| 6 | Agent CRUD + IP↔agent map with `valid_from` / `valid_to`. CSV import for initial directory rollout. Tag CRUD + pivot on recordings. |
| 7 | Reports page: daily call volume chart, agent leaderboard, disposition pie, top callers. CSV export. |
| 8 | Storage-state watcher (scheduled command): scans the recordings paths, flips rows between `online` / `archived` based on file presence and retention policy. `storage_state` badge everywhere; "Request restore" UI on archived rows creates `restore_requests` rows and emails the ops team (Veeam REST wiring lands day 11). |
| 9 | Auth hardening: role gates, signed-URL downloads, activity log on every playback / download / mutation. Rate limits on login and API. Security review pass against OWASP top 10. |
| 10 | Deploy the alpha to `ccivr.zesco.co.zm`. Nginx + PHP-FPM + queue-worker + scheduler + storage-watcher systemd units. Smoke test with live sidecars ingesting from the local `ENRICHED_DIR`. Internal QA walkthrough. |

### 7.3 Week 3 (days 11–14) — Veeam, polish, load, handover

| Day | Deliverable |
|---|---|
| 11 | **Veeam REST integration.** `POST /api/v1/restoreSessions` from the restore-request queue job; poll session state and flip `restore_requests` row to `completed`/`failed`; storage-watcher confirms file is back online. Credentials from `.env` (`VEEAM_ENT_MGR_URL`, `VEEAM_USER`, `VEEAM_PASSWORD`, `VEEAM_REPO_ID`). Manual/email fallback path kept as a config toggle. |
| 12 | **Reporting polish.** PDF export of reports (via `barryvdh/laravel-dompdf`). Wavesurfer.js waveform on the audio player. Saved-search / bookmark filters. |
| 13 | **Load / durability.** Backfill 30 days of production sidecars into the DB, tune indexes on `recordings(calldate, dst)`, `sip_legs(callid)`, and `agent_ip_map(ip, valid_from, valid_to)` to keep the search page under 500 ms at 1M+ rows. Redis cache warm-up on the reports queries. DB dump added to the nightly backup path Veeam already snapshots. |
| 14 | **Documentation + handover.** Admin runbook (add agent, rotate Veeam credentials, restart services), operator quick-start (search, playback, restore-request), on-call cheatsheet (queue stuck, ingest lag, storage-watcher divergence). 60-minute walkthrough with QA supervisors and ops. Sign-off. |

### 7.4 What has to be true for the 14 days to hold

Any slip on the items below adds day-for-day to the schedule:

- No new VM required — `ccivr.zesco.co.zm` is already running and remains the production host. PHP 8.3, Nginx, Redis, Node 20, `oci8` + `yajra/laravel-oci8` installed on the box by **end of day 1**. Oracle DB connectivity from this host (host, port, service name / SID / PDB, credentials for the dashboard schema) confirmed same day.
- Sidecars and audio files are already local; **no NFS/CIFS mount work required**.
- Homer web URL reachable from the QA-team workstations by day 5.
- Agent directory CSV (extension, name, current IP) delivered by **day 5**.
- **Veeam service account + REST endpoint URL delivered by end of day 10**, so day 11 can start on time. If the credential doesn't land, day 11 falls back to "harden the email/manual restore path" and Veeam REST slips into a fast-follow week.
- Stakeholder available for 30-minute daily standup and same-day sign-off on §8 questions.

---

## 8. Open questions for stakeholder sign-off

- ~~Confirm target VM (Oracle Linux 8 or 9? RHEL? Ubuntu?).~~ **Resolved 2026-09-02: Oracle Linux 8, co-located on `ccivr.zesco.co.zm` — no new VM.**
- ~~DB engine preference — MariaDB or PostgreSQL?~~ **Resolved 2026-09-02: Oracle DB in production, MySQL 8 in development.**
- Confirm the Oracle DB target: existing shared instance (which host / SID / PDB) or a new dedicated schema on the CCIVR-side database.
- Agree the Nginx port on `ccivr.zesco.co.zm` (proposed `8443`) and whether the dashboard is reached directly or through a corporate reverse-proxy for `https://<name>/`.
- Should the dashboard be exposed only on the internal LAN, or also via VPN to remote supervisors?
- Who owns issuance of the Veeam service account for the dashboard, and is the Enterprise Manager REST API exposed to `ccivr.zesco.co.zm` (the backup jobs themselves are already running — this is only about the *restore-request* automation).
- Timeline / go-live target date (the 14-day clock starts once §7.4 dependencies are in place).
- User count and role breakdown for licensing / capacity sizing.

---

**End of scope of works.**
