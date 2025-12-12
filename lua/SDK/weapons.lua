local lib = {}

local old_weapon, lastFire, nextPrimaryAttack, nextAttack = nil, 0, 0, 0

local function GetLastFireTime(weapon)
	return weapon:GetPropFloat("LocalActiveTFWeaponData", "m_flLastFireTime")
end

local function GetNextPrimaryAttack(weapon)
	return weapon:GetPropFloat("LocalActiveWeaponData", "m_flNextPrimaryAttack")
end

local function GetNextAttack(player)
	return player:GetPropFloat("bcc_localdata", "m_flNextAttack")
end

--- https://www.unknowncheats.me/forum/team-fortress-2-a/273821-canshoot-function.html
function lib.CanShoot()
	local player = entities:GetLocalPlayer()
	if not player then
		return false
	end

	local weapon = player:GetPropEntity("m_hActiveWeapon")
	if not weapon or not weapon:IsValid() then
		return false
	end

	if weapon:GetPropInt("LocalWeaponData", "m_iClip1") == 0 then
		return false
	end

	if weapon:IsMeleeWeapon() then
		return GetNextPrimaryAttack(weapon) <= globals.CurTime() + weapon:GetWeaponData().smackDelay
	end

	local lastfiretime = GetLastFireTime(weapon)

	local tickBase = player:GetPropInt("m_nTickBase") * globals.TickInterval()

	if lastFire ~= lastfiretime or weapon ~= old_weapon then
		lastFire = lastfiretime
		nextPrimaryAttack = GetNextPrimaryAttack(weapon)
		nextAttack = GetNextAttack(player)
	end

	old_weapon = weapon
	return nextPrimaryAttack <= tickBase or nextAttack <= tickBase
end

return lib