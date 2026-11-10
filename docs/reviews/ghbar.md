# Review: ghbar

- **Round:** 2026-11-10
- **Open findings:** 4
- **State:** awaiting fix
- **Implemented by:** grok
- **Independent review:** done (claude)

> File rewritten whole on every `/rpi review`. A finding only disappears from here
> because it stopped existing in the code: whoever fixes it does not mark it resolved.

<!-- findings:begin -->

| Severity | File:line | Issue | Suggested fix |
|----------|-----------|-------|---------------|
| Spec | — | — | — |
| Medium | service.luau:194 | REQ-007: `pendingMark[id]` is cleared as soon as the PATCH answers, so a poll whose GET was issued before the PATCH and answered after it still lists the thread (GitHub had not marked it yet) and the row comes back until the next poll. Probe on a copy: refresh, click row 1001, PATCH 205, then the older GET answers with the fixture: 3 rows instead of 2. | On PATCH success keep the id filtered until a poll that started after the PATCH answer has been applied (compare `generation` at PATCH completion with the poll's `gen`), and add that test. |
| Medium | docs/specs/ghbar/SPEC.md:40 | The spec no longer validates: REQ-013 sits at the end of P1, before REQ-010..012 in P2, so `validate_spec.py` fails with `REQ-010: IDs must ascend (after REQ-013)` (also REQ-011, REQ-012). `verify-claims.sh` reports drift too: the Verified Claims row `function Present.label(raw: any): string` (SPEC.md:23) points to a function the code removed. | Renumber so IDs ascend (for example move REQ-013 after REQ-012 under P1 via a renumbered table, or renumber P2 to REQ-011..013 and the new one to REQ-010), update the traceability table and the plan checks, and replace the stale claim with a live anchor (for example `function Gh.parseToken` in lib/gh.luau). Re-run both scripts to exit 0. |
| Medium | docs/plans/2026-11-10-ghbar.md:27 | REQ-013 (empty click opens github.com/notifications) is a P1 requirement with no task and no check: `validate_plan.py` prints `REQ-013: P1 requirement covered by no task` and `has no check`, and `ghbar.proofs.md` has no C10. The behavior is tested (tests/widget.test.luau:102, tests/service_open.test.luau:196) but nothing proves it at plan close. | Add a task (or amend Task 9 and 7) with `**Requirement:** REQ-013` and a check `C10 (REQ-013): ... Proof: run unit \| ok opens the inbox url on empty click instead of the panel`, then re-run `check_proofs.py`. |
| Low | widget.luau:46 | The empty-click branch tests `count == 0 and not err` instead of the view's `empty` flag, so a click before the first poll answers (view has `loaded = false`, count 0) sends the user to github.com although the inbox state is unknown. | Use `v.empty == true` for the web-inbox branch and toggle the panel (which shows the loading or empty state) while not loaded; cover it with a test. |

<!-- findings:end -->

## Checks

<!-- checks:begin -->

| Check | Test | Holds |
|-------|------|-------|
| C1 | tests/service.test.luau::token never appears in state, logs or notifications | yes |
| C2 | tests/service.test.luau::polls the notifications endpoint every 60 seconds | yes |
| C3 | tests/widget.test.luau::shows the glyph and 50+ from fifty | yes |
| C4 | tests/widget.test.luau::keeps the glyph visible and dimmed at zero without error | yes |
| C5 | tests/widget.test.luau::shows the alert glyph on error | yes |
| C6 | tests/panel.test.luau::lists one row per notification | yes |
| C7 | tests/service_open.test.luau::restores the item when the PATCH fails | yes |
| C8 | tests/manifest.test.luau::declares the service, the toast setting and the panel size | yes |
| C9 | tests/widget.test.luau::entries use theme tokens only | yes |

<!-- checks:end -->
