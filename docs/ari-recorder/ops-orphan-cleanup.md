# Orphaned UnicastRTP cleanup

Run these on the Asterisk box (`ccivr-prod`) when `core show channels` shows
`UnicastRTP/ccivr.zesco.co.zm-*` legs accumulating far in excess of the
active call count. Historically caused by `ChannelsApi.externalMediaDelete()`
missing the `api_key` query param — fixed in commit XXXXXXX, but the same
cleanup applies to any future orphan.

An orphan is any `UnicastRTP/*` channel whose `BridgeID` field is empty:
the mixing bridge has been destroyed (the caller and peer both hung up),
yet the externalMedia leg is still `Up` inside `Stasis(hello)`.

## 1. Dry run — list orphans, kill nothing

Prints one line per orphan, `no bridge` vs bridged-but-under-populated.
Safe to run any time.

```bash
asterisk -rx "core show channels concise" \
  | awk -F'!' '$1 ~ /^UnicastRTP/ {print $1"\t"$9}' \
  | while IFS=$'\t' read -r chan bridge; do
      [ -z "$bridge" ] && { echo "ORPHAN (no bridge): $chan"; continue; }
      n=$(asterisk -rx "bridge show $bridge" 2>/dev/null | grep -c '^Channel:')
      [ "$n" -lt 3 ] && echo "ORPHAN (bridge=$bridge members=$n): $chan"
    done
```

Healthy recordings have 3 members in the bridge (caller + peer + extMedia),
so `n < 3` flags anything missing a leg.

## 2. Kill — hang up orphans only

Only touches UnicastRTP legs whose BridgeID column is empty. Any leg still
attached to a live bridge is left alone, so this is safe to run while
recordings are in progress.

```bash
asterisk -rx "core show channels concise" \
  | awk -F'!' '$1 ~ /^UnicastRTP/ && $9 == "" {print $1}' \
  | while read -r chan; do
      asterisk -rx "channel request hangup $chan"
    done
```

## 3. Verify

```bash
asterisk -rx "core show channels" | tail -5
```

`X active channels` should now match roughly `3 * active_calls` (caller +
peer + extMedia per call). A ratio much higher than 3 means the cleanup
missed something — re-run step 1 with `$9 == ""` removed to see the full
UnicastRTP inventory.

## Notes

- The `concise` output is `!`-delimited; column 9 is `BridgeID`. Column
  positions have been stable across Asterisk 18/22/23.
- `channel request hangup` returns immediately; ARI/pjsip does the actual
  teardown a few ms later. Loop tolerates missing channels silently.
- Do **not** run `channel request hangup all` — it will kill live recordings
  too.
