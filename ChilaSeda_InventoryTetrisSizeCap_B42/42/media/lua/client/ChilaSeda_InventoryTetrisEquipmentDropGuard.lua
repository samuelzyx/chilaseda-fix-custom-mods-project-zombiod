local TAG = "[ChilaSeda_InventoryTetrisEquipmentDropGuard] "
local MAX_TRACE_LINES = 24
local traceLines = 0
local TRACE_ENABLED = true

local function trace(message)
	if not TRACE_ENABLED or traceLines >= MAX_TRACE_LINES then return end
	traceLines = traceLines + 1
	print(TAG .. tostring(message))
end

local function requiredTable(moduleName)
	local ok, value = pcall(require, moduleName)
	if ok and type(value) == "table" then return value end
	return nil
end

local settings = requiredTable("EquipmentUI/Settings")
local dragAndDrop = requiredTable("EquipmentUI/DragAndDrop")
local equipmentSlot = requiredTable("EquipmentUI/UI/Slots/EquipmentSlot")
local equipmentSuperSlot = requiredTable("EquipmentUI/UI/Slots/EquipmentSuperSlot")

if not settings or not settings.InventoryTetris then
	trace("install skipped=Equipment-UI-or-Inventory-Tetris-unavailable")
	return
end

if not dragAndDrop or type(dragAndDrop.cancelDrag) ~= "function"
		or not equipmentSlot or type(equipmentSlot.doDropOrUnequip) ~= "function" then
	trace("install fallback=deferred-cancel-API-unavailable")
	return
end

local function itemInSlot(slot)
	if not slot then return nil end
	local ok, item = pcall(function() return slot.item end)
	if ok then return item end
	return nil
end

local function topSlot(owner)
	if not owner or type(owner.getTopSlot) ~= "function" then return nil end
	local ok, slot = pcall(owner.getTopSlot, owner)
	if ok then return slot end
	return nil
end

local function itemType(item)
	if not item or type(item.getFullType) ~= "function" then return "unknown" end
	local ok, value = pcall(item.getFullType, item)
	if ok and type(value) == "string" then return value end
	return "unknown"
end

local function scheduleCapturedCancel(owner, originSlot, item, resolveCurrentSlot)
	if not originSlot or not item then
		trace("cancel fallback=origin-slot-unavailable; item-retained")
		if type(dragAndDrop.endDrag) == "function" then
			pcall(dragAndDrop.endDrag)
		end
		return
	end

	local callback = function(cancelledOwner)
		local callbackOwner = cancelledOwner or owner
		local currentSlot = resolveCurrentSlot and resolveCurrentSlot(callbackOwner) or callbackOwner
		if currentSlot ~= originSlot or itemInSlot(currentSlot) ~= item then
			trace("cancel skipped=slot-item-changed item=" .. itemType(item))
			return
		end
		trace("cancel accepted=slot-item-still-present item=" .. itemType(item))
		return equipmentSlot.doDropOrUnequip(callbackOwner, item)
	end

	local ok = pcall(dragAndDrop.cancelDrag, owner, callback)
	if not ok then
		trace("cancel fallback=queue-failed; item-retained")
		if type(dragAndDrop.endDrag) == "function" then
			pcall(dragAndDrop.endDrag)
		end
	end
end

if not equipmentSlot._chilaSedaTetrisCapturedDropInstalled then
	local original = equipmentSlot.onMouseUpOutside
	if type(original) == "function" then
		equipmentSlot.onMouseUpOutside = function(self, x, y)
			local item = itemInSlot(self)
			if not item then return original(self, x, y) end
			scheduleCapturedCancel(self, self, item)
		end
		equipmentSlot._chilaSedaTetrisCapturedDropInstalled = true
		trace("hook installed=EquipmentSlot.onMouseUpOutside")
	else
		trace("hook fallback=EquipmentSlot.onMouseUpOutside-unavailable")
	end
end

if equipmentSuperSlot and not equipmentSuperSlot._chilaSedaTetrisCapturedDropInstalled then
	local original = equipmentSuperSlot.onMouseUpOutside
	if type(original) == "function" then
		equipmentSuperSlot.onMouseUpOutside = function(self, x, y)
			local originSlot = topSlot(self)
			local item = itemInSlot(originSlot)
			if not item then return original(self, x, y) end
			scheduleCapturedCancel(self, originSlot, item, topSlot)
		end
		equipmentSuperSlot._chilaSedaTetrisCapturedDropInstalled = true
		trace("hook installed=EquipmentSuperSlot.onMouseUpOutside")
	else
		trace("hook fallback=EquipmentSuperSlot.onMouseUpOutside-unavailable")
	end
end
