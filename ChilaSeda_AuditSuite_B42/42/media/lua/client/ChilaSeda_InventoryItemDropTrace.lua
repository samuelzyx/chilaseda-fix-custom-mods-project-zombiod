-- Bounded, read-only trace for items transferred between Jill's inventory and the floor.
local PREFIX = "[ChilaSeda_InventoryItemDropTrace]"
local TRACE_ENABLED = true
local MAX_TRACE_LINES = 192
local MAX_CALLER_TRACES = 8
local MAX_CARRIED_ITEMS = 2000
local MAX_CONTAINER_DEPTH = 6
local traceLines = 0
local traceEvents = 0
local callerTraces = 0
local limitLogged = false
local missingApiLogged = false

local function safeMethod(object, methodName, ...)
	if object == nil then return nil end
	local args = { ... }
	local unpackValues = table.unpack or unpack
	local ok, value = pcall(function()
		local method = object[methodName]
		if type(method) ~= "function" then return nil end
		return method(object, unpackValues(args))
	end)
	return ok and value or nil
end

local function trace(message)
	if not TRACE_ENABLED then return end
	if traceLines >= MAX_TRACE_LINES then
		if not limitLogged then
			limitLogged = true
			print(PREFIX .. " capped=1 lines=" .. tostring(traceLines))
		end
		return
	end
	traceLines = traceLines + 1
	print(PREFIX .. " event=" .. tostring(message))
end

local function globalValue(name)
	if type(_G) ~= "table" then return nil end
	local ok, value = pcall(function() return _G[name] end)
	return ok and value or nil
end

local function itemField(item, methodName, fallback)
	local value = safeMethod(item, methodName)
	if value == nil and item then
		local ok, field = pcall(function() return item[fallback] end)
		if ok then value = field end
	end
	if value == nil then return "na" end
	return tostring(value):gsub("[%c|,]", "_")
end

local function containerType(container)
	if container == nil then return "none" end
	local value = safeMethod(container, "getType")
	if value == nil then value = safeMethod(container, "getName") end
	return value == nil and "unknown" or tostring(value):gsub("[%c|,]", "_")
end

local function itemType(item)
	return itemField(item, "getFullType", "fullType")
end

local function itemId(item)
	return itemField(item, "getID", "id")
end

local function forEachItem(items, callback)
	if items == nil then return end
	local size = safeMethod(items, "size")
	if type(size) == "number" then
		for index = 0, size - 1 do
			local item = safeMethod(items, "get", index)
			if item ~= nil then callback(item) end
		end
		return
	end
	if type(items) == "table" then
		for _, item in pairs(items) do callback(item) end
	end
end

local function carriedItemCount(player)
	local root = safeMethod(player, "getInventory")
	if root == nil then return "na" end
	local seenContainers = {}
	local total = 0
	local truncated = false
	local function visit(container, depth)
		if container == nil or depth > MAX_CONTAINER_DEPTH or seenContainers[container] then return end
		seenContainers[container] = true
		local items = safeMethod(container, "getItems")
		forEachItem(items, function(item)
			if total >= MAX_CARRIED_ITEMS then
				truncated = true
				return
			end
			total = total + 1
			visit(safeMethod(item, "getItemContainer"), depth + 1)
		end)
	end
	visit(root, 0)
	return tostring(total) .. (truncated and "+" or "")
end

local function traceCaller()
	if callerTraces >= MAX_CALLER_TRACES then return "cap" end
	callerTraces = callerTraces + 1
	local frames = {}
	local source = "LuaManager"
	local java = globalValue("luajava")
	local bindClass = java and java.bindClass
	local manager
	if type(bindClass) == "function" then
		local ok, value = pcall(bindClass, "zombie.Lua.LuaManager")
		if ok then manager = value end
	end
	local stackGetter = manager and manager.getLuaStackTraceStrings
	if type(stackGetter) == "function" then
		local ok, stack = pcall(stackGetter, nil)
		if ok and stack ~= nil then
			local count = type(stack) == "table" and #stack or safeMethod(stack, "size")
			if type(count) == "number" then
				for index = 1, math.min(count, 16) do
					local frame = type(stack) == "table" and stack[index] or safeMethod(stack, "get", index - 1)
					if frame ~= nil then
						local compact = tostring(frame):gsub("[%c|]", "|")
						if not compact:find("ChilaSeda_InventoryItemDropTrace", 1, true)
							and compact:find("%.lua:%d+") then
							compact = compact:match("([^/\\]+%.lua:%d+") or compact
							frames[#frames + 1] = compact
							if #frames >= 5 then break end
						end
					end
				end
			end
		end
	end
	if #frames == 0 then
		source = "debug.traceback"
		local debugLibrary = globalValue("debug")
		if debugLibrary and type(debugLibrary.traceback) == "function" then
			local ok, value = pcall(debugLibrary.traceback, "", 3)
			if ok and value ~= nil then
				for frame in tostring(value):gmatch("[^\r\n]+") do
					local compact = frame:gsub("[%c|]", "|")
					if compact:find("%.lua:%d+") then
						compact = compact:match("([^/\\]+%.lua:%d+") or compact
						frames[#frames + 1] = compact
						if #frames >= 5 then break end
					end
				end
			end
		end
	end
	if #frames == 0 then return "unavailable:lua-stack-api" end
	return (source .. ":" .. table.concat(frames, ">")):sub(1, 420)
end

local function unpackResults(values)
	local unpackValues = table.unpack or unpack
	return unpackValues(values, 1, values.n)
end

local function packResults(...)
	return { n = select("#", ...), ... }
end

local function playerFor(player, playerNum)
	if player ~= nil then return player end
	if type(getSpecificPlayer) ~= "function" then return nil end
	local ok, value = pcall(getSpecificPlayer, tonumber(playerNum) or 0)
	return ok and value or nil
end

local function itemSummary(item)
	return "item=" .. itemType(item) .. " id=" .. itemId(item)
		.. " source=" .. containerType(safeMethod(item, "getContainer"))
end

local function floorTransfer(self, player, item, sourceContainer, destinationContainer, ...)
	local sourceType = containerType(sourceContainer)
	local destinationType = containerType(destinationContainer)
	local relevant = sourceType == "floor" or destinationType == "floor"
	if not relevant then
		return self.__chilaOriginalTransferItem(self, player, item, sourceContainer, destinationContainer, ...)
	end
	local before = carriedItemCount(player)
	local caller = destinationType == "floor" and traceCaller() or "not-a-drop"
	trace("transfer phase=before direction=" .. (sourceType == "floor" and "pickup" or "drop")
		.. " " .. itemSummary(item) .. " destination=" .. destinationType
		.. " carriedItems=" .. before .. " player=" .. tostring(player ~= nil)
		.. " caller=" .. caller)
	local results = packResults(self.__chilaOriginalTransferItem(
		self, player, item, sourceContainer, destinationContainer, ...))
	local after = carriedItemCount(player)
	trace("transfer phase=after direction=" .. (sourceType == "floor" and "pickup" or "drop")
		.. " item=" .. itemType(item) .. " id=" .. itemId(item)
		.. " source=" .. sourceType .. " destination=" .. destinationType
		.. " carriedBefore=" .. before .. " carriedAfter=" .. after
		.. " itemContainerAfter=" .. containerType(safeMethod(item, "getContainer")))
	return unpackResults(results)
end

local function installTransferTrace()
	local actionClass = globalValue("ISTransferAction")
	if type(actionClass) ~= "table" or type(actionClass.transferItem) ~= "function" then
		local ok, loaded = pcall(require, "TimedActions/ISTransferAction")
		actionClass = globalValue("ISTransferAction")
			or (ok and type(loaded) == "table" and loaded or nil)
	end
	if type(actionClass) ~= "table" or type(actionClass.transferItem) ~= "function" then
		if not missingApiLogged then
			missingApiLogged = true
			trace("install fallback=ISTransferAction.transferItem unavailable")
		end
		return false
	end
	if actionClass.__ChilaSedaInventoryItemDropTrace then return true end
	actionClass.__chilaOriginalTransferItem = actionClass.transferItem
	actionClass.transferItem = floorTransfer
	actionClass.__ChilaSedaInventoryItemDropTrace = true
	trace("install hook=ISTransferAction.transferItem readOnly=1")
	return true
end

local function installDropActionTrace()
	local actionClass = globalValue("ISDropItemAction")
	if type(actionClass) ~= "table" or type(actionClass.perform) ~= "function" then
		local ok, loaded = pcall(require, "TimedActions/ISDropItemAction")
		actionClass = globalValue("ISDropItemAction")
			or (ok and type(loaded) == "table" and loaded or nil)
	end
	if type(actionClass) ~= "table" or type(actionClass.perform) ~= "function"
			or actionClass.__ChilaSedaInventoryItemDropTrace then return false end
	local original = actionClass.perform
	actionClass.perform = function(self, ...)
		local player = self and self.character
		local item = self and self.item
		local before = carriedItemCount(player)
		trace("drop-action phase=before " .. itemSummary(item)
			.. " carriedItems=" .. before .. " caller=" .. traceCaller())
		local results = packResults(original(self, ...))
		trace("drop-action phase=after item=" .. itemType(item)
			.. " id=" .. itemId(item) .. " carriedBefore=" .. before
			.. " carriedAfter=" .. carriedItemCount(player)
			.. " itemContainerAfter=" .. containerType(safeMethod(item, "getContainer")))
		return unpackResults(results)
	end
	actionClass.__ChilaSedaInventoryItemDropTrace = true
	trace("install hook=ISDropItemAction.perform readOnly=1")
	return true
end

local function installDropRequestTrace()
	local menu = globalValue("ISInventoryPaneContextMenu")
	if type(menu) ~= "table" or type(menu.dropItem) ~= "function" then
		local ok, loaded = pcall(require, "ISUI/ISInventoryPaneContextMenu")
		menu = globalValue("ISInventoryPaneContextMenu")
			or (ok and type(loaded) == "table" and loaded or nil)
	end
	if type(menu) ~= "table" or type(menu.dropItem) ~= "function"
			or menu.__ChilaSedaInventoryItemDropTrace then return false end
	local original = menu.dropItem
	menu.dropItem = function(item, playerNum, ...)
		local player = playerFor(nil, playerNum)
		trace("drop-request phase=queue " .. itemSummary(item)
			.. " playerNum=" .. tostring(playerNum)
			.. " carriedItems=" .. carriedItemCount(player)
			.. " caller=" .. traceCaller())
		return original(item, playerNum, ...)
	end
	menu.__ChilaSedaInventoryItemDropTrace = true
	trace("install hook=ISInventoryPaneContextMenu.dropItem readOnly=1")
	return true
end

local function install()
	local transferReady = installTransferTrace()
	local dropActionReady = installDropActionTrace()
	local dropRequestReady = installDropRequestTrace()
	return transferReady or dropActionReady or dropRequestReady
end

if Events then
	if Events.OnGameBoot and type(Events.OnGameBoot.Add) == "function" then Events.OnGameBoot.Add(install) end
	if Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then Events.OnGameStart.Add(install) end
end
install()
print(PREFIX .. " loaded readOnly=1 maxEvents=" .. tostring(MAX_TRACE_LINES)
	.. " maxCarriedItems=" .. tostring(MAX_CARRIED_ITEMS))
