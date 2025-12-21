--- I am not smart enough to make this by myself
--- Source: https://www.unknowncheats.me/forum/team-fortress-2-a/700159-simple-glow-outline.html

--- make the lsp stop complaining about nil shit
---@diagnostic disable: param-type-mismatch

local lib = {}

local SDK = require("SDK.sdk")

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
			local color = SDK.GetColor(player)
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

---@param outTable table
---@param className string
local function GetClass(className, outTable)
	for _, building in pairs(entities.FindByClass(className)) do
		if building:ShouldDraw() and building:IsDormant() == false then
			outTable[#outTable+1] = {building:GetIndex(), SDK.GetColor(building)}
		end
	end
end

---@param outTable table
local function GetChristmasBalls(outTable)
	for _, ball in pairs (entities.FindByClass("CPhysicsProp")) do
		if models.GetModelName(ball:GetModel()) == "models/props_gameplay/ball001.mdl" then
			outTable[#outTable+1] = {ball:GetIndex(), SDK.GetColor(ball)}
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

	if settings.glow.enabled == false then
		return
	end

	if settings.glow.blurriness == 0 and settings.glow.stencil == 0 then
		return
	end

	InitMaterials()

	local glowEnts = {}

	local players = SDK.bGetFlag(settings.esp.filter, 0)
	local weapon = SDK.bGetFlag(settings.esp.filter, 1)
	local sentries = SDK.bGetFlag(settings.esp.filter, 2)
	local dispensers = SDK.bGetFlag(settings.esp.filter, 3)
	local teleporters = SDK.bGetFlag(settings.esp.filter, 4)
	local christmasball = SDK.bGetFlag(settings.esp.filter, 5)
	local medammo = SDK.bGetFlag(settings.esp.filter, 6)

	if sentries then GetClass("CObjectSentrygun", glowEnts) end
	if dispensers then GetClass("CObjectDispenser", glowEnts) end
	if teleporters then GetClass("CObjectTeleporter", glowEnts) end
	if medammo then GetClass("CBaseAnimating", glowEnts) end
	if players then GetPlayers(glowEnts, weapon) end

	if christmasball then GetChristmasBalls(glowEnts) end

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