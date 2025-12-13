local playerWrapper = require("SDK.wrappers.player")

local WEAPON_NOCLIP = -1

---@class Weapon
---@field private __handle Entity
---@field private __index Weapon
local Weapon = {}
Weapon.__index = Weapon

---@param entity Entity
---@return Weapon
function Weapon.Get(entity)
	local this = {__handle = entity}
	setmetatable(this, Weapon)
	return this
end

function Weapon:m_hOwner()
	return self.__handle:GetPropEntity("m_hOwner")
end

function Weapon:m_iClip1()
	return self.__handle:GetPropInt("LocalWeaponData", "m_iClip1")
end

function Weapon:m_iClip2()
	return self.__handle:GetPropInt("LocalWeaponData", "m_iClip2")
end

function Weapon:m_iPrimaryAmmoType()
	return self.__handle:GetPropInt("LocalWeaponData", "m_iPrimaryAmmoType")
end

function Weapon:m_iSecondaryAmmoType()
	return self.__handle:GetPropInt("LocalWeaponData", "m_iSecondaryAmmoType")
end

function Weapon:m_flNextPrimaryAttack()
	return self.__handle:GetPropFloat("LocalActiveWeaponData", "m_flNextPrimaryAttack")
end

function Weapon:m_flNextSecondaryAttack()
	return self.__handle:GetPropFloat("LocalActiveWeaponData", "m_flNextSecondaryAttack")
end

function Weapon:m_flLastFireTime()
	return self.__handle:GetPropFloat("LocalActiveTFWeaponData", "m_flLastFireTime")
end

function Weapon:GetAmmoPerShot()
	local ammoPerShot = self.__handle:AttributeHookInt("mod_ammo_per_shot", 0)
	return ammoPerShot > 0 and ammoPerShot or self.__handle:GetWeaponData().ammoPerShot
end

function Weapon:HasPrimaryAmmoForShot()
	local iClip = self:m_iClip1()
	local owner = playerWrapper.Get(self:m_hOwner())
	return (iClip == WEAPON_NOCLIP and owner:GetAmmoCount(self:m_iPrimaryAmmoType()) or iClip) >= self:GetAmmoPerShot()
end

function Weapon:CanPrimaryAttack()
	local owner = self:m_hOwner()
	local player = playerWrapper.Get(owner)

	local curtime = player:m_nTickBase() * globals.TickInterval()
	return self:m_flNextPrimaryAttack() <= curtime and player:m_flNextAttack() <= curtime
end

function Weapon:CanSecondaryAttack()
	local owner = self:m_hOwner()
	local player = playerWrapper.Get(owner)
	local curtime = player:m_nTickBase() * globals.TickInterval()
	return self:m_flNextSecondaryAttack() <= curtime and player:m_flNextAttack() <= curtime
end

function Weapon:IsMeleeWeapon()
	return self.__handle:IsMeleeWeapon()
end

function Weapon:GetWeaponData()
	return self.__handle:GetWeaponData()
end

function Weapon:GetWeaponProjectileType()
	return self.__handle:GetWeaponProjectileType()
end

---@param cmd UserCmd
function Weapon:CanShootPrimary(cmd)
	if cmd.weaponselect ~= 0 then
		return false
	end

	if self:HasPrimaryAmmoForShot() == false then
		return false
	end

	if self.__handle:IsMeleeWeapon() then
		return self:m_flNextPrimaryAttack() + self:GetWeaponData().smackDelay <= globals.CurTime()
	end

	return self:CanPrimaryAttack()
end

---@param cmd UserCmd
function Weapon:CanShootSecondary(cmd)
	if cmd.weaponselect ~= 0 then
		return false
	end

	if self:HasPrimaryAmmoForShot() == false then
		return false
	end

	return self:CanSecondaryAttack()
end

function Weapon:m_iItemDefinitionIndex()
	return self.__handle:GetPropInt("m_Item", "m_iItemDefinitionIndex")
end

function Weapon:GetCurrentCharge()
	return self.__handle:CanCharge() and self.__handle:GetCurrentCharge() or 0
end

function Weapon:GetHandle()
	return self.__handle
end

return Weapon