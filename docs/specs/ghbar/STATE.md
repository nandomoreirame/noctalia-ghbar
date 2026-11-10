feature: ghbar
phase: implement
review: pending (self-assessment)
independent_reviewer_tried: opencode exit 3 (unavailable) on fix-round re-review; agy/codex disabled; Claude panel only in Claude Code
spec_path: docs/specs/ghbar/SPEC.md
plan_path: docs/plans/2026-11-10-ghbar.md
implemented_by: grok
review_base: 7347037a0b9a31d6a5b9f99229c4f40a31a4eb5c
notes: |
  Implementing plan 2026-11-10-ghbar.md with --agentic.
  Adaptation Task 3: plan expected parseTime("2026-11-10T12:00:00Z") == 1794398400000;
  correct UTC value is 1794312000000 (plan was +1 day). Fixed the test fixture.
  Adaptation Task 7: URL open guard lives in Gh.isSafeOpenUrl (pure); service_open
  asserts it and checks xdg-open args. parse() always yields github.com URLs, so a
  non-github row cannot be planted through the fixture alone.

  Task 12 live verification (2026-11-10):
  - ./run-tests: 62 passed, 0 failed
  - noctalia plugins lint .: 0 errors, 0 warnings
  - noctalia-plugins-link: ghbar symlinked
  - noctalia msg plugins enable nandomoreirame/ghbar: enabled
  - bar.toml: slot "ghbar" + [widget.ghbar]; plugins.toml: floating panel
  - noctalia msg config-reload: ok; panel-toggle: ok
  - gh api notifications: 1 unread (matches expected visible widget)
  - Did not click a real notification (would mark the user's thread read).
  - screenshots/panel.png remains a demo mockup (octo/hello), no personal repos.
  - Dotfiles bar/plugins edits are uncommitted in ~/.dotfiles.

  Review findings fix round (2026-11-10, grok):
  - ./run-tests: 70 passed, 0 failed after addressing all 9 open findings.
  - PATCH live probe on already-read thread 27093518653: gh api -X PATCH
    notifications/threads/<id> → HTTP 205 Reset Content (same status the
    service treats as success). Unread inbox stayed at 0.
  - Host noctalia.http PATCH support confirmed from noctalia-dev/noctalia source:
    HttpRequest.method uses CURLOPT_CUSTOMREQUEST for non-GET/POST
    (src/net/http_client.cpp); luau_host passes the method string through
    (src/scripting/luau_host.cpp). aibar live smoke already proved POST with
    body reaches the network. No fallback to `gh api -X PATCH` needed.
  - Assumption row "noctalia.http accepts method = PATCH" held; keep markRead
    on noctalia.http.
