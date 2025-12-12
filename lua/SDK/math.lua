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

return lib