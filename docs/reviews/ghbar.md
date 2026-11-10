# Review: ghbar

- **Round:** 2026-11-10
- **Open findings:** 0
- **State:** awaiting independent review
- **Implemented by:** grok
- **Independent review:** pending (self-assessment)

> File rewritten whole on every `/rpi review`. A finding only disappears from here
> because it stopped existing in the code: whoever fixes it does not mark it resolved.

<!-- findings:begin -->

| Severity | File:line | Issue | Suggested fix |
|----------|-----------|-------|---------------|
| — | — | no findings this round | — |

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

## Reviewer notes

- Fix round addressed all 9 findings from round 2 (claude).
- `./run-tests`: 70 passed, 0 failed. `check_proofs.py`: PASS (C1–C9).
- Live PATCH: `gh api -X PATCH notifications/threads/27093518653` → HTTP 205; host `noctalia.http` passes arbitrary methods via CURLOPT_CUSTOMREQUEST (noctalia-dev/noctalia `src/net/http_client.cpp`); aibar live smoke already proved POST. No `gh api` fallback.
- Independent reviewer chain with `--implementer grok --running-in grok`: only `opencode` (codex/agy disabled). `opencode-review.sh` exit 3 (unavailable: auth/quota/upstream/network). Claude panel applies only in Claude Code. Round stays pending self-assessment until an independent CLI reviews.
