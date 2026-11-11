require "Moveables/ISMoveablesAction"

local function getActiveContainer(playerObj)
	if not playerObj then return nil end
	local pane = ISInventoryPane and ISInventoryPane.getInventoryPane and ISInventoryPane.getInventoryPane(playerObj:getPlayerNum())
	if not pane or not pane.selected then return nil end
	return pane.selected
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

local originalMoveablesNew = ISMoveablesAction.new
function ISMoveablesAction:new(character, ...)
	-- B42 passes square, mode, sprite, object, direction, item and cursor.
	-- Forward every argument, including nil slots, to the vanilla constructor.
	local o = originalMoveablesNew(self, character, ...)
	o.originalPrimaryHand = character and character:getPrimaryHandItem() or nil
	o.toolContainer = o.tool and o.tool:getContainer() or nil
	return o
end

local function selectedPlacementItemMatches(cursor, item)
	if not cursor or not item or not instanceof(item, "Moveable") then return false end
	local character = cursor.character
	local inventory = character and character:getInventory()
	if not inventory or not inventory:contains(item) then return false end
	local ok, worldSprite = pcall(function() return item:getWorldSprite() end)
	if not ok or not worldSprite or not cursor.origSpriteName then return false end
	if worldSprite == cursor.origSpriteName then return true end
	local sprite = getSprite(worldSprite)
	local grid = sprite and sprite:getSpriteGrid()
	local anchor = grid and grid:getAnchorSprite()
	return anchor ~= nil and anchor:getName() == cursor.origSpriteName
end

-- Keep the exact inventory item selected from the green Place Object option.
-- B42's cursor may fail to find it again by sprite name when Viewpoint updates
-- the placement cursor at action completion.
local function installMissingPlacementItemGuard()
	if not ISMoveableCursor or type(ISMoveableCursor.create) ~= "function"
			or ISMoveableCursor.chilaMissingPlacementItemGuard then return end
	local originalTryInitialItem = ISMoveableCursor.tryInitialItem
	if type(originalTryInitialItem) ~= "function" then return end
	ISMoveableCursor.tryInitialItem = function(cursor, item, ...)
		cursor.chilaSelectedPlacementItem = item
		return originalTryInitialItem(cursor, item, ...)
	end

	local originalCreate = ISMoveableCursor.create
	ISMoveableCursor.create = function(cursor, x, y, z, north, sprite)
		local mode = ISMoveableCursor.mode and ISMoveableCursor.mode[cursor.player]
		if mode == "place" then
			local props = cursor.currentMoveProps
			local findItem = props and props.findInInventory
			local ok, item = false, nil
			if type(findItem) == "function" then
				ok, item = pcall(findItem, props, cursor.character, cursor.origSpriteName)
			end
			local selected = cursor.chilaSelectedPlacementItem or cursor.tryInitialInvItem
			if props and (not ok or not item) and selectedPlacementItemMatches(cursor, selected) then
				local originalFind = props.findInInventory
				props.findInInventory = function(moveProps, character, spriteName, ...)
					if moveProps == props and character == cursor.character
							and spriteName == cursor.origSpriteName
							and selectedPlacementItemMatches(cursor, selected) then
						return selected
					end
					return originalFind(moveProps, character, spriteName, ...)
				end
				local createOk, result = pcall(originalCreate, cursor, x, y, z, north, sprite)
				props.findInInventory = originalFind
				if not createOk then error(result) end
				return result
			end
			if not ok or not item then
				cursor.cursorFacing = nil
				cursor.joypadFacing = nil
				cursor.objectListCache = nil
				return
			end
		end
		return originalCreate(cursor, x, y, z, north, sprite)
	end
	ISMoveableCursor.chilaMissingPlacementItemGuard = true
	print("[ChilaSeda DismantleToolEquip] v0.1.2 placement item recovery guard installed")
end

Events.OnGameStart.Add(installMissingPlacementItemGuard)

local originalMoveablesComplete = ISMoveablesAction.complete
function ISMoveablesAction:complete()
	local result = originalMoveablesComplete(self)
	local playerObj = self.character
	local inventory = playerObj and playerObj:getInventory()

	if not playerObj or not inventory then return result end

	-- Restaurar arma primaria original
	if self.originalPrimaryHand then
		if not playerObj:getPrimaryHandItem() or (self.tool and playerObj:getPrimaryHandItem() == self.tool) then
			playerObj:setPrimaryHandItem(self.originalPrimaryHand)
		end
	end

	-- Devolver herramienta a su contenedor de origen
	if self.tool and inventory:contains(self.tool) and self.toolContainer then
		tryMoveToContainer(self.tool, inventory, self.toolContainer, playerObj)
	end

	-- Enviar componentes al contenedor activo/seleccionado
	if self.result and self.result:size() then
		local activeContainer = getActiveContainer(playerObj)
		for i = 0, self.result:size() - 1 do
			local item = self.result:get(i)
			if inventory:contains(item) then
				if activeContainer and activeContainer ~= inventory then
					tryMoveToContainer(item, inventory, activeContainer, playerObj)
				end
			end
		end
	end

	return result
end
