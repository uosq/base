--[[local entitylib = require("SDK.entity")
local weaponlib = require("SDK.weapons")]]

local hitscan = require("Features.Aimbot.Hitscan.hitscan")

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

	local weapon = weaponWrapper.Get(plocal:GetPropEntity("m_hActiveWeapon"))
	if weapon:CanShoot() == false then
		return
	end
	--[[local weapon = entitylib.GetWeapon(plocal)
	if weapon == nil then
		return
	end

	if weaponlib.HasPrimaryAmmoForShot(plocal, weapon) == false then
		return
	end]]

	if weapon:GetWeaponProjectileType() == E_ProjectileType.TF_PROJECTILE_BULLET then
		hitscan.Run(cmd, plocal, data)
	end
end

return lib