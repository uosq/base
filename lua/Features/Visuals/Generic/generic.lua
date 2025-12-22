local lib = {}
local SDK = require("SDK.sdk")

---@param entity Entity
function lib:IsValidEntity(entity)
	if entity:IsDormant() then
		return false
	end

	if entity:IsPlayer() then
		return entity:IsAlive()
	else
		return entity:GetHealth() >= 0
	end
end

---@param settings Settings
---@return Entity[]
function lib:GetTargets(settings)
	local targets = {}

	local entityFilter = settings.visuals.filter

	--- players
	if SDK.bGetFlag(entityFilter, 0) then
		for _, entity in pairs(entities.FindByClass("CTFPlayer")) do
			if self:IsValidEntity(entity) then
				targets[#targets+1] = entity
			end
		end
	end

	--- sentries
	if SDK.bGetFlag(entityFilter, 2) then
		for _, entity in pairs(entities.FindByClass("CObjectSentrygun")) do
			if self:IsValidEntity(entity) then
				targets[#targets+1] = entity
			end
		end
	end

	--- dispensers
	if SDK.bGetFlag(entityFilter, 3) then
		for _, entity in pairs(entities.FindByClass("CObjectDispenser")) do
			if self:IsValidEntity(entity) then
				targets[#targets+1] = entity
			end
		end
	end

	--- teleporters
	if SDK.bGetFlag(entityFilter, 4) then
		for _, entity in pairs(entities.FindByClass("CObjectTeleporter")) do
			if self:IsValidEntity(entity) then
				targets[#targets+1] = entity
			end
		end
	end

	return targets
end

return lib