local assert = require("./support/assert")
local runner = require("./support/runner")
local modules = require("./support/modules")
local describe, it = runner.describe, runner.it
local View = modules.load("lib/view.luau")
local Poll = modules.load("lib/poll.luau")

local function items(n)
	local out = {}
	for i = 1, n do
		table.insert(out, {
			id = tostring(i),
			repo = "octo/hello",
			title = "t",
			kind = "Issue",
			reason = "mention",
			updatedMs = 0,
			url = "u",
		})
	end
	return out
end

describe("view model", function()
	it("shows the glyph and 50+ from fifty", function()
		local v = View.build(Poll.succeed(Poll.create(), items(50), 1), 60000)
		assert.equal(v.label, "50+")
		assert.equal(v.glyphColor, "on_surface")
		local few = View.build(Poll.succeed(Poll.create(), items(12), 1), 60000)
		assert.equal(few.label, "12")
	end)
	it("keeps the glyph visible and dimmed at zero without error", function()
		local v = View.build(Poll.succeed(Poll.create(), {}, 1), 60000)
		assert.equal(v.empty, true)
		assert.equal(v.glyph, "brand-github")
		assert.equal(v.glyphColor, "on_surface_variant")
		assert.equal(v.label, "")
	end)
	it("shows the alert glyph on error", function()
		local v = View.build(Poll.fail(Poll.create(), "auth", 401, 1), 60000)
		assert.equal(v.glyph, "alert-triangle")
		assert.equal(v.glyphColor, "error")
		assert.equal(v.error.kind, "auth")
	end)
	it("builds one row per notification with a compact age", function()
		local v = View.build(Poll.succeed(Poll.create(), items(2), 1), 3 * 3600 * 1000)
		assert.equal(#v.rows, 2)
		assert.equal(v.rows[1].age, "3h")
		assert.equal(v.rows[1].repo, "octo/hello")
	end)
	it("ages in minutes, hours and days", function()
		assert.equal(View.age(0, 30 * 1000), "now")
		assert.equal(View.age(5 * 60 * 1000, 0), "5m")
		assert.equal(View.age(2 * 86400 * 1000, 0), "2d")
	end)
	it("shows a dimmed glyph before the first poll finishes", function()
		local v = View.build(Poll.create(), 0)
		assert.equal(v.glyph, "brand-github")
		assert.equal(v.glyphColor, "on_surface_variant")
		assert.equal(v.empty, false)
	end)
end)
