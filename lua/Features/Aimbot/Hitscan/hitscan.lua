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
	local weaponID = weapon:GetWeaponID()
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

	if inputlib.GetKey(data.aimbot.hitscan.key) == false then
		return
	end

	local entitylist = entities.FindByClass("CTFPlayer")

	local viewangle = engine.GetViewAngles()
	local forward = viewangle:Forward()
	mathlib.NormalizeVector(forward)

	local localPos = plocal:GetEyePos()
	local localTeam = plocal:GetTeamNumber()
	local localIndex = plocal:GetIndex()

	---@type {[1]: Vector3, [2]: number, [3]: Entity}[]
	local validTargets = {}

	local maxFov = data.aimbot.hitscan.fov

	local latency = clientstate.GetNetChannel():GetLatency(E_Flows.FLOW_INCOMING)
	local trace

	for _, entity in pairs (entitylist) do
		if entity:GetTeamNumber() ~= localTeam and entity:IsAlive() and entity:IsDormant() == false then
			local player = SDK.AsPlayer(entity)
			if player then
				local shootPos = GetShootPosition(plocal, player, weapon)
				if shootPos then
					local dir = (shootPos - localPos)

					local distance = dir:Length()
					mathlib.NormalizeVector(dir)

					local dot = forward:Dot(dir)
					local fovDeg = math.deg(math.acos(dot))

					if distance <= 2048 and fovDeg <= maxFov then
						trace = engine.TraceLine(localPos, shootPos, MASK_SHOT_HULL, function (ent, contentsMask)
							return ent:GetIndex() ~= localIndex and ent:GetIndex() ~= entity:GetIndex()
						end)

						if trace.fraction == 1.0 then
							validTargets[#validTargets+1] = {dir, fovDeg, entity}
						end
					end
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
		local player = SDK.AsPlayer(target[3])
		if player and weapon:CanHit(player) then
			if data.aimbot.hitscan.autoshoot and weapon:CanPrimaryAttack() then
				cmd.buttons = cmd.buttons | IN_ATTACK
			end

			if SDK.IsAttacking(plocal, weapon, cmd) then
				local angle = mathlib.DirectionToAngles(target[1])
				cmd.viewangles = angle
			end

			state.target = target[3]
			return
		end
	end
end

return aim