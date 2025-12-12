local aimbot = require("Features.Aimbot.aimbot")
local settings = require("Settings.settings")
--local hookManager = require("SDK.hookMgr")

---@param cmd UserCmd
local function OnCreateMove(cmd)
	if settings.GetStatus() == false then
		return
	end

	local data = settings.Get()
	aimbot.Run(cmd, data)
end

callbacks.Register("CreateMove", OnCreateMove)
--hookManager.Register("CreateMove", "BaseCM", OnCreateMove)