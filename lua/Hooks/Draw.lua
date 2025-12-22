--local settings = require("Settings.settings")
--local hookManager = require("SDK.hookMgr")

local Aimbot = require("Features.Aimbot.aimbot")
local ESP = require("Features.Visuals.ESP.esp")

local SDK = require("SDK.sdk")
local settingsManager = SDK.GetSettingsManager()

local function OnDraw()
	if clientstate.GetClientSignonState() <= E_SignonState.SIGNONSTATE_SPAWN then
		return
	end

	if engine.IsChatOpen() or engine.Con_IsVisible() or engine.IsGameUIVisible() then
		return
	end

	if engine.IsTakingScreenshot() then
		return
	end

	if settingsManager.GetStatus() == false then
		return
	end

	local settings = settingsManager.Get()

	ESP.Run(settings)
	Aimbot.Draw()
end

callbacks.Register("Draw", OnDraw)
--hookManager.Register("Draw", "BaseDraw", OnDraw)