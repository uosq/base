local lib = {}

local playerPred = require("SDK.prediction.playersim")
--local projPred = require("Features.Aimbot.Proj.projectilesim")
local projectileInfo = require("Features.Aimbot.Proj.projectileinfo")

local SDK = require("SDK.sdk")
local mathlib = SDK.GetMathLib()
local inputlib = SDK.GetInputLib()
local chokedManager = SDK.GetChokedLib()

---@param plocal Player
---@param weapon Weapon
local function GetPositionOffset(plocal, weapon)
	local weaponID = weapon:GetWeaponID()
	if weaponID == E_WeaponBaseID.TF_WEAPON_ROCKETLAUNCHER
	or weaponID == E_WeaponBaseID.TF_WEAPON_DIRECTHIT then
		return 10
	end

	if weaponID == E_WeaponBaseID.TF_WEAPON_COMPOUND_BOW then
		return plocal:GetMaxs().z * 0.8
	end

	return plocal:GetMaxs().z * 0.5
end

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
---@param plocal Player
---@param weapon Weapon
---@param state AimbotState
function lib.Run(cmd, plocal, weapon, data, state)
	if data.aimbot.proj.enabled == false then
		return
	end

	if inputlib.IsKeyDown(data.aimbot.proj.key) == false then
		return
	end

	local info = projectileInfo(weapon:m_iItemDefinitionIndex())
	if info == nil then
		return
	end

	if chokedManager:GetChoked() > 0 then
		return
	end

	local entitylist = SDK.GetPlayerList()
	if #entitylist == 0 then
		return
	end

	local viewangle = engine.GetViewAngles()
	local forward = viewangle:Forward()
	mathlib.NormalizeVector(forward)

	local localPos = plocal:GetEyePos()
	local localTeam = plocal:GetTeamNumber()

	---@type {[1]: Player, [2]: number}[]
	local validTargets = {}

	local maxDot = math.cos(math.rad(data.aimbot.proj.fov))

	for _, player in pairs (entitylist) do
		if player:GetTeamNumber() ~= localTeam and player:IsAlive() and player:IsDormant() == false and player:InCond(E_TFCOND.TFCond_Cloaked) == false then
			local center = player:GetWorldSpaceCenter()
			local dir = (center - localPos)

			local distance = dir:Length()
			mathlib.NormalizeVector(dir)

			local dot = forward:Dot(dir)

			if distance <= 2048 and dot >= maxDot then
				validTargets[#validTargets+1] = {player, dot}
			end
		end
	end

	if #validTargets == 0 then
		return
	end

	table.sort(validTargets, function (a, b)
		return a[2] > b[2]
	end)

	local charge = info.m_bCharges and weapon:GetCurrentCharge() or 0
	local speed = info:GetVelocity(charge):Length2D()
	local gravity = 400 * info:GetGravity(charge)
	local autoshoot = data.aimbot.proj.autoshoot

	local trace, mask = nil, info.m_iTraceMask
	local mins, maxs = info.m_vecMins, info.m_vecMaxs
	local hasGravity = info.m_bHasGravity
	local dmgRadius = info.m_flDamageRadius
	local selfdamage = data.aimbot.proj.selfdamage

	local validTarget, validAngle = nil, nil

	local weaponOffset = GetPositionOffset(plocal, weapon)
	local extraTime = (data.aimbot.proj.compensate and weapon:GetWeaponID() == TF_WEAPON_PIPEBOMBLAUNCHER) and 0.7 or 0

	for _, target in ipairs (validTargets) do
		local distance = (localPos - target[1]:GetWorldSpaceCenter()):Length()
		if selfdamage == false and distance <= dmgRadius then
			goto skip
		end

		local time = (distance/speed) + extraTime
		if time > data.aimbot.proj.maxsimtime then
			goto skip
		end

		local _, targetPos = playerPred(target[1]:GetHandle(), time)

		targetPos.z = targetPos.z + weaponOffset

		if hasGravity then
			local drop = gravity * (time - extraTime)^2
			targetPos.z = targetPos.z + drop
		end

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

			validTarget = target[1]
			validAngle = angle
			break
		end

		::skip::
	end

	if not validTarget or not validAngle then
		return
	end

	--- this is really fucking buggy
	--- doesn't work right with chargeable weapons (huntsman, stickybomb launcher, etc)
	if autoshoot then
		if weapon:CanPrimaryAttack() then
			cmd.buttons = cmd.buttons | IN_ATTACK
			if info.m_bCharges and charge > 0 then
				cmd.buttons = cmd.buttons & ~IN_ATTACK
			end
		end
	end

	if SDK.IsAttacking(plocal, weapon, cmd) then
		cmd.viewangles = validAngle
		cmd.sendpacket = false
	end

	state.target = validTarget
end

return lib