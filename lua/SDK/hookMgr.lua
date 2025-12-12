local lib = {}
local hooks = {}

---@param id string
---@param name string
---@param func function
function lib.Register(id, name, func)
	if callbacks.Register(id, name, func) then
		if hooks[id] == nil then
			hooks[id] = {}
		end

		hooks[id][name] = true
		return true
	end

	return false
end

---@param id string
---@param name string
function lib.Unregister(id, name)
	if callbacks.Unregister(id, name) then
		hooks[id][name] = nil
		return true
	end
	return false
end

function lib.UnregisterAll()
	for id, hookTable in pairs (hooks) do
		--- Dont want to acidentally unregister our unload functions
		if id ~= "Unload" then
			for name in pairs (hookTable) do
				callbacks.Unregister(id, name)
			end
		end
	end

	hooks = {}
end

return lib