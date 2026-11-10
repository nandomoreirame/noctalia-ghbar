-- Poll service: only entry that runs gh, HTTP and notifications.
-- The token lives only in callback locals and http headers.

local gh = require("./lib/gh.luau")
local notifications = require("./lib/notifications.luau")
local poll = require("./lib/poll.luau")
local view = require("./lib/view.luau")

local TICK_MS = 15000
local POLL_MS = 60000
local NOTIF_URL = "https://api.github.com/notifications?per_page=50"

local state = poll.create()
local nextPollAt = 0
local generation = 0
local inFlight = false

local function now(): number
	return noctalia.nowMs()
end

local function publish()
	noctalia.state.set("view", view.build(state, now()))
end

local function applyFail(kind: string, status: number)
	state = poll.fail(state, kind, status, now())
	publish()
end

local function onHttp(gen: number, res: any)
	if gen ~= generation then
		return
	end
	inFlight = false
	local status = if typeof(res.status) == "number" then res.status else 0
	if res.ok ~= true or status ~= 200 then
		noctalia.log("ghbar poll status " .. tostring(status))
		applyFail(poll.errorKind(status), status)
		return
	end
	local decoded, err = noctalia.json.decode(if typeof(res.body) == "string" then res.body else "")
	if err ~= nil or decoded == nil then
		noctalia.log("ghbar poll status decode-error")
		applyFail("http", status)
		return
	end
	local parsed = notifications.parse(decoded)
	if parsed.ok ~= true then
		noctalia.log("ghbar poll status shape")
		applyFail("http", status)
		return
	end
	noctalia.log("ghbar poll status 200")
	state = poll.succeed(state, parsed.items, now())
	publish()
end

local function requestNotifications(token: string, gen: number)
	noctalia.http({
		url = NOTIF_URL,
		method = "GET",
		headers = {
			"Authorization: Bearer " .. token,
			"Accept: application/vnd.github+json",
			"User-Agent: noctalia-ghbar",
		},
	}, function(res)
		onHttp(gen, res)
	end)
end

local function startPoll()
	generation += 1
	local gen = generation
	inFlight = true
	nextPollAt = now() + POLL_MS

	local launched = noctalia.runAsync(gh.TOKEN_ARGV, function(res)
		if gen ~= generation then
			return
		end
		local parsed = gh.parseToken(res)
		if parsed.ok ~= true then
			inFlight = false
			applyFail(parsed.error, 0)
			return
		end
		local token = parsed.token
		requestNotifications(token, gen)
	end)

	if launched == false then
		inFlight = false
		applyFail("no-gh", 0)
	end
end

function update()
	if now() >= nextPollAt then
		startPoll()
	else
		publish()
	end
end

noctalia.setUpdateInterval(TICK_MS)
publish()
startPoll()
