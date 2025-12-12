---@class Player
---@field private __index Player
---@field private __handle Entity
local Player = {}
Player.__index = Player

---@param entity Entity
---@return Player
function Player.Get(entity)
	local this = {__handle = entity}
	setmetatable(this, Player)
	return this
end

function Player:m_flNextAttack()
	return self.__handle:GetPropFloat("bcc_localdata", "m_flNextAttack")
end

function Player:m_nTickBase()
	return self.__handle:GetPropInt("m_nTickBase")
end

function Player:GetAmmoCount(iAmmoIndex)
	if iAmmoIndex == -1 then
		return 0
	end

	return self.__handle:GetPropDataTableInt("m_iAmmo")[iAmmoIndex]
end

function Player:GetWorldSpaceCenter()
	local mins = self.__handle:GetMins()
	local maxs = self.__handle:GetMaxs()
	local origin = self.__handle:GetAbsOrigin()
	return origin + (mins + maxs) * 0.5
end

function Player:GetEyePos()
	return self.__handle:GetAbsOrigin() + self.__handle:GetPropVector("localdata", "m_vecViewOffset[0]")
end

return Player