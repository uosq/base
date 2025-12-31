--- Unused
--- Have to find another way of making this work

---@param view ViewSetup
local function RenderView(view)
	for _, vm in pairs (entities.FindByClass("CTFViewModel")) do
		vm:SetAbsAngles(Vector3())
		vm:SetVAngles(Vector3())
	end
end

callbacks.Register("RenderView", RenderView)