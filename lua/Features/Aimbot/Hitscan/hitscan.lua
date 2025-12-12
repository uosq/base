local aim = {}

local mathlib = require("SDK.math")
local entitylib = require("SDK.entity")
local weaponlib = require("SDK.weapons")
local inputlib = require("SDK.input")

---@param cmd UserCmd
---@param plocal Entity
---@param data Settings
function aim.Run(cmd, plocal, data)
	if data.aimbot.hitscan.enabled == false then
		return
	end

	if inputlib.GetKey(data.aimbot.hitscan.key) == false then
		return
	end

	--[[local canshoot = weaponlib.CanShoot()
	if not canshoot then
		return
	end]]

	local entitylist = entities.FindByClass("CTFPlayer")

	local viewangle = engine.GetViewAngles()
	local forward = viewangle:Forward()
	mathlib.NormalizeVector(forward)

	local localPos = entitylib.GetEyePos(plocal)
	local localTeam = plocal:GetTeamNumber()
	local localIndex = plocal:GetIndex()

	---@type {[1]: Vector3, [2]: number}[]
	local validTargets = {}

	local maxFov = data.aimbot.hitscan.fov

	local trace

	for _, player in pairs (entitylist) do
		if player:GetTeamNumber() ~= localTeam and player:IsAlive() and player:IsDormant() == false then
			local center = entitylib.GetWorldSpaceCenter(player)
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
					validTargets[#validTargets+1] = {dir, fovDeg}
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

	if data.aimbot.hitscan.autoshoot then
		cmd.buttons = cmd.buttons | IN_ATTACK
	end

	for _, target in ipairs (validTargets) do
		if cmd.buttons & IN_ATTACK ~= 0 then
			local angle = mathlib.DirectionToAngles(target[1])
			cmd.viewangles = angle
			return
		end
	end
end

return aim