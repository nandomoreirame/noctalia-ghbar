-- Poll service: only entry that runs gh, HTTP, xdg-open and notifications.
-- The token lives only in callback locals and http headers.

local gh = require("./lib/gh.luau")
local notifications = require("./lib/notifications.luau")
local poll = require("./lib/poll.luau")
local view = require("./lib/view.luau")

local TICK_MS = 15000
local POLL_MS = 60000
local NOTIF_URL = "https://api.github.com/notifications?per_page=50"
local INBOX_URL = "https://github.com/notifications"

local state = poll.create()
local nextPollAt = 0
local generation = 0
-- id -> true while PATCH in flight; or generation number after PATCH success
-- (keep filtering until a poll with gen greater than that number has applied).
local pendingMark = {}

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

local function clearError()
	if state.error == nil then
		return
	end
	state = {
		items = state.items,
		loaded = state.loaded,
		error = nil,
	}
end

local function filterPending(items: { any }): { any }
	local out = {}
	for _, it in items do
		if not pendingMark[it.id] then
			table.insert(out, it)
		end
	end
	return out
end

local function toastEnabled(): boolean
	local ok, val = pcall(function()
		return noctalia.getConfig("notify_new")
	end)
	return ok and val == true
end

local function maybeNotify(fresh: { any })
	if not toastEnabled() or #fresh == 0 then
		return
	end
	local limit = 3
	local shown = math.min(limit, #fresh)
	for i = 1, shown do
		local item = fresh[i]
		noctalia.notify(item.repo, item.title)
	end
	local rest = #fresh - shown
	if rest > 0 then
		noctalia.notify(noctalia.tr("notify.title"), noctalia.tr("notify.more", { n = rest }))
	end
end

local function onHttp(gen: number, res: any)
	if gen ~= generation then
		return
	end
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
	local items = filterPending(parsed.items)
	local previous = state
	local fresh = poll.fresh(previous, items)
	state = poll.succeed(state, items, now())
	maybeNotify(fresh)
	local clearIds = {}
	for id, marker in pendingMark do
		if typeof(marker) == "number" and gen > marker then
			table.insert(clearIds, id)
		end
	end
	for _, id in clearIds do
		pendingMark[id] = nil
	end
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
	nextPollAt = now() + POLL_MS

	local launched = noctalia.runAsync(gh.TOKEN_ARGV, function(res)
		if gen ~= generation then
			return
		end
		local parsed = gh.parseToken(res)
		if parsed.ok ~= true then
			applyFail(parsed.error, 0)
			return
		end
		local token = parsed.token
		requestNotifications(token, gen)
	end)

	if launched == false then
		applyFail("no-gh", 0)
	end
end

local function markRead(token: string, id: string, done: (ok: boolean, status: number) -> ())
	noctalia.http({
		url = "https://api.github.com/notifications/threads/" .. id,
		method = "PATCH",
		headers = {
			"Authorization: Bearer " .. token,
			"Accept: application/vnd.github+json",
			"User-Agent: noctalia-ghbar",
		},
	}, function(res)
		local status = if typeof(res.status) == "number" then res.status else 0
		local ok = res.ok == true and (status == 200 or status == 205)
		done(ok, status)
	end)
end

local function withToken(done: (token: string) -> (), onErr: (kind: string) -> ())
	local launched = noctalia.runAsync(gh.TOKEN_ARGV, function(res)
		local parsed = gh.parseToken(res)
		if parsed.ok ~= true then
			onErr(parsed.error)
			return
		end
		done(parsed.token)
	end)
	if launched == false then
		onErr("no-gh")
	end
end

local function openItem(payload: any)
	if typeof(payload) ~= "table" or typeof(payload.id) ~= "string" then
		return
	end
	local id = payload.id
	local removed = poll.remove(state, id)
	if removed.item == nil then
		return
	end
	pendingMark[id] = true
	state = removed.state
	publish()

	local url = removed.item.url
	if gh.isSafeOpenUrl(url) then
		noctalia.runAsync({ "xdg-open", url })
	end

	withToken(function(token)
		markRead(token, id, function(ok, status)
			if ok then
				-- Keep filtering until a poll that started after this answer applies.
				pendingMark[id] = generation
				clearError()
				publish()
				return
			end
			pendingMark[id] = nil
			state = poll.restore(state, removed.item, removed.index)
			applyFail("mark", status)
		end)
	end, function(kind)
		pendingMark[id] = nil
		state = poll.restore(state, removed.item, removed.index)
		applyFail(kind, 0)
	end)
end

local function openInbox()
	noctalia.runAsync({ "xdg-open", INBOX_URL })
end

noctalia.state.watch("cmd.refresh", function()
	startPoll()
end)

noctalia.state.watch("cmd.open", function(payload)
	openItem(payload)
end)

noctalia.state.watch("cmd.inbox", function()
	openInbox()
end)

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
