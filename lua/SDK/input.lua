local lib = {}

function lib.GetKey(keystr)
	local upper = string.upper(keystr)

	--- early return as none means yes
	if upper == "KEY_NONE" then
		return true
	end

	if E_ButtonCode[upper] then
		return input.IsButtonDown(E_ButtonCode[upper])
	end

	local key = E_ButtonCode["KEY_" .. upper]

	if not key then
		key = E_ButtonCode[upper]
	end

	return key and input.IsButtonDown(key)
end

return lib