local lib = {}

---@param entity Entity
---@return Entity?
function lib.GetWeapon(entity)
	return entity:GetPropEntity("m_hActiveWeapon")
end

---@param entity Entity
function lib.GetEyePos(entity)
	return entity:GetAbsOrigin() + entity:GetPropVector("localdata", "m_vecViewOffset[0]")
end

function lib.GetWorldSpaceCenter(entity)
	local mins, maxs, origin
	mins = entity:GetMins()
	maxs = entity:GetMaxs()
	origin = entity:GetAbsOrigin()
	return origin + (mins + maxs) * 0.5
end

return lib