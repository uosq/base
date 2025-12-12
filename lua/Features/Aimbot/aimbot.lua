--[[local entitylib = require("SDK.entity")
local weaponlib = require("SDK.weapons")]]

local hitscan = require("Features.Aimbot.Hitscan.hitscan")
local projectile = require("Features.Aimbot.Proj.main")

local weaponWrapper = require("SDK.wrappers.weapon")

local lib = {}

---@param data Settings
---@param cmd UserCmd
function lib.Run(cmd, data)
	if data.aimbot.enabled == false then
		return
	end

	local plocal = entities.GetLocalPlayer()
	if plocal == nil then
		return
	end

	local m_hActiveWeapon = plocal:GetPropEntity("m_hActiveWeapon")
	if m_hActiveWeapon == nil then
		return
	end

	local weapon = weaponWrapper.Get(m_hActiveWeapon)

	if weapon:GetWeaponProjectileType() == E_ProjectileType.TF_PROJECTILE_BULLET then
		hitscan.Run(cmd, plocal, weapon, data)
	elseif weapon:IsMeleeWeapon() == false then
		projectile.Run(cmd, plocal, weapon, data)
	end
end

return lib