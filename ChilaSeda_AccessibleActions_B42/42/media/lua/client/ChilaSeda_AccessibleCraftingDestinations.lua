require "TimedActions/ISCraftAction"
require "TimedActions/ISInventoryTransferAction"

local function getActiveContainer(playerObj)
	if not playerObj then return nil end
	local pane = ISInventoryPane and ISInventoryPane.getInventoryPane and ISInventoryPane.getInventoryPane(playerObj:getPlayerNum())
	if not pane or not pane.selected then return nil end
	return pane.selected
end

local function outputDestinations(playerObj, preferred, source)
	local inventory = playerObj and playerObj:getInventory()
	local destinations, seen = {}, {}
	local function add(container)
		if container and type(container.getType) == "function"
				and container:getType() == "floor" then return end
		if container and not seen[container] then
			seen[container] = true
			destinations[#destinations + 1] = container
		end
	end
	add(preferred)
	local function addNested(container)
		if not container or type(container.getItems) ~= "function" then return end
		local items = container:getItems()
		if not items then return end
		for i = 0, items:size() - 1 do
			local item = items:get(i)
			if item and instanceof(item, "InventoryContainer") then
				local nested = item:getInventory()
				add(nested)
				addNested(nested)
			end
		end
	end
	addNested(inventory)
	add(source)
	add(inventory)
	return destinations, inventory
end

local function tryMoveToContainer(item, sourceContainer, targetContainer, playerObj)
	if not item or not targetContainer or targetContainer == playerObj:getInventory() then return false end
	local inventory = playerObj:getInventory()
	if inventory:contains(item) then
		local transfer = ISInventoryTransferAction:new(playerObj, item, inventory, targetContainer, nil)
		if transfer:isValid() then
			transfer:transferItem(item)
			return targetContainer:contains(item)
		end
	end
	return false
end

local function dropToGround(item, playerObj)
	if not item or not playerObj then return false end
	local inventory = playerObj:getInventory()
	local square = playerObj:getCurrentSquare()
	if not square or not inventory:contains(item) then return false end
	local okRemove = pcall(inventory.Remove, inventory, item)
	if not okRemove or inventory:contains(item) then return false end
	if type(sendRemoveItemFromContainer) == "function" then
		sendRemoveItemFromContainer(inventory, item)
	end
	local okDrop, worldItem = pcall(square.AddWorldInventoryItem, square, item,
		playerObj:getX() - math.floor(playerObj:getX()),
		playerObj:getY() - math.floor(playerObj:getY()),
		playerObj:getZ() - math.floor(playerObj:getZ()))
	local okWorldObject, worldObject = pcall(item.getWorldItem, item)
	if okDrop and worldItem and not inventory:contains(item) and okWorldObject and worldObject then
		return true
	end
	pcall(inventory.AddItem, inventory, item)
	if type(sendAddItemToContainer) == "function" and inventory:contains(item) then
		sendAddItemToContainer(inventory, item)
	end
	return false
end

local function dropCraftOutputToGround(item, playerObj)
	if not item or not playerObj then return false end
	local source = item:getContainer()
	local square = playerObj:getCurrentSquare()
	if not square or not source or not source:contains(item) then return false end
	local okRemove = pcall(source.Remove, source, item)
	if not okRemove or source:contains(item) then return false end
	if type(sendRemoveItemFromContainer) == "function" then
		sendRemoveItemFromContainer(source, item)
	end
	local okDrop, worldItem = pcall(square.AddWorldInventoryItem, square, item,
		playerObj:getX() - math.floor(playerObj:getX()),
		playerObj:getY() - math.floor(playerObj:getY()),
		playerObj:getZ() - math.floor(playerObj:getZ()))
	local okWorldObject, worldObject = pcall(item.getWorldItem, item)
	if okDrop and worldItem and not source:contains(item) and okWorldObject and worldObject then
		return true
	end
	pcall(source.AddItem, source, item)
	if type(sendAddItemToContainer) == "function" and source:contains(item) then
		sendAddItemToContainer(source, item)
	end
	return false
end

local function canStoreCraftOutput(container, playerObj, item)
	if not container or not playerObj or not item then return false end
	local ok, fits = pcall(function()
		if not container:isItemAllowed(item) then return false end
		local currentWeight = container:getCapacityWeight()
		local capacity = container:getEffectiveCapacity(playerObj)
		if container:contains(item) then return currentWeight <= capacity end
		return container:hasRoomFor(playerObj, item)
			and currentWeight + item:getUnequippedWeight() <= capacity
	end)
	return ok and fits == true
end

local function tryTransferCraftOutput(playerObj, item, source, target)
	if not playerObj or not item or not source or not target then return false end
	if source == target then return target:contains(item) end
	local ok, moved = pcall(function()
		local transfer = ISInventoryTransferAction:new(playerObj, item, source, target, nil)
		if not transfer or not transfer:isValid() then return false end
		transfer:transferItem(item)
		return target:contains(item)
	end)
	return ok and moved == true
end

local function routeCraftOutput(playerObj, item)
	if not playerObj or not item then return "failed" end
	local main = playerObj:getInventory()
	local source = item:getContainer()
	if not main or not source then return "failed" end

	local selected = getActiveContainer(playerObj)
	if selected == main or (selected and type(selected.getType) == "function"
			and selected:getType() == "floor") then
		selected = nil
	end
	if selected then
		if source == selected or selected:contains(item) then return "selected" end
		if canStoreCraftOutput(selected, playerObj, item)
				and tryTransferCraftOutput(playerObj, item, source, selected) then
			return "selected"
		end
	end

	if source == main or main:contains(item) then
		if canStoreCraftOutput(main, playerObj, item) then return "main" end
	elseif canStoreCraftOutput(main, playerObj, item)
			and tryTransferCraftOutput(playerObj, item, source, main) then
		return "main"
	end

	return dropCraftOutputToGround(item, playerObj) and "floor" or "failed"
end

ChilaSedaRouteCraftingOutput = routeCraftOutput

local function notifyOutputDestinations(playerObj, label, counts)
	if not HaloTextHelper or not HaloTextHelper.addText then return end
	local destinations = {}
	if counts.selected > 0 then destinations[#destinations + 1] = counts.selected .. " mochila seleccionada" end
	if counts.main > 0 then destinations[#destinations + 1] = counts.main .. " inventario principal" end
	if counts.floor > 0 then destinations[#destinations + 1] = counts.floor .. " piso" end
	if counts.failed > 0 then destinations[#destinations + 1] = counts.failed .. " sin destino" end
	local message = #destinations > 0 and (label .. ": " .. table.concat(destinations, ", ")) or nil
	if message then pcall(HaloTextHelper.addText, playerObj, message, " ", 255, 220, 120) end
end

local function notifyFloorResult(playerObj, label, dropped, failed)
	if not HaloTextHelper or not HaloTextHelper.addText then return end
	local message
	if dropped > 0 and failed == 0 then
		message = label .. ": objetos en el piso"
	elseif dropped > 0 then
		message = label .. ": algunos objetos quedaron en inventario"
	elseif failed > 0 then
		message = label .. ": no se pudieron soltar objetos"
	end
	if message then pcall(HaloTextHelper.addText, playerObj, message, " ", 255, 220, 120) end
end

local originalCraftComplete = ISCraftAction.complete
function ISCraftAction:complete()
	local result = originalCraftComplete(self)

	if not self.result or not self.character then return result end

	local playerObj = self.character
	local inventory = playerObj:getInventory()
	local newItems = {}

	if self.result:size() then
		for i = 0, self.result:size() - 1 do
			newItems[#newItems + 1] = self.result:get(i)
		end
	else
		newItems[#newItems + 1] = self.result
	end

	local counts = { selected = 0, main = 0, floor = 0, failed = 0 }
	for _, item in ipairs(newItems) do
		if inventory:contains(item) then
			local destination = routeCraftOutput(playerObj, item)
			counts[destination] = counts[destination] + 1
		end
	end
	notifyOutputDestinations(playerObj, "Fabricacion", counts)

	return result
end

local originalRepairComplete = ISRepairAction and ISRepairAction.complete
if originalRepairComplete then
	function ISRepairAction:complete()
		local result = originalRepairComplete(self)
		local playerObj = self.character
		local inventory = playerObj:getInventory()

		if self.item and inventory:contains(self.item) then
			local sourceContainer = self.item:getContainer()
			local activeContainer = getActiveContainer(playerObj)
			local moved = false
			local destinations = outputDestinations(playerObj, activeContainer, sourceContainer)
			for _, target in ipairs(destinations) do
				if target == inventory or target:contains(self.item)
						or tryMoveToContainer(self.item, inventory, target, playerObj) then
					moved = true
					break
				end
			end

			if not moved then
				if playerObj:getCurrentSquare() then
					dropToGround(self.item, playerObj)
				end
			end
		end

		return result
	end
end

local originalDismantleComplete = ISMoveablesAction and ISMoveablesAction.complete
if originalDismantleComplete then
	function ISMoveablesAction:complete()
		local result = originalDismantleComplete(self)
		local playerObj = self.character
		local inventory = playerObj:getInventory()

		if self.result and self.result:size() then
			local dropped, failed = 0, 0
			for i = 0, self.result:size() - 1 do
				local item = self.result:get(i)
				if inventory:contains(item) then
					if dropToGround(item, playerObj) then dropped = dropped + 1
					else failed = failed + 1 end
				end
			end
			notifyFloorResult(playerObj, "Desmantelado", dropped, failed)
		end

		return result
	end
end

local originalConsumeComplete = ISConsumeAction and ISConsumeAction.complete
if originalConsumeComplete then
function ISConsumeAction:complete()
	local result = originalConsumeComplete(self)
	local playerObj = self.character

	if self.container and playerObj then
		local inventory = playerObj:getInventory()

		if self.resultContainer and inventory:contains(self.resultContainer) then
			local sourceContainer = self.container
			local activeContainer = getActiveContainer(playerObj)
			local moved = false
			for _, target in ipairs(outputDestinations(playerObj, activeContainer, sourceContainer)) do
				if target == inventory or target:contains(self.resultContainer)
						or tryMoveToContainer(self.resultContainer, inventory, target, playerObj) then
					moved = true
					break
				end
			end

			if not moved then
				if playerObj:getCurrentSquare() then
					dropToGround(self.resultContainer, playerObj)
				end
			end
		end
	end

	return result
end
end
