local viewpointLoaded = pcall(require, "Viewpoint_Loot")
local viewpointLootAvailable = viewpointLoaded and type(ViewpointLoot) == "table"
local TAG = "[ChilaSeda_ViewpointSelectedContainer] "
if not viewpointLootAvailable then
    print(TAG .. "Viewpoint loot API unavailable; continuing with vanilla transfer routing.")
end
pcall(require, "Foraging/ISForageIcon")
pcall(require, "Foraging/ISWorldItemIcon")
require "TimedActions/ISInventoryTransferUtil"
require "TimedActions/ISInventoryTransferAction"
require "ISUI/ISContextMenu"

local function selectedDestination(playerNum)
    local page = getPlayerInventory(playerNum)
    if not page then return nil, nil end

    local main = page.inventory
    local selected = page.inventoryPane and page.inventoryPane.inventory
    if selected and selected ~= main and type(selected.getItems) == "function"
            and selected:getType() ~= "floor" then
        return selected, page
    end
    return main, page
end

local function canStoreIn(container, player, item)
    if not container or not player or not item then return false end
    return container:isItemAllowed(item) and container:hasRoomFor(player, item)
        and container:getCapacityWeight() + item:getUnequippedWeight()
            <= container:getEffectiveCapacity(player)
end

local function itemDisplayName(item)
	if not item then return nil end
	local display = item.getDisplayName and item:getDisplayName() or nil
	local itemType = item.getType and item:getType() or nil
	if display and display ~= "" and display ~= itemType then return display end
	local fullType = item.getFullType and item:getFullType() or nil
	if fullType and type(getText) == "function" then
		local key = "ItemName_" .. fullType
		local translated = getText(key)
		if translated and translated ~= key then return translated end
	end
	return display or itemType
end

local destinationName

local function selectDestinationFromMenu(page, container)
	if not page or not container then return end
	if type(page.selectButtonForContainer) == "function" then
		page:selectButtonForContainer(container)
	end
	if page.inventoryPane and page.inventoryPane.inventory ~= container
			and type(page.setNewContainer) == "function" then
		page:setNewContainer(container)
	end
	if page.inventoryPane then page.inventoryPane.lastinventory = container end
	local player = getSpecificPlayer(page.player)
	if player and HaloTextHelper and type(HaloTextHelper.addText) == "function" then
		HaloTextHelper.addText(player,
			"Destino seleccionado: " .. destinationName(player, container), " ", 255, 220, 120)
	end
end

local function canStoreBatch(container, player, items)
	if not container or not player or not items then return false end
	local plannedWeight = 0
	for _, item in ipairs(items) do
		if item and not instanceof(item, "InventoryContainer") then
			local weight
			local ok, fits = pcall(function()
				weight = item:getUnequippedWeight()
				return container:isItemAllowed(item) and container:hasRoomFor(player, item)
					and container:getCapacityWeight() + plannedWeight + weight
						<= container:getEffectiveCapacity(player)
			end)
			if not ok or not fits then return false end
			plannedWeight = plannedWeight + weight
		end
	end
	return true
end

local function showAlternateDestinationMenu(player, page, selected, items)
	if not player or not page or not ISContextMenu or type(ISContextMenu.get) ~= "function" then
		return false
	end
	local destinations, seen = {}, {}
	local function add(container)
		if not container or container == selected or seen[container]
				or not canStoreBatch(container, player, items) then return end
		seen[container] = true
		destinations[#destinations + 1] = container
	end
	add(player:getInventory())
	local worn = player:getWornItems()
	if worn then
		for i = 0, worn:size() - 1 do
			local wornItem = worn:getItemByIndex(i)
			if wornItem and instanceof(wornItem, "InventoryContainer")
					and not player:isHandItem(wornItem) then
				add(wornItem:getInventory())
			end
		end
	end
	if #destinations == 0 then
		if HaloTextHelper and type(HaloTextHelper.addText) == "function" then
			HaloTextHelper.addText(player,
				"La mochila seleccionada esta llena y no hay otro destino con espacio.",
				" ", 255, 220, 120)
		end
		return false
	end
	local playerNum = player:getPlayerNum()
	local x = type(getMouseX) == "function" and getMouseX() or 0
	local y = type(getMouseY) == "function" and getMouseY() or 0
	local menu = ISContextMenu.get(playerNum, x, y)
	if not menu then return false end
	local header = menu:addOption("La mochila seleccionada esta llena.", nil, nil)
	if header then header.notAvailable = true end
	local prompt = menu:addOption("No se movio ningun objeto. Elige destino para intentar de nuevo:", nil, nil)
	if prompt then prompt.notAvailable = true end
	for _, container in ipairs(destinations) do
		menu:addOption(destinationName(player, container), page,
			selectDestinationFromMenu, container)
	end
	menu:addOption("Cancelar; dejar todo donde estaba", nil, nil)
	return true
end

local function findContainerOwnerItem(root, target, visited)
	if not root or not target or visited[root] then return nil end
	visited[root] = true
	local items = root:getItems()
	if not items then return nil end
	for i = 0, items:size() - 1 do
		local item = items:get(i)
		if item and item.getInventory then
			local child = item:getInventory()
			if child == target then return item end
			local owner = findContainerOwnerItem(child, target, visited)
			if owner then return owner end
		end
	end
	return nil
end

destinationName = function(player, container)
    if container == player:getInventory() then return "inventario principal" end
    local containingItem = container and container.getContainingItem
        and container:getContainingItem() or nil
    if not containingItem then
		containingItem = findContainerOwnerItem(player:getInventory(), container, {})
	end
	if not containingItem then
		local function searchOpenPage(ui)
			local root = ui and ui.inventoryPane and ui.inventoryPane.inventory
			return root and findContainerOwnerItem(root, container, {}) or nil
		end
		local playerNum = player:getPlayerNum()
		local page = type(getPlayerInventory) == "function" and getPlayerInventory(playerNum) or nil
		local loot = type(getPlayerLoot) == "function" and getPlayerLoot(playerNum) or nil
		containingItem = searchOpenPage(page) or searchOpenPage(loot)
	end
	local displayName = itemDisplayName(containingItem)
	if displayName then
		return displayName
    end
    local parent = container and container.getParent and container:getParent() or nil
    if parent and parent.getDisplayName then return parent:getDisplayName() end
    return container and container.getType and container:getType() or "contenedor"
end

local originalTransferFactory = ISInventoryTransferUtil.newInventoryTransferAction
ISInventoryTransferUtil.newInventoryTransferAction = function(player, item, source, destination, time, ...)
    local main = player and player:getInventory()
    local selected = player and selectedDestination(player:getPlayerNum()) or nil
    local sourceInPlayerInventory = source and main and source:getOutermostContainer() == main
    local pickupToPlayer = player and item and source and not sourceInPlayerInventory
        and (destination == main or destination == selected)
    if not pickupToPlayer then
        return originalTransferFactory(player, item, source, destination, time, ...)
    end

    -- Equipping from a corpse must put the item in the character's root
    -- inventory first; ISEquipWeaponAction:isValid() searches that inventory
    -- by ID and cancels if corpse-loot routing sends it to a nested bag.
    if ChilaSeda_EquipFromCorpse == true and destination == main then
        return originalTransferFactory(player, item, source, main, time, ...)
    end

    local target = selected or main
    if target ~= main and not canStoreIn(target, player, item) then target = main end
    local action = originalTransferFactory(player, item, source, target, time, ...)
    if action and action:isValid() then
        if HaloTextHelper and HaloTextHelper.addText then
            HaloTextHelper.addText(player, "Guardado en: " .. destinationName(player, target), " ", 255, 220, 120)
        end
        return action
    end

    if target ~= main then
        target = main
        action = originalTransferFactory(player, item, source, target, time, ...)
    end
    if action and action:isValid() and HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(player, "Guardado en: " .. destinationName(player, target), " ", 255, 220, 120)
    end
    return action
end

local function withSelectedPageInventory(playerNum, callback, ...)
    local destination, page = selectedDestination(playerNum)
    if not destination or not page or destination == page.inventory then
        return callback(...)
    end

    local previous = page.inventory
    page.inventory = destination
    local ok, result = pcall(callback, ...)
    page.inventory = previous
    if not ok then error(result, 0) end
    return result
end

if ViewpointLoot and type(ViewpointLoot.take) == "function" then
    local originalTake = ViewpointLoot.take
    ViewpointLoot.take = function(player, ...)
        return withSelectedPageInventory(player:getPlayerNum(), originalTake, player, ...)
    end
end

if ViewpointLoot and type(ViewpointLoot.takeAll) == "function" then
    local originalTakeAll = ViewpointLoot.takeAll
    ViewpointLoot.takeAll = function(player, ...)
        return withSelectedPageInventory(player:getPlayerNum(), originalTakeAll, player, ...)
    end
end

local function isModActive(modId)
    if type(getActivatedMods) ~= "function" then return false end
    local ok, mods = pcall(getActivatedMods)
    if not ok or not mods then return false end
    if type(mods.contains) == "function" then
        local containsOk, contains = pcall(mods.contains, mods, modId)
        return containsOk and contains == true
    end
    if type(mods.size) == "function" and type(mods.get) == "function" then
        for i = 0, mods:size() - 1 do
            if mods:get(i) == modId then return true end
        end
    end
    return false
end

if isModActive("ViewpointForaging") and ISForageIcon
        and type(ISForageIcon.doForage) == "function" then
    local originalDoForage = ISForageIcon.doForage
    ISForageIcon.doForage = function(icon, x, y, contextOption, targetContainer)
        local destination = targetContainer or selectedDestination(icon.player)
        return originalDoForage(icon, x, y, contextOption, destination)
    end
end

if isModActive("ViewpointForaging") and ISWorldItemIcon
        and type(ISWorldItemIcon.doPickup) == "function" then
    local originalDoPickup = ISWorldItemIcon.doPickup
    ISWorldItemIcon.doPickup = function(icon, x, y, contextOption, targetContainer, items)
        local destination = targetContainer or selectedDestination(icon.player)
        return originalDoPickup(icon, x, y, contextOption, destination, items)
    end
end

local function installViewpointUI()
    local actions = ViewpointUI and ViewpointUI.Inventory and ViewpointUI.Inventory.Actions
    if not actions then return end

    if type(actions.planLoot) == "function" and not actions.ChilaSedaSelectedContainerPlan then
        local originalPlanLoot = actions.planLoot
        actions.planLoot = function(player, items, ...)
            local plan = originalPlanLoot(player, items, ...)
            local destination, page = selectedDestination(player:getPlayerNum())
            if not destination or not page or destination == player:getInventory() then return plan end

            local selectedPlan, overflowItems = {}, {}
            local planned = 0
            for _, entry in ipairs(plan) do
                local item = entry.item
                if item and not instanceof(item, "InventoryContainer") then
                    local weight = item:getUnequippedWeight()
                    if destination:isItemAllowed(item) and destination:hasRoomFor(player, item)
                            and destination:getCapacityWeight() + planned + weight
                                <= destination:getEffectiveCapacity(player) then
                        entry.dest = destination
                        planned = planned + weight
						table.insert(selectedPlan, entry)
					else
						table.insert(overflowItems, item)
                    end
				elseif item then
					table.insert(selectedPlan, entry)
                end
            end
			if #overflowItems > 0 then
				showAlternateDestinationMenu(player, page, destination, overflowItems)
				-- Do not let the items that fit move while the player is still
				-- deciding where the overflow should go. Dismissing the menu is
				-- cancellation: the complete batch stays in its source container.
				return {}
			end
			return selectedPlan
        end
        actions.ChilaSedaSelectedContainerPlan = true
    end

    if type(actions.grabWorldItem) == "function" and not actions.ChilaSedaSelectedContainerGrab then
        local originalGrabWorldItem = actions.grabWorldItem
        actions.grabWorldItem = function(player, worldItem, ...)
            if not player or not worldItem then
                return originalGrabWorldItem(player, worldItem, ...)
            end

            local item = worldItem:getItem()
            local source = item and item:getContainer()
            if not item or not source or (isForceDropHeavyItem and isForceDropHeavyItem(item)) then
                return originalGrabWorldItem(player, worldItem, ...)
            end

            local plan = actions.planLoot(player, { item })
            local destination = plan[1] and plan[1].dest
            local square = worldItem:getSquare()
            if destination and square and luautils.walkAdj(player, square) then
                ISTimedActionQueue.add(ISInventoryTransferUtil.newInventoryTransferAction(
                    player, item, source, destination))
            end
        end
        actions.ChilaSedaSelectedContainerGrab = true
    end

    print(TAG .. "Viewpoint UI loot routing installed")
end

installViewpointUI()
Events.OnGameStart.Add(installViewpointUI)
Events.OnCreatePlayer.Add(installViewpointUI)

print(TAG .. "Selected-container transfer routing loaded")
