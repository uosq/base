local playerWrapper = require("SDK.wrappers.player")
local BaseClass = require("SDK.wrappers.basewrapper")

local WEAPON_NOCLIP = -1
local SYDNEY_SLEEPER = 230

---@class Weapon: BaseWrapper
---@field protected __handle Entity
local Weapon = {}
Weapon.__index = Weapon
setmetatable(Weapon, {__index = BaseClass})

---@param entity Entity?
---@return Weapon?
function Weapon.Get(entity)
	if entity == nil then
		return nil
	end

	return setmetatable({__handle = entity}, Weapon)
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
	if owner == nil then
		return false
	end

	return (iClip == WEAPON_NOCLIP and owner:GetAmmoCount(self:m_iPrimaryAmmoType()) or iClip) >= self:GetAmmoPerShot()
end

function Weapon:CanPrimaryAttack()
	local owner = self:m_hOwner()
	local player = playerWrapper.Get(owner)
	if player == nil then
		return false
	end

	local curtime = player:m_nTickBase() * globals.TickInterval()
	return self:m_flNextPrimaryAttack() <= curtime and player:m_flNextAttack() <= curtime
end

function Weapon:CanSecondaryAttack()
	local owner = playerWrapper.Get(self:m_hOwner())
	if owner == nil then
		return false
	end

	local curtime = owner:m_nTickBase() * globals.TickInterval()
	return self:m_flNextSecondaryAttack() <= curtime and owner:m_flNextAttack() <= curtime
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

---@return number
function Weapon:GetCurrentCharge()
	--- WARNING: CanCharge() will crash your game with a Rocket Launcher!
	--- I have to find another way
	--- This doesn't work right with Loose Cannon
	if self.__handle:CanCharge() then
		local maxtime = self.__handle:GetChargeMaxTime()
		local begintime = self.__handle:GetChargeBeginTime()
		local diff = globals.CurTime() - begintime
		if diff > maxtime then
			return 0
		end

		return diff/maxtime
	end

	return 0
end

function Weapon:GetHandle()
	return self.__handle
end

function Weapon:GetWeaponID()
	return self.__handle:GetWeaponID()
end

function Weapon:GetSlot()
	return self.__handle:GetLoadoutSlot()
end

function Weapon:m_iReloadMode()
	return self.__handle:GetPropInt("m_iReloadMode")
end

---@param attrib string
---@param defaultValue number? # optional (default = `1.0`)
---@return number
function Weapon:AttributeHookFloat(attrib, defaultValue)
	return self.__handle:AttributeHookFloat(attrib, defaultValue)
end

---@param attrib string
---@param defaultValue number? # optional (default = `1.0`)
function Weapon:AttributeHookInt(attrib, defaultValue)
	return self.__handle:AttributeHookInt(attrib, defaultValue)
end

function Weapon:m_flChargedDamage()
	if self.__handle:GetWeaponID() == E_WeaponBaseID.TF_WEAPON_SNIPERRIFLE
	or self.__handle:GetWeaponID() == E_WeaponBaseID.TF_WEAPON_SNIPERRIFLE_CLASSIC then
		return self.__handle:GetPropFloat("SniperRifleLocalData", "m_flChargedDamage")
	end

	return 0
end

function Weapon:m_iWeaponState()
	if self.__handle:GetWeaponID() == TF_WEAPON_MINIGUN then
		return self.__handle:GetPropInt("m_iWeaponState")
	end

	return 0
end

function Weapon:get_weapon_mode_float()
	return self.__handle:AttributeHookFloat("set_weapon_mode", 0)
end

function Weapon:get_weapon_mode_int()
	return self.__handle:AttributeHookInt("set_weapon_mode", 0)
end

function Weapon:IsAmbassador()
	return self:GetWeaponID() == TF_WEAPON_REVOLVER and self:get_weapon_mode_float() == 1.0
end

function Weapon:CanAmbassadorHeadshot()
	if self:IsAmbassador() then
		return (globals.CurTime() - self:m_flLastFireTime()) > 1.0
	end

	return false
end

function Weapon:IsHitscan()
	return self:GetWeaponProjectileType() == E_ProjectileType.TF_PROJECTILE_BULLET
end

function Weapon:IsProjectileWeapon()
	return self:IsHitscan() == false and self:IsMeleeWeapon() == false
end

---@param player Player
---@param offset Vector3
---@param hitTeammates boolean
---@return Vector3 vecSrc, Vector3 angForward
function Weapon:GetProjectileFireSetup(player, offset, hitTeammates)
	return self.__handle:GetProjectileFireSetup(player:GetHandle(), offset, hitTeammates, 2048)
end

---@param player Player
function Weapon:CanHit(player)
	local m_hOwner = self:m_hOwner()
	if m_hOwner == nil then
		return false
	end

	if m_hOwner:GetTeamNumber() == player:GetTeamNumber() then
		local weaponID = self:GetWeaponID()
		if weaponID == TF_WEAPON_MEDIGUN then
			return true
		end

		if weaponID == TF_WEAPON_LUNCHBOX then
			return true
		end

		if self:m_iItemDefinitionIndex() == SYDNEY_SLEEPER and player:InCond(TFCond_OnFire) then
			return true
		end

		return false
	end

	return player:InCond(TFCond_Ubercharged) == false
end

return Weapon