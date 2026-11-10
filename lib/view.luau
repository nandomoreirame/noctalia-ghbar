-- Pure view model built from poll state for widget and panel.

local View = {}

function View.age(nowMs: number, updatedMs: number): string
	local delta = nowMs - updatedMs
	if delta < 0 then
		delta = 0
	end
	if delta < 60 * 1000 then
		return "now"
	end
	if delta < 3600 * 1000 then
		return tostring(delta // (60 * 1000)) .. "m"
	end
	if delta < 86400 * 1000 then
		return tostring(delta // (3600 * 1000)) .. "h"
	end
	return tostring(delta // (86400 * 1000)) .. "d"
end

function View.build(state: any, nowMs: number): any
	local items = state.items or {}
	local count = #items
	local err = state.error
	local loaded = state.loaded == true
	local label = if count >= 50 then "50+" else tostring(count)
	local glyph = if err ~= nil then "alert-triangle" else "brand-github"
	local visible = count > 0 or err ~= nil
	local empty = loaded and err == nil and count == 0
	local rows = {}
	for _, it in items do
		table.insert(rows, {
			id = it.id,
			repo = it.repo,
			title = it.title,
			kind = it.kind,
			reason = it.reason,
			age = View.age(nowMs, it.updatedMs or 0),
			url = it.url,
		})
	end
	return {
		visible = visible,
		glyph = glyph,
		label = label,
		count = count,
		empty = empty,
		error = err,
		rows = rows,
	}
end

return View
