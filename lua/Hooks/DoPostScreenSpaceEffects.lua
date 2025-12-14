local glow = require("Features.Glow.glow")
local settingsManager = require("Settings.settings")

local function DoPostScreenSpaceEffects()
	if clientstate.GetClientSignonState() <= E_SignonState.SIGNONSTATE_SPAWN then
		return
	end

	if settingsManager.GetStatus() == false then
		return
	end

	local settings = settingsManager.Get()

	glow.Run(settings)
end

callbacks.Register("DoPostScreenSpaceEffects", DoPostScreenSpaceEffects)