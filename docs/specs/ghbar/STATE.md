feature: ghbar
phase: implement
spec_path: docs/specs/ghbar/SPEC.md
plan_path: docs/plans/2026-11-10-ghbar.md
implemented_by: grok
review_base: 7347037
notes: |
  Implementing plan 2026-11-10-ghbar.md with --agentic.
  Adaptation Task 3: plan expected parseTime("2026-11-10T12:00:00Z") == 1794398400000;
  correct UTC value is 1794312000000 (plan was +1 day). Fixed the test fixture.
  Adaptation Task 7: URL open guard lives in Gh.isSafeOpenUrl (pure); service_open
  asserts it and checks xdg-open args. parse() always yields github.com URLs, so a
  non-github row cannot be planted through the fixture alone.
