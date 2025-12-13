local settings = {}
local data = {}

local unload = false
local status = false
local attempts = 0

local json = require("SDK.json")

---@return Settings
function settings.Get()
	return data
end

function settings.GetStatus()
	return status
end

function settings.ShouldUnload()
	return unload
end

function settings.Store()
	if attempts >= 3 then
		data = nil
		status = false
		unload = true
		return
	end

	local response = http.Get("http://localhost:8080/")
	if response == "" then
		attempts = attempts + 1
		return
	end

	local decoded = json.decode(response)
	if type(decoded) ~= "table" then
		return
	end

	data = decoded
	attempts = 0
	status = true
end

return settings