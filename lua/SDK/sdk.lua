local playerWrap = require("SDK.wrappers.player")
local weaponWrap = require("SDK.wrappers.weapon")

local inputlib = require("SDK.input")
local mathlib = require("SDK.math")
local chokedlib = require("SDK.chokedcmds")

local angleManager = require("SDK.angleMgr")
local settingsManager = require("Settings.settings")
local cvarManager = require("SDK.cvarManager")
local colorManager = require("SDK.colors")

local EAmmoType = require("SDK.ammotype")
local EMinigunState = require("SDK.minigunstate")
local EBoneIndex = require("SDK.boneindexes")

local playerSimulation = require("SDK.prediction.playersim")

local TF_PARTICLE_MAX_CHARGE_TIME = 2.0

local iThrowTick = -5
local iLastTickBase = 0
local Throwing = false
local bFiring, bLoading = false, false
local aimTarget = nil

local sdk = {}

---@return Entity?
function sdk.GetAimTarget()
	return aimTarget
end

---@param entity Entity?
function sdk.SetAimTarget(entity)
	aimTarget = entity
end

function sdk.GetSettingsManager()
	return settingsManager
end

function sdk.GetPlayerSim()
	return playerSimulation
end

function sdk.GetColorManager()
	return colorManager
end

--[[
---@param entity Entity?
---@return Player?
function sdk.AsPlayer(entity)
	return playerWrap.Get(entity)
end

---@param entity Entity?
---@return BasePlayer?
function sdk.AsBasePlayer(entity)
	return basePlayerWrap.Get(entity)
end]]

--- Function to convert `obj` to `class` (Player, BasePlayer, Weapon, ...) \
--- Can convert a Entity to class \
--- Or you can use a already existing wrapped class (example: Player)
---@generic T
---@param obj Entity|table?
---@param classTable T
---@return T?
function sdk.Reinterpret(obj, classTable)
	if obj == nil or type(classTable) ~= "table" then
		return nil
	end

	if type(obj) == "table" then
		if obj.__handle == nil then
			return nil
		end

		return setmetatable(obj, classTable)
	end

	return setmetatable({__handle = obj}, classTable)
end

function sdk.GetWeaponClass()
	return weaponWrap
end

function sdk.GetPlayerClass()
	return playerWrap
end

---@return Player[]
function sdk.GetPlayerList()
	local baseclass = playerWrap
	local list = {}

	for i = 1, globals.MaxClients() do
		local player = sdk.Reinterpret(entities.GetByIndex(i), baseclass)
		if player then
			list[#list+1] = player
		end
	end

	return list
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

function sdk.GetBoneIndexEnum()
	return EBoneIndex
end

function sdk.UnloadScript()
	UnloadScript(GetScriptName())
end

function sdk.GetChokedLib()
	return chokedlib
end

function sdk.GetConVarManager()
	return cvarManager
end

--- Source: https://github.com/rei-2/Amalgam/blob/398e61d0948c1a49477caf806a3995ab12efbeff/Amalgam/src/SDK/SDK.cpp#L531
--- Man this was an absolute nightmare to convert to Lua
--- Holy shit
--- Why we dont have a function for this natively??
---@param weapon Weapon
---@param cmd UserCmd
---@return boolean
function sdk.IsAttacking(weapon, cmd)
	if not weapon or cmd.weaponselect ~= 0 then
		return false
	end

	local iTickBase = cmd.tick_count

	if weapon:GetSlot() == E_LoadoutSlot.LOADOUT_POSITION_MELEE then
		local weaponID = weapon:GetID()
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

	local weaponID = weapon:GetID()
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
--- we dont have m_bInReload so I can't get the reloading part :p
	return (weapon:CanPrimaryAttack() and cmd.buttons & IN_ATTACK ~= 0)
end

---@param value integer
---@param n integer
---@return boolean
function sdk.bGetFlag(value, n)
	return (value & (1<<n)) ~= 0
end

---@param entity Entity
function sdk.GetColor(entity)
	return colorManager.GetColor(settingsManager.Get(), entity, aimTarget)
end

return sdk