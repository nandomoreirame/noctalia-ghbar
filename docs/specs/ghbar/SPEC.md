# Spec: ghbar (GitHub notifications for Noctalia)

**Glossary:** none

## Problem Statement

Unread GitHub notifications live only in the browser at `github.com/notifications`, so they are noticed late or never. A Noctalia v5 bar widget with the unread count and a panel with the inbox keeps them in view without opening a tab.

## Goals

- Show the unread notification count in the bar within one poll interval (60 s) of a change on GitHub; keep a dimmed GitHub glyph when the inbox is empty.
- Read and clear a notification from the panel in one click, without leaving the desktop; an empty-bar click opens the web inbox.
- Hold no GitHub secret on disk: the token comes from the already-logged-in `gh` CLI.

## Context

The author runs Noctalia v5 and maintains one repo per plugin (`nandomoreirame/noctalia-<name>`; aibar is the reference for a polling service, scaffold for structure and style). The `gh` CLI is logged in with the `repo` scope, which `GET /notifications` accepts, and the API answers with `X-Poll-Interval: 60`. The Noctalia v5 `noctalia.http` callback receives only `ok`, `status` and `body` (runtime-api.mdx, "HTTP and downloads"), so response headers such as `Last-Modified` or `X-Poll-Interval` are unreadable: polling uses a fixed 60 s and no conditional requests. Fine-grained tokens are not supported by that endpoint. The repo was generated with `./scaffold new ghbar --dir .. --author nandomoreirame`.

## Verified Claims

| Claim | Source (file:line) | Verified |
|-------|--------------------|----------|
| function Gh.parseToken(res: { exitCode: number, stdout: string?, stderr: string? }): any | `lib/gh.luau:11` | yes |
| local PANEL = "nandomoreirame/ghbar:panel" | `widget.luau:6` | yes |
| `noctalia.http` accepts `method = "PATCH"` (docs list only `method = "GET"` as example) | n/a | assumption |

## Requirements

### P1 (MVP)

1. **[REQ-001]** WHEN the service starts THEN the system SHALL obtain the token with `gh auth token` and keep it only in a local variable, never in state, logs, files, argv or notifications
2. **[REQ-002]** WHEN the poll cycle fires THEN the system SHALL call `GET /notifications?per_page=50` every 60 s and replace the list with the answer; a failed poll SHALL keep the last list and set the error state
3. **[REQ-003]** WHEN there is at least one unread notification THEN the bar widget SHALL show the GitHub glyph and the count, rendering `50+` from 50 upward
4. **[REQ-004]** WHEN the count is 0 and there is no error THEN the bar widget SHALL stay visible with a dimmed GitHub glyph and no count label
5. **[REQ-005]** WHEN an error occurs (`gh` missing or logged out, 401, 403, offline) THEN the bar widget SHALL show an alert glyph and the panel SHALL show the cause and a suggested action above any retained list
6. **[REQ-006]** WHEN the widget is clicked and there is at least one notification or an error THEN the system SHALL open a panel listing each notification with repository, title, subject type, reason and relative time
7. **[REQ-007]** WHEN a notification is clicked THEN the system SHALL open its web page in the browser and call `PATCH /notifications/threads/{id}`; IF the PATCH fails THEN the item SHALL be restored and an error shown
8. **[REQ-008]** WHEN the plugin is created THEN it SHALL start from `noctalia-scaffold` and `./run-tests` SHALL pass before any ghbar logic is added
9. **[REQ-009]** WHEN the widget or panel renders THEN the system SHALL use only theme tokens (no hex colors) and explicit visual properties on every render
10. **[REQ-010]** WHEN the widget is clicked and the published view reports an empty inbox (`empty = true`) THEN the system SHALL open `https://github.com/notifications` in the browser without opening the panel

### P2 (Should Have)

11. **[REQ-011]** WHEN a notification arrives that was not in the previous poll AND the toast setting is on THEN the system SHALL show a desktop notification; the setting SHALL default to off
12. **[REQ-012]** WHEN the user presses refresh THEN the system SHALL poll immediately; WHEN the list is empty the panel SHALL show an empty state; all strings SHALL exist in `en` and `pt-BR`
13. **[REQ-013]** WHEN the README is written THEN it SHALL follow `docs/README.template.md`, open with the problem, include a Security section on the token and network use, and ship a panel screenshot

### P3 (Nice to Have)

None.

## Edge Cases

- **API URL to web URL** - `subject.url` is an API URL; the web link is derived by rule (`pulls`, `issues`, `commits`, `releases`) with fallback to `https://github.com/notifications`.
- **More than 50 unread** - the first page is shown and the count reads `50+`.
- **Translucent bar** - an `attached` panel inherits the bar opacity and loses contrast; the README documents `panel_placement = "floating"` from the styleguide.
- **Token expires mid-session** - a 401 moves the widget to the error state; the token is never refreshed or cached.
- **PATCH unsupported by the host** - if a live probe shows `noctalia.http` cannot send `PATCH`, mark-as-read falls back to `gh api -X PATCH` through `runAsync` (token stays inside `gh`).
- **No response headers** - the host exposes none, so conditional requests and `X-Poll-Interval` are not used; a fixed 60 s matches the API's value.
- **Optimistic removal** - an item removed after click returns if the PATCH fails.

## Architecture Decisions

1. **Token from `gh auth token`** - Chose reusing the `gh` CLI over a PAT in settings because it writes no secret to disk and needs no setup. Alternative discarded: PAT in settings (secret at rest). ADR: none
2. **Open and mark read per item, no bulk action** - Chose per-item PATCH over "mark all read" to avoid accidental mass writes. ADR: none
3. **Unread only, like the website** - Chose the API default over `participating=true` so the count matches github.com. ADR: none
4. **Always visible** - Chose a dimmed glyph at zero over hiding the widget, so the bar stays a click target for the GitHub inbox. The error state uses the alert glyph. ADR: none
5. **Scaffold structure** - Pure `lib/` modules, thin `widget.luau` and `panel.luau`, polling in `service.luau` as in aibar. ADR: none
6. **Empty click opens the web inbox** - Chose `xdg-open https://github.com/notifications` over an empty panel when the published view has `empty = true` (loaded, no error, zero items). A click before the first poll finishes opens the panel instead. ADR: none

## Grilling Log

| # | Decision | Resolution | Rationale |
|---|----------|------------|-----------|

## Constraints

- Noctalia v5, plugin API 22, Luau; id `nandomoreirame/ghbar`; MIT.
- `lib/` modules never touch `noctalia`, `barWidget`, `panel` or `ui`.
- Credentials are read-only; no absolute home path in any file (global pre-commit hook).
- Follow `docs/STYLEGUIDE.md` of the scaffold: attached panel with `open_near_click`, theme tokens, settings with `label_key` and `description_key`, `en` and `pt-BR` parity.

## Out of Scope

| Item | Reason |
|------|--------|
| Mark all as read | Mass write risk; per-item is enough for v1 |
| `participating` filter | Count would diverge from the website |
| PAT in settings | Secret at rest; `gh` covers the need |
| GitHub Enterprise hosts | Single `github.com` account for now |
| Actions beyond open and mark read (unsubscribe, mute) | Not requested |

## Test Seams

| Seam | What it catches | What it misses |
|------|-----------------|----------------|
| `lib/` pure modules (parse, URL mapping, count label, interval, view model) | Logic and formatting errors | Host integration |
| `service.luau` with the mocked host (scripted `runAsync` for `gh`, mocked HTTP) | Token flow, 304, error states, PATCH rollback | Real host timing and real GitHub responses |
| `widget.luau` and `panel.luau` via the mock `entry.load` | Render calls per state (hidden, count, alert) | Real layout and contrast in the shell |

## Test Strategy

- **Unit:** Luau tests per `lib/` module with fixtures of real `/notifications` responses (personal fields removed, `/data/u` paths).
- **Integration:** `service.luau` against the scaffold mock host; shell tests for the manifest, purity and translation parity.
- **E2E:** manual check in the real Noctalia shell (panel layout, translucent bar), plus a screenshot for the README.

## Requirement Traceability

| ID | Description | Priority | Status |
|----|-------------|----------|--------|
| REQ-001 | Token via `gh auth token`, in memory only | P1 | Pending |
| REQ-002 | Fixed 60 s poll of unread notifications | P1 | Pending |
| REQ-003 | Count in the bar, `50+` cap | P1 | Pending |
| REQ-004 | Dimmed glyph at zero, always visible | P1 | Pending |
| REQ-005 | Error state with alert glyph and cause | P1 | Pending |
| REQ-006 | Panel lists the inbox | P1 | Pending |
| REQ-007 | Click opens page and marks as read | P1 | Pending |
| REQ-008 | Start from scaffold, tests green | P1 | Pending |
| REQ-009 | Theme tokens only | P1 | Pending |
| REQ-010 | Empty click opens github.com/notifications | P1 | Pending |
| REQ-011 | Optional toast, off by default | P2 | Pending |
| REQ-012 | Refresh, empty state, i18n | P2 | Pending |
| REQ-013 | README from template with Security section | P2 | Pending |
