local assert = require("./support/assert")
local runner = require("./support/runner")
local modules = require("./support/modules")
local mock = require("./support/noctalia_mock")
local entry = require("./support/entry")

local describe, it = runner.describe, runner.it

local function last(loaded, path)
	local calls = mock.calls(loaded.env, path)
	return calls[#calls]
end

local function boot(view, opts)
	local o = opts or {}
	local w = entry.load("widget.luau", { vertical = o.vertical == true })
	if view ~= nil then
		w.env.noctalia.state.set("view", view)
	end
	return w
end

describe("widget", function()
	it("shows the glyph and 50+ from fifty", function()
		local w = boot({
			glyph = "brand-github",
			glyphColor = "on_surface",
			label = "50+",
			count = 50,
			empty = false,
			error = nil,
			rows = {},
		})
		local tree = last(w, "barWidget.render")[1]
		assert.equal(tree.children[1].type, "glyph")
		assert.equal(tree.children[1].props.name, "brand-github")
		assert.equal(tree.children[2].props.text, "50+")
	end)

	it("keeps the glyph visible and dimmed at zero without error", function()
		local w = boot({
			glyph = "brand-github",
			glyphColor = "on_surface_variant",
			label = "",
			count = 0,
			empty = true,
			error = nil,
			rows = {},
		})
		assert.equal(last(w, "barWidget.setVisible")[1], true)
		local tree = last(w, "barWidget.render")[1]
		assert.equal(tree.children[1].props.name, "brand-github")
		assert.equal(tree.children[1].props.color, "on_surface_variant")
		assert.equal(#tree.children, 1)
	end)

	it("shows the alert glyph on error", function()
		local w = boot({
			glyph = "alert-triangle",
			glyphColor = "error",
			label = "",
			count = 0,
			empty = false,
			error = { kind = "auth", status = 401 },
			rows = {},
		})
		local glyph = last(w, "barWidget.render")[1].children[1]
		assert.equal(glyph.props.name, "alert-triangle")
		assert.equal(glyph.props.color, "error")
	end)

	it("shows only the glyph on a vertical bar", function()
		local w = boot({
			glyph = "brand-github",
			glyphColor = "on_surface",
			label = "3",
			count = 3,
			empty = false,
			error = nil,
			rows = {},
		}, { vertical = true })
		local tree = last(w, "barWidget.render")[1]
		assert.equal(tree.type, "column")
		assert.equal(#tree.children, 1)
		assert.equal(tree.children[1].type, "glyph")
	end)

	it("toggles the panel on click", function()
		local w = boot({
			glyph = "brand-github",
			glyphColor = "on_surface",
			label = "1",
			count = 1,
			empty = false,
			error = nil,
			rows = {},
		})
		w.call("onClick")
		assert.equal(last(w, "noctalia.togglePanel")[1], "nandomoreirame/ghbar:panel")
	end)

	it("opens the inbox url on empty click instead of the panel", function()
		local w = boot({
			glyph = "brand-github",
			glyphColor = "on_surface_variant",
			label = "",
			count = 0,
			empty = true,
			error = nil,
			rows = {},
		})
		local before = #mock.calls(w.env, "noctalia.togglePanel")
		w.call("onClick")
		assert.equal(#mock.calls(w.env, "noctalia.togglePanel"), before)
		assert.equal(w.env.noctalia.state.get("cmd.inbox"), 1)
		w.call("onClick")
		assert.equal(w.env.noctalia.state.get("cmd.inbox"), 2)
	end)

	it("toggles the panel before the first poll finishes", function()
		local w = boot({
			glyph = "brand-github",
			glyphColor = "on_surface_variant",
			label = "",
			count = 0,
			empty = false,
			error = nil,
			rows = {},
		})
		local beforeInbox = w.env.noctalia.state.get("cmd.inbox")
		w.call("onClick")
		assert.equal(last(w, "noctalia.togglePanel")[1], "nandomoreirame/ghbar:panel")
		assert.equal(w.env.noctalia.state.get("cmd.inbox"), beforeInbox)
	end)

	it("opens the panel on error even when the count is zero", function()
		local w = boot({
			glyph = "alert-triangle",
			glyphColor = "error",
			label = "",
			count = 0,
			empty = false,
			error = { kind = "network", status = 0 },
			rows = {},
		})
		w.call("onClick")
		assert.equal(last(w, "noctalia.togglePanel")[1], "nandomoreirame/ghbar:panel")
	end)

	it("sets a translated tooltip with the count", function()
		local w = boot({
			glyph = "brand-github",
			glyphColor = "on_surface",
			label = "3",
			count = 3,
			empty = false,
			error = nil,
			rows = {},
		})
		assert.equal(last(w, "barWidget.setTooltip")[1], "bar.tooltip")

		w.env.noctalia.state.set("view", {
			glyph = "alert-triangle",
			glyphColor = "error",
			label = "",
			count = 0,
			empty = false,
			error = { kind = "network", status = 0 },
			rows = {},
		})
		assert.equal(last(w, "barWidget.setTooltip")[1], "bar.tooltip_error")
	end)

	it("entries use theme tokens only", function()
		for _, path in { "widget.luau", "panel.luau", "service.luau" } do
			local source = modules.text(path)
			assert.equal(string.find(source, "#[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]") == nil, true)
		end
	end)
end)
