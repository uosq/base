local glow = require("Features.Glow.glow")
local settingsManager = require("Settings.settings")

local function DoPostScreenSpaceEffects()
	if settingsManager.GetStatus() == false then
		return
	end

	local settings = settingsManager.Get()

	glow.Run(settings)
end

callbacks.Register("DoPostScreenSpaceEffects", DoPostScreenSpaceEffects)