--[[local entitylib = require("SDK.entity")
local weaponlib = require("SDK.weapons")]]

local hitscan = require("Features.Aimbot.Hitscan.hitscan")
local projectile = require("Features.Aimbot.Proj.main")

local SDK = require("SDK.sdk")

local lib = {}

---@class AimbotState
local state = {
	target = nil
}

---@return AimbotState
function lib.GetState()
	return state
end

function lib.ResetState()
	state.target = nil
end

---@param data Settings
---@param cmd UserCmd
function lib.Run(cmd, data)
	lib.ResetState()

	if data.aimbot.enabled == false then
		return
	end

	if engine.IsChatOpen() or engine.Con_IsVisible() or engine.IsGameUIVisible() then
		return
	end

	local plocal = SDK.AsPlayer(entities.GetLocalPlayer())
	if plocal == nil then
		return
	end

	if plocal:InCond(E_TFCOND.TFCond_Taunting) then
		return
	end

	if plocal:InCond(E_TFCOND.TFCond_HalloweenGhostMode) then
		return
	end

	local weapon = SDK.AsWeapon(plocal:m_hActiveWeapon())
	if weapon == nil then
		return
	end

	if weapon:GetWeaponProjectileType() == E_ProjectileType.TF_PROJECTILE_BULLET then
		hitscan.Run(cmd, plocal, weapon, data, state)
	elseif weapon:IsMeleeWeapon() == false then
		projectile.Run(cmd, plocal, weapon, data, state)
	end
end

function lib.Store()
	projectile.Store()
end

return lib