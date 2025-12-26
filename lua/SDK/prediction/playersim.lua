--- Returns the type of its only argument, coded as a string.
---@return "AttributeDefinition" | "BitBuffer" | "DrawModelContext" | "Entity" | "EulerAngles" | "EventInfo" | "GameEvent" | "GameServerLobby" | "Item" | "ItemDefinition" | "LobbyPlayer" | "MatchGroup" | "MatchMapDefinition" | "Material" | "Model" | "NetChannel" | "NetMessage" | "PartyMemberActivity" | "PhysicsCollisionModel" | "PhysicsEnvironment" | "PhysicsObject" | "PhysicsObjectParameters" | "PhysicsSolid" | "StaticPropRenderInfo" | "StringCmd" | "StudioBBox" | "StudioHitboxSet" | "StudioModelHeader" | "TempEntity" | "Texture" | "Trace" | "UserCmd" | "UserMessage" | "Vector3" | "ViewSetup" | "WeaponData
local function typeof(v)
	return getmetatable(v).__name
end

--- Why is this not in the lua docs?
local RuneTypes_t = {
	RUNE_NONE = -1,
	RUNE_STRENGTH = 0,
	RUNE_HASTE = 1,
	RUNE_REGEN = 2,
	RUNE_RESIST = 3,
	RUNE_VAMPIRE = 4,
	RUNE_REFLECT = 5,
	RUNE_PRECISION = 6,
	RUNE_AGILITY = 7,
	RUNE_KNOCKOUT = 8,
	RUNE_KING = 9,
	RUNE_PLAGUE = 10,
	RUNE_SUPERNOVA = 11,
}

---@param velocity Vector3
---@param wishdir Vector3
---@param wishspeed number
---@param accel number
---@param frametime number
local function Accelerate(velocity, wishdir, wishspeed, accel, frametime)
	local addspeed, accelspeed, currentspeed

	currentspeed = velocity:Dot(wishdir)
	addspeed = wishspeed - currentspeed

	if addspeed <= 0 then
		return
	end

	accelspeed = accel * frametime * wishspeed
	if accelspeed > addspeed then
		accelspeed = addspeed
	end

	velocity.x = velocity.x + wishdir.x * accelspeed
	velocity.y = velocity.y + wishdir.y * accelspeed
	velocity.z = velocity.z + wishdir.z * accelspeed
end

---@param target Player
---@return number
local function GetAirSpeedCap(target)
	local m_hGrapplingHookTarget = target:m_hGrapplingHookTarget()
	if m_hGrapplingHookTarget then
		if target:GetCarryingRuneType() == RuneTypes_t.RUNE_AGILITY then
			local m_iClass = target:m_iClass()
			return (m_iClass == E_Character.TF2_Soldier or E_Character.TF2_Heavy) and 850 or 950
		end
		local _, tf_grapplinghook_move_speed = client.GetConVar("tf_grapplinghook_move_speed")
		return tf_grapplinghook_move_speed
	elseif target:InCond(E_TFCOND.TFCond_Charging) then
		local _, tf_max_charge_speed = client.GetConVar("tf_max_charge_speed")
		return tf_max_charge_speed
	else
		local flCap = 30.0
		if target:InCond(E_TFCOND.TFCond_ParachuteDeployed) then
			local _, tf_parachute_aircontrol = client.GetConVar("tf_parachute_aircontrol")
			flCap = flCap * tf_parachute_aircontrol
		end
		if target:InCond(E_TFCOND.TFCond_HalloweenKart) then
			if target:InCond(E_TFCOND.TFCond_HalloweenKartDash) then
				local _, tf_halloween_kart_dash_speed = client.GetConVar("tf_halloween_kart_dash_speed")
				return tf_halloween_kart_dash_speed
			end
			local _, tf_hallowen_kart_aircontrol = client.GetConVar("tf_hallowen_kart_aircontrol")
			flCap = flCap * tf_hallowen_kart_aircontrol
		end
		return flCap * target:AttributeHookFloat("mod_air_control")
	end
end

---@param v Vector3 Velocity
---@param wishdir Vector3
---@param wishspeed number
---@param accel number
---@param dt number globals.TickInterval()
---@param surf number Is currently surfing?
---@param target Player
local function AirAccelerate(v, wishdir, wishspeed, accel, dt, surf, target)
	wishspeed = math.min(wishspeed, GetAirSpeedCap(target))
	local currentspeed = v:Dot(wishdir)
	local addspeed = wishspeed - currentspeed
	if addspeed <= 0 then
		return
	end

	local accelspeed = math.min(accel * wishspeed * dt * surf, addspeed)
	v.x = v.x + accelspeed * wishdir.x
	v.y = v.y + accelspeed * wishdir.y
	v.z = v.z + accelspeed * wishdir.z
end

local function CheckIsOnGround(origin, mins, maxs, index)
	local down = Vector3(origin.x, origin.y, origin.z - 18)
	local trace = engine.TraceHull(origin, down, mins, maxs, MASK_PLAYERSOLID, function(ent, contentsMask)
		return ent:GetIndex() ~= index
	end)

	return trace and trace.fraction < 1.0 and not trace.startsolid and trace.plane and trace.plane.z >= 0.7
end

---@param index integer
local function StayOnGround(origin, mins, maxs, step_size, index)
	local vstart = Vector3(origin.x, origin.y, origin.z + 2)
	local vend = Vector3(origin.x, origin.y, origin.z - step_size)

	local trace = engine.TraceHull(vstart, vend, mins, maxs, MASK_PLAYERSOLID, function(ent, contentsMask)
		return ent:GetIndex() ~= index
	end)

	if trace and trace.fraction < 1.0 and not trace.startsolid and trace.plane and trace.plane.z >= 0.7 then
		local delta = math.abs(origin.z - trace.endpos.z)
		if delta > 0.5 then
			origin.x = trace.endpos.x
			origin.y = trace.endpos.y
			origin.z = trace.endpos.z
			return true
		end
	end

	return false
end

---@param velocity Vector3
---@param is_on_ground boolean
---@param frametime number
local function Friction(velocity, is_on_ground, frametime)
	assert(typeof(velocity) == "Vector3", "Friction: velocity is not a Vector3!")
	assert(type(is_on_ground) == "boolean", "Friction: is_on_ground is not a boolean!")
	assert(type(frametime) == "number", "Friction: frametime is not a number!")

	local speed, newspeed, control, friction, drop
	speed = velocity:LengthSqr()
	if speed < 0.01 then
		return
	end

	local _, sv_stopspeed = client.GetConVar("sv_stopspeed")
	drop = 0

	if is_on_ground then
		local _, sv_friction = client.GetConVar("sv_friction")
		friction = sv_friction

		control = speed < sv_stopspeed and sv_stopspeed or speed
		drop = drop + control * friction * frametime
	end

	newspeed = speed - drop
	if newspeed ~= speed then
		newspeed = newspeed / speed
		velocity.x = velocity.x * newspeed
		velocity.y = velocity.y * newspeed
		velocity.z = velocity.z * newspeed
	end
end

-- Clip velocity along a plane normal
local function ClipVelocity(velocity, normal, overbounce)
	assert(typeof(velocity) == "Vector3", "ClipVelocity: velocity is not a Vector3!")
	assert(typeof(normal) == "Vector3", "ClipVelocity: normal is not a Vector3!")
	assert(type(overbounce) == "number", "ClipVelocity: overbounce is not a number!")

	local backoff = velocity:Dot(normal) * overbounce

	velocity.x = velocity.x - normal.x * backoff
	velocity.y = velocity.y - normal.y * backoff
	velocity.z = velocity.z - normal.z * backoff

	-- Zero out small components
	if math.abs(velocity.x) < 0.01 then velocity.x = 0 end
	if math.abs(velocity.y) < 0.01 then velocity.y = 0 end
	if math.abs(velocity.z) < 0.01 then velocity.z = 0 end
end

---@param origin Vector3
---@param velocity Vector3
---@param mins Vector3
---@param maxs Vector3
---@param step number
---@param dt number
---@return Vector3 NewOrigin, boolean IfMoved
local function TryStepMove(origin, velocity, mins, maxs, step, dt)
	local move = velocity * dt

	--- try normal move 
	local trace = engine.TraceHull(
		origin,
		origin + move,
		mins,
		maxs,
		MASK_PLAYERSOLID,
		function() return false end
	)

	--- 0.7 is roughly 90 degrees right?
	--- i dont remember
	--- its working so i dont care xd
	if trace.fraction == 1.0 and trace.plane.z <= 0.7 then
		return origin + move, true
	end

	--- step up
	local up = Vector3(0, 0, step)
	local traceUp = engine.TraceHull(
		origin,
		origin + up,
		mins,
		maxs,
		MASK_PLAYERSOLID,
		function() return false end
	)

	if traceUp.fraction < 1.0 and traceUp.plane.z <= 0.7 then
		return origin, false
	end

	local stepOrigin = origin + up
	local traceForward = engine.TraceHull(
		stepOrigin,
		stepOrigin + move,
		mins,
		maxs,
		MASK_PLAYERSOLID,
		function() return false end
	)

	if traceForward.fraction < 1.0 and traceForward.plane.z <= 0.7 then
		return origin, false
	end

	--- step down
	local traceDown = engine.TraceHull(
		traceForward.endpos,
		traceForward.endpos - up,
		mins,
		maxs,
		MASK_PLAYERSOLID,
		function() return false end
	)

	return traceDown.endpos, true
end

---@param player Player
---@param time_seconds number
---@return Vector3[], Vector3
local function RunSeconds(player, time_seconds)
	local path = {}
	local velocity = player:EstimateAbsVelocity() or Vector3()
	local origin = player:GetAbsOrigin() + Vector3(0, 0, 1)

	if velocity:Length() <= 10 then
		path[1] = origin
		return path, origin
	end

	local maxspeed = player:m_flMaxspeed()

	local clock = 0.0
	local tickinterval = globals.TickInterval()

	local wishdir = velocity / velocity:Length()
	local mins, maxs = player:GetMins(), player:GetMaxs()

	local _, sv_airaccelerate = client.GetConVar("sv_airaccelerate")
	local _, sv_accelerate = client.GetConVar("sv_accelerate")

	local index = player:GetIndex()

	local speed = velocity:Length2D()
	local wishspeed = math.min(speed, maxspeed)

	local gravity = 800 * tickinterval

	local stepsize = player:m_flStepSize()

	while clock < time_seconds do
		local is_on_ground = CheckIsOnGround(origin, mins, maxs, index)

		velocity.z = velocity.z - gravity * 0.5 * tickinterval

		if is_on_ground then
			velocity.z = 0
			Friction(velocity, is_on_ground, tickinterval)
			Accelerate(velocity, wishdir, wishspeed, sv_accelerate, tickinterval)
		else
			AirAccelerate(velocity, wishdir, maxspeed, sv_airaccelerate, tickinterval, 0, player)
			velocity.z = velocity.z - gravity
		end

		local newOrigin, moved = TryStepMove(
			origin,
			velocity,
			mins,
			maxs,
			stepsize,
			tickinterval
		)

		velocity.z = velocity.z - gravity * 0.5 * tickinterval

		if moved then
			origin = newOrigin
		else
			velocity.x = 0
			velocity.y = 0
		end

		--- if on ground, stick to it
		if is_on_ground then
			StayOnGround(origin, mins, maxs, 18, index)
		end

		path[#path + 1] = Vector3(origin:Unpack())
		clock = clock + tickinterval
	end

	return path, path[#path]
end

return RunSeconds