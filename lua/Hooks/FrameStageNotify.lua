local settings = require("Settings.settings")
--local hookManager = require("SDK.hookMgr")
local angleManager = require("SDK.angleMgr")

local function OnFrameStageNotify(stage)
	if clientstate.GetClientSignonState() <= E_SignonState.SIGNONSTATE_SPAWN then
		return
	end

	if stage == E_ClientFrameStage.FRAME_START then
		if settings.ShouldUnload() then
			printc(255, 150, 150, 255, "Base - Failed to get settings, unloading...")
			--hookManager.UnregisterAll()
			UnloadScript(GetScriptName())
			return
		end

		settings.Store()

	elseif stage == E_ClientFrameStage.FRAME_RENDER_START then
		local angle = angleManager.GetAngle()
		if angle then
			local plocal = entities.GetLocalPlayer()
			if plocal == nil or plocal:GetPropBool("m_nForceTauntCam") == false then
				return
			end

			plocal:SetVAngles(angle)
		end
	end
end

callbacks.Register("FrameStageNotify", OnFrameStageNotify)
--hookManager.Register("FrameStageNotify", "BaseFSN", OnFrameStageNotify)