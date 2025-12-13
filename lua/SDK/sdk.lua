local playerWrap = require("SDK.wrappers.player")
local weaponWrap = require("SDK.wrappers.weapon")
local basePlayerWrap = require("SDK.wrappers.baseplayer")

local inputlib = require("SDK.input")
local mathlib = require("SDK.math")

local angleManager = require("SDK.angleMgr")

local EAmmoType = require("SDK.ammotype")

local sdk = {}

---@param entity Entity
---@return Player
function sdk.AsPlayer(entity)
	return playerWrap.Get(entity)
end

---@param entity Entity
---@return BasePlayer
function sdk.AsBasePlayer(entity)
	return basePlayerWrap.Get(entity)
end

---@param entity Entity
---@return Weapon
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

return sdk