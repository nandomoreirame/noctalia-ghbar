-- Pure helpers for the gh CLI token source. Never touches noctalia.

local Gh = {}

Gh.TOKEN_ARGV = { "gh", "auth", "token" }

local function trim(s: string): string
	return (string.gsub(s, "^%s+", ""):gsub("%s+$", ""))
end

function Gh.parseToken(res: { exitCode: number, stdout: string?, stderr: string? }): any
	local exitCode = res.exitCode
	local stdout = if typeof(res.stdout) == "string" then res.stdout else ""
	local stderr = if typeof(res.stderr) == "string" then res.stderr else ""

	if exitCode == 0 then
		local token = trim(stdout)
		if token == "" then
			return { ok = false, error = "logged-out" }
		end
		return { ok = true, token = token }
	end

	if exitCode == 127 or string.find(stderr, "not found", 1, true) ~= nil then
		return { ok = false, error = "no-gh" }
	end

	return { ok = false, error = "logged-out" }
end

function Gh.isSafeOpenUrl(url: any): boolean
	return typeof(url) == "string" and string.sub(url, 1, 19) == "https://github.com/"
end

return Gh
