require "TimedActions/ISInventoryTransferAction"

local function call(method, object, ...)
	if not object or type(object[method]) ~= "function" then return nil end
	local ok, result = pcall(object[method], object, ...)
	if ok then return result end
	return nil
end

local function isKey(item)
	if not item or type(instanceof) ~= "function" then return false end
	local ok, result = pcall(instanceof, item, "Key")
	return ok and result == true
end

local function isKeyRing(item)
	if not item then return false end
	if call("getType", item) == "KeyRing" then return true end
	return ItemTag and ItemTag.KEY_RING and call("hasTag", item, ItemTag.KEY_RING) == true
end

local function findKeyRing(container, character, key, depth, visited)
	if not container or depth > 6 or visited[container] then return nil end
	visited[container] = true
	local items = call("getItems", container)
	if not items or type(items.size) ~= "function" then return nil end
	local okSize, size = pcall(items.size, items)
	if not okSize or type(size) ~= "number" then return nil end

	for index = 0, size - 1 do
		local okItem, item = pcall(items.get, items, index)
		if okItem and item then
			if isKeyRing(item) then
				local ringInventory = call("getInventory", item)
				local allowed = call("isItemAllowed", ringInventory, key)
				local hasRoom = call("hasRoomFor", ringInventory, character, key)
				if ringInventory and allowed == true and hasRoom == true then
					return ringInventory
				end
			end
			local nested = call("getInventory", item)
				or call("getItemContainer", item)
			local result = findKeyRing(nested, character, key, depth + 1, visited)
			if result then return result end
		end
	end
	return nil
end

local function install()
	if not ISInventoryTransferAction or not ISInventoryTransferAction.new
		or ISInventoryTransferAction._ChilaSedaKeyRingRoutingWrapped then return end

	local originalNew = ISInventoryTransferAction.new
	ISInventoryTransferAction.new = function(self, character, item, sourceContainer, destinationContainer, time)
		if isKey(item) and character and sourceContainer and destinationContainer then
			local sourceIsCarried = call("isInCharacterInventory", sourceContainer, character)
			local destinationIsCarried = destinationContainer == call("getInventory", character)
				or call("isInCharacterInventory", destinationContainer, character) == true
			if sourceIsCarried == false and destinationIsCarried then
				local playerInventory = call("getInventory", character)
				local visited = {}
				local ringInventory = findKeyRing(destinationContainer, character, item, 0, visited)
					or findKeyRing(playerInventory, character, item, 0, visited)
				if ringInventory then destinationContainer = ringInventory end
			end
		end
		return originalNew(self, character, item, sourceContainer, destinationContainer, time)
	end
	ISInventoryTransferAction._ChilaSedaKeyRingRoutingWrapped = true
	print("[ChilaSeda_AccessibleKeyRingRouting] installed; external key pickups prefer carried key rings")
end

Events.OnGameBoot.Add(install)
install()
