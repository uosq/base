local entitylib = require("SDK.entity")

local hitscan = require("Features.Aimbot.Hitscan.hitscan")

local lib = {}

---@param data Settings
function lib.Run(cmd, data)
	if data.aimbot.enabled == false then
		return
	end

	local plocal = entities.GetLocalPlayer()
	if plocal == nil then
		return
	end

	local weapon = entitylib.GetWeapon(plocal)
	if weapon == nil then
		return
	end

	if weapon:GetWeaponProjectileType() == E_ProjectileType.TF_PROJECTILE_BULLET then
		hitscan.Run(cmd, plocal, data)
	end
end

return lib