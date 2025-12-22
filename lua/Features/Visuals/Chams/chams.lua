local lib = {}

local SDK = require("SDK.sdk")
local Helper = require("Features.Visuals.Generic.generic")

local bDrawing = false
local drawModels = {}

local STUDIO_RENDER = 0x00000001
local STUDIO_NOSHADOWS = 0x00000080

local mat = materials.Create("vapo", [[UnlitGeneric
{
	$basetexture "white"
}]])

function lib.IsDrawing()
	return bDrawing
end

---@param settings Settings
function lib.DoPostScreenSpaceEffects(settings)
	drawModels = {}

	local targets = Helper:GetTargets(settings)
	if #targets == 0 then
		return
	end

	local r, g, b = render.GetColorModulation()
	local blend = render.GetBlend()
	local znear, zfar = render.GetDepthRange()

	render.ForcedMaterialOverride(mat)
	render.SetBlend(settings.visuals.chams.alpha/100)

	if settings.visuals.chams.always then
		render.DepthRange(0, 0.2)
	end

	for _, player in pairs (targets) do
		if player:ShouldDraw() then
			bDrawing = true
			local color = SDK.GetColor(player)
			render.SetColorModulation(color[1], color[2], color[3])

			drawModels[player:GetIndex()] = true
			player:DrawModel(STUDIO_RENDER | STUDIO_NOSHADOWS)

			local child = player:GetMoveChild()
			while child do
				drawModels[child:GetIndex()] = true
				color = SDK.GetColor(child)
				render.SetColorModulation(color[1], color[2], color[3])
				child:DrawModel(STUDIO_RENDER | STUDIO_NOSHADOWS)
				child = child:GetMovePeer()
			end

			bDrawing = false
		end
	end

	render.SetColorModulation(r, g, b)
	render.SetBlend(blend)
	render.ForcedMaterialOverride(nil)
	render.DepthRange(znear, zfar)
end

---@param ctx DrawModelContext
function lib.DrawModel(ctx)
	local ent = ctx:GetEntity()
	if not ent or not drawModels[ent:GetIndex()] then
		return
	end

	if ctx:IsDrawingGlow() or ctx:IsDrawingAntiAim() or ctx:IsDrawingBackTrack() then
		return
	end

	if not bDrawing then
		ctx:SetAlphaModulation(0)
	end
end

return lib