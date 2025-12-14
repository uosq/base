local playerWrap = require("SDK.wrappers.player")
local weaponWrap = require("SDK.wrappers.weapon")
local basePlayerWrap = require("SDK.wrappers.baseplayer")

local inputlib = require("SDK.input")
local mathlib = require("SDK.math")

local angleManager = require("SDK.angleMgr")

local EAmmoType = require("SDK.ammotype")
local EMinigunState = require("SDK.minigunstate")

local TF_PARTICLE_MAX_CHARGE_TIME = 2.0

local iThrowTick = -5
local iLastTickBase = 0
local Throwing = false
local bFiring, bLoading = false, false

local sdk = {}

---@param entity Entity?
---@return Player?
function sdk.AsPlayer(entity)
	return playerWrap.Get(entity)
end

---@param entity Entity?
---@return BasePlayer?
function sdk.AsBasePlayer(entity)
	return basePlayerWrap.Get(entity)
end

---@param entity Entity?
---@return Weapon?
function sdk.AsWeapon(entity)
	return weaponWrap.Get(entity)
end

function sdk.GetInputLib()
	return inputlib
end

function sdk.GetMathLib()
	return mathlib
end

function sdk.GetAngleManager()
	return angleManager
end

function sdk.GetAmmoTypeEnum()
	return EAmmoType
end

function sdk.UnloadScript()
	UnloadScript(GetScriptName())
end

--- Source: https://github.com/rei-2/Amalgam/blob/398e61d0948c1a49477caf806a3995ab12efbeff/Amalgam/src/SDK/SDK.cpp#L531
--- Man this was an absolute nightmare to convert to Lua
--- Holy shit
--- Why we dont have a function for this natively??
---@param plocal Player
---@param weapon Weapon
---@param cmd UserCmd
---@return boolean
function sdk.IsAttacking(plocal, weapon, cmd)
	if not plocal or cmd.weaponselect ~= 0 then
		return false
	end

	local useTickBase = engine.GetServerIP() ~= "loopback"
	local iTickBase = useTickBase and cmd.tick_count or plocal:m_nTickBase()

	if weapon:GetSlot() == E_LoadoutSlot.LOADOUT_POSITION_MELEE then
		local weaponID = weapon:GetWeaponID()
		if weaponID == TF_WEAPON_KNIFE then
			return weapon:CanPrimaryAttack() and (cmd.buttons & IN_ATTACK) ~= 0

		elseif weaponID == TF_WEAPON_BAT_WOOD
		or weaponID == E_WeaponBaseID.TF_WEAPON_BAT_GIFTWRAP then
			if (iTickBase ~= iLastTickBase) then
				iThrowTick = math.max(iThrowTick - 1, -5)
			end
			iLastTickBase = iTickBase

			if weapon:CanPrimaryAttack() and weapon:HasPrimaryAmmoForShot() and cmd.buttons & IN_ATTACK2 ~= 0 and iThrowTick == -5 then
				iThrowTick = 12
			end

			if iThrowTick > -5 then
				Throwing = true
			end

			if iThrowTick > 1 then
				Throwing = true
			end

			if iThrowTick == 1 then
				return true
			end
		end

		--- no m_flSmackTime netvar so we're fucked here
		return weapon:CanPrimaryAttack()
	end

	local weaponID = weapon:GetWeaponID()
	if weaponID == TF_WEAPON_COMPOUND_BOW then
		return cmd.buttons & IN_ATTACK == 0 and weapon:GetCurrentCharge() > 0.0
	end

	if weaponID == TF_WEAPON_PIPEBOMBLAUNCHER
	or weaponID == TF_WEAPON_STICKY_BALL_LAUNCHER
	or weaponID == TF_WEAPON_GRENADE_STICKY_BALL then
		local charge = weapon:GetCurrentCharge()
		local amount = mathlib.RemapVal(charge, 0, weapon:AttributeHookFloat("stickybomb_charge_rate", 4.0), 0, 1, true)
		return (cmd.buttons & IN_ATTACK == 0 and amount > 0) or amount == 1
	end

	if weaponID == TF_WEAPON_CANNON then
		local mortar = weapon:AttributeHookFloat("grenade_launcher_mortar_mode", 0)
		if mortar ~= 0 then
			return (weapon:CanPrimaryAttack() and cmd.buttons & IN_ATTACK ~= 0)
		end

		local charge = weapon:GetCurrentCharge()
		local amount = mathlib.RemapVal(charge, 0, mortar, 0, 1, true)
		return (cmd.buttons & IN_ATTACK == 0 and amount > 0) or amount == 1
	end

	if weaponID == TF_WEAPON_SNIPERRIFLE_CLASSIC then
		return cmd.buttons & IN_ATTACK == 0 and weapon:m_flChargedDamage() > 0
	end

	if weaponID == TF_WEAPON_PARTICLE_CANNON then
		local charge = weapon:GetCurrentCharge()
		return charge >= TF_PARTICLE_MAX_CHARGE_TIME
	end

	if weaponID == TF_WEAPON_CLEAVER
	or weaponID == TF_WEAPON_JAR
	or weaponID == TF_WEAPON_JAR_MILK
	or weaponID == TF_WEAPON_JAR_GAS then
		if iTickBase ~= iLastTickBase then
			iThrowTick = math.max(iThrowTick - 1, -5)
		end
		iLastTickBase = iTickBase

		local iAttack = weaponID == E_WeaponBaseID.TF_WEAPON_CLEAVER and IN_ATTACK | IN_ATTACK2 or IN_ATTACK
		if weapon:CanPrimaryAttack() and weapon:HasPrimaryAmmoForShot() and cmd.buttons & IN_ATTACK ~= 0 and iAttack ~= 0 and iThrowTick == -5 then
			iThrowTick = 12
		end
		if iThrowTick > -5 then
			Throwing = true
		end
		if iThrowTick > 1 then
			iThrowTick = 2
		end
		return iThrowTick == 1
	end

	if weaponID == TF_WEAPON_MINIGUN then
		local state = weapon:m_iWeaponState()
		if state == EMinigunState.AC_STATE_FIRING
		or state == EMinigunState.AC_STATE_SPINNING then
			if weapon:HasPrimaryAmmoForShot() then
				return (weapon:CanPrimaryAttack() and cmd.buttons & IN_ATTACK ~= 0)
			end
		end

		--- on Amalgam this returns false, but if I do it then it breaks minigun
		return not (weapon:HasPrimaryAmmoForShot() and cmd.buttons & IN_ATTACK ~= 0)
	end

	if weaponID == TF_WEAPON_LUNCHBOX then
		if weapon:CanSecondaryAttack() and weapon:HasPrimaryAmmoForShot() and cmd.buttons & IN_ATTACK2 ~= 0 then
			return true
		end

		return false
	end

	if weaponID == TF_WEAPON_FLAMETHROWER then
		if weapon:AttributeHookInt("set_charged_airblast", 0) == 0 and weapon:CanSecondaryAttack() and cmd.buttons & IN_ATTACK2 ~= 0 then
			return true
		end
	end

	if weaponID == TF_WEAPON_FLAME_BALL then
		if weapon:AttributeHookInt("set_charged_airblast", 0) ~= 0 then
			return false
		elseif weapon:CanSecondaryAttack() and cmd.buttons & IN_ATTACK2 ~= 0 then
			return true
		end
	end

	--- Beggar's Bazooka
	if weapon:m_iItemDefinitionIndex() == 730 then
		local bAmmo = weapon:HasPrimaryAmmoForShot()
		if bAmmo == 0 then
			bLoading = false
			bFiring = false
		elseif not bFiring then
			bLoading = true
		end

		if ((bFiring or (bLoading and (cmd.buttons & IN_ATTACK == 0))) and bAmmo ~= 0) then
			bFiring = true
			bLoading = false
			return weapon:CanPrimaryAttack()
		end

		return false
	end

--- wtf does this 2 mean?
--- return G::CanPrimaryAttack && pCmd->buttons & IN_ATTACK ? 1 : G::Reloading && pCmd->buttons & IN_ATTACK ? 2 : 0;
	return (weapon:CanShootPrimary(cmd) and cmd.buttons & IN_ATTACK ~= 0)
end

return sdk