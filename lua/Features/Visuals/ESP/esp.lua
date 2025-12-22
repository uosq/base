local SDK = require("SDK.sdk")
local CTFPlayer = SDK.GetPlayerClass()
local Helper = require("Features.Visuals.Generic.generic")

local lib = {}
local fontSize = 12
local font = draw.CreateFont("Arial", fontSize, 400)

--[[
Cloaked			0
Ubercharged		1
Jarated			2
Kritz			3
Milked			4
Overhealed		5
Sapped			6
Vaccinator Resist	7
]]

local healthBarWidth = 3
local gap = 2

---@enum CondPositions
local CondPositions = {
	left = 0,
	right = 1,
	top = 2,
	bottom = 3,
}

local VACCFlags = {
	[58] = "Bullet Resist",
	[59] = "Blast Resist",
	[60] = "Fire Resist",
	[61] = "Small Bullet Resist",
	[62] = "Small Blast Resist",
	[63] = "Small Fire Resist",
}

---@param entity Player
---@param condFilter integer
---@return {[1]: CondPositions, [2]: string}[]
local function GetEntityConds(entity, condFilter)
	local list = {}

	if entity:IsPlayer() then
		if SDK.bGetFlag(condFilter, 0) and entity:InCond(TFCond_Cloaked) then
			list[#list+1] = {CondPositions.bottom, "Cloaked"}
		end

		--- uber
		if SDK.bGetFlag(condFilter, 1) and entity:InCond(TFCond_Ubercharged) then
			list[#list+1] = {CondPositions.bottom, "Ubercharged"}
		end

		--- jarated
		if SDK.bGetFlag(condFilter, 2) and entity:InCond(TFCond_Jarated) then
			list[#list+1] = {CondPositions.bottom, "Jarated"}
		end

		--- Kritz
		if SDK.bGetFlag(condFilter, 3) and entity:InCond(TFCond_Kritzkrieged) then
			list[#list+1] = {CondPositions.bottom, "Kritz"}
		end

		--- Milked
		if SDK.bGetFlag(condFilter, 4) and entity:InCond(TFCond_Milked) then
			list[#list+1] = {CondPositions.bottom, "Milked"}
		end

		--- Overhealed
		if SDK.bGetFlag(condFilter, 5) and entity:InCond(TFCond_Overhealed) then
			list[#list+1] = {CondPositions.bottom, "Overhealed"}
		end

		--- Sapped
		if SDK.bGetFlag(condFilter, 6) and entity:InCond(TFCond_Sapped) then
			list[#list+1] = {CondPositions.bottom, "Sapped"}
		end

		--- Vaccinator Resists
		if SDK.bGetFlag(condFilter, 7) then
			local m_nPlayerCondEx = entity:m_nPlayerCondEx()
			for i = 58, 63 do
				if SDK.bGetFlag(m_nPlayerCondEx, i - 32) then
					list[#list+1] = {CondPositions.right, VACCFlags[i]}
				end
			end
		end
	end

	return list
end

--- Call on Draw
---@param settings Settings
function lib.Run(settings)
	if settings.visuals.esp.enabled == false then
		return
	end

	local targets = Helper:GetTargets(settings)
	if #targets == 0 then
		return
	end

	local boxEnabled = settings.visuals.esp.box.enabled
	local boxOutlined = settings.visuals.esp.box.mode == "Outlined"

	local healthBarEnabled = settings.visuals.esp.healthbar.enabled
	local healthBarTopColor = settings.visuals.esp.healthbar.topcolor
	local healthBarBottomColor = settings.visuals.esp.healthbar.bottomcolor

	local condFilter = settings.visuals.conds

	local Name = SDK.bGetFlag(settings.visuals.esp.options, 0)
	local Class = SDK.bGetFlag(settings.visuals.esp.options, 1)
	local Health = SDK.bGetFlag(settings.visuals.esp.options, 2)
	local Distance = SDK.bGetFlag(settings.visuals.esp.options, 3)
	local Ubercharge = SDK.bGetFlag(settings.visuals.esp.options, 4)
	local Weapon = SDK.bGetFlag(settings.visuals.esp.options, 5)
	local SteamID = SDK.bGetFlag(settings.visuals.esp.options, 6)

	draw.SetFont(font)
	draw.Color(255, 255, 255, 255)
	for _, target in ipairs(targets) do
		local feetPos = target:GetAbsOrigin() + Vector3(0, 0, target:GetMins().z)

		local feetScreenPos = client.WorldToScreen(feetPos)
		if not feetScreenPos then goto continue end

		local headPos = client.WorldToScreen(feetPos + Vector3(0, 0, target:GetMaxs().z))
		if not headPos then goto continue end

		--- feet - head because feet is probably in a higher screen Y than head
		local h = math.abs(feetScreenPos[2] - headPos[2])
		local w = target:IsPlayer() and (h * 0.3) // 1 or (h * 0.3) // 1

		if boxEnabled then
			local color = SDK.GetColor(target)
			draw.Color((color[1]*255)//1, (color[2]*255)//1, (color[3]*255)//1, 255)
			draw.OutlinedRect(feetScreenPos[1] - w, headPos[2], feetScreenPos[1] + w, headPos[2] + h)

			if boxOutlined then
				draw.Color(0, 0, 0, 255)
				draw.OutlinedRect(feetScreenPos[1] - w - 1, feetScreenPos[2] - h - 1, feetScreenPos[1] + w + 1, feetScreenPos[2] + 1)
				draw.OutlinedRect(feetScreenPos[1] - w + 1, feetScreenPos[2] - h + 1, feetScreenPos[1] + w - 1, feetScreenPos[2] - 1)
			end
		end

		if healthBarEnabled then
			local x, y = feetScreenPos[1] - w - healthBarWidth - gap, headPos[2]

			draw.Color(40, 40, 40, 255)
			draw.OutlinedRect(x - 1, y - 1, x + healthBarWidth + 1, y + h + 1)

			draw.Color(healthBarBottomColor.R, healthBarBottomColor.G, healthBarBottomColor.B, 255)
			draw.FilledRectFade(x, y, x + healthBarWidth, y + h, 0, 255, false)

			draw.Color(healthBarTopColor.R, healthBarTopColor.G, healthBarTopColor.B, 255)
			draw.FilledRectFade(x, y, x + healthBarWidth, y + h, 255, 0, false)

			local percent = math.min(target:GetHealth()/target:GetMaxHealth(), 1)
			draw.Color(40, 40, 40, 255)
			draw.FilledRect(x, y, x + healthBarWidth, y + h - (h * percent)//1)

			if (target:GetHealth() > target:GetMaxHealth()) then
				local maxhealth = target:GetMaxHealth()
				percent = math.min(1, (target:GetHealth()-maxhealth)/(target:GetMaxBuffedHealth()-maxhealth))

				draw.Color(0, 255, 255, 255)
				draw.FilledRect(x, y + h - (h * percent)//1, x + healthBarWidth, y + h)
			end
		end

		local leftIndex = 0
		local rightIndex = 0
		local bottomIndex = 0
		local topIndex = 0

		if condFilter ~= 0 then
			local player = SDK.Reinterpret(target, CTFPlayer)
			if player then
				local conds = GetEntityConds(player, condFilter)
				if #conds > 0 then

					draw.Color(255, 255, 255, 255)
					for i = 1, #conds do
						local cond = conds[i]
						local x, y

						if cond[1] == CondPositions.right then
							x = feetScreenPos[1] + w + gap
							y = headPos[2] + (fontSize * rightIndex) + (gap * rightIndex)

							rightIndex = rightIndex + 1

							draw.TextShadow(x, y, cond[2])
						elseif cond[1] == CondPositions.left then
							local tw = draw.GetTextSize(cond[2])
							x = feetScreenPos[1] - w - gap*2 - (healthBarEnabled and healthBarWidth or 0) - (tw//1)
							y = headPos[2] + (fontSize * leftIndex) + (gap * leftIndex)

							leftIndex = leftIndex + 1

							draw.TextShadow(x, y, cond[2])
						elseif cond[1] == CondPositions.top then
							local tw = draw.GetTextSize(cond[2])
							x = (feetScreenPos[1] - tw*0.5) // 1
							y = headPos[2] - fontSize - (fontSize * topIndex) - (gap * topIndex)

							topIndex = topIndex + 1

							draw.TextShadow(x, y, cond[2])
						elseif cond[1] == CondPositions.bottom then
							local tw = draw.GetTextSize(cond[2])
							x = (feetScreenPos[1] - tw*0.5) // 1
							y = feetScreenPos[2] + (fontSize * bottomIndex) + (gap * bottomIndex)

							bottomIndex = bottomIndex + 1

							draw.TextShadow(x, y, cond[2])
						end
					end
				end
			end
		end

		if Name then
			
		end

		::continue::
	end
end

return lib