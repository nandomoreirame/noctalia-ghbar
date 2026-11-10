-- Pure poll state machine for the notifications inbox.

local Poll = {}

local function copyItems(items: { any }): { any }
	local out = {}
	for i, it in items do
		out[i] = it
	end
	return out
end

function Poll.create(): any
	return {
		items = {},
		loaded = false,
		error = nil,
	}
end

function Poll.succeed(state: any, items: { any }, nowMs: number): any
	return {
		items = copyItems(items),
		loaded = true,
		error = nil,
	}
end

function Poll.fail(state: any, kind: string, status: number, nowMs: number): any
	return {
		items = copyItems(state.items or {}),
		loaded = state.loaded == true,
		error = { kind = kind, status = status },
	}
end

function Poll.errorKind(status: number): string
	if status == 401 then
		return "auth"
	end
	if status == 403 then
		return "forbidden"
	end
	if status == 0 then
		return "network"
	end
	return "http"
end

function Poll.remove(state: any, id: string): any
	local items = copyItems(state.items or {})
	local index = nil
	local item = nil
	for i, it in items do
		if it.id == id then
			index = i
			item = it
			table.remove(items, i)
			break
		end
	end
	return {
		state = {
			items = items,
			loaded = state.loaded,
			error = state.error,
		},
		item = item,
		index = index,
	}
end

function Poll.restore(state: any, item: any, index: number): any
	local items = copyItems(state.items or {})
	if index == nil or item == nil then
		return {
			items = items,
			loaded = state.loaded,
			error = state.error,
		}
	end
	for _, it in items do
		if it.id == item.id then
			return {
				items = items,
				loaded = state.loaded,
				error = state.error,
			}
		end
	end
	if index < 1 then
		index = 1
	end
	if index > #items + 1 then
		index = #items + 1
	end
	table.insert(items, index, item)
	return {
		items = items,
		loaded = state.loaded,
		error = state.error,
	}
end

function Poll.fresh(state: any, items: { any }): { any }
	if state.loaded ~= true then
		return {}
	end
	local seen = {}
	for _, it in state.items or {} do
		seen[it.id] = true
	end
	local out = {}
	for _, it in items do
		if not seen[it.id] then
			table.insert(out, it)
		end
	end
	return out
end

return Poll
