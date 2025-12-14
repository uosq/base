--- I am not smart enough to make this by myself
--- Source: https://www.unknowncheats.me/forum/team-fortress-2-a/700159-simple-glow-outline.html

--- make the lsp stop complaining about nil shit
---@diagnostic disable: param-type-mismatch

local lib = {}

local Aimbot = require("Features.Aimbot.aimbot")

--- materials
local m_pMatGlowColor = nil
local m_pMatHaloAddToScreen = nil
local m_pMatBlurX = nil
local m_pMatBlurY = nil
local pRtFullFrame = nil
local m_pGlowBuffer1 = nil
local m_pGlowBuffer2 = nil

local function InitMaterials()
	if m_pMatGlowColor == nil then
		m_pMatGlowColor = materials.Find("dev/glow_color")
	end

	if m_pMatHaloAddToScreen == nil then
		m_pMatHaloAddToScreen = materials.Create("GlowMaterialHalo",
		[[UnlitGeneric
		{
			$basetexture "GlowBuffer1"
			$additive "1"
		}]])
	end

	if m_pMatBlurX == nil then
		m_pMatBlurX = materials.Create("GlowMatBlurX",
		[[BlurFilterX
		{
			$basetexture "GlowBuffer1"
		}]]);
	end

	if m_pMatBlurY == nil then
		m_pMatBlurY = materials.Create("GlowMatBlurY",
		[[BlurFilterY
		{
			$basetexture "GlowBuffer2"
		}]])
	end

	if pRtFullFrame == nil then
		pRtFullFrame = materials.FindTexture("_rt_FullFrameFB", "RenderTargets", true);
	end

	if m_pGlowBuffer1 == nil then
		m_pGlowBuffer1 = materials.CreateTextureRenderTarget(
			"GlowBuffer1",
			pRtFullFrame:GetActualWidth(),
			pRtFullFrame:GetActualHeight()
		)
	end

	if m_pGlowBuffer2 == nil then
		m_pGlowBuffer2 = materials.CreateTextureRenderTarget(
			"GlowBuffer2",
			pRtFullFrame:GetActualWidth(),
			pRtFullFrame:GetActualHeight()
		)
	end
end

local STUDIO_RENDER = 0x00000001
local STUDIO_NOSHADOWS = 0x00000080

local function GetGuiColor(option)
    local value = gui.GetValue(option)
    if value == 255 then
        return nil
    elseif value == -1 then
	return {1, 1, 1, 1}
    end

    -- convert signed 32-bit int to unsigned 32-bit
    if value < 0 then
        value = value + 0x100000000
    end

    local r = (value >> 24) & 0xFF
    local g = (value >> 16) & 0xFF
    local b = (value >> 8)  & 0xFF
    local a = value & 0xFF

    return { r * 0.003921, g * 0.003921, b * 0.003921, a * 0.003921 }
end

---@param entity Entity
---@param weapon boolean
local function GetColor(entity, weapon)
	if entity:GetClass() == "CBaseAnimating" then
		local modelName = models.GetModelName(entity:GetModel())
		if string.find(modelName, "ammopack") then
			return {1.0, 1.0, 1.0, 1.0}
		elseif string.find(modelName, "medkit") then
			return {0.15294117647059, 0.96078431372549, 0.32941176470588, 1.0}
		end
	end

	local target = Aimbot.GetState().target
	if target and target:GetIndex() == entity:GetIndex() then
		local color = GetGuiColor("aimbot target color")
		if color then return color end
	end

	if entity:GetIndex() == client.GetLocalPlayerIndex() then
		return {0, 1, 0.501888, 1}
	end

	if entity:GetClass() == "CPhysicsProp" then
		return {1.0, 1.0, 1.0, 1.0}
	end

	if weapon and entity:IsWeapon() then
		return {1.0, 1.0, 1.0, 1.0}
	end

	local color = GetGuiColor("aimbot target color")
	if aimbot.GetAimbotTarget() == entity:GetIndex() and color then
		return color
	end

	if playerlist.GetPriority(entity) > 0 then
		return {1, 1, 0.0, 1}
	elseif playerlist.GetPriority(entity) < 0 then
		return {0, 1, 0.501888, 1}
	end

	if entity:GetTeamNumber() == 3 then
		return GetGuiColor("blue team color") or {0.145077, 0.58815, 0.74499, 1}
	else
		return GetGuiColor("red team color") or {0.929277, 0.250944, 0.250944, 1}
	end
end

local function DrawEntities(ents)
	for _, info in pairs (ents) do
		local entity = entities.GetByIndex(info[1])
		if entity then
			local color = info[2]
			render.SetColorModulation(color[1], color[2], color[3])
			entity:DrawModel(STUDIO_RENDER | STUDIO_NOSHADOWS)
		end
	end
end

---@param outTable table
---@param weapon boolean
local function GetPlayers(outTable, weapon)
	for _, player in pairs (entities.FindByClass("CTFPlayer")) do
		if player:ShouldDraw() and player:IsDormant() == false then
			local color = GetColor(player, weapon)
			outTable[#outTable+1] = {player:GetIndex(), color}
			local child = player:GetMoveChild()
			while child ~= nil do
				if weapon and child:IsWeapon() then
					outTable[#outTable+1] = {child:GetIndex(), {1, 1, 1, 1}}
				else
					outTable[#outTable+1] = {child:GetIndex(), color}
				end
				child = child:GetMovePeer()
			end
		end
	end
end

---@param weapon boolean
---@param outTable table
---@param className string
local function GetClass(className, outTable, weapon)
	for _, building in pairs(entities.FindByClass(className)) do
		if building:ShouldDraw() and building:IsDormant() == false then
			outTable[#outTable+1] = {building:GetIndex(), GetColor(building, weapon)}
		end
	end
end

---@param weapon boolean
---@param outTable table
local function GetChristmasBalls(outTable, weapon)
	for _, ball in pairs (entities.FindByClass("CPhysicsProp")) do
		if models.GetModelName(ball:GetModel()) == "models/props_gameplay/ball001.mdl" then
			outTable[#outTable+1] = {ball:GetIndex(), GetColor(ball, weapon)}
		end
	end
end

--[[ flags
	Enabled: 		0
	Players = 		1
	Weapons = 		2
	Sentries = 		3
	Dispensers = 		4
	Teleporters = 		5
	ChristmasBall = 	6
	MedKit / Ammo = 	7
	ViewModel = 		8
]]

--- call in DoPostScreenSpaceEffects
---@param settings Settings
function lib.Run(settings)
	if engine.IsTakingScreenshot() then
		return
	end

	if clientstate.GetClientSignonState() <= E_SignonState.SIGNONSTATE_SPAWN then
		return
	end

	if clientstate.GetNetChannel() == nil then
		return
	end

	local flags = settings.glow.flags
	local enabled = flags & (1 << 0) ~= 0

	if enabled == false then
		return
	end

	if settings.glow.blurriness == 0 and settings.glow.stencil == 0 then
		return
	end

	InitMaterials()

	local glowEnts = {}

	local players = flags & (1 << 1) ~= 0
	local weapon = flags & (1 << 2) ~= 0
	local sentries = flags & (1 << 3) ~= 0
	local dispensers = flags & (1 << 4) ~= 0
	local teleporters = flags & (1 << 5) ~= 0
	local christmasball = flags & (1 << 6) ~= 0
	local medammo = flags & (1 << 7) ~= 0
	local viewmodel = flags & (1 << 8) ~= 0

	if sentries then GetClass("CObjectSentrygun", glowEnts, weapon) end
	if dispensers then GetClass("CObjectDispenser", glowEnts, weapon) end
	if teleporters then GetClass("CObjectTeleporter", glowEnts, weapon) end
	if medammo then GetClass("CBaseAnimating", glowEnts, weapon) end
	if players then GetPlayers(glowEnts, weapon) end

	if viewmodel then
		local plocal = entities.GetLocalPlayer()
		if plocal and plocal:GetPropBool("m_nForceTauntCam") == false and plocal:InCond(E_TFCOND.TFCond_Taunting) == false then
			local _, _, cvar = client.GetConVar("cl_first_person_uses_world_model")
			if cvar == "0" then
				GetClass("CTFViewModel", glowEnts, weapon)
			end
		end
	end

	if christmasball then GetChristmasBalls(glowEnts, weapon) end

	if #glowEnts == 0 then
		return
	end

	local w, h = draw.GetScreenSize()

	--- Stencil Pass
	do
		render.SetStencilEnable(true)

		render.ForcedMaterialOverride(m_pMatGlowColor)
		local savedBlend = render.GetBlend()
		render.SetBlend(0)

		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(E_StencilComparisonFunction.STENCILCOMPARISONFUNCTION_ALWAYS)
		render.SetStencilPassOperation(E_StencilOperation.STENCILOPERATION_REPLACE)
		render.SetStencilFailOperation(E_StencilOperation.STENCILOPERATION_KEEP)
		render.SetStencilZFailOperation(E_StencilOperation.STENCILOPERATION_REPLACE)

		DrawEntities(glowEnts)

		render.SetBlend(savedBlend)
		render.ForcedMaterialOverride(nil)
		render.SetStencilEnable(false)
	end

	--- Color pass
	do
		render.PushRenderTargetAndViewport()

		local r, g, b = render.GetColorModulation()

		local savedBlend = render.GetBlend()
		render.SetBlend(1.0)

		render.SetRenderTarget(m_pGlowBuffer1)
		render.Viewport(0, 0, w, h)

		render.ClearColor3ub(0, 0, 0)
		render.ClearBuffers(true, false, false)

		render.ForcedMaterialOverride(m_pMatGlowColor)

		DrawEntities(glowEnts)

		render.ForcedMaterialOverride(nil)
		render.SetColorModulation(r, g, b)
		render.SetBlend(savedBlend)

		render.PopRenderTargetAndViewport()
	end

	--- Blur pass
	if settings.glow.blurriness > 0 then
		render.PushRenderTargetAndViewport()
		render.Viewport(0, 0, w, h)

		-- More blur iterations = blurrier (does this word exist?) glow
		for i = 1, settings.glow.blurriness do
			render.SetRenderTarget(m_pGlowBuffer2)
			render.DrawScreenSpaceRectangle(m_pMatBlurX, 0, 0, w, h, 0, 0, w - 1, h - 1, w, h)
			render.SetRenderTarget(m_pGlowBuffer1)
			render.DrawScreenSpaceRectangle(m_pMatBlurY, 0, 0, w, h, 0, 0, w - 1, h - 1, w, h)
		end

		render.PopRenderTargetAndViewport()
	end

	--- Final pass
	do
		render.SetStencilEnable(true)
		render.SetStencilWriteMask(0)
		render.SetStencilTestMask(0xFF)

		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(E_StencilComparisonFunction.STENCILCOMPARISONFUNCTION_NOTEQUAL)

		render.SetStencilPassOperation(E_StencilOperation.STENCILOPERATION_KEEP)
		render.SetStencilFailOperation(E_StencilOperation.STENCILOPERATION_KEEP)
		render.SetStencilZFailOperation(E_StencilOperation.STENCILOPERATION_KEEP)

		--- my code to make the glow work
		--- not used anymore :(
		--[[render.DrawScreenSpaceRectangle(
			m_pMatHaloAddToScreen,
			0, 0,
			w, h,
			0, 0,
			w - 1, h - 1,
			w, h
		)]]

		--- pasted from amalgam
		--- https://github.com/rei-2/Amalgam/blob/fce4740bf3af0799064bf6c8fbeaa985151b708c/Amalgam/src/Features/Visuals/Glow/Glow.cpp#L65
		if settings.glow.stencil > 0 then
			local iSide = (settings.glow.stencil + 1) // 2
			render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, -iSide, 0, w, h, 0, 0, w - 1, h - 1, w, h);
			render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, 0, -iSide, w, h, 0, 0, w - 1, h - 1, w, h);
			render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, iSide, 0, w, h, 0, 0, w - 1, h - 1, w, h);
			render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, 0, iSide, w, h, 0, 0, w - 1, h - 1, w, h);
			local iCorner = settings.glow.stencil // 2
			if (iCorner > 0) then
				render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, -iCorner, -iCorner, w, h, 0, 0, w - 1, h - 1, w, h);
				render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, iCorner, iCorner, w, h, 0, 0, w - 1, h - 1, w, h);
				render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, iCorner, -iCorner, w, h, 0, 0, w - 1, h - 1, w, h);
				render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, -iCorner, iCorner, w, h, 0, 0, w - 1, h - 1, w, h);
			end
		end

		if settings.glow.blurriness > 0 then
			render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, 0, 0, w, h, 0, 0, w - 1, h - 1, w, h);
		end

		render.SetStencilEnable(false)
	end
end

return lib