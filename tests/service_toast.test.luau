local assert = require("./support/assert")
local runner = require("./support/runner")
local modules = require("./support/modules")
local mock = require("./support/noctalia_mock")
local entry = require("./support/entry")

local describe, it = runner.describe, runner.it

local FIXTURE = modules.text("tests/fixtures/notifications.json")
local TOKEN_OK = {
	exitCode = 0,
	stdout = "SECRET-GH\n",
	stderr = "",
	timedOut = false,
	stdoutTruncated = false,
	stderrTruncated = false,
}

local function boot(config)
	return entry.load("service.luau", {
		now = 0,
		async = { ["gh auth token"] = TOKEN_OK },
		config = config or {},
	})
end

local function httpCalls(s)
	return mock.calls(s.env, "noctalia.http")
end

local function answerHttp(s, index, res)
	httpCalls(s)[index][2](res)
end

local function fixturePlus(nExtra: number): string
	local items = mock.json.decode(FIXTURE)
	for i = 1, nExtra do
		table.insert(items, {
			id = tostring(2000 + i),
			reason = "mention",
			updated_at = "2026-11-10T13:00:00Z",
			subject = {
				title = "extra-" .. i,
				url = "https://api.github.com/repos/octo/hello/issues/" .. (20 + i),
				type = "Issue",
			},
			repository = { full_name = "octo/hello" },
		})
	end
	return mock.json.encode(items)
end

describe("service toast", function()
	it("stays silent by default", function()
		local s = boot({})
		answerHttp(s, 1, { ok = true, status = 200, body = FIXTURE })
		mock.setNow(s.env, 60000)
		s.call("update")
		answerHttp(s, 2, { ok = true, status = 200, body = fixturePlus(1) })
		assert.equal(#mock.calls(s.env, "noctalia.notify"), 0)
	end)

	it("notifies only items new since the last poll", function()
		local s = boot({ notify_new = true })
		answerHttp(s, 1, { ok = true, status = 200, body = FIXTURE })
		assert.equal(#mock.calls(s.env, "noctalia.notify"), 0)
		mock.setNow(s.env, 60000)
		s.call("update")
		answerHttp(s, 2, { ok = true, status = 200, body = fixturePlus(1) })
		local notes = mock.calls(s.env, "noctalia.notify")
		assert.equal(#notes, 1)
		assert.equal(notes[1][1], "octo/hello")
		assert.equal(notes[1][2], "extra-1")
	end)

	it("caps the burst at three toasts and one summary", function()
		local s = boot({ notify_new = true })
		answerHttp(s, 1, { ok = true, status = 200, body = FIXTURE })
		mock.setNow(s.env, 60000)
		s.call("update")
		answerHttp(s, 2, { ok = true, status = 200, body = fixturePlus(5) })
		local notes = mock.calls(s.env, "noctalia.notify")
		-- three item toasts + one summary
		assert.equal(#notes, 4)
		local summary = notes[4]
		-- summary uses translated notify.title / notify.more
		assert.equal(typeof(summary[1]) == "string", true)
		assert.equal(typeof(summary[2]) == "string", true)
	end)
end)
