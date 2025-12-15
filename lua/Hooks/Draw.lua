--local settings = require("Settings.settings")
--local hookManager = require("SDK.hookMgr")

local function OnDraw()
	if clientstate.GetClientSignonState() <= E_SignonState.SIGNONSTATE_SPAWN then
		return
	end
end

callbacks.Register("Draw", OnDraw)
--hookManager.Register("Draw", "BaseDraw", OnDraw)