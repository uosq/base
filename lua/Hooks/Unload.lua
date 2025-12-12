local function Unload()
	print("Unloaded!")
end

callbacks.Register("Unload", Unload)