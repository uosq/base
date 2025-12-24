local mathlib = require("SDK.math")
local playerWrapper = require("SDK.wrappers.player")
local BaseClass = require("SDK.wrappers.basewrapper")

local WEAPON_NOCLIP = -1
local SYDNEY_SLEEPER = 230

---@class Weapon: BaseWrapper
---@field protected __handle Entity
local Weapon = {}
Weapon.__index = Weapon
setmetatable(Weapon, {__index = BaseClass})

---@class ProjectileInfo
local ProjectileInfo_t = {
	speed = 0.0,
	gravity = 0.0,
	primetime = 0.0,
	damage_radius = 0.0,
	offset = Vector3(),
	simple_trace = false,
	lifetime = 60,
	hull = Vector3(6, 6, 6),
}
ProjectileInfo_t.__index = ProjectileInfo_t

---@param offset Vector3?
---@param speed number?
---@param gravity number?
---@param primetime number?
---@param damage_radius number?
---@param simple_trace boolean
---@param lifetime number?
---@param hull Vector3?
---@return ProjectileInfo
function ProjectileInfo_t.New(offset, speed, gravity, primetime, damage_radius, lifetime, hull, simple_trace)
	local new = setmetatable({}, {__index = ProjectileInfo_t})
	new.speed = speed or 0
	new.gravity = gravity or 0
	new.primetime = primetime or 0
	new.damage_radius = damage_radius or 0
	new.lifetime = lifetime or 60
	new.simple_trace = simple_trace
	new.offset = offset or Vector3()
	new.hull = hull or Vector3(6, 6, 6)
	return new
end

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
			if self:GetWeaponID() == TF_WEAPON_COMPOUND_BOW then
				return 1
			end
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

---@param offset Vector3
---@param angle EulerAngles
---@param allowflip boolean
---@param startPosOut Vector3
---@param startAngleOut Vector3
function Weapon:GetProjectileFireSetup2(offset, angle, allowflip, startPosOut, startAngleOut)
	local m_hOwner = self:m_hOwner()
	local player = playerWrapper.Get(m_hOwner)
	if player == nil then
		return nil
	end

	allowflip = allowflip == nil and true or false

	local cl_flipviewmodels = client.GetConVar("cl_flipviewmodels")
	if allowflip and cl_flipviewmodels == 1 then
		offset.y = offset.y * -1
	end

	local shootPos = player:GetShootPos()

	local forward, right, up = angle:Forward(), angle:Right(), angle:Up()
	do
		local pos = shootPos + (forward * offset.x) + (right * offset.y) + (up * offset.z)
		startPosOut.x, startPosOut.y, startPosOut.z = pos:Unpack()
	end

	local endPos = shootPos + forward * 2048
	local trace = engine.TraceHull(shootPos, endPos, player:GetMins(), player:GetMaxs(), MASK_SOLID, function (ent, contentsMask)
		if ent:GetIndex() == m_hOwner:GetIndex() then
			return false
		end

		return true
	end)

	if trace.fraction > 0.1 then
		endPos = trace.endpos
	end

	--- this is fucking stupid
	--- why vector.AngleVectors wants a EulerAngles?!?!?!
	startAngleOut.x, startAngleOut.y, startAngleOut.z = EulerAngles((endPos - startPosOut):Unpack()):Forward():Unpack()
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

function Weapon:m_flDetonateTime()
	if self.__handle:GetClass() == "CWeaponGrenadeLauncher" then
		return self.__handle:GetPropFloat("m_flDetonateTime")
	end

	return 0
end

--- Source: https://github.com/rei-2/Amalgam/blob/bffae9999cf35a5fbdeb92387b9fae58796b8939/Amalgam/src/Features/Simulation/ProjectileSimulation/ProjectileSimulation.cpp#L6
--- I dont like pasting amalgam just as much as you
--- But I dont have the patience to get all the stats for every weapon
--- Why we dont have a native function for this??

---@return ProjectileInfo?
function Weapon:GetProjectileInfo()
	local m_hOwner = self:m_hOwner()
	local m_bDucking = m_hOwner:GetPropInt("m_fFlags") & FL_DUCKING ~= 0
	local _, gravity = client.GetConVar("sv_gravity")
	gravity = gravity/800

	local id = self:GetWeaponID()
	if id == TF_WEAPON_ROCKETLAUNCHER
	or id == TF_WEAPON_DIRECTHIT then
		local info = ProjectileInfo_t.New(nil, 0, 0, 0, 0, 60, Vector3(6, 6, 6), false)
		info.offset.x = 23.5
		info.offset.y = self:AttributeHookInt("centerfire_projectile", 0) == 1 and 0 or 12
		info.offset.z = m_bDucking and 8 or -3
		info.speed = m_hOwner:InCond(E_TFCOND.TFCond_RunePrecision) and 3000 or self:AttributeHookFloat("mult_projectile_speed", 1100)
		info.hull.x = 0
		info.hull.y = 0
		info.hull.z = 0
		info.gravity = 0
		info.simple_trace = true
		return info
	end

	if id == TF_WEAPON_PARTICLE_CANNON
	or id == TF_WEAPON_RAYGUN
	or id == TF_WEAPON_DRG_POMSON then
		local info = ProjectileInfo_t.New(nil, 0, 0, 0, 0, 60, Vector3(6, 6, 6), false)
		local isCowMangler = id == TF_WEAPON_PARTICLE_CANNON
		info.offset.x = 23.5
		info.offset.y = 8
		info.offset.z = m_bDucking and 8 or -3
		info.speed = isCowMangler and 1100 or 1200
		info.hull = isCowMangler and Vector3() or Vector3(1, 1, 1)
		info.simple_trace = true
		return info
	end

	if id == TF_WEAPON_GRENADELAUNCHER
	or id == TF_WEAPON_CANNON then
		local info = ProjectileInfo_t.New(nil, 0, 0, 0, 0, 60, Vector3(6, 6, 6), false)
		local isCannon = id == TF_WEAPON_CANNON
		local mortar = isCannon and self:AttributeHookFloat("grenade_launcher_mortar_mode", 0) or 0
		info.speed = self:AttributeHookFloat("mult_projectile_range", m_hOwner:InCond(E_TFCOND.TFCond_RunePrecision) and 3000 or self:AttributeHookFloat("mult_projectile_speed", 1200))
		info.lifetime = mortar ~= 0 and self:m_flDetonateTime() > 0 and self:m_flDetonateTime() - globals.CurTime() or mortar or self:AttributeHookFloat("fuse_mult", 2)
		info.gravity = gravity

		return info
	end

	if id == TF_WEAPON_PIPEBOMBLAUNCHER then
		local info = ProjectileInfo_t.New(nil, 0, 0, 0, 0, 60, Vector3(6, 6, 6), false)
		info.offset.x = 16
		info.offset.y = 8
		info.offset.z = -6
		info.gravity = gravity

		local charge = self:GetCurrentCharge()
		info.speed = self:AttributeHookFloat("mult_projectile_range", mathlib.RemapVal(charge, 0, self:AttributeHookFloat("stickybomb_charge_rate", 4.0), 900, 2400, true))

		return info
	end

	if id == TF_WEAPON_FLAREGUN then
		local info = ProjectileInfo_t.New(nil, 0, 0, 0, 0, 60, Vector3(6, 6, 6), false)
		info.offset.x = 23.5
		info.offset.y = 12
		info.offset.z = m_bDucking and 8 or -3
		info.hull.x = 0
		info.hull.y = 0
		info.hull.z = 0
		info.speed = self:AttributeHookFloat("mult_projectile_speed", 2000)
		info.gravity = 0
		info.lifetime = 0.3 * gravity

		return info
	end

	--- TF_WEAPON_FLAREGUN_RENVEGE
	if id == TF_WEAPON_RAYGUN_REVENGE then
		local info = ProjectileInfo_t.New(nil, 0, 0, 0, 0, 60, Vector3(6, 6, 6), false)
		info.offset.x = 23.5
		info.offset.y = 12
		info.offset.z = m_bDucking and 8 or -3
		info.hull.x = 0
		info.hull.y = 0
		info.hull.z = 0
		info.speed = 3000

		return info
	end

	if id == TF_WEAPON_COMPOUND_BOW then
		local info = ProjectileInfo_t.New(nil, 0, 0, 0, 0, 60, Vector3(6, 6, 6), false)
		info.offset.x = 23.5
		info.offset.y = 12
		info.offset.z = -3
		info.hull.x = 1
		info.hull.y = 1
		info.hull.z = 1

		local charge = self:GetCurrentCharge()
		info.speed = mathlib.RemapVal(charge, 0, 1, 1800, 2600)
		info.gravity = mathlib.RemapVal(charge, 0, 1, 0.5, 0.1) * gravity
		info.lifetime = 10

		return info
	end

	if id == TF_WEAPON_CROSSBOW
	or id == TF_WEAPON_SHOTGUN_BUILDING_RESCUE then
		local info = ProjectileInfo_t.New(nil, 0, 0, 0, 0, 60, Vector3(6, 6, 6), false)
		local isCrossbow = id == E_WeaponBaseID.TF_WEAPON_CROSSBOW
		info.offset.x = 23.5
		info.offset.y = 12
		info.offset.z = -3
		info.hull.x = isCrossbow and 3 or 1
		info.hull.y = isCrossbow and 3 or 1
		info.hull.z = isCrossbow and 3 or 1
		info.speed = 2400
		info.gravity = gravity * 0.2
		info.lifetime = 10

		return info
	end

	if id == TF_WEAPON_SYRINGEGUN_MEDIC then
		local info = ProjectileInfo_t.New(nil, 0, 0, 0, 0, 60, Vector3(6, 6, 6), false)
		info.offset.x = 16
		info.offset.y = 6
		info.offset.z = -8
		info.hull.x = 1
		info.hull.y = 1
		info.hull.z = 1
		info.speed = 1000
		info.gravity = 0.3 * gravity

		return info
	end

	if id == TF_WEAPON_FLAMETHROWER then
		local info = ProjectileInfo_t.New(nil, 0, 0, 0, 0, 60, Vector3(6, 6, 6), false)
		local _, flhull = client.GetConVar("tf_flamethrower_boxsize")
		info.offset.x = 40
		info.offset.y = 5
		info.offset.z = 0
		info.hull.x = flhull
		info.hull.y = flhull
		info.hull.z = flhull
		info.speed = 1000
		info.lifetime = 0.285

		return info
	end

	if id == TF_WEAPON_FLAME_BALL then
		local info = ProjectileInfo_t.New(nil, 0, 0, 0, 0, 60, Vector3(6, 6, 6), false)
		info.offset.x = 3
		info.offset.y = 7
		info.offset.z = -9
		info.hull.x = 1
		info.hull.y = 1
		info.hull.z = 1
		info.speed = 3000
		info.lifetime = 0.18
		info.gravity = 0

		return info
	end

	if id == TF_WEAPON_CLEAVER then
		local info = ProjectileInfo_t.New(nil, 0, 0, 0, 0, 60, Vector3(6, 6, 6), false)
		info.offset.x = 16
		info.offset.y = 8
		info.offset.z = -6
		info.hull.x = 1
		info.hull.y = 1
		info.hull.z = 10
		info.speed = 3000
		info.gravity = 1
		info.lifetime = 2.2

		return info
	end

	if id == TF_WEAPON_BAT_WOOD
	or id == TF_WEAPON_BAT_GIFTWRAP then
		local info = ProjectileInfo_t.New(nil, 0, 0, 0, 0, 60, Vector3(6, 6, 6), false)
		local _, tf_scout_stunball_base_speed = client.GetConVar("tf_scout_stunball_base_speed")
		info.speed = tf_scout_stunball_base_speed
		info.gravity = 1
		info.simple_trace = false
		info.lifetime = gravity

		return info
	end

	if id == TF_WEAPON_JAR
	or id == TF_WEAPON_JAR_MILK then
		local info = ProjectileInfo_t.New(nil, 0, 0, 0, 0, 60, Vector3(6, 6, 6), false)
		info.offset.x = 16
		info.offset.y = 8
		info.offset.z = -6
		info.speed = 1000
		info.gravity = 1
		info.lifetime = 2.2
		info.hull.x = 3
		info.hull.y = 3
		info.hull.z = 3
		info.simple_trace = false
		return info
	end

	if id == TF_WEAPON_JAR_GAS then
		local info = ProjectileInfo_t.New(nil, 0, 0, 0, 0, 60, Vector3(6, 6, 6), false)
		info.offset.x = 16
		info.offset.y = 8
		info.offset.z = -6
		info.speed = 2000
		info.gravity = 1
		info.lifetime = 2.2
		info.hull.x = 3
		info.hull.y = 3
		info.hull.z = 3
		info.simple_trace = false
		return info
	end

	if id == TF_WEAPON_LUNCHBOX then
		local info = ProjectileInfo_t.New(nil, 0, 0, 0, 0, 60, Vector3(6, 6, 6), false)
		info.offset.z = -8
		info.hull.x = 17
		info.hull.y = 17
		info.hull.z = 7
		info.speed = 500
		info.gravity = 1 * gravity
		info.simple_trace = false
	end

	return nil
end

return Weapon