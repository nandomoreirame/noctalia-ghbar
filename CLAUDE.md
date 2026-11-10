# ghbar

Noctalia v5 plugin: unread GitHub notifications in the bar and inbox panel.
Id `nandomoreirame/ghbar`. Read `docs/STYLEGUIDE.md` before UI edits.

## Commands

```bash
./run-tests
./run-tests tests/<name>.test.luau
noctalia plugins lint .
```

Read the `N passed, M failed` line. A piped exit code is the pipe's, not the suite's.

## Architecture

- `service.luau` is the only entry that runs `gh`, HTTP, `xdg-open` and notify. It polls every 60 s, publishes one `view` on `noctalia.state`, and watches `cmd.refresh` and `cmd.open`.
- `widget.luau` and `panel.luau` render only from `view`. Click toggles the panel; a row click sets `cmd.open`; refresh bumps `cmd.refresh`.
- `lib/*.luau` is pure: `gh`, `notifications`, `poll`, `view`, `present`. No `noctalia`, `barWidget`, `panel` or `ui`.
- Token from `gh auth token` lives only in callback locals and HTTP headers. Never in state, logs, files, argv or notifications.
- Paths stay portable (`~`, `$PWD`). No absolute home path in any file.

## Spec

- Spec: `docs/specs/ghbar/SPEC.md`
- Plan: `docs/plans/2026-11-10-ghbar.md`
