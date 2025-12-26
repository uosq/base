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
	path = {},
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

function lib.ResetState()
	state.target = nil
end

---@param data Settings
---@param cmd UserCmd
function lib.Run(cmd, data)
	lib.ResetState()

	if data.aimbot.enabled == false then
		return
	end

	if engine.IsChatOpen() or engine.Con_IsVisible() or engine.IsGameUIVisible() then
		return
	end

	local plocal = SDK.Reinterpret(entities.GetLocalPlayer(), SDK.GetPlayerClass())
	if plocal == nil then
		return
	end

	if plocal:InCond(E_TFCOND.TFCond_Taunting) then
		return
	end

	if plocal:InCond(E_TFCOND.TFCond_HalloweenGhostMode) then
		return
	end

	local weapon = SDK.Reinterpret(plocal:m_hActiveWeapon(), SDK.GetWeaponClass())
	if weapon == nil then
		return
	end

	previousAimFov = currentAimFov

	if weapon:GetProjectileType() == E_ProjectileType.TF_PROJECTILE_BULLET then
		currentAimFov = mathlib.Lerp(previousAimFov, SDK.GetSettingsManager().Get().aimbot.hitscan.fov, 0.2)
		hitscan.Run(cmd, plocal, weapon, data, state)
	elseif weapon:IsMelee() == false then
		currentAimFov = mathlib.Lerp(previousAimFov, SDK.GetSettingsManager().Get().aimbot.proj.fov, 0.2)
		projectile.Run(cmd, plocal, weapon, data, state)
	else
		currentAimFov = mathlib.Lerp(previousAimFov, 0, 0.2)
	end

	SDK.SetAimTarget(state.target)
end

---@param plocal Player
---@param settings Settings
local function DrawFovIndicator(plocal, settings)
	if settings.aimbot.enabled == false or settings.aimbot.fovindicator == false then
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

local function DrawPath()
	if type(state.path) ~= "table" then
		return false
	end

	if #state.path < 2 then
		return false
	end

	local path = state.path

	draw.Color(255, 255, 255, 255)

	local prev = client.WorldToScreen(path[1])
	for i = 2, #path do
		local cur = client.WorldToScreen(path[i])
		if prev and cur then
			draw.Line(prev[1], prev[2], cur[1], cur[2])
			prev = cur
		end
	end

	return true
end

function lib.Draw()
	local settings = SDK.GetSettingsManager().Get()

	if settings.aimbot.enabled == false then
		return
	end

	local plocal = SDK.Reinterpret(entities.GetLocalPlayer(), SDK.GetPlayerClass())
	if plocal == nil then
		return
	end

	DrawPath()
	DrawFovIndicator(plocal, settings)
end

return lib