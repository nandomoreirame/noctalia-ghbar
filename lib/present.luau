-- Pure helpers for widget and panel command counters.

local Present = {}

function Present.bump(raw: any): number
	local n = tonumber(raw)
	if n == nil then
		return 1
	end
	return n + 1
end

return Present
