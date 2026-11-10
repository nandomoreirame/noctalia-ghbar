# Proofs: ghbar

- **Commit:** 2cad092f125dbd633221406ea47aead0a7e8e35b
- **Tree:** dirty (docs/plans/2026-11-10-ghbar.md, docs/specs/ghbar/SPEC.md, service.luau, tests/service_open.test.luau, tests/widget.test.luau, widget.luau)
- **Result:** FAIL

| Check | Requirements | Proof | Status |
| --- | --- | --- | --- |
| C1 | REQ-001 | run unit \| ok token never appears in state, logs or notifications | PASS |
| C2 | REQ-002 | run unit \| ok polls the notifications endpoint every 60 seconds | PASS |
| C3 | REQ-003 | run unit \| ok shows the glyph and 50+ from fifty | PASS |
| C4 | REQ-004 | run unit \| ok keeps the glyph visible and dimmed at zero without error | PASS |
| C5 | REQ-005 | run unit \| ok shows the alert glyph on error | PASS |
| C6 | REQ-006 | run unit \| ok lists one row per notification | PASS |
| C7 | REQ-007 | run unit \| ok restores the item when the PATCH fails | PASS |
| C8 | REQ-008 | run unit \| ok declares the service, the toast setting and the panel size | PASS |
| C9 | REQ-009 | run unit \| ok entries use theme tokens only | PASS |
| C10 | REQ-010 | run unit \| ok opens the inbox url on empty click instead of the panel | PASS |

## Runs

### run unit (exit 0)

```text
  ok keeps the item removed on a 205 answer
  ok ignores an id that is not in the list
  ok refresh polls immediately
  ok opens only https github.com urls
  ok keeps a pending mark-read id out of a concurrent poll
  ok does not duplicate a row when restore races a poll
  ok keeps a marked id filtered after PATCH until a newer poll applies
  ok opens the web inbox on cmd.inbox
service poll
  ok polls the notifications endpoint every 60 seconds
  ok publishes the view from the fixture answer
  ok token never appears in state, logs or notifications
  ok reports gh missing when the launch fails
  ok reports logged out and auth errors
service toast
  ok stays silent by default
  ok notifies only items new since the last poll
  ok caps the burst at three toasts and one summary
translations
  ok en declares exactly the required keys
  ok pt-BR has the same key set as en
view model
  ok shows the glyph and 50+ from fifty
  ok keeps the glyph visible and dimmed at zero without error
  ok shows the alert glyph on error
  ok builds one row per notification with a compact age
  ok ages in minutes, hours and days
  ok shows a dimmed glyph before the first poll finishes
widget
  ok shows the glyph and 50+ from fifty
  ok keeps the glyph visible and dimmed at zero without error
  ok shows the alert glyph on error
  ok shows only the glyph on a vertical bar
  ok toggles the panel on click
  ok opens the inbox url on empty click instead of the panel
  ok toggles the panel before the first poll finishes
  ok opens the panel on error even when the count is zero
  ok sets a translated tooltip with the count
  ok entries use theme tokens only
72 passed, 0 failed
```
