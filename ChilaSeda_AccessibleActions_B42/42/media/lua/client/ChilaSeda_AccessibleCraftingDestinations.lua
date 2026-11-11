require "TimedActions/ISCraftAction"

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
	if not item or not playerObj then return end
	local inventory = playerObj:getInventory()
	local square = playerObj:getCurrentSquare()
	if square and inventory:contains(item) then
		inventory:Remove(item)
		square:AddWorldInventoryItem(item,
			playerObj:getX() - math.floor(playerObj:getX()),
			playerObj:getY() - math.floor(playerObj:getY()),
			playerObj:getZ() - math.floor(playerObj:getZ()))
		return true
	end
	return false
end

local function notifyDestination(playerObj, destination)
	if not HaloTextHelper or not HaloTextHelper.addText then return end
	local label = "el suelo"
	if destination == playerObj:getInventory() then
		label = "inventario principal"
	elseif destination then
		local parent = destination.getParent and destination:getParent() or nil
		label = parent and parent.getDisplayName and parent:getDisplayName()
			or (destination.getType and destination:getType()) or "contenedor"
	end
	HaloTextHelper.addText(playerObj, "Fabricado: " .. tostring(label), " ", 255, 220, 120)
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

	for _, item in ipairs(newItems) do
		if inventory:contains(item) then
			local sourceContainer = self.container
			local activeContainer = getActiveContainer(playerObj)
			local moved = false
			local destination
			local destinations = outputDestinations(playerObj, activeContainer, sourceContainer)
			for _, target in ipairs(destinations) do
				if target == inventory or target:contains(item) then
					moved, destination = true, target
					break
				elseif tryMoveToContainer(item, inventory, target, playerObj) then
					moved, destination = true, target
					break
				end
			end

			if not moved and dropToGround(item, playerObj) then
				destination = nil
			end
			notifyDestination(playerObj, destination)
		end
	end

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
			local activeContainer = getActiveContainer(playerObj)
			for i = 0, self.result:size() - 1 do
				local item = self.result:get(i)
				if inventory:contains(item) then
					local moved = false
					for _, target in ipairs(outputDestinations(playerObj, activeContainer)) do
						if target == inventory or target:contains(item)
								or tryMoveToContainer(item, inventory, target, playerObj) then
							moved = true
							break
						end
					end

					if not moved then
						if playerObj:getCurrentSquare() then
							dropToGround(item, playerObj)
						end
					end
				end
			end
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
