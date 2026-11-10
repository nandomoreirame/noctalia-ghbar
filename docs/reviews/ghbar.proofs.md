# Proofs: ghbar

- **Commit:** db327197317f1a9f9a75203f2cb1baf23337a26a
- **Tree:** clean
- **Result:** PASS

| Check | Requirements | Proof | Status |
| --- | --- | --- | --- |
| C1 | REQ-001 | run unit \| ok token never appears in state, logs or notifications | PASS |
| C2 | REQ-002 | run unit \| ok polls the notifications endpoint every 60 seconds | PASS |
| C3 | REQ-003 | run unit \| ok shows the glyph and 50+ from fifty | PASS |
| C4 | REQ-004 | run unit \| ok hides the widget at zero without error | PASS |
| C5 | REQ-005 | run unit \| ok shows the alert glyph on error | PASS |
| C6 | REQ-006 | run unit \| ok lists one row per notification | PASS |
| C7 | REQ-007 | run unit \| ok restores the item when the PATCH fails | PASS |
| C8 | REQ-008 | run unit \| ok declares the service, the toast setting and the panel size | PASS |
| C9 | REQ-009 | run unit \| ok entries use theme tokens only | PASS |

## Runs

### run unit (exit 0)

```text
present.bump
  ok starts at one and increments
present.reasonKey
  ok maps known reasons and falls back to other
service open
  ok opens the page and marks the thread read
  ok restores the item when the PATCH fails
  ok keeps the item removed on a 205 answer
  ok ignores an id that is not in the list
  ok refresh polls immediately
  ok opens only https github.com urls
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
  ok hides the widget at zero without error
  ok shows the alert glyph on error
  ok builds one row per notification with a compact age
  ok ages in minutes, hours and days
  ok is not visible before the first poll finishes
widget
  ok shows the glyph and 50+ from fifty
  ok hides the widget at zero without error
  ok shows the alert glyph on error
  ok shows only the glyph on a vertical bar
  ok toggles the panel on click
  ok sets a translated tooltip with the count
  ok entries use theme tokens only
62 passed, 0 failed
```
