local chams = require("Features.Visuals.Chams.chams")
local SDK = require("SDK.sdk")
local settingsManager = SDK.GetSettingsManager()

local function DrawModel(ctx)
	if settingsManager.GetStatus() == false then
		return
	end

	local settings = settingsManager.Get()
	if settings.visuals.chams.enabled then
		chams.DrawModel(ctx)
	end
end

callbacks.Register("DrawModel", DrawModel)