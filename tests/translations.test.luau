local assert = require("./support/assert")
local runner = require("./support/runner")
local modules = require("./support/modules")
local mock = require("./support/noctalia_mock")

local describe, it = runner.describe, runner.it

local json = mock.new().noctalia.json

local REQUIRED = {
	"bar.tooltip",
	"bar.tooltip_error",
	"error.auth.action",
	"error.auth.title",
	"error.forbidden.action",
	"error.forbidden.title",
	"error.http.action",
	"error.http.title",
	"error.logged-out.action",
	"error.logged-out.title",
	"error.mark.action",
	"error.mark.title",
	"error.network.action",
	"error.network.title",
	"error.no-gh.action",
	"error.no-gh.title",
	"notify.more",
	"notify.title",
	"panel.empty",
	"panel.refresh",
	"panel.title",
	"reason.assign",
	"reason.author",
	"reason.ci_activity",
	"reason.comment",
	"reason.invitation",
	"reason.manual",
	"reason.mention",
	"reason.other",
	"reason.review_requested",
	"reason.security_alert",
	"reason.state_change",
	"reason.subscribed",
	"reason.team_mention",
	"settings.notify_new.description",
	"settings.notify_new.label",
}

local function flatten(node: any, prefix: string, out: { string })
	for k, v in node do
		local key = if prefix == "" then k else prefix .. "." .. k
		if typeof(v) == "table" then
			flatten(v, key, out)
		else
			table.insert(out, key)
		end
	end
	return out
end

local function keys(locale: string): { string }
	local decoded = json.decode(modules.text("translations/" .. locale .. ".json"))
	local out = flatten(decoded, "", {})
	table.sort(out)
	return out
end

describe("translations", function()
	it("en declares exactly the required keys", function()
		assert.equal(table.concat(keys("en"), ","), table.concat(REQUIRED, ","))
	end)

	it("pt-BR has the same key set as en", function()
		assert.equal(table.concat(keys("pt-BR"), ","), table.concat(keys("en"), ","))
	end)
end)
