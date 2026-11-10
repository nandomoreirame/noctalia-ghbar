local assert = require("./support/assert")
local runner = require("./support/runner")
local modules = require("./support/modules")
local mock = require("./support/noctalia_mock")
local entry = require("./support/entry")

local describe, it = runner.describe, runner.it

local FIXTURE = modules.text("tests/fixtures/notifications.json")
local Gh = modules.load("lib/gh.luau")
local TOKEN_OK = {
	exitCode = 0,
	stdout = "SECRET-GH\n",
	stderr = "",
	timedOut = false,
	stdoutTruncated = false,
	stderrTruncated = false,
}

local function boot()
	return entry.load("service.luau", {
		now = 0,
		async = { ["gh auth token"] = TOKEN_OK },
		config = { notify_new = false },
	})
end

local function httpCalls(s)
	return mock.calls(s.env, "noctalia.http")
end

local function lastView(s)
	local view = nil
	for _, call in mock.calls(s.env, "noctalia.state.set") do
		if call[1] == "view" then
			view = call[2]
		end
	end
	return view
end

local function answerHttp(s, index, res)
	local call = httpCalls(s)[index]
	assert.equal(call ~= nil, true)
	call[2](res)
end

local function loadWithFixture()
	local s = boot()
	answerHttp(s, 1, { ok = true, status = 200, body = FIXTURE })
	assert.equal(#lastView(s).rows, 3)
	return s
end

local function lastPatch(s)
	local idx, req, cb = nil, nil, nil
	for i, call in httpCalls(s) do
		if call[1].method == "PATCH" then
			idx, req, cb = i, call[1], call[2]
		end
	end
	return idx, req, cb
end

describe("service open", function()
	it("opens the page and marks the thread read", function()
		local s = loadWithFixture()
		s.env.noctalia.state.set("cmd.open", { id = "1001", n = 1 })
		local opened = false
		for _, call in mock.calls(s.env, "noctalia.runAsync") do
			local argv = call[1]
			if typeof(argv) == "table" and argv[1] == "xdg-open" then
				assert.equal(argv[2], "https://github.com/octo/hello/pull/12")
				assert.equal(call[2], nil)
				opened = true
			end
		end
		assert.equal(opened, true)
		local _, req = lastPatch(s)
		assert.equal(req ~= nil, true)
		assert.equal(req.url, "https://api.github.com/notifications/threads/1001")
		assert.equal(req.method, "PATCH")
		assert.equal(#lastView(s).rows, 2)
	end)

	it("restores the item when the PATCH fails", function()
		local s = loadWithFixture()
		s.env.noctalia.state.set("cmd.open", { id = "1001", n = 1 })
		local _, _, cb = lastPatch(s)
		assert.equal(cb ~= nil, true)
		cb({ ok = false, status = 0, body = "" })
		local v = lastView(s)
		assert.equal(#v.rows, 3)
		assert.equal(v.rows[1].id, "1001")
		assert.equal(v.error.kind, "mark")

		s.env.noctalia.state.set("cmd.open", { id = "1001", n = 2 })
		local _, _, cb2 = lastPatch(s)
		cb2({ ok = true, status = 500, body = "" })
		local v2 = lastView(s)
		assert.equal(#v2.rows, 3)
		assert.equal(v2.error.kind, "mark")
	end)

	it("keeps the item removed on a 205 answer", function()
		local s = loadWithFixture()
		s.env.noctalia.state.set("cmd.open", { id = "1001", n = 1 })
		local _, _, cb = lastPatch(s)
		cb({ ok = true, status = 205, body = "" })
		local v = lastView(s)
		assert.equal(#v.rows, 2)
		assert.equal(v.error, nil)
	end)

	it("ignores an id that is not in the list", function()
		local s = loadWithFixture()
		local beforeHttp = #httpCalls(s)
		local beforeAsync = #mock.calls(s.env, "noctalia.runAsync")
		s.env.noctalia.state.set("cmd.open", { id = "9999", n = 1 })
		assert.equal(#httpCalls(s), beforeHttp)
		for i = beforeAsync + 1, #mock.calls(s.env, "noctalia.runAsync") do
			local argv = mock.calls(s.env, "noctalia.runAsync")[i][1]
			assert.equal(typeof(argv) == "table" and argv[1] == "xdg-open", false)
		end
	end)

	it("refresh polls immediately", function()
		local s = loadWithFixture()
		local before = #mock.calls(s.env, "noctalia.runAsync")
		s.env.noctalia.state.set("cmd.refresh", 1)
		local tokens = 0
		local after = mock.calls(s.env, "noctalia.runAsync")
		for i = before + 1, #after do
			local argv = after[i][1]
			if typeof(argv) == "table" and table.concat(argv, " ") == "gh auth token" then
				tokens += 1
			end
		end
		assert.equal(tokens >= 1, true)
	end)

	it("opens only https github.com urls", function()
		assert.equal(Gh.isSafeOpenUrl("https://github.com/octo/hello/pull/12"), true)
		assert.equal(Gh.isSafeOpenUrl("https://github.com/notifications"), true)
		assert.equal(Gh.isSafeOpenUrl("http://github.com/octo/hello"), false)
		assert.equal(Gh.isSafeOpenUrl("https://evil.example/x"), false)
		assert.equal(Gh.isSafeOpenUrl("javascript:alert(1)"), false)
		assert.equal(Gh.isSafeOpenUrl(nil), false)

		local s = loadWithFixture()
		s.env.noctalia.state.set("cmd.open", { id = "1001", n = 1 })
		for _, call in mock.calls(s.env, "noctalia.runAsync") do
			local argv = call[1]
			if typeof(argv) == "table" and argv[1] == "xdg-open" then
				assert.equal(Gh.isSafeOpenUrl(argv[2]), true)
			end
		end
	end)

	it("keeps a pending mark-read id out of a concurrent poll", function()
		local s = loadWithFixture()
		s.env.noctalia.state.set("cmd.open", { id = "1001", n = 1 })
		assert.equal(#lastView(s).rows, 2)
		s.env.noctalia.state.set("cmd.refresh", 1)
		answerHttp(s, #httpCalls(s), { ok = true, status = 200, body = FIXTURE })
		assert.equal(#lastView(s).rows, 2)
		local ids = {}
		for _, row in lastView(s).rows do
			ids[row.id] = true
		end
		assert.equal(ids["1001"], nil)
	end)

	it("does not duplicate a row when restore races a poll", function()
		local s = loadWithFixture()
		s.env.noctalia.state.set("cmd.open", { id = "1001", n = 1 })
		s.env.noctalia.state.set("cmd.refresh", 1)
		-- Clear pending by answering PATCH fail after poll re-listed the id:
		-- first clear pendingMark by failing PATCH after poll already restored via filter.
		-- Force: answer GET with fixture (filters 1001 while pending), then fail PATCH
		-- which restores; restore must not duplicate if somehow present.
		answerHttp(s, #httpCalls(s), { ok = true, status = 200, body = FIXTURE })
		local _, _, cb = lastPatch(s)
		cb({ ok = false, status = 500, body = "" })
		local v = lastView(s)
		local count = 0
		for _, row in v.rows do
			if row.id == "1001" then
				count += 1
			end
		end
		assert.equal(count, 1)
		assert.equal(#v.rows, 3)
	end)

	it("opens the web inbox on cmd.inbox", function()
		local s = loadWithFixture()
		local before = #mock.calls(s.env, "noctalia.runAsync")
		s.env.noctalia.state.set("cmd.inbox", 1)
		local opened = false
		for i = before + 1, #mock.calls(s.env, "noctalia.runAsync") do
			local argv = mock.calls(s.env, "noctalia.runAsync")[i][1]
			if typeof(argv) == "table" and argv[1] == "xdg-open" then
				assert.equal(argv[2], "https://github.com/notifications")
				opened = true
			end
		end
		assert.equal(opened, true)
	end)
end)
