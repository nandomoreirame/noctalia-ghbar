local assert = require("./support/assert")
local runner = require("./support/runner")
local modules = require("./support/modules")

local describe, it = runner.describe, runner.it

local toml = modules.text("plugin.toml")

local function has(needle: string)
	if string.find(toml, needle, 1, true) == nil then
		error("plugin.toml lacks " .. needle)
	end
end

describe("plugin.toml", function()
	it("declares the id, api level, widget and panel", function()
		for _, needle in {
			'id = "nandomoreirame/ghbar"',
			'name = "Ghbar"',
			"plugin_api = 22",
			'license = "MIT"',
			'entry = "widget.luau"',
			'entry = "panel.luau"',
		} do
			has(needle)
		end
	end)

	it("declares the service, the toast setting and the panel size", function()
		for _, needle in {
			"[[service]]",
			'id = "poll"',
			'entry = "service.luau"',
			'key = "notify_new"',
			'type = "bool"',
			"default = false",
			'label_key = "settings.notify_new.label"',
			'description_key = "settings.notify_new.description"',
			"width = 380",
			"height = 480",
			'placement = "attached"',
			"open_near_click = true",
		} do
			has(needle)
		end
	end)

	it("keeps the description within 120 characters", function()
		local description = string.match(toml, '\ndescription%s*=%s*"([^"]*)"')
		assert.equal(description ~= nil and utf8.len(description) <= 120, true)
	end)
end)

describe("lib purity", function()
	it("lib modules never touch host globals", function()
		local source = string.gsub(modules.text("lib/present.luau"), "%-%-[^\n]*", "")
		source = string.gsub(source, '"[^"\n]*"', '""')
		for _, global in { "noctalia%.", "barWidget%.", "panel%.", "ui%." } do
			assert.equal(string.find(source, "%f[%w_]" .. global) == nil, true)
		end
	end)
end)
