require "ISUI/ISUIElement"
require "ISUI/ISInventoryPaneContextMenu"

local TAG = "[ChilaSeda_InventoryTetrisOverflowFloorDrop] "
local MAX_TRACE_LINES = 32
local traceLines = 0
local TRACE_AUTO_DROP = true
local MAX_AUTO_DROP_TRACE_LINES = 64
local autoDropTraceLines = 0
local autoDropTraceInstalled = false
local warnedMissingApi = false
local installed = false

local function trace(message)
	if traceLines >= MAX_TRACE_LINES then return end
	traceLines = traceLines + 1
	print(TAG .. tostring(message))
end

local function traceAutoDrop(message)
	if not TRACE_AUTO_DROP or autoDropTraceLines >= MAX_AUTO_DROP_TRACE_LINES then return end
	autoDropTraceLines = autoDropTraceLines + 1
	print(TAG .. tostring(message))
end

local function safeMethod(object, methodName, ...)
	local okMethod, method = pcall(function() return object and object[methodName] end)
	if not okMethod or type(method) ~= "function" then return nil end
	local ok, value = pcall(method, object, ...)
	if ok then return value end
	return nil
end

local function playerWornState(item, playerNum)
	if type(getSpecificPlayer) ~= "function" then
		return nil, "getSpecificPlayer-unavailable"
	end
	local okPlayer, player = pcall(getSpecificPlayer, playerNum)
	if not okPlayer or not player then return nil, "player-unavailable" end

	local equippedClothing = safeMethod(player, "isEquippedClothing", item)
	if equippedClothing == true then return true, "player-isEquippedClothing" end

	local wornItems = safeMethod(player, "getWornItems")
	local contains = safeMethod(wornItems, "contains", item)
	if contains == true then return true, "WornItems.contains" end
	if equippedClothing == false or contains == false then
		return false, "worn-state-checked"
	end
	return nil, "worn-state-unavailable"
end

local function autoDropItemLabel(item)
	local fullType = safeMethod(item, "getFullType") or "unknown"
	local itemId = safeMethod(item, "getID") or "na"
	local container = safeMethod(item, "getContainer")
	local containerType = safeMethod(container, "getType") or "none"
	local equipped = safeMethod(item, "isEquipped")
	return "item=" .. tostring(fullType) .. " id=" .. tostring(itemId)
		.. " source=" .. tostring(containerType) .. " equipped=" .. tostring(equipped)
end

local function installAutoDropTrace()
	if autoDropTraceInstalled then return true end
	local ok, autoDropSystem = pcall(require, "InventoryTetris/System/GridAutoDropSystem")
	if not ok or type(autoDropSystem) ~= "table" then
		traceAutoDrop("install fallback=GridAutoDropSystem-unavailable")
		return false
	end
	if autoDropSystem.ChilaSedaAutoDropTraceInstalled then
		autoDropTraceInstalled = true
		return true
	end
	local originalHandleDropItem = autoDropSystem._handleDropItem
	if type(originalHandleDropItem) ~= "function" then
		traceAutoDrop("install fallback=GridAutoDropSystem._handleDropItem-unavailable")
		return false
	end

	autoDropSystem._handleDropItem = function(item, playerNum)
		local label = autoDropItemLabel(item)
		local isPlayerWearing, wornCheck = playerWornState(item, playerNum)
		if isPlayerWearing == true then
			traceAutoDrop("event=auto-drop-protected reason=player-worn-item check=" .. tostring(wornCheck)
				.. " result=retained playerNum=" .. tostring(playerNum) .. " " .. label)
			-- GridAutoDropSystem treats true as resolved, so no floor transfer is queued.
			return true
		end
		if isPlayerWearing == nil then
			traceAutoDrop("event=auto-drop-fallback reason=worn-state-unavailable check=" .. tostring(wornCheck)
				.. " playerNum=" .. tostring(playerNum) .. " " .. label)
		end

		local route = "floor-transfer-after-grid-no-fit"
		local okGrid, itemContainerGrid = pcall(require, "InventoryTetris/Model/ItemContainerGrid")
		local liveAnimal = false
		if okGrid and type(itemContainerGrid) == "table"
				and type(itemContainerGrid.isLiveAnimalCarrier) == "function" then
			local okLive, value = pcall(itemContainerGrid.isLiveAnimalCarrier, item)
			liveAnimal = okLive and value == true
		end
		local undroppable = false
		if type(autoDropSystem._isItemUndroppable) == "function" then
			local okUndroppable, value = pcall(autoDropSystem._isItemUndroppable, item)
			undroppable = okUndroppable and value == true
		end
		if liveAnimal then
			route = "retain-live-animal"
		elseif undroppable then
			route = "force-position-or-equip"
		end
		traceAutoDrop("event=auto-drop-decision reason=unpositioned-no-grid-fit route=" .. route
			.. " playerNum=" .. tostring(playerNum) .. " " .. label)
		local result = originalHandleDropItem(item, playerNum)
		traceAutoDrop("event=auto-drop-result route=" .. route .. " result=" .. tostring(result)
			.. " playerNum=" .. tostring(playerNum) .. " " .. label)
		return result
	end
	autoDropSystem.ChilaSedaAutoDropTraceInstalled = true
	autoDropTraceInstalled = true
	traceAutoDrop("install=GridAutoDropSystem._handleDropItem maxEvents=" .. tostring(MAX_AUTO_DROP_TRACE_LINES))
	return true
end

local function findOverflowStackByItem(containerGrid, item)
	if not containerGrid or type(containerGrid.overflow) ~= "table" or not item
			or type(item.getID) ~= "function" then
		return nil
	end
	local ok, itemId = pcall(item.getID, item)
	if not ok or itemId == nil then return nil end
	for _, stack in ipairs(containerGrid.overflow) do
		if stack and type(stack.itemIDs) == "table" and stack.itemIDs[itemId] then
			return stack
		end
	end
	return nil
end

local function liveOverflowItems(inventory, stack)
	local items, staleIds = {}, 0
	if not inventory or type(inventory.getItemWithID) ~= "function"
			or not stack or type(stack.itemIDs) ~= "table" then
		return items, staleIds
	end
	for itemId in pairs(stack.itemIDs) do
		local ok, item = pcall(inventory.getItemWithID, inventory, itemId)
		if ok and item then
			items[#items + 1] = item
		else
			staleIds = staleIds + 1
		end
	end
	return items, staleIds
end

local function install()
	installAutoDropTrace()
	if installed then return true end
	local okRenderer, renderer = pcall(require, "InventoryTetris/UI/Container/GridOverflowRenderer")
	local okItemGrid, itemGridUi = pcall(require, "InventoryTetris/UI/Grid/ItemGridUI")
	local okDrag, dragAndDrop = pcall(require, "InventoryTetris/System/DragAndDrop")
	if not okRenderer or type(renderer) ~= "table"
			or not okItemGrid or type(itemGridUi) ~= "table"
			or not okDrag or type(dragAndDrop) ~= "table"
			or type(dragAndDrop.isDragOwner) ~= "function"
			or type(dragAndDrop.getDraggedStack) ~= "function"
			or type(itemGridUi.cancelDragDropItem) ~= "function" then
		if not warnedMissingApi then
			warnedMissingApi = true
			trace("install fallback=Inventory-Tetris overflow API unavailable")
		end
		return false
	end
	if renderer.ChilaSedaOverflowFloorDropInstalled then
		installed = true
		return true
	end

	local function isOwnerGrid(self)
		if not self.gridUi or type(dragAndDrop.isDragOwner) ~= "function" then return false end
		local ok, ownsDrag = pcall(dragAndDrop.isDragOwner, self.gridUi)
		return ok and ownsDrag == true
	end

	local function originalOrNil(original, self, ...)
		if type(original) == "function" then return original(self, ...) end
		return nil
	end

	local originalOnMouseMove = renderer.onMouseMove
	renderer.onMouseMove = function(self, dx, dy)
		if isOwnerGrid(self) and type(self.gridUi.onMouseMove) == "function" then
			return self.gridUi:onMouseMove(dx, dy)
		end
		return originalOrNil(originalOnMouseMove, self, dx, dy)
	end

	local originalOnMouseMoveOutside = renderer.onMouseMoveOutside
	renderer.onMouseMoveOutside = function(self, dx, dy)
		if isOwnerGrid(self) and type(self.gridUi.onMouseMoveOutside) == "function" then
			return self.gridUi:onMouseMoveOutside(dx, dy)
		end
		return originalOrNil(originalOnMouseMoveOutside, self, dx, dy)
	end

	local originalOnMouseUpOutside = renderer.onMouseUpOutside
	renderer.onMouseUpOutside = function(self, x, y)
		if isOwnerGrid(self) and type(self.gridUi.onMouseUpOutside) == "function" then
			local ok, gridX, gridY = pcall(function()
				return x + self:getAbsoluteX() - self.gridUi:getAbsoluteX(),
					y + self:getAbsoluteY() - self.gridUi:getAbsoluteY()
			end)
			if ok then return self.gridUi:onMouseUpOutside(gridX, gridY) end
			trace("mouse-up coordinate fallback=original callback")
		end
		return originalOrNil(originalOnMouseUpOutside, self, x, y)
	end

	local originalCancelDragDropItem = itemGridUi.cancelDragDropItem
	itemGridUi.cancelDragDropItem = function(self)
		if self.playerNum ~= 0 or not self.grid or type(self.grid.findStackByItem) ~= "function" then
			return originalCancelDragDropItem(self)
		end
		local vanillaStack = dragAndDrop.getDraggedStack()
		local item = vanillaStack and vanillaStack.items and vanillaStack.items[1]
		if not item then return originalCancelDragDropItem(self) end
		if self.grid:findStackByItem(item) then
			return originalCancelDragDropItem(self)
		end

		local overflowStack = findOverflowStackByItem(self.containerGrid, item)
		if not overflowStack then
			trace("floor-drop fallback=stack-not-in-overflow")
			return originalCancelDragDropItem(self)
		end
		local playerObj = type(getSpecificPlayer) == "function" and getSpecificPlayer(self.playerNum)
		if not playerObj then
			trace("floor-drop fallback=player-unavailable")
			return
		end
		if type(playerObj.getVehicle) == "function" and playerObj:getVehicle() then
			trace("floor-drop skipped=player-in-vehicle")
			return
		end
		if not ISUIElement or type(ISUIElement.isMouseOverAnyUI) ~= "function" then
			trace("floor-drop fallback=UI-state-unavailable")
			return
		end
		local okUi, mouseOverUi = pcall(ISUIElement.isMouseOverAnyUI)
		if not okUi then
			trace("floor-drop fallback=UI-state-error")
			return
		end
		if mouseOverUi then
			trace("floor-drop skipped=cursor-over-UI")
			return
		end
		if not ISInventoryPaneContextMenu
				or type(ISInventoryPaneContextMenu.dropItem) ~= "function" then
			trace("floor-drop fallback=vanilla-drop-api-unavailable")
			return
		end

		local items, staleIds = liveOverflowItems(self.grid.inventory, overflowStack)
		if #items == 0 then
			trace("floor-drop fallback=no-live-items stale-ids=" .. tostring(staleIds))
			return
		end
		local dropCalls = 0
		for _, overflowItem in ipairs(items) do
			local okDrop = pcall(ISInventoryPaneContextMenu.dropItem, overflowItem, self.playerNum)
			if okDrop then dropCalls = dropCalls + 1 end
		end
		trace("floor-drop source=overflow items=" .. tostring(#items)
			.. " drop-calls=" .. tostring(dropCalls) .. " stale-ids=" .. tostring(staleIds))
	end

	renderer.ChilaSedaOverflowFloorDropInstalled = true
	installed = true
	trace("installed events=move,move-outside,mouse-up-outside drop=vanilla")
	return true
end

if Events and Events.OnGameBoot and type(Events.OnGameBoot.Add) == "function" then
	Events.OnGameBoot.Add(install)
end
if Events and Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then
	Events.OnGameStart.Add(install)
end
install()
