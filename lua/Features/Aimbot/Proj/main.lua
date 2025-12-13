local lib = {}

local playerPred = require("Features.Aimbot.Proj.playersim")
--local projPred = require("Features.Aimbot.Proj.projectilesim")
local projectileInfo = require("Features.Aimbot.Proj.projectileinfo")

local SDK = require("SDK.sdk")
local mathlib = SDK.GetMathLib()
local inputlib = SDK.GetInputLib()

---@param startPos Vector3
---@param targetPos Vector3
---@param angle EulerAngles
---@param speed number
---@param gravity number
---@param accuracy number
---@param mask number
---@param mins Vector3
---@param maxs Vector3
---@return boolean
local function CheckArcTrajectory(startPos, targetPos, angle, speed, gravity, accuracy, mask, mins, maxs)
	accuracy = accuracy or 15

	local distance = (targetPos - startPos):Length()
	local totalTime = distance / speed
	local velocity = angle:Forward() * speed

	for i = 1, accuracy do
		local t = (i / accuracy) * totalTime

		-- pos = startPos + velocity * t + 0.5 * gravity * t^2
		local pos = startPos + (velocity * t)
		pos.z = pos.z - (0.5 * gravity * t * t)

		local prevT = ((i - 1) / accuracy) * totalTime
		local prevPos = startPos + (velocity * prevT)
		prevPos.z = prevPos.z - (0.5 * gravity * prevT^2)

		local trace = engine.TraceHull(prevPos, pos, mins, maxs, mask, function(ent, contentsMask)
			return false
		end)

		if trace.fraction < 1.0 then
			return false
		end
	end

	return true
end

---@param cmd UserCmd
---@param data Settings
---@param plocal Entity
---@param weapon Weapon
---@param state AimbotState
function lib.Run(cmd, plocal, weapon, data, state)
	if data.aimbot.proj.enabled == false then
		return
	end

	if inputlib.GetKey(data.aimbot.proj.key) == false then
		return
	end

	local info = projectileInfo(weapon:m_iItemDefinitionIndex())
	if info == nil then
		return
	end

	local entitylist = entities.FindByClass("CTFPlayer")
	local lp = SDK.AsPlayer(plocal)

	local viewangle = engine.GetViewAngles()
	local forward = viewangle:Forward()
	mathlib.NormalizeVector(forward)

	local localPos = lp:GetEyePos()
	local localTeam = plocal:GetTeamNumber()
	--local localIndex = plocal:GetIndex()

	---@type {[1]: Entity, [2]: number}[]
	local validTargets = {}

	local maxFov = data.aimbot.proj.fov

	--local trace

	for _, player in pairs (entitylist) do
		if player:GetTeamNumber() ~= localTeam and player:IsAlive() and player:IsDormant() == false then
			local center = SDK.AsPlayer(player):GetWorldSpaceCenter()
			local dir = (center - localPos)

			local distance = dir:Length()
			mathlib.NormalizeVector(dir)

			local dot = forward:Dot(dir)
			local fovDeg = math.deg(math.acos(dot))

			if distance <= 2048 and fovDeg <= maxFov then
				--[[trace = engine.TraceLine(localPos, center, MASK_SHOT_HULL, function (ent, contentsMask)
					return ent:GetIndex() ~= localIndex and ent:GetIndex() ~= player:GetIndex()
				end)]]

				--if trace.fraction == 1.0 then
					validTargets[#validTargets+1] = {player, fovDeg}
				--end
			end
		end
	end

	if #validTargets == 0 then
		return
	end

	table.sort(validTargets, function (a, b)
		return a[2] < b[2]
	end)

	local charge = info.m_bCharges and weapon:GetCurrentCharge() or 0
	if info.m_bCharges then
		if charge == 0 then
			cmd.buttons = cmd.buttons | IN_ATTACK
		end
	end

	local speed = info:GetVelocity(charge):Length2D()
	local gravity = 400 * info:GetGravity(charge)
	local autoshoot = data.aimbot.proj.autoshoot

	local attacking = false
	local canshoot = weapon:CanShootPrimary(cmd)

	local trace, mask = nil, info.m_iTraceMask
	local mins, maxs = info.m_vecMins, info.m_vecMaxs
	local hasGravity = info.m_bHasGravity
	local dmgRadius = info.m_flDamageRadius

	for _, target in ipairs (validTargets) do
		local distance = (localPos - SDK.AsPlayer(target[1]):GetWorldSpaceCenter()):Length()
		if data.aimbot.proj.selfdamage == false and distance <= dmgRadius then
			goto skip
		end

		local time = (distance/speed)
		if time > data.aimbot.proj.maxsimtime then
			goto skip
		end

		local _, targetPos = playerPred(target[1], time, 3)
		local drop = gravity * 2 * time^2
		targetPos = targetPos + Vector3(0, 0, drop)

		local angle = mathlib.SolveBallisticArc(localPos, targetPos, speed, gravity)
		if angle then
			if hasGravity then
				if CheckArcTrajectory(localPos, targetPos, EulerAngles(angle:Unpack()), speed, gravity, 15, mask, mins, maxs) == false then
					goto skip
				end
			else
				trace = engine.TraceHull(localPos, targetPos, mins, maxs, mask, function (ent, contentsMask)
					return false
				end)

				if trace.fraction < 1.0 then
					goto skip
				end
			end

			--- this is really fucking buggy
			--- doesn't work right with chargeable weapons (huntsman, stickybomb launcher, etc)
			if autoshoot then
				if info.m_bCharges == false and canshoot then
					cmd.buttons = cmd.buttons | IN_ATTACK
					attacking = true
				elseif info.m_bCharges then
					cmd.buttons = cmd.buttons & ~IN_ATTACK
					attacking = true
				end
			end

			if attacking then
				cmd.viewangles = angle
				cmd.sendpacket = false
			end

			state.target = target[1]
			return
		end

		::skip::
	end
end

return lib