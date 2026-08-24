# Call Recording — 3-Week Deliverables

## Week 1 — Deploy

- Package the recorder as a Linux service; deploy to the provisioned server.
- Start parallel-run alongside the current setup.
- Hook into existing monitoring for health alerts.
- **SIP proxy:** first working version of the proxy in front of Asterisk;
  internal test calls flow through it.

## Week 2 — Test & harden

- Load-test the recorder against expected peak call volume; confirm no
  missed calls.
- Harden: remove hard-coded credentials, tighten file permissions, rotate
  any exposed passwords.
- Verify recorder auto-recovers from Asterisk restarts, network blips,
  and daemon restarts.
- Retention policy + compliance sign-off (from stakeholders).
- **SIP proxy:** add the custom headers that identify the specific agent;
  recorder consumes them.

## Week 3 — Cut over

- Cut over from parallel-run to primary; the old setup goes into standby.
- Recorder now labels every recording with the specific agent who took
  the call (via proxy headers).
- Hand over runbook + monitoring dashboards to the operations team.
- Post-cutover soak: monitor for 48 hours before declaring done.

## Blocking dependencies

- Retention + compliance sign-off must land by end of Week 2 or cut-over
  slips.
- SIP proxy Week-2 milestone must land or agent-labelling ships in a
  follow-up.
