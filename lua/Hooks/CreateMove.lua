local aimbot = require("Features.Aimbot.aimbot")
local SDK = require("SDK.sdk")
local settings = SDK.GetSettingsManager()
local angleManager = SDK.GetAngleManager()
local chokedManager = SDK.GetChokedLib()

---@param cmd UserCmd
local function OnCreateMove(cmd)
	if clientstate.GetClientSignonState() <= E_SignonState.SIGNONSTATE_SPAWN then
		return
	end

	if settings.GetStatus() == false then
		return
	end

	local data = settings.Get()

	aimbot.Run(cmd, data)

	if cmd.sendpacket then
		angleManager.SetAngle(cmd.viewangles)
		chokedManager:ResetChoked()
	else
		chokedManager:AddChoked()
	end

	---cmd.impulse = 101
end

callbacks.Register("CreateMove", OnCreateMove)
--hookManager.Register("CreateMove", "BaseCM", OnCreateMove)