local assert = require("./support/assert")
local runner = require("./support/runner")
local modules = require("./support/modules")

local describe, it = runner.describe, runner.it
local present = modules.load("lib/present.luau")

describe("present.bump", function()
	it("starts at one and increments", function()
		assert.equal(present.bump(nil), 1)
		assert.equal(present.bump(1), 2)
		assert.equal(present.bump(41), 42)
	end)
end)
