--[[local entitylib = require("SDK.entity")
local weaponlib = require("SDK.weapons")]]

local hitscan = require("Features.Aimbot.Hitscan.hitscan")
local projectile = require("Features.Aimbot.Proj.main")

local SDK = require("SDK.sdk")
local mathlib = SDK.GetMathLib()

local lib = {}

---@class AimbotState
local state = {
	target = nil,
}

local currentAimFov = 0
local previousAimFov = 0

function lib.GetAimFOV()
	return currentAimFov
end

---@return AimbotState
function lib.GetState()
	return state
end

function lib.ResetTarget()
	state.target = nil
end

---@param data Settings
---@param cmd UserCmd
function lib.Run(cmd, data)
	lib.ResetTarget()

	if data.aimbot.enabled == false then
		return
	end

	if engine.IsChatOpen() or engine.Con_IsVisible() or engine.IsGameUIVisible() then
		return
	end

	local plocal = SDK.AsPlayer(entities.GetLocalPlayer())
	if plocal == nil then
		return
	end

	if plocal:InCond(E_TFCOND.TFCond_Taunting) then
		return
	end

	if plocal:InCond(E_TFCOND.TFCond_HalloweenGhostMode) then
		return
	end

	local weapon = SDK.AsWeapon(plocal:m_hActiveWeapon())
	if weapon == nil then
		return
	end

	previousAimFov = currentAimFov

	if weapon:GetWeaponProjectileType() == E_ProjectileType.TF_PROJECTILE_BULLET then
		currentAimFov = mathlib.Lerp(previousAimFov, SDK.GetSettingsManager().Get().aimbot.hitscan.fov, 0.2)
		hitscan.Run(cmd, plocal, weapon, data, state)
	elseif weapon:IsMeleeWeapon() == false then
		--currentAimFov = SDK.GetSettingsManager().Get().aimbot.proj.fov
		currentAimFov = mathlib.Lerp(previousAimFov, SDK.GetSettingsManager().Get().aimbot.proj.fov, 0.2)
		projectile.Run(cmd, plocal, weapon, data, state)
	else
		currentAimFov = 0
	end
end

function lib.Draw()
	local plocal = SDK.AsBasePlayer(entities.GetLocalPlayer())
	if plocal == nil then
		return
	end

	local settings = SDK.GetSettingsManager().Get()

	if settings.aimbot.enabled == false then
		return
	end

	if settings.aimbot.fovindicator == false then
		return
	end

	if currentAimFov == 0 or currentAimFov >= 90 then
		return
	end

	local aimFov = math.rad(currentAimFov)
	local camFov = math.rad(plocal:m_iDefaultFOV() / 2) --- m_iDefaultFOV returns current fov

	local w, h = draw.GetScreenSize()
	local radius = math.tan(aimFov)/math.tan(camFov) * w/2 * (3/4)

	draw.Color(255, 255, 255, 255)
	draw.OutlinedCircle(w//2, h//2, radius//1, 32)
end

return lib