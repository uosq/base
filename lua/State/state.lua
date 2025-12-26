---@class BaseState
local state = {}

local is_attacking = false
local can_shoot = false

function state.IsAttacking()
	return is_attacking
end

function state.CanShoot()
	return can_shoot
end

function state.UpdateIsAttacking(bool)
	if type(bool) ~= "boolean" then
		return 0
	end

	is_attacking = bool
	return 1
end

function state.UpdateCanShoot(bool)
	if type(bool) ~= "boolean" then
		return false
	end

	can_shoot = bool
	return true
end

return state