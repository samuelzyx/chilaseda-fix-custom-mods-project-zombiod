local FireTransfers = {}

local callbacks = {
	"onLightFromLiterature",
	"onLightFromKindle",
	"onLightFromPetrol",
}

local activePlayer = nil
local activeCallback = nil
local MAX_TRACE_LINES = 32
local traceLines = 0

function FireTransfers.install(menu)
	if type(menu) ~= "table" then return 0 end
	local installed = 0
	for _, callbackName in ipairs(callbacks) do
		local original = menu[callbackName]
		local marker = callbackName .. "_ChilaSedaFireTransferWrapped"
		if type(original) == "function" and not menu[marker] then
			menu[callbackName] = function(player, ...)
				local previousPlayer = activePlayer
				local previousCallback = activeCallback
				activePlayer = player
				activeCallback = callbackName
				local ok, result = pcall(original, player, ...)
				activePlayer = previousPlayer
				activeCallback = previousCallback
				if not ok then error(result) end
				return result
			end
			menu[marker] = true
			installed = installed + 1
		end
	end
	return installed
end

function FireTransfers.callbackFor(player, source, destination, main)
	if not activeCallback or player ~= activePlayer or not source or destination ~= main then
		return nil
	end
	if source:getOutermostContainer() == main then return nil end
	return activeCallback
end

function FireTransfers.trace(callbackName, item, source)
	if traceLines >= MAX_TRACE_LINES then return end
	traceLines = traceLines + 1
	local itemType = "unknown"
	local sourceType = "unknown"
	if item and item.getFullType then
		local ok, value = pcall(item.getFullType, item)
		if ok and value then itemType = tostring(value) end
	end
	if source and source.getType then
		local ok, value = pcall(source.getType, source)
		if ok and value then sourceType = tostring(value) end
	end
	print("[ChilaSeda_ViewpointSelectedContainer] fire-input-main callback="
		.. tostring(callbackName) .. " item=" .. itemType .. " source=" .. sourceType)
end

return FireTransfers
