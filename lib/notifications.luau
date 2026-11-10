-- Pure parsing of GitHub /notifications payloads into panel rows.

local N = {}

local INBOX = "https://github.com/notifications"

-- Days since 1970-01-01 for a proleptic Gregorian date (Howard Hinnant).
local function daysFromCivil(y: number, m: number, d: number): number
	if m <= 2 then
		y -= 1
	end
	local era = (if y >= 0 then y else y - 399) // 400
	local yoe = y - era * 400
	local mp = (m + 9) % 12
	local doy = (153 * mp + 2) // 5 + d - 1
	local doe = yoe * 365 + yoe // 4 - yoe // 100 + doy
	return era * 146097 + doe - 719468
end

function N.parseTime(text: any): number?
	if typeof(text) ~= "string" then
		return nil
	end
	local y, mo, d, h, mi, s = string.match(text, "^(%d%d%d%d)%-(%d%d)%-(%d%d)[Tt ](%d%d):(%d%d):(%d%d)")
	if y == nil then
		return nil
	end
	local Y, M, D = tonumber(y), tonumber(mo), tonumber(d)
	local H, MI, S = tonumber(h), tonumber(mi), tonumber(s)
	local seconds = daysFromCivil(Y, M, D) * 86400 + H * 3600 + MI * 60 + S
	return seconds * 1000
end

function N.webUrl(apiUrl: any): string
	if typeof(apiUrl) ~= "string" then
		return INBOX
	end
	local owner, repo, kind, rest = string.match(apiUrl, "^https://api%.github%.com/repos/([^/]+)/([^/]+)/([^/]+)/(.*)$")
	if owner == nil then
		return INBOX
	end
	if kind == "pulls" then
		return "https://github.com/" .. owner .. "/" .. repo .. "/pull/" .. rest
	end
	if kind == "issues" then
		return "https://github.com/" .. owner .. "/" .. repo .. "/issues/" .. rest
	end
	if kind == "commits" then
		return "https://github.com/" .. owner .. "/" .. repo .. "/commit/" .. rest
	end
	if kind == "releases" then
		return "https://github.com/" .. owner .. "/" .. repo .. "/releases"
	end
	return INBOX
end

local function isArray(decoded: any): boolean
	if typeof(decoded) ~= "table" then
		return false
	end
	-- JSON arrays decode with consecutive integer keys from 1.
	local n = 0
	for k, _ in decoded do
		if typeof(k) ~= "number" then
			return false
		end
		n += 1
	end
	return #decoded == n
end

function N.parse(decoded: any): any
	if not isArray(decoded) then
		return { ok = false, error = "shape" }
	end
	local items = {}
	for _, raw in decoded do
		local subject = if typeof(raw.subject) == "table" then raw.subject else {}
		local repo = if typeof(raw.repository) == "table" then raw.repository else {}
		local id = if raw.id ~= nil then tostring(raw.id) else ""
		table.insert(items, {
			id = id,
			repo = if typeof(repo.full_name) == "string" then repo.full_name else "",
			title = if typeof(subject.title) == "string" then subject.title else "",
			kind = if typeof(subject.type) == "string" then subject.type else "",
			reason = if typeof(raw.reason) == "string" then raw.reason else "",
			updatedMs = N.parseTime(raw.updated_at) or 0,
			url = N.webUrl(subject.url),
		})
	end
	return { ok = true, items = items }
end

return N
