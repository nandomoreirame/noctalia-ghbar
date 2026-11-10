-- Inbox panel: lists notifications from the published view.
-- The host already pads the panel, so the root adds no padding.

local present = require("./lib/present.luau")

local isOpen = false

local function openCommand(id: string)
	local prev = noctalia.state.get("cmd.open")
	local n = present.bump(if typeof(prev) == "table" then prev.n else nil)
	noctalia.state.set("cmd.open", { id = id, n = n })
end

local function refresh()
	noctalia.state.set("cmd.refresh", present.bump(noctalia.state.get("cmd.refresh")))
end

local function header(v: any): any
	local countLabel = if v and v.label then v.label else "0"
	return ui.row({
		align = "center",
		gap = 8,
		paddingH = 4,
		paddingV = 2,
	}, {
		ui.label({
			text = noctalia.tr("panel.title"),
			fontSize = 14,
			fontWeight = "bold",
			color = "on_surface",
		}),
		ui.label({
			text = countLabel,
			fontSize = 12,
			color = "on_surface_variant",
		}),
		ui.spacer({ flexGrow = 1 }),
		ui.button({
			glyph = "refresh",
			variant = "ghost",
			controlSize = "sm",
			tooltip = noctalia.tr("panel.refresh"),
			onClick = refresh,
		}),
	})
end

local function errorBlock(kind: string): any
	return ui.column({
		gap = 8,
		paddingH = 8,
		paddingV = 12,
		align = "stretch",
	}, {
		ui.label({
			text = noctalia.tr("error." .. kind .. ".title"),
			fontSize = 13,
			fontWeight = "medium",
			color = "error",
		}),
		ui.label({
			text = noctalia.tr("error." .. kind .. ".action"),
			fontSize = 12,
			color = "on_surface_variant",
			maxLines = 4,
		}),
	})
end

local function emptyBlock(): any
	return ui.column({
		flexGrow = 1,
		align = "center",
		justify = "center",
		gap = 6,
	}, {
		ui.glyph({ name = "bell-off", color = "on_surface_variant", size = 20 }),
		ui.label({
			text = noctalia.tr("panel.empty"),
			fontSize = 13,
			color = "on_surface_variant",
		}),
	})
end

local function rowNode(row: any): any
	local reason = noctalia.tr(present.reasonKey(row.reason))
	return ui.row({
		key = row.id,
		gap = 10,
		align = "center",
		radius = 10,
		paddingH = 10,
		paddingV = 8,
		fill = "surface_variant/0.35",
		onClick = function()
			openCommand(row.id)
		end,
	}, {
		ui.glyph({
			name = present.kindGlyph(row.kind),
			color = "on_surface",
			size = 16,
		}),
		ui.column({ gap = 2, flexGrow = 1, align = "stretch" }, {
			ui.label({
				text = row.repo or "",
				fontSize = 11,
				color = "on_surface_variant",
				maxLines = 1,
			}),
			ui.label({
				text = row.title or "",
				fontSize = 13,
				fontWeight = "medium",
				color = "on_surface",
				maxLines = 2,
			}),
			ui.row({ gap = 8, align = "center" }, {
				ui.label({
					text = reason,
					fontSize = 11,
					color = "on_surface_variant",
				}),
				ui.label({
					text = row.age or "",
					fontSize = 11,
					color = "on_surface_variant",
				}),
			}),
		}),
	})
end

local function listBlock(v: any): any
	if v == nil or #(v.rows or {}) == 0 then
		return emptyBlock()
	end
	local children = {}
	for _, row in v.rows do
		table.insert(children, rowNode(row))
	end
	return ui.scroll({ flexGrow = 1 }, {
		ui.column({ gap = 6, align = "stretch", paddingH = 2, paddingV = 4 }, children),
	})
end

local function body(v: any): any
	local parts = {}
	if v and v.error and typeof(v.error.kind) == "string" then
		table.insert(parts, errorBlock(v.error.kind))
	end
	if v == nil or v.empty == true or #(v.rows or {}) == 0 then
		if #parts == 0 then
			return emptyBlock()
		end
		-- Error with an empty retained list: still show the empty state under the banner.
		table.insert(parts, emptyBlock())
		return ui.column({ flexGrow = 1, gap = 8, align = "stretch" }, parts)
	end
	table.insert(parts, listBlock(v))
	if #parts == 1 then
		return parts[1]
	end
	return ui.column({ flexGrow = 1, gap = 8, align = "stretch" }, parts)
end

local function render(v: any)
	if not isOpen and v == nil then
		return
	end
	local view = v or noctalia.state.get("view")
	panel.render(ui.column({
		flexGrow = 1,
		gap = 8,
		align = "stretch",
	}, {
		header(view),
		body(view),
	}))
end

function onOpen(_context: any)
	isOpen = true
	render(noctalia.state.get("view"))
end

function onClose()
	isOpen = false
end

noctalia.state.watch("view", function(v)
	if isOpen then
		render(v)
	end
end)
