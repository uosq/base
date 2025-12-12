--local settings = require("Settings.settings")
--local hookManager = require("SDK.hookMgr")

local function OnDraw()
	--print("Draw")
end

callbacks.Register("Draw", OnDraw)
--hookManager.Register("Draw", "BaseDraw", OnDraw)