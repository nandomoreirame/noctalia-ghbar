# ghbar

Unread GitHub notifications in the Noctalia bar, with an inbox panel to open and mark them read.

![ghbar inbox panel listing three demo notifications](screenshots/panel.png)

## Why

Unread GitHub notifications only show up in a browser tab at `github.com/notifications`, so they are noticed late or never. Keeping that tab open is noisy and easy to bury under other work. ghbar puts the unread count in the Noctalia bar and the inbox in a panel, so you can open a thread and mark it read without leaving the desktop.

## Features

- Unread count in the bar (caps at `50+`), hidden when the inbox is empty
- Panel lists repository, title, reason and relative time
- Click a row to open the page and mark the thread read
- Optional desktop toast for newly arrived items (off by default)
- Token from `gh auth token` only, never written to disk by the plugin

## Quick start

Requires Noctalia v5 (plugin API 22+) and the GitHub CLI logged in with the `repo` scope (`gh auth status`).

```bash
mkdir -p ~/.local/share/noctalia/plugins
ln -sfn "$PWD" ~/.local/share/noctalia/plugins/ghbar
```

Enable `nandomoreirame/ghbar` in `plugins.toml`, add `nandomoreirame/ghbar:bar` to a bar slot, then restart Noctalia. The widget appears when there is at least one unread notification (or an error).

## Usage

- The bar shows the GitHub glyph and the unread count. Click opens the panel.
- Each panel row opens the subject in the browser and marks that thread read.
- The refresh button polls immediately.
- On a translucent bar the attached panel inherits the bar opacity. Float it for contrast:

```toml
[plugin_settings."<whoami>/ghbar"]
panel_placement = "floating"
panel_open_near_click = true
```

Replace `<whoami>` with the output of `whoami`. Restart the shell after changing placement.

| Setting | Type | Default | Effect |
| --- | --- | --- | --- |
| `notify_new` | bool | `false` | Desktop toast when a new unread item arrives |

## Development

Needs the `luau` CLI on `PATH`.

```bash
./run-tests
./run-tests tests/service.test.luau
noctalia plugins lint .
```

## Security

- **Token:** obtained with `gh auth token` and held only in callback locals and the `Authorization` header of `noctalia.http`. Never stored in `noctalia.state`, logs, files, argv or notifications.
- **Network:** `GET https://api.github.com/notifications?per_page=50` every 60 s; `PATCH https://api.github.com/notifications/threads/{id}` when a row is opened. No other hosts.
- **Commands:** `gh auth token` for the token; `xdg-open` only for URLs that start with `https://github.com/`.
- **Writes:** the only GitHub write is marking a single thread read. There is no bulk mark-all.

## License

MIT, Fernando Moreira Costa. See [LICENSE](LICENSE).
