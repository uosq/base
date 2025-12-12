local settings = require("Settings.settings")
--local hookManager = require("SDK.hookMgr")

local function OnFrameStageNotify(stage)
	if stage == E_ClientFrameStage.FRAME_START then
		if settings.GetStatus() == false then
			printc(255, 150, 150, 255, "Please unload the script (BASE)")
			--hookManager.UnregisterAll()
			UnloadScript(GetScriptName())
			return
		end

		settings.Store()
	end
end

callbacks.Register("FrameStageNotify", OnFrameStageNotify)
--hookManager.Register("FrameStageNotify", "BaseFSN", OnFrameStageNotify)