ChilaSedaAccessibleActions = ChilaSedaAccessibleActions or {}

function ChilaSedaAccessibleActions.isModActive(modId)
	if type(modId) ~= "string" or type(getActivatedMods) ~= "function" then
		return false
	end
	local ok, activeMods = pcall(getActivatedMods)
	if not ok or not activeMods then return false end
	if type(activeMods) == "table" then
		for _, activeId in ipairs(activeMods) do
			if tostring(activeId) == modId then return true end
		end
		return false
	end
	local okSize, size = pcall(function() return activeMods:size() end)
	if not okSize or type(size) ~= "number" then return false end
	for index = 0, size - 1 do
		local okId, activeId = pcall(function() return activeMods:get(index) end)
		if okId and tostring(activeId) == modId then return true end
	end
	return false
end
