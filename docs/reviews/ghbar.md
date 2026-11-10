# Review: ghbar

- **Round:** 2026-11-10
- **Open findings:** 9
- **State:** awaiting fix
- **Implemented by:** grok
- **Independent review:** done (claude)

> File rewritten whole on every `/rpi review`. A finding only disappears from here
> because it stopped existing in the code: whoever fixes it does not mark it resolved.

<!-- findings:begin -->

| Severity | File:line | Issue | Suggested fix |
|----------|-----------|-------|---------------|
| Standards | — | — | — |
| Low | lib/gh.luau:16 | `parseToken` checks stderr for "not found" before the exit code, so a successful `gh auth token` (exit 0, valid token) that prints a warning containing "not found" is reported as `no-gh` and the plugin stops working (probe confirmed). | Test `exitCode == 0` with a non-empty token first; use the stderr heuristic only for non-zero exits. |
| Low | service.luau:16 | `inFlight` is assigned in four places and never read (dead state). | Remove it, or use it to skip a poll while one is running. |
| Spec | — | — | — |
| High | lib/view.luau:29 | Change request: the widget must always show the GitHub icon. `visible = count > 0 or err ~= nil` and `barWidget.setVisible(v.visible == true)` (widget.luau:34) hide it at zero, which implements REQ-004 as written but contradicts the new requirement; with the widget hidden at zero there is also no way to reach github.com from the bar. | Update SPEC REQ-004 and Architecture Decision 4 (always visible: dimmed glyph at zero, count when there are items, alert on error). Drop `visible` from the view model, call `barWidget.setVisible(true)`, render the glyph with `on_surface_variant` at zero, and invert the tests `view: hides the widget at zero without error` and `widget: hides the widget at zero without error` (C4 must then assert the glyph stays visible and dimmed). |
| High | widget.luau:43 | Change request: when the inbox is empty a click must go straight to GitHub instead of opening the panel; `onClick` always calls `noctalia.togglePanel`. Interpretation to confirm: with notifications the click still opens the panel, and in the error state it opens the panel (cause and action). | Branch on the published view: when `count == 0` and no error, the widget bumps a `cmd.inbox` counter and the service runs `xdg-open https://github.com/notifications` (service.luau stays the only entry that starts processes); otherwise `togglePanel`. Add a REQ to the spec, plus tests: empty click calls no `togglePanel` and triggers exactly one `xdg-open` of the inbox URL; non-empty click toggles the panel; the URL is a constant, never taken from payload data. |
| High | tests/service.test.luau:89 | C1: the leak test covers only the poll path with toasts off (`notify_new = false`), so `noctalia.notify` is never called and the open/PATCH path never runs; it would still pass if the token leaked into a toast, a log line of `markRead`, or the open path. | Extend it: run with `notify_new = true` and a second poll, trigger `cmd.open` and answer the PATCH, then assert no recorded state, log, notify or writeFile call contains SECRET-GH; also assert no runAsync argv contains it. |
| Medium | service.luau:92 | A poll that started before the PATCH landed replaces the list (`state = poll.succeed(...)`) and brings the optimistically removed thread back until the next poll. Probe on a copy: click row 1001, refresh, answer the GET with the fixture, 3 rows instead of 2. | Keep a set of ids pending mark-read in the service and filter them out of `parsed.items` until the PATCH answers. |
| Medium | service.luau:191 | REQ-007 rollback `poll.restore` does not check that the id is already in the list: after an overlapping poll listed the thread again, a failed PATCH inserts a duplicate row with the same `key` (probe: 4 rows instead of 3). | Make `Poll.restore` a no-op when an item with the same id exists, and cover it with a test (poll answers before a failing PATCH). |
| Medium | docs/specs/ghbar/STATE.md:25 | REQ-007 depends on the host sending `PATCH` (spec assumption row). Task 12 never clicked a real row, so PATCH support and the `gh api` fallback decision are still unverified in the real host; the 62 unit tests only use the mock. | Verify once in the live shell with a disposable notification (or a `PATCH` against a test thread) and record the result; switch `markRead` to `gh api -X PATCH` if the host cannot send it. |
| Low | panel.luau:135 | On a failed poll the panel shows only the error block and hides the last list that REQ-002 says to keep, so a network blip hides a valid inbox. Possible Speculative Generality in `fetchedAt` too: it is written on every transition and never read. | Render the error as a banner above the retained rows; drop `fetchedAt` or use it for a 'updated Nm ago' line. |

<!-- findings:end -->

## Checks

<!-- checks:begin -->

| Check | Test | Holds |
|-------|------|-------|
| C1 | tests/service.test.luau::token never appears in state, logs or notifications | no - toasts off and no open/PATCH path, so notify and markRead leaks would not fail it |
| C2 | tests/service.test.luau::polls the notifications endpoint every 60 seconds | yes |
| C3 | tests/widget.test.luau::shows the glyph and 50+ from fifty | yes |
| C4 | tests/widget.test.luau::hides the widget at zero without error | yes |
| C5 | tests/widget.test.luau::shows the alert glyph on error | yes |
| C6 | tests/panel.test.luau::lists one row per notification | yes |
| C7 | tests/service_open.test.luau::restores the item when the PATCH fails | yes |
| C8 | tests/manifest.test.luau::declares the service, the toast setting and the panel size | yes |
| C9 | tests/widget.test.luau::entries use theme tokens only | yes |

<!-- checks:end -->
