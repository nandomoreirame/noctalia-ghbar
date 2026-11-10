-- Pure helpers for widget and panel command counters and reason keys.

local Present = {}

local REASONS = {
	assign = true,
	author = true,
	comment = true,
	ci_activity = true,
	invitation = true,
	manual = true,
	mention = true,
	review_requested = true,
	security_alert = true,
	state_change = true,
	subscribed = true,
	team_mention = true,
	other = true,
}

local KIND_GLYPH = {
	PullRequest = "git-pull-request",
	Issue = "circle-dot",
	Release = "tag",
	Commit = "git-commit",
	Discussion = "message-circle",
}

function Present.bump(raw: any): number
	local n = tonumber(raw)
	if n == nil then
		return 1
	end
	return n + 1
end

function Present.reasonKey(reason: any): string
	if typeof(reason) == "string" and REASONS[reason] then
		return "reason." .. reason
	end
	return "reason.other"
end

function Present.kindGlyph(kind: any): string
	if typeof(kind) == "string" and KIND_GLYPH[kind] then
		return KIND_GLYPH[kind]
	end
	return "bell"
end

return Present
