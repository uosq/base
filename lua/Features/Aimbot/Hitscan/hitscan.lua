local aim = {}

local SDK = require("SDK.sdk")
local mathlib = SDK.GetMathLib()
local inputlib = SDK.GetInputLib()

---@param cmd UserCmd
---@param plocal Entity
---@param data Settings
---@param weapon Weapon
---@param state AimbotState
function aim.Run(cmd, plocal, weapon, data, state)
	if data.aimbot.hitscan.enabled == false then
		return
	end

	if inputlib.GetKey(data.aimbot.hitscan.key) == false then
		return
	end

	local lp = SDK.AsPlayer(plocal)
	if lp == nil then
		return
	end

	local entitylist = entities.FindByClass("CTFPlayer")

	local viewangle = engine.GetViewAngles()
	local forward = viewangle:Forward()
	mathlib.NormalizeVector(forward)

	local localPos = lp:GetEyePos()
	local localTeam = plocal:GetTeamNumber()
	local localIndex = plocal:GetIndex()

	---@type {[1]: Vector3, [2]: number, [3]: Entity}[]
	local validTargets = {}

	local maxFov = data.aimbot.hitscan.fov

	local trace

	for _, player in pairs (entitylist) do
		if player:GetTeamNumber() ~= localTeam and player:IsAlive() and player:IsDormant() == false then
			local center = SDK.AsPlayer(player):GetWorldSpaceCenter()
			local dir = (center - localPos)

			local distance = dir:Length()
			mathlib.NormalizeVector(dir)

			local dot = forward:Dot(dir)
			local fovDeg = math.deg(math.acos(dot))

			if distance <= 2048 and fovDeg <= maxFov then
				trace = engine.TraceLine(localPos, center, MASK_SHOT_HULL, function (ent, contentsMask)
					return ent:GetIndex() ~= localIndex and ent:GetIndex() ~= player:GetIndex()
				end)

				if trace.fraction == 1.0 then
					validTargets[#validTargets+1] = {dir, fovDeg, player}
				end
			end
		end
	end

	if #validTargets == 0 then
		return
	end

	table.sort(validTargets, function (a, b)
		return a[2] < b[2]
	end)

	for _, target in ipairs (validTargets) do
		if data.aimbot.hitscan.autoshoot then
			cmd.buttons = cmd.buttons | IN_ATTACK
		end

		if SDK.IsAttacking(lp, weapon, cmd) then
			local angle = mathlib.DirectionToAngles(target[1])
			cmd.viewangles = angle
		end

		state.target = target[3]
		return
	end
end

return aim