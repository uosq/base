local lib = {}

---@param color ColorRGBA
local function ConvertColor(color)
	return {color.R/255, color.G/255, color.B/255, color.A/255}
end

---@param settings Settings
---@param entity Entity
---@param aimTarget Entity?
function lib.GetColor(settings, entity, aimTarget)
	do
		local class = entity:GetClass()
		if class == "CBaseAnimating" then
			local modelName = models.GetModelName(entity:GetModel())
			if string.find(modelName, "ammopack") then
				return ConvertColor(settings.visuals.colors.ammopack)
			elseif string.find(modelName, "medkit") then
				return ConvertColor(settings.visuals.colors.medkit)
			end
		end

		if class == "CPhysicsProp" then
			return ConvertColor(settings.visuals.colors.cphysicsprop)
		end
	end

	if aimTarget and aimTarget:GetIndex() == entity:GetIndex() then
		return ConvertColor(settings.visuals.colors.aimtarget)
	end

	if entity:IsWeapon() then
		return ConvertColor(settings.visuals.colors.weapon)
	end

	do
		local priority = playerlist.GetPriority(entity)
		if priority > 0 then
			return ConvertColor(settings.visuals.colors.priority)
		elseif priority < 0 then
			return ConvertColor(settings.visuals.colors.friend)
		end
	end

	if entity:GetIndex() == client.GetLocalPlayerIndex() then
		return ConvertColor(settings.visuals.colors.localplayer)
	end

	do
		local team = entity:GetTeamNumber()
		if team == 3 then
			return ConvertColor(settings.visuals.colors.blueteam)
		end

		if team == 2 then
			return ConvertColor(settings.visuals.colors.redteam)
		end
	end

	--- COLOR_NONE
	return {1, 1, 1}
end

return lib