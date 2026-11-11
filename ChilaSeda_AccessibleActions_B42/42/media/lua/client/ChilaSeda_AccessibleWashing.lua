require "ISUI/ISWorldObjectContextMenu"
require "ISUI/ISInventoryPaneContextMenu"
require "TimedActions/ISCleanBandage"
require "TimedActions/ISInventoryTransferAction"

local function collectItemsFromContainer(container, fullType, limit)
	local found = container:getAllEvalRecurse(function(item)
		return item:getFullType() == fullType
	end)
	local result = {}
	for i = 0, found:size() - 1 do
		result[#result + 1] = found:get(i)
		if #result >= limit then
			break
		end
	end
	return result
end

local function getAccessibleContainers(playerObj)
	local ok, containers = pcall(ISInventoryPaneContextMenu.getContainers, playerObj)
	return ok and containers or nil
end

local function collectAccessibleItems(playerObj, fullType, limit, includePlayerInventory)
	local result = {}
	local seen = {}
	local playerInventory = playerObj:getInventory()
	local function addItem(item)
		if not item or seen[item] or #result >= limit then return end
		seen[item] = true
		result[#result + 1] = item
	end
	local function addFrom(container)
		if not container or #result >= limit then return end
		for _, item in ipairs(collectItemsFromContainer(container, fullType, limit - #result)) do
			addItem(item)
		end
	end
	if includePlayerInventory then
		addFrom(playerInventory)
	else
		-- Scan the live inventory tree even when the main inventory itself is not
		-- part of this menu. Keep only items inside a secondary container.
		for _, item in ipairs(collectItemsFromContainer(playerInventory, fullType, math.huge)) do
			if item:getContainer() ~= playerInventory then addItem(item) end
		end
	end
	local containers = getAccessibleContainers(playerObj)
	if containers then
		for i = 0, containers:size() - 1 do
			addFrom(containers:get(i))
			if #result >= limit then break end
		end
	end
	return result
end

local function getItemIcon(fullType)
	local scriptItem = getScriptManager():FindItem(fullType)
	return scriptItem and scriptItem:getNormalTexture() or nil
end

local function positionAfterEquipSecondary(context, option)
	local options = context.options
	if type(options) ~= "table" then return end
	local handLabels = {
		[getText("ContextMenu_Equip_Primary")] = true,
		[getText("ContextMenu_Equip_Secondary")] = true,
		[getText("ContextMenu_Equip_Two_Hands")] = true,
	}
	local optionIndex, insertAfter
	for index, entry in ipairs(options) do
		if entry == option then optionIndex = index end
		if entry ~= option and handLabels[entry.name] then insertAfter = index end
	end
	if not insertAfter then
		-- Water-source menus have no equipment entries; stay near their initial actions.
		for index, entry in ipairs(options) do
			if entry ~= option and (entry.name == getText("ContextMenu_Drink")
				or entry.name == getText("ContextMenu_Fill")
				or entry.name == getText("ContextMenu_Wash")) then
				insertAfter = index
			end
		end
	end
	if optionIndex then
		table.remove(options, optionIndex)
		if insertAfter and optionIndex <= insertAfter then insertAfter = insertAfter - 1 end
	end
	if not insertAfter then insertAfter = math.min(1, #options) end
	table.insert(options, insertAfter + 1, option)
	for index, entry in ipairs(options) do entry.id = index end
	pcall(function()
		if context.calcHeight then context:calcHeight() end
		if context.calcWidth and context.setWidth then context:setWidth(context:calcWidth()) end
	end)
end

local function collectNearbyItems(playerObj, waterObject)
	local waterCount = math.floor(waterObject:getFluidAmount())
	if waterCount < 1 then
		return {}
	end

	local wanted = {
		{ type = "Base.BandageDirty", recipe = "Base.Clean Bandage" },
		{ type = "Base.DenimStripsDirty", recipe = "Base.Clean Denim Strips" },
		{ type = "Base.LeatherStripsDirty", recipe = "Base.Clean Leather Strips" },
		{ type = "Base.RippedSheetsDirty", recipe = "Base.Clean Rag" },
	}
	local output = {}
	for _, data in ipairs(wanted) do
		local recipe = getScriptManager():getRecipe(data.recipe)
		if recipe then
			local items = collectAccessibleItems(playerObj, data.type, 99999, false)
			if #items > 0 then
				output[#output + 1] = { itemType = data.type, recipe = recipe, items = items }
			end
		end
	end
	return output
end

local function findNearbyWaterSource(playerObj)
	local origin = playerObj:getCurrentSquare()
	if not origin then return nil end
	local cell = getCell()
	local candidates = {}
	for radius = 0, 2 do
		for dx = -radius, radius do
			for dy = -radius, radius do
				if math.max(math.abs(dx), math.abs(dy)) == radius then
					local square = cell:getGridSquare(origin:getX() + dx, origin:getY() + dy, origin:getZ())
					if square then
						local objects = square:getObjects()
						for i = 0, objects:size() - 1 do
							local object = objects:get(i)
							local ok, amount = pcall(function() return object:getFluidAmount() end)
							local canCheckTaint = pcall(function() return object:isTaintedWater() end)
							if ok and canCheckTaint and amount and amount >= 1 then
								candidates[#candidates + 1] = { object = object, amount = amount }
							end
						end
					end
				end
			end
		end
		if #candidates > 0 then break end
	end
	if #candidates == 0 then return nil end
	table.sort(candidates, function(a, b) return a.amount > b.amount end)
	return candidates[1].object
end

local function getRainWashSquare(playerObj)
	if not playerObj or not RainManager or not RainManager.isRaining or not RainManager.isRaining() then
		return nil
	end
	local square = playerObj:getCurrentSquare()
	if not square or not square:isOutside() then return nil end
	return square
end

local function returnCleanItemToSourceContainer(playerObj, item, sourceContainer)
	local inventory = playerObj:getInventory()
	if not sourceContainer or sourceContainer == inventory then return end

	local transfer = ISInventoryTransferAction:new(playerObj, item, inventory, sourceContainer, nil)
	if transfer:isValid() then
		transfer:transferItem(item)
		if transfer.item and transfer.item:getContainer() == sourceContainer then
			return
		end
	end
	print("[ChilaSeda_AccessibleActions_B42] Could not return the clean item to its source container; it remains in the player inventory.")
end

ISCleanBandageAccessible = ISCleanBandage:derive("ISCleanBandageAccessible")

function ISCleanBandageAccessible:complete()
	local primary = self.character:isPrimaryHandItem(self.item)
	local secondary = self.character:isSecondaryHandItem(self.item)
	local inventory = self.character:getInventory()
	inventory:Remove(self.item)
	local item = inventory:AddItem(self.result)
	sendReplaceItemInContainer(inventory, self.item, item)
	if primary then self.character:setPrimaryHandItem(item) end
	if secondary then self.character:setSecondaryHandItem(item) end
	sendEquip(self.character)

	returnCleanItemToSourceContainer(self.character, item, self.originalContainer)
	if instanceof(self.waterObject, "IsoWorldInventoryObject") then
		self.waterObject:useFluid(1)
	elseif self.waterObject:useFluid(1) > 0 then
		self.waterObject:transmitModData()
	end

	return true
end

function ISCleanBandageAccessible:new(character, item, waterObject, recipe, originalContainer)
	local o = ISCleanBandage.new(self, character, item, waterObject, recipe)
	o.originalContainer = originalContainer
	return o
end

local function enqueueWashItems(playerObj, waterObject, dataList, count)
	if not waterObject:getSquare() or not luautils.walkAdj(playerObj, waterObject:getSquare(), true) then
		return
	end
	local remaining = count
	for _, data in ipairs(dataList) do
		for _, item in ipairs(data.items) do
			if remaining <= 0 then
				return
			end
			local originalContainer = item:getContainer()
			ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item)
			ISTimedActionQueue.add(ISCleanBandageAccessible:new(playerObj, item, waterObject, data.recipe, originalContainer))
			remaining = remaining - 1
		end
	end
end

local function addNearbyContainerOptions(context, playerObj, waterObject)
	local dataList = collectNearbyItems(playerObj, waterObject)
	if #dataList == 0 then
		return
	end

	local root = context:addOption(getText("UI_ChilaSeda_WashAccessibleContainers"))
	root.iconTexture = getItemIcon("Base.BandageDirty")
	local menu = context:getNew(context)
	context:addSubMenu(root, menu)
	local total = 0
	for _, data in ipairs(dataList) do
		total = total + #data.items
	end
	local waterAvailable = math.max(0, math.floor(waterObject:getFluidAmount()))
	local amount = math.min(total, waterAvailable)
	local allLabel = amount < total
		and getText("UI_ChilaSeda_WashPartial", amount, total)
		or getText("ContextMenu_AllWithCount", amount)
	local allOption = menu:addActionsOption(allLabel, enqueueWashItems, waterObject, dataList, amount)
	allOption.iconTexture = getItemIcon("Base.BandageDirty")
	allOption.notAvailable = amount < 1

	for _, data in ipairs(dataList) do
		local label = data.recipe:getName()
		local sub = menu:addOption(label .. " (" .. #data.items .. ")")
		sub.iconTexture = getItemIcon(data.itemType)
		local subMenu = context:getNew(menu)
		menu:addSubMenu(sub, subMenu)
		local available = waterAvailable
		local one = subMenu:addActionsOption(getText("ContextMenu_One"), enqueueWashItems, waterObject, { data }, 1)
		local count = math.min(#data.items, available)
		local manyLabel = count < #data.items
			and getText("UI_ChilaSeda_WashPartial", count, #data.items)
			or getText("ContextMenu_AllWithCount", #data.items)
		local many = subMenu:addActionsOption(manyLabel, enqueueWashItems, waterObject, { data }, count)
		one.iconTexture = getItemIcon(data.itemType)
		many.iconTexture = getItemIcon(data.itemType)
		one.notAvailable = #data.items < 1 or waterAvailable < 1
		many.notAvailable = count < 1
	end
	positionAfterEquipSecondary(context, root)
end

local function enableNewWashOptions(context, options, firstIndex)
	for i = firstIndex, #options do
		local option = options[i]
		if option then
			if option.notAvailable then
				option.notAvailable = false
				option.toolTip = nil
			end
			if option.subOption then
				local subMenu = context:getSubMenu(option.subOption)
				if subMenu then
					enableNewWashOptions(context, subMenu.options, 1)
				end
			end
		end
	end
end

-- Direct rain is an unlimited ambient source. Keep its action separate from
-- ISCleanBandage so physical sinks, containers, lakes and puddles still consume
-- exactly the amount of water tracked by vanilla.
ISCleanBandageInRain = ISCleanBandage:derive("ISCleanBandageInRain")

function ISCleanBandageInRain:isValid()
	local square = self.square
	return self.item:getContainer() == self.character:getInventory()
		and RainManager.isRaining()
		and square ~= nil
		and square:isOutside()
end

function ISCleanBandageInRain:waitToStart()
	self.character:faceLocation(self.square:getX(), self.square:getY())
	return self.character:shouldBeTurning()
end

function ISCleanBandageInRain:update()
	self.item:setJobDelta(self:getJobDelta())
	self.character:faceLocation(self.square:getX(), self.square:getY())
end

function ISCleanBandageInRain:complete()
	local primary = self.character:isPrimaryHandItem(self.item)
	local secondary = self.character:isSecondaryHandItem(self.item)
	local inventory = self.character:getInventory()
	inventory:Remove(self.item)
	local item = inventory:AddItem(self.result)
	sendReplaceItemInContainer(inventory, self.item, item)
	if primary then self.character:setPrimaryHandItem(item) end
	if secondary then self.character:setSecondaryHandItem(item) end
	sendEquip(self.character)
	returnCleanItemToSourceContainer(self.character, item, self.originalContainer)
	return true
end

function ISCleanBandageInRain:new(character, item, square, recipe, originalContainer)
	local o = ISBaseTimedAction.new(self, character)
	o.item = item
	o.square = square
	o.recipe = recipe
	o.result = recipe:getResult():getType()
	o.originalContainer = originalContainer
	o.maxTime = o:getDuration()
	return o
end

local function enqueueRainWash(playerObj, dataList, count, square)
	if not RainManager.isRaining() or not square or not square:isOutside() then return end
	if not luautils.walkAdj(playerObj, square, true) then return end
	local remaining = count
	for _, data in ipairs(dataList) do
		for _, item in ipairs(data.items) do
			if remaining <= 0 then return end
			local originalContainer = item:getContainer()
			ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item)
			ISTimedActionQueue.add(ISCleanBandageInRain:new(playerObj, item, square, data.recipe, originalContainer))
			remaining = remaining - 1
		end
	end
end

local collectRainItems

local function actualSelectedItems(selectedItems)
	local source = selectedItems or {}
	if ISInventoryPane and ISInventoryPane.getActualItems then
		local ok, items = pcall(ISInventoryPane.getActualItems, source)
		if ok and type(items) == "table" then return items end
	end

	local items = {}
	for _, entry in ipairs(source) do
		if instanceof(entry, "InventoryItem") or instanceof(entry, "IsoWorldInventoryObject") then
			items[#items + 1] = entry
		elseif type(entry) == "table" and type(entry.items) == "table" then
			for _, item in ipairs(entry.items) do
				items[#items + 1] = item
			end
		end
	end
	return items
end

local function addSelectedItemWash(playerNum, context, selectedItems)
	local playerObj = getSpecificPlayer(playerNum)
	if not playerObj then return end
	local rainSquare = getRainWashSquare(playerObj)
	local waterObject = findNearbyWaterSource(playerObj)
	local waterCount = waterObject and math.floor(waterObject:getFluidAmount()) or 0
	local itemTypes = {
		["Base.BandageDirty"] = "Base.Clean Bandage",
		["Base.DenimStripsDirty"] = "Base.Clean Denim Strips",
		["Base.LeatherStripsDirty"] = "Base.Clean Leather Strips",
		["Base.RippedSheetsDirty"] = "Base.Clean Rag",
	}
	local dataList = {}
	local seenTypes = {}
	for _, item in ipairs(actualSelectedItems(selectedItems)) do
		local selectedItem = instanceof(item, "IsoWorldInventoryObject") and item:getItem() or item
		local fullType = selectedItem and selectedItem.getFullType and selectedItem:getFullType()
		local recipeName = itemTypes[fullType]
		if recipeName and not seenTypes[fullType] then
			seenTypes[fullType] = true
			local recipe = getScriptManager():getRecipe(recipeName)
			local items = waterObject and collectAccessibleItems(playerObj, fullType, waterCount, true) or {}
			if recipe and #items > 0 then
				dataList[#dataList + 1] = { itemType = fullType, recipe = recipe, items = items }
				waterCount = waterCount - #items
			end
		end
	end
	local rainDataList = {}
	local rainCount = 0
	if rainSquare then
		for _, data in ipairs(collectRainItems(playerObj, rainSquare)) do
			if seenTypes[data.itemType] then
				rainDataList[#rainDataList + 1] = data
				rainCount = rainCount + #data.items
			end
		end
	end
	if #dataList == 0 and rainCount == 0 then return end

	local rootLabel = #dataList > 0
		and getText("UI_ChilaSeda_WashNearbySource")
		or getText("UI_ChilaSeda_WashBandages")
	local root = context:addOption(rootLabel)
	local rootIconType = dataList[1] and dataList[1].itemType
	if not rootIconType then
		for fullType in pairs(seenTypes) do rootIconType = fullType; break end
	end
	root.iconTexture = getItemIcon(rootIconType or "Base.BandageDirty")
	local menu = context:getNew(context)
	context:addSubMenu(root, menu)
	if #dataList > 0 then
		local available = 0
		for _, data in ipairs(dataList) do available = available + #data.items end
		local all = menu:addActionsOption(getText("UI_ChilaSeda_WashAll", available), enqueueWashItems, waterObject, dataList, available)
		all.iconTexture = getItemIcon("Base.BandageDirty")
		for _, data in ipairs(dataList) do
			local typeOption = menu:addOption(data.recipe:getName() .. " (" .. #data.items .. ")")
			typeOption.iconTexture = getItemIcon(data.itemType)
			local typeMenu = context:getNew(menu)
			menu:addSubMenu(typeOption, typeMenu)
			local one = typeMenu:addActionsOption(getText("UI_ChilaSeda_WashOne"), enqueueWashItems, waterObject, { data }, 1)
			local many = typeMenu:addActionsOption(getText("UI_ChilaSeda_WashAll", #data.items), enqueueWashItems, waterObject, { data }, #data.items)
			one.iconTexture = getItemIcon(data.itemType)
			many.iconTexture = getItemIcon(data.itemType)
		end
	end
	if rainCount > 0 then
		local rainOption = menu:addActionsOption(getText("UI_ChilaSeda_WashAllRain", rainCount), enqueueRainWash, rainDataList, rainCount, rainSquare)
		rainOption.iconTexture = getItemIcon("Base.BandageDirty")
		for _, data in ipairs(rainDataList) do
			local typeOption = menu:addOption(data.recipe:getName() .. " (lluvia)")
			typeOption.iconTexture = getItemIcon(data.itemType)
			local typeMenu = context:getNew(menu)
			menu:addSubMenu(typeOption, typeMenu)
			local one = typeMenu:addActionsOption(getText("UI_ChilaSeda_WashOne"), enqueueRainWash, { data }, 1, rainSquare)
			local many = typeMenu:addActionsOption(getText("UI_ChilaSeda_WashAll", #data.items), enqueueRainWash, { data }, #data.items, rainSquare)
			one.iconTexture = getItemIcon(data.itemType)
			many.iconTexture = getItemIcon(data.itemType)
		end
	end
	positionAfterEquipSecondary(context, root)
end

collectRainItems = function(playerObj, square)
	local wanted = {
		{ type = "Base.BandageDirty", recipe = "Base.Clean Bandage" },
		{ type = "Base.DenimStripsDirty", recipe = "Base.Clean Denim Strips" },
		{ type = "Base.LeatherStripsDirty", recipe = "Base.Clean Leather Strips" },
		{ type = "Base.RippedSheetsDirty", recipe = "Base.Clean Rag" },
	}
	local all = {}
	for _, spec in ipairs(wanted) do
		local recipe = getScriptManager():getRecipe(spec.recipe)
		local items = collectAccessibleItems(playerObj, spec.type, 9999, true)
		if recipe and #items > 0 then
			all[#all + 1] = { itemType = spec.type, recipe = recipe, items = items }
		end
	end
	return all
end

local function hasWashMenu(context)
	local label = getText("ContextMenu_CleanBandageEtc")
	for _, option in ipairs(context.options) do
		if option.name and string.find(option.name, label, 1, true) then
			return true
		end
	end
	return false
end

local function addWaterAndRainOptions(playerNum, context, worldobjects, test)
	if test then return end
	local playerObj = getSpecificPlayer(playerNum)
	if not playerObj then return end

	if not hasWashMenu(context) and ISWorldObjectContextMenu.doRecipeUsingWaterMenu then
		for _, object in ipairs(worldobjects or {}) do
			local ok, amount = pcall(function() return object:getFluidAmount() end)
			local canCheckTaint = pcall(function() return object:isTaintedWater() end)
			if ok and canCheckTaint and amount and amount >= 1 then
				ISWorldObjectContextMenu.doRecipeUsingWaterMenu(object, playerNum, context)
				break
			end
		end
	end

	local square = getRainWashSquare(playerObj)
	if not square then return end
	local dataList = collectRainItems(playerObj, square)
	if #dataList == 0 then return end

	local count = 0
	for _, data in ipairs(dataList) do count = count + #data.items end
	local root = context:addOption(getText("ContextMenu_CleanBandageEtc") .. " (lluvia)")
	root.iconTexture = getItemIcon("Base.BandageDirty")
	local menu = context:getNew(context)
	context:addSubMenu(root, menu)
	local all = menu:addActionsOption(getText("ContextMenu_AllWithCount", count), enqueueRainWash, dataList, count, square)
	all.iconTexture = getItemIcon("Base.BandageDirty")
	for _, data in ipairs(dataList) do
		local typeOption = menu:addOption(data.recipe:getName() .. " (" .. #data.items .. ")")
		typeOption.iconTexture = getItemIcon(data.itemType)
		local typeMenu = context:getNew(menu)
		menu:addSubMenu(typeOption, typeMenu)
		local one = typeMenu:addActionsOption(getText("ContextMenu_One"), enqueueRainWash, { data }, 1, square)
		local many = typeMenu:addActionsOption(getText("ContextMenu_AllWithCount", #data.items), enqueueRainWash, { data }, #data.items, square)
		one.iconTexture = getItemIcon(data.itemType)
		many.iconTexture = getItemIcon(data.itemType)
	end
	positionAfterEquipSecondary(context, root)
end

-- Priority: hide vanilla water-from-inventory options when external sources exist
local function hideVanillaInventoryWaterOptions(playerNum, context, items)
	local playerObj = getSpecificPlayer(playerNum)
	if not playerObj then return end

	-- Check if there's a nearby water source OR rain
	local hasExternalWater = findNearbyWaterSource(playerObj) ~= nil
	local hasRain = RainManager.isRaining() and playerObj:getCurrentSquare() and playerObj:getCurrentSquare():isOutside()

	if not (hasExternalWater or hasRain) then return end

	-- Hide vanilla options that use inventory water (bottles, etc.)
	-- They appear as "Clean Bandage" / "Limpiar venda" with water bottle tooltip
	for i = #context.options, 1, -1 do
		local option = context.options[i]
		if option and option.name then
			local isCleanAction = string.find(option.name, getText("ContextMenu_CleanBandageEtc"), 1, true)
				or string.find(option.name, "Clean Bandage", 1, true)
				or string.find(option.name, "Limpiar", 1, true)

			-- Check if it requires water from inventory (has water item tooltip)
			local usesInventoryWater = false
			if option.toolTip and option.toolTip.description then
				local desc = tostring(option.toolTip.description)
				usesInventoryWater = string.find(desc, "Water", 1, true)
					or string.find(desc, "Agua", 1, true)
					or string.find(desc, "Bottle", 1, true)
					or string.find(desc, "Botella", 1, true)
			end

			if isCleanAction and usesInventoryWater then
				-- Mark as unavailable instead of removing (preserves menu structure)
				option.notAvailable = true
				option.toolTip = ISWorldObjectContextMenu.addToolTip()
				option.toolTip.description = getText("UI_ChilaSeda_UseExternalWaterSource")
			end
		end
	end
end

local function safeCall(object, method, ...)
	if not object then return nil end
	local fn = object[method]
	if type(fn) ~= "function" then return nil end
	local ok, result = pcall(fn, object, ...)
	if ok then return result end
	return nil
end

local function isFillableWithWater(item)
	local fluid = safeCall(item, "getFluidContainer")
	if fluid then
		local freeCapacity = safeCall(fluid, "getFreeCapacity")
		if type(freeCapacity) == "number" then return freeCapacity > 0 end
		local capacity = safeCall(fluid, "getCapacity")
		local amount = safeCall(fluid, "getAmount")
		if type(capacity) == "number" and type(amount) == "number" then
			return capacity > amount
		end
	end
	if safeCall(item, "canStoreWater") == true then
		return safeCall(item, "isWaterSource") ~= true
	end
	return false
end

local function collectFillableItems(container, output, seenContainers, seenItems)
	if not container or seenContainers[container] then return end
	seenContainers[container] = true
	local items = safeCall(container, "getItems")
	local size = safeCall(items, "size")
	if type(size) ~= "number" then return end

	for index = 0, size - 1 do
		local item = safeCall(items, "get", index)
		if item then
			if not seenItems[item] and isFillableWithWater(item) then
				seenItems[item] = true
				table.insert(output, item)
			end
			local nestedInventory = safeCall(item, "getInventory")
			if nestedInventory then
				collectFillableItems(nestedInventory, output, seenContainers, seenItems)
			end
		end
	end
end

local function collectPlayerFillables(playerObj)
	local result = {}
	local inventory = safeCall(playerObj, "getInventory")
	collectFillableItems(inventory, result, {}, {})
	return result
end

local function extendFillContainerSearch(playerNum, context, worldobjects, test)
	if test then return end
	local playerObj = getSpecificPlayer(playerNum)
	if not playerObj then return end

	local waterSource
	for _, object in ipairs(worldobjects or {}) do
		local amount = safeCall(object, "getFluidAmount")
		local tainted = safeCall(object, "isTaintedWater")
		if type(amount) == "number" and amount > 0 and tainted ~= nil then
			waterSource = object
			break
		end
	end
	if not waterSource or not context then return end

	-- Refresh the visible pane, then scan the live inventory tree rather than its old listbox rows.
	local inventoryUI = getPlayerInventory and getPlayerInventory(playerNum)
	local inventoryPane = inventoryUI and inventoryUI.inventoryPane
	if inventoryPane then
		pcall(function() inventoryPane:refreshContainer() end)
		pcall(function() inventoryPane:updateMainListbox() end)
	end

	local fillableItems = collectPlayerFillables(playerObj)
	if #fillableItems == 0 then return end

	local represented = {}
	if context.options then
		local menus = { context }
		for _, submenu in pairs(context.instanceMap or {}) do
			menus[#menus + 1] = submenu
		end
		for _, menu in ipairs(menus) do
			for _, option in ipairs(menu.options or {}) do
				if option.onSelect == ISWorldObjectContextMenu.onTakeWater then
					if option.param3 then represented[option.param3] = true end
					local list = option.param2
					if type(list) == "table" then
						for _, item in ipairs(list) do
							represented[item] = true
						end
					else
						local count = safeCall(list, "size")
						for index = 0, (type(count) == "number" and count or 0) - 1 do
							local item = safeCall(list, "get", index)
							if item then represented[item] = true end
						end
					end
				end
			end
		end
	end

	local missing = {}
	for _, item in ipairs(fillableItems) do
		if not represented[item] then missing[#missing + 1] = item end
	end
	if #missing == 0 then return end

	local root = context:addOption(getText("UI_ChilaSeda_FillContainers"))
	root.iconTexture = getItemIcon("Base.WaterBottleFull")
	local submenu = context:getNew(context)
	context:addSubMenu(root, submenu)
	if #missing > 1 then
		local allOption = submenu:addOption(getText("UI_ChilaSeda_FillAll", #missing), worldobjects,
			ISWorldObjectContextMenu.onTakeWater, waterSource, missing, nil, playerNum)
		allOption.iconTexture = getItemIcon("Base.WaterBottleFull")
	end
	for _, item in ipairs(missing) do
		local itemName = safeCall(item, "getName") or tostring(item)
		local option = submenu:addOption(getText("UI_ChilaSeda_FillOne", tostring(itemName)), worldobjects,
			ISWorldObjectContextMenu.onTakeWater, waterSource, nil, item, playerNum)
		local fullType = safeCall(item, "getFullType")
		option.iconTexture = getItemIcon(fullType)
	end
	positionAfterEquipSecondary(context, root)
end

Events.OnFillWorldObjectContextMenu.Add(addWaterAndRainOptions)
Events.OnFillInventoryObjectContextMenu.Add(addSelectedItemWash)
Events.OnFillInventoryObjectContextMenu.Add(hideVanillaInventoryWaterOptions)

-- The vanilla fillable-item list can be stale after an inventory transfer. Rebuild
-- the options after the complete world context menu has been populated.
local vanillaCreateMenu = ISWorldObjectContextMenu.createMenu
if vanillaCreateMenu then
	ISWorldObjectContextMenu.createMenu = function(playerNum, worldobjects, x, y, test, ...)
		local result = vanillaCreateMenu(playerNum, worldobjects, x, y, test, ...)
		if not test then
			local context = type(result) == "table" and result or nil
			if not context and getPlayerContextMenu then
				local ok, rootMenu = pcall(getPlayerContextMenu, playerNum)
				if ok then context = rootMenu end
			end
			extendFillContainerSearch(playerNum, context, worldobjects, test)
		end
		return result
	end
end

local vanillaMenu = ISWorldObjectContextMenu.doRecipeUsingWaterMenu
if vanillaMenu then
	ISWorldObjectContextMenu.doRecipeUsingWaterMenu = function(waterObject, playerNum, context)
		local firstOption = #context.options + 1
		vanillaMenu(waterObject, playerNum, context)
		-- Vanilla blocks washing with tainted water when the warning option is enabled.
		-- Washing is still safe as an item action; it consumes water, but does not sterilize.
		local tainted = false
		local ok, value = pcall(function() return waterObject:isTaintedWater() end)
		if ok then tainted = value end
		if tainted then
			enableNewWashOptions(context, context.options, firstOption)
		end
		addNearbyContainerOptions(context, getSpecificPlayer(playerNum), waterObject)
	end
end
