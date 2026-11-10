-- Bar widget: glyph + count from the published view. Click toggles the panel.

local PANEL = "nandomoreirame/ghbar:panel"

local function render(v: any)
	if typeof(v) ~= "table" then
		barWidget.setVisible(false)
		return
	end

	local vertical = barWidget.isVertical()
	local err = v.error ~= nil
	local color = if err then "error" else "on_surface"
	local children = {
		ui.glyph({ name = v.glyph or "brand-github", color = color }),
	}
	if not vertical then
		table.insert(children, ui.label({
			text = v.label or "",
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

	barWidget.setVisible(v.visible == true)

	if err then
		barWidget.setTooltip(noctalia.tr("bar.tooltip_error"))
	else
		barWidget.setTooltip(noctalia.tr("bar.tooltip", { n = v.count or 0 }))
	end
end

function onClick()
	noctalia.togglePanel(PANEL)
end

function update()
	render(noctalia.state.get("view"))
end

noctalia.state.watch("view", render)
render(noctalia.state.get("view"))
