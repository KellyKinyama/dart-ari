# Deriving the physical agent endpoint (Option A)

## The problem

When Asterisk dials `PJSIP/3636@mytrunk` and the trunk is a B2BUA that
media-anchors (like Alcatel OmniPCX Enterprise), everything Asterisk sees
about "the peer" points at the trunk's own address (e.g. `10.1.8.226`),
not the actual agent phone (e.g. `10.100.37.30`). Our `peer_rtp_remote`
field is correctly reporting **who Asterisk is exchanging RTP with**, but
that's the OXE, not the agent.

The agent's real endpoint only appears in **the OXE-originated SIP dialog
that the B2BUA opens against Asterisk to represent the agent side**, and
in the raw SDP body of that dialog's INVITE / 200 OK.

## What the recorder captures for correlation

Since v844d14d the recorder writes two extra fields into every sidecar:

```json
{
  ...
  "caller_sip": {
    "Call-ID": "abc123@10.100.53.200",
    "From": "\"6001\" <sip:6001@10.100.53.200>;tag=...",
    "To": "<sip:6665@10.1.101.155>;tag=...",
    "Contact": "<sip:6001@10.100.53.200:52156>",
    "Remote-Party-ID": null,
    "P-Asserted-Identity": null,
    "Diversion": null
  },
  "peer_sip": {
    "Call-ID": "729bcc55-4da5-4298-b891-1eb9901f23ad",
    "From": "sip:6001@10.1.101.155;tag=...",
    "To": "sip:3636@10.1.8.222;tag=...",
    "Contact": "sip:10.1.8.222",
    "Remote-Party-ID": null,
    "P-Asserted-Identity": null,
    "Diversion": null
  }
}
```

These are read via `PJSIP_HEADER(read,<name>)` on each channel. They are
the exact identifiers of the SIP dialog Asterisk is party to for that
leg.

**They are NOT the agent's IP.** They are the correlation key you use to
find the raw SIP messages in a pcap, from which you can extract the SDP
`c=` line that IS the agent's IP.

## Offline correlation with sngrep

Prerequisites on the Asterisk box:

- `sngrep` installed.
- Continuous pcap rotation running, e.g.:
  ```bash
  sudo tcpdump -i any -s0 -w /var/log/sip/sip-%Y%m%d-%H%M%S.pcap -G 3600 \
       -Z asterisk 'port 5060 or port 5061'
  ```

For a specific recording, take the `Call-ID` from either `caller_sip` or
`peer_sip` and grep the pcaps:

```bash
CALLID='729bcc55-4da5-4298-b891-1eb9901f23ad'
sngrep -I /var/log/sip/*.pcap -c "$CALLID"
```

sngrep opens with only the dialogs matching that Call-ID. Press `F2` on
any dialog to see the ladder view, `Enter` on any message to see raw
SIP+SDP, then read the `c=` line for the true media endpoint.

To pull just the SDP `c=` non-interactively:

```bash
CALLID='729bcc55-4da5-4298-b891-1eb9901f23ad'
tshark -r /var/log/sip/sip-*.pcap \
       -Y "sip.Call-ID == \"$CALLID\" and sdp" \
       -T fields -e frame.time -e ip.src -e sip.CSeq \
       -e sdp.connection_info \
       -e sdp.media
```

Example output:

```
2026-08-24 11:49:15  10.1.8.222  1659614785 INVITE  IN IP4 10.100.37.30  audio 32600 RTP/AVP 8 101
```

`10.100.37.30:32600` is the physical agent endpoint.

## Correlating across dialogs (advanced)

When the OXE opens a separate callback dialog for the agent side, its
Call-ID differs from the outbound dialog Asterisk originated. In our
sidecar you get *the Asterisk-side* Call-IDs; the agent-side dialog has a
different Call-ID that isn't present in ARI.

Two ways to bridge that gap:

### By timing + peer address

The two dialogs happen within the same second at OXE→Asterisk on port
5060. Use a windowed query:

```bash
# Find every dialog OXE initiated to Asterisk within ±5s of your call
tshark -r /var/log/sip/*.pcap \
       -Y "sip.Request-Line contains \"INVITE\" \
           and ip.src == 10.1.8.222 \
           and frame.time >= \"2026-08-24 11:49:10\" \
           and frame.time <= \"2026-08-24 11:49:20\"" \
       -T fields -e frame.time -e sip.Call-ID -e sdp.connection_info
```

If only one match falls in that window, that's your agent-side dialog.
Grab its Call-ID and re-run the SDP query.

### By tags in Diversion / Remote-Party-ID

Some OXE configs echo a `Diversion` or `Remote-Party-ID` header on the
callback dialog that references the original dialed number (`3636`). If
you see `Diversion` populated on either side of the sidecar, use it as
the correlation key instead of the wall-clock window.

## When Option A isn't enough

If you find yourself running this correlation for every call, upgrade
to Option B (AMI `PJSIPMessageSent`/`Received` in-process). That path
gets the agent SDP directly into the sidecar at write time — no offline
step. See [implementation-notes.md](implementation-notes.md) §8 for a
sketch.
