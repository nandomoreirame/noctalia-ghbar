local assert = require("./support/assert")
local runner = require("./support/runner")
local modules = require("./support/modules")
local mock = require("./support/noctalia_mock")
local entry = require("./support/entry")

local describe, it = runner.describe, runner.it

local FIXTURE = modules.text("tests/fixtures/notifications.json")
local NOTIF_URL = "https://api.github.com/notifications?per_page=50"
local TOKEN_OK = {
	exitCode = 0,
	stdout = "SECRET-GH\n",
	stderr = "",
	timedOut = false,
	stdoutTruncated = false,
	stderrTruncated = false,
}

local function boot(opts: any?)
	local o = opts or {}
	local async = o.async or { ["gh auth token"] = TOKEN_OK }
	return entry.load("service.luau", {
		now = o.now or 0,
		async = async,
		config = o.config or { notify_new = false },
	})
end

local function httpCalls(s)
	return mock.calls(s.env, "noctalia.http")
end

local function lastView(s)
	local sets = mock.calls(s.env, "noctalia.state.set")
	local view = nil
	for _, call in sets do
		if call[1] == "view" then
			view = call[2]
		end
	end
	return view
end

local function hasHeader(headers, needle)
	for _, h in headers do
		if h == needle then
			return true
		end
	end
	return false
end

local function answerHttp(s, index, res)
	local call = httpCalls(s)[index]
	assert.equal(call ~= nil, true)
	call[2](res)
end

describe("service poll", function()
	it("polls the notifications endpoint every 60 seconds", function()
		local s = boot()
		local calls = httpCalls(s)
		assert.equal(#calls, 1)
		local req = calls[1][1]
		assert.equal(req.url, NOTIF_URL)
		assert.equal(req.method, "GET")
		assert.equal(hasHeader(req.headers, "Authorization: Bearer SECRET-GH"), true)
		assert.equal(hasHeader(req.headers, "Accept: application/vnd.github+json"), true)
		assert.equal(hasHeader(req.headers, "User-Agent: noctalia-ghbar"), true)

		mock.setNow(s.env, 59000)
		s.call("update")
		assert.equal(#httpCalls(s), 1)

		mock.setNow(s.env, 60000)
		s.call("update")
		assert.equal(#httpCalls(s), 2)
	end)

	it("publishes the view from the fixture answer", function()
		local s = boot()
		answerHttp(s, 1, { ok = true, status = 200, body = FIXTURE })
		local v = lastView(s)
		assert.equal(v.label, "3")
		assert.equal(#v.rows, 3)
	end)

	it("token never appears in state, logs or notifications", function()
		local s = boot({ config = { notify_new = true } })
		answerHttp(s, 1, { ok = true, status = 200, body = FIXTURE })
		-- Second poll with one extra item fires a toast while notify_new is on.
		local plus = mock.json.decode(FIXTURE)
		table.insert(plus, {
			id = "2001",
			reason = "mention",
			updated_at = "2026-11-10T13:00:00Z",
			subject = {
				title = "extra",
				url = "https://api.github.com/repos/octo/hello/issues/99",
				type = "Issue",
			},
			repository = { full_name = "octo/hello" },
		})
		mock.setNow(s.env, 60000)
		s.call("update")
		answerHttp(s, 2, { ok = true, status = 200, body = mock.json.encode(plus) })
		assert.equal(#mock.calls(s.env, "noctalia.notify") >= 1, true)
		-- Open + PATCH path also must not leak the token.
		s.env.noctalia.state.set("cmd.open", { id = "1001", n = 1 })
		local patchCb = nil
		for _, call in httpCalls(s) do
			if call[1].method == "PATCH" then
				patchCb = call[2]
			end
		end
		assert.equal(patchCb ~= nil, true)
		patchCb({ ok = true, status = 205, body = "" })

		local paths = {
			"noctalia.state.set",
			"noctalia.log",
			"noctalia.notify",
			"noctalia.writeFile",
		}
		for _, path in paths do
			for _, call in mock.calls(s.env, path) do
				local text = mock.json.encode(call)
				assert.equal(string.find(text, "SECRET-GH", 1, true), nil)
			end
		end
		for _, call in mock.calls(s.env, "noctalia.runAsync") do
			local text = mock.json.encode(call[1])
			assert.equal(string.find(text, "SECRET-GH", 1, true), nil)
		end
	end)

	it("reports gh missing when the launch fails", function()
		local s = boot({
			async = {
				["gh auth token"] = {
					exitCode = 127,
					stdout = "",
					stderr = "",
					timedOut = false,
					stdoutTruncated = false,
					stderrTruncated = false,
					failLaunch = true,
				},
			},
		})
		local v = lastView(s)
		assert.equal(v.error.kind, "no-gh")
	end)

	it("reports logged out and auth errors", function()
		local loggedOut = boot({
			async = {
				["gh auth token"] = {
					exitCode = 1,
					stdout = "",
					stderr = "You are not logged in",
					timedOut = false,
					stdoutTruncated = false,
					stderrTruncated = false,
				},
			},
		})
		assert.equal(lastView(loggedOut).error.kind, "logged-out")

		local s = boot()
		answerHttp(s, 1, { ok = true, status = 200, body = FIXTURE })
		assert.equal(#lastView(s).rows, 3)

		mock.setNow(s.env, 60000)
		s.call("update")
		answerHttp(s, 2, { ok = true, status = 401, body = "" })
		local authView = lastView(s)
		assert.equal(authView.error.kind, "auth")
		assert.equal(#authView.rows, 3)

		mock.setNow(s.env, 120000)
		s.call("update")
		answerHttp(s, 3, { ok = false, status = 0, body = "" })
		local netView = lastView(s)
		assert.equal(netView.error.kind, "network")
		assert.equal(#netView.rows, 3)
	end)
end)
