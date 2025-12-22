local glow = require("Features.Visuals.Glow.glow")
local chams = require("Features.Visuals.Chams.chams")
local settingsManager = require("Settings.settings")

local function DoPostScreenSpaceEffects()
	if clientstate.GetClientSignonState() <= E_SignonState.SIGNONSTATE_SPAWN then
		return
	end

	if settingsManager.GetStatus() == false then
		return
	end

	local settings = settingsManager.Get()

	if settings.visuals.chams.enabled then
		chams.DoPostScreenSpaceEffects(settings)
	end

	if settings.visuals.glow.enabled then
		glow.Run(settings)
	end
end

callbacks.Register("DoPostScreenSpaceEffects", DoPostScreenSpaceEffects)