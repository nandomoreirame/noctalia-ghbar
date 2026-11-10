-- Bar widget: always-visible GitHub glyph + count from the published view.
-- Empty inbox click opens github.com/notifications; otherwise toggles the panel.

local present = require("./lib/present.luau")

local PANEL = "nandomoreirame/ghbar:panel"

local function render(v: any)
	if typeof(v) ~= "table" then
		v = { glyph = "brand-github", glyphColor = "on_surface_variant", label = "", count = 0, empty = false, error = nil, rows = {} }
	end

	local vertical = barWidget.isVertical()
	local color = v.glyphColor or "on_surface"
	local children = {
		ui.glyph({ name = v.glyph or "brand-github", color = color }),
	}
	if not vertical and typeof(v.label) == "string" and v.label ~= "" then
		table.insert(children, ui.label({
			text = v.label,
			color = "on_surface",
			fontSize = 12,
			fontWeight = "medium",
		}))
	end

	local container = if vertical then ui.column else ui.row
	barWidget.render(container({
		gap = 6,
		align = "center",
		paddingH = 8,
		paddingV = 2,
	}, children))

	barWidget.setVisible(true)

	if v.error ~= nil then
		barWidget.setTooltip(noctalia.tr("bar.tooltip_error"))
	else
		barWidget.setTooltip(noctalia.tr("bar.tooltip", { n = v.count or 0 }))
	end
end

function onClick()
	local v = noctalia.state.get("view")
	local count = if typeof(v) == "table" then (v.count or 0) else 0
	local err = typeof(v) == "table" and v.error ~= nil
	if count == 0 and not err then
		noctalia.state.set("cmd.inbox", present.bump(noctalia.state.get("cmd.inbox")))
		return
	end
	noctalia.togglePanel(PANEL)
end

function update()
	render(noctalia.state.get("view"))
end

noctalia.state.watch("view", render)
render(noctalia.state.get("view"))
