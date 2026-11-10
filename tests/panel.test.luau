local assert = require("./support/assert")
local runner = require("./support/runner")
local modules = require("./support/modules")
local mock = require("./support/noctalia_mock")
local entry = require("./support/entry")

local describe, it = runner.describe, runner.it

local View = modules.load("lib/view.luau")
local Poll = modules.load("lib/poll.luau")
local N = modules.load("lib/notifications.luau")
local fixture = modules.text("tests/fixtures/notifications.json")
local decode = mock.new().noctalia.json.decode

local function fixtureView()
	local items = N.parse(decode(fixture)).items
	-- Age relative to the first item's updatedMs so the compact label is "3h".
	local nowMs = (items[1].updatedMs or 0) + 3 * 3600 * 1000
	return View.build(Poll.succeed(Poll.create(), items, 1), nowMs)
end

local function walk(node, out)
	out = out or {}
	if typeof(node) == "table" and node.type then
		table.insert(out, node)
		for _, child in node.children or {} do
			walk(child, out)
		end
	end
	return out
end

local function lastTree(p)
	local calls = mock.calls(p.env, "panel.render")
	return calls[#calls][1]
end

local function texts(p)
	local list = {}
	for _, node in walk(lastTree(p)) do
		if node.props.text then
			table.insert(list, node.props.text)
		end
	end
	return list
end

local function has(list, value)
	for _, v in list do
		if v == value then
			return true
		end
	end
	return false
end

local function find(p, pred)
	for _, node in walk(lastTree(p)) do
		if pred(node) then
			return node
		end
	end
	return nil
end

local function findAll(p, pred)
	local out = {}
	for _, node in walk(lastTree(p)) do
		if pred(node) then
			table.insert(out, node)
		end
	end
	return out
end

local function boot(view)
	local p = entry.load("panel.luau", {})
	p.env.noctalia.state.set("view", view)
	p.call("onOpen", {})
	return p
end

describe("panel", function()
	it("lists one row per notification", function()
		local p = boot(fixtureView())
		assert.equal(find(p, function(n)
			return n.type == "scroll"
		end) ~= nil, true)
		local rows = findAll(p, function(n)
			return n.props and (n.props.key == "1001" or n.props.key == "1002" or n.props.key == "1003")
		end)
		assert.equal(#rows, 3)
		local t = texts(p)
		assert.equal(has(t, "octo/hello"), true)
		assert.equal(has(t, "Add notifications widget"), true)
		assert.equal(has(t, "3h"), true)
	end)

	it("shows the translated reason and kind", function()
		local p = boot(fixtureView())
		local t = texts(p)
		assert.equal(has(t, "reason.review_requested"), true)
		local unknown = View.build(
			Poll.succeed(Poll.create(), {
				{
					id = "9",
					repo = "octo/hello",
					title = "x",
					kind = "Issue",
					reason = "weird_reason",
					updatedMs = 0,
					url = "https://github.com/notifications",
				},
			}, 1),
			0
		)
		p.env.noctalia.state.set("view", unknown)
		assert.equal(has(texts(p), "reason.other"), true)
	end)

	it("sends cmd.open with a bumped counter when a row is clicked", function()
		local p = boot(fixtureView())
		local row = find(p, function(n)
			return n.props and n.props.key == "1001"
		end)
		assert.equal(row ~= nil, true)
		row.props.onClick()
		assert.deepEqual(p.env.noctalia.state.get("cmd.open"), { id = "1001", n = 1 })
		row.props.onClick()
		assert.deepEqual(p.env.noctalia.state.get("cmd.open"), { id = "1001", n = 2 })
	end)

	it("shows the empty state when the list is empty", function()
		local empty = View.build(Poll.succeed(Poll.create(), {}, 1), 0)
		local p = boot(empty)
		assert.equal(has(texts(p), "panel.empty"), true)
	end)

	it("shows the cause and the action on error", function()
		local kinds = { "auth", "forbidden", "no-gh", "logged-out", "network", "http", "mark" }
		for _, kind in kinds do
			local v = View.build(Poll.fail(Poll.create(), kind, 0, 1), 0)
			local p = boot(v)
			local t = texts(p)
			assert.equal(has(t, "error." .. kind .. ".title"), true)
			assert.equal(has(t, "error." .. kind .. ".action"), true)
		end
	end)

	it("refresh bumps cmd.refresh", function()
		local p = boot(fixtureView())
		local btn = find(p, function(n)
			return n.type == "button" and n.props.glyph == "refresh"
		end)
		assert.equal(btn ~= nil, true)
		btn.props.onClick()
		assert.equal(p.env.noctalia.state.get("cmd.refresh"), 1)
		btn.props.onClick()
		assert.equal(p.env.noctalia.state.get("cmd.refresh"), 2)
	end)

	it("renders again when the view changes and when opened", function()
		local p = boot(fixtureView())
		local before = #mock.calls(p.env, "panel.render")
		p.env.noctalia.state.set("view", View.build(Poll.succeed(Poll.create(), {}, 1), 0))
		assert.equal(#mock.calls(p.env, "panel.render") > before, true)
		local mid = #mock.calls(p.env, "panel.render")
		p.call("onOpen", {})
		assert.equal(#mock.calls(p.env, "panel.render"), mid + 1)
	end)

	it("renders explicit visual properties on every row", function()
		local p = boot(fixtureView())
		local rows = findAll(p, function(n)
			return n.props and (n.props.key == "1001" or n.props.key == "1002" or n.props.key == "1003")
		end)
		assert.equal(#rows, 3)
		for _, row in rows do
			assert.equal(row.props.radius ~= nil, true)
			assert.equal(row.props.paddingH ~= nil, true)
			assert.equal(row.props.paddingV ~= nil, true)
			assert.equal(row.props.gap ~= nil, true)
		end
	end)
end)
