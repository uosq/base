local lib = {}

local old_weapon, lastFire, nextPrimaryAttack, nextAttack = nil, 0, 0, 0

local WEAPON_NOCLIP = -1
local entitylib = require("SDK.entity")

local function GetLastFireTime(weapon)
	return weapon:GetPropFloat("LocalActiveTFWeaponData", "m_flLastFireTime")
end

local function GetNextPrimaryAttack(weapon)
	return weapon:GetPropFloat("LocalActiveWeaponData", "m_flNextPrimaryAttack")
end

local function GetNextAttack(player)
	return player:GetPropFloat("bcc_localdata", "m_flNextAttack")
end

local function GetNextSecondaryAttack(weapon)
	return weapon:GetPropFloat("LocalActiveWeaponData", "m_flNextSecondaryAttack")
end

--- http :---www.unknowncheats.me/forum/team-fortress-2-a/273821-canshoot-function.html
function lib.CanShoot()
	local player = entities:GetLocalPlayer()
	if not player then
		return false
	end

	local weapon = player:GetPropEntity("m_hActiveWeapon")
	if not weapon or not weapon:IsValid() then
		return false
	end

	if weapon:GetPropInt("LocalWeaponData", "m_iClip1") == 0 then
		return false
	end

	if weapon:IsMeleeWeapon() then
		return GetNextPrimaryAttack(weapon) <= globals.CurTime() + weapon:GetWeaponData().smackDelay
	end

	local lastfiretime = GetLastFireTime(weapon)

	local tickBase = player:GetPropInt("m_nTickBase") * globals.TickInterval()

	if lastFire ~= lastfiretime or weapon ~= old_weapon then
		lastFire = lastfiretime
		nextPrimaryAttack = GetNextPrimaryAttack(weapon)
		nextAttack = GetNextAttack(player)
	end

	old_weapon = weapon
	return nextPrimaryAttack <= tickBase and nextAttack <= tickBase
end

---@param weapon Entity
function lib.m_iPrimaryAmmoType(weapon)
	return weapon:GetPropInt("LocalWeaponData", "m_iPrimaryAmmoType")
end

---@param weapon Entity
function lib.m_iSecondaryAmmoType(weapon)
	return weapon:GetPropInt("LocalWeaponData", "m_iSecondaryAmmoType")
end

---@param weapon Entity
function lib.m_iClip1(weapon)
	return weapon:GetPropInt("LocalWeaponData", "m_iClip1")
end

---@param weapon Entity
function lib.GetAmmoPerShot(weapon)
	local ammoPerShot = weapon:AttributeHookInt("mod_ammo_per_shot", 0)
	return ammoPerShot > 0 and ammoPerShot or weapon:GetWeaponData().ammoPerShot
end

---@param entity Entity
---@param weapon Entity
function lib.HasPrimaryAmmoForShot(entity, weapon)
	local iClip = lib.m_iClip1(weapon)
	return (iClip == WEAPON_NOCLIP and entitylib.GetAmmoCount(entity, lib.m_iPrimaryAmmoType(weapon)) or iClip) >= lib.GetAmmoPerShot(weapon)
end

---@param weapon Entity
function lib.CanPrimaryAttacK(weapon)
	local owner = weapon:GetPropEntity("m_hOwner")
	if owner == nil then
		return false
	end

	local curtime = owner:GetPropInt("m_nTickBase") * globals.TickInterval()
	return GetNextPrimaryAttack(weapon) <= curtime and GetNextAttack(owner) <= curtime
end

---@param weapon Entity
function lib.CanSecondaryAttack(weapon)
	local owner = weapon:GetPropEntity("m_hOwner")
	if owner == nil then
		return false
	end

	local curtime = owner:GetPropInt("m_nTickBase") * globals.TickInterval()
	return GetNextSecondaryAttack(weapon) <= curtime and GetNextAttack(owner) <= curtime
end

return lib