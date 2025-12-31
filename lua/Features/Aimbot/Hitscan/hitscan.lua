local aim = {}

local SDK = require("SDK.sdk")
local mathlib = SDK.GetMathLib()
local inputlib = SDK.GetInputLib()

local boneIndexes = SDK.GetBoneIndexEnum()

local playersim = SDK.GetPlayerSim()

---@param plocal Player
---@param target Player
---@param weapon Weapon
---@return Vector3?
local function GetShootPosition(plocal, target, weapon)
	local weaponID = weapon:GetID()
	if weaponID == TF_WEAPON_REVOLVER then
		if weapon:IsAmbassador() and weapon:CanAmbassadorHeadshot() then
			local headPosition = target:GetBonePosition(boneIndexes.Head) + Vector3(0, 0, 5)
			return headPosition
		end
	end

	if weaponID == TF_WEAPON_SNIPERRIFLE or weaponID == TF_WEAPON_SNIPERRIFLE_DECAP then
		if plocal:InCond(TFCond_Zoomed) then
			return target:GetBonePosition(boneIndexes.Head) + Vector3(0, 0, 5)
		end
	end

	return target:GetWorldSpaceCenter()
end

---@param cmd UserCmd
---@param plocal Player
---@param data Settings
---@param weapon Weapon
---@param state AimbotState
function aim.Run(cmd, plocal, weapon, data, state)
	if data.aimbot.hitscan.enabled == false then
		return
	end

	if inputlib.IsKeyDown(data.aimbot.hitscan.key) == false then
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
	local localIndex = plocal:GetIndex()

	---@type {[1]: Vector3, [2]: number, [3]: Player}[]
	local validTargets = {}

	local maxDot = math.cos(math.rad(data.aimbot.hitscan.fov))

	local trace

	for _, player in pairs (entitylist) do
		if player:GetTeamNumber() ~= localTeam and player:IsAlive() and player:IsDormant() == false then
			local shootPos = GetShootPosition(plocal, player, weapon)
			if shootPos then
				local dir = (shootPos - localPos)

				local distance = dir:Length()
				mathlib.NormalizeVector(dir)

				local dot = forward:Dot(dir)
				if distance <= 2048 and dot >= maxDot then
					trace = engine.TraceLine(localPos, shootPos, MASK_SHOT_HULL, function (ent, contentsMask)
						return ent:GetIndex() ~= localIndex and ent:GetIndex() ~= player:GetIndex()
					end)

					if trace.fraction == 1.0 then
						validTargets[#validTargets+1] = {dir, dot, player}
					end
				end
			end
		end
	end

	if #validTargets == 0 then
		return
	end

	table.sort(validTargets, function (a, b)
		return a[2] > b[2]
	end)

	for _, target in ipairs (validTargets) do
		if weapon:CanHit(target[3]) then
			if data.aimbot.hitscan.autoshoot and weapon:CanPrimaryAttack() then
				cmd.buttons = cmd.buttons | IN_ATTACK
			end

			if SDK.IsAttacking(weapon, cmd) then
				local angle = mathlib.DirectionToAngles(target[1])
				cmd.viewangles = angle
			end

			state.target = target[3]
			return
		end
	end
end

return aim