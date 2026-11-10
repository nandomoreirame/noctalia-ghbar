# Review: ghbar

- **Round:** 2026-11-10
- **Open findings:** 0
- **State:** cycle closed
- **Implemented by:** grok
- **Independent review:** done (claude)

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
| C10 | tests/widget.test.luau::opens the inbox url on empty click instead of the panel | yes |

<!-- checks:end -->
