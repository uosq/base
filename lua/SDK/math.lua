local lib = {}

---@param vec Vector3
---@return number
function lib.NormalizeVector(vec)
	local len = vec:Length()
	if len < 0.0001 then
		return 0
	end

	vec.x = vec.x / len
	vec.y = vec.y / len
	vec.z = vec.z / len

	return len
end

---@param a Vector3
---@param b Vector3
---@return number
function lib.Fov(a, b)
	return math.acos(a:Dot(b)) * (180 / math.pi)
end

function lib.DirectionToAngles(direction)
    local pitch = math.asin(-direction.z) * (180 / math.pi)
    local yaw = math.atan(direction.y, direction.x) * (180 / math.pi)
    return Vector3(pitch, yaw, 0)
end

---@param p0 Vector3 -- start position
---@param p1 Vector3 -- target position
---@param speed number -- projectile speed
---@param gravity number -- gravity constant
---@return Vector3? -- Returns the angle and the apex of the trajectory
function lib.SolveBallisticArc(p0, p1, speed, gravity)
	local diff = p1 - p0
	local dx = diff:Length2D()
	local dy = diff.z
	local speed2 = speed * speed
	local g = gravity

	local root = speed2 * speed2 - g * (g * dx * dx + 2 * dy * speed2)
	if root < 0 then
		return nil -- no solution
	end

	local angle = math.atan((speed2 - math.sqrt(root)) / (g * dx)) -- low arc
	local yaw = (math.atan(diff.y, diff.x)) * (180 / math.pi)
	local pitch = -angle * (180 / math.pi)

	return Vector3(pitch, yaw, 0)
end

return lib