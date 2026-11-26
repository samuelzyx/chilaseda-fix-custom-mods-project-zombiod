require "TimedActions/ISTimedActionQueue"

local TAG = "[ChilaSeda_AutoEquipBrokenWeapon] "
local MOD_ID = "ChilaSeda_AutoEquipBrokenWeapon_B42"
local PAGE_NAME = "Reemplazo rapido de armas"
local SAME_KEY_ID = "sameWeaponKey"
local OTHER_KEY_ID = "otherClassKey"
local DELETE_BROKEN_OPTION_ID = "deleteBrokenWeapon"
local DEFAULT_SAME_KEY = Keyboard and Keyboard.KEY_A or 30
local DEFAULT_OTHER_KEY = Keyboard and Keyboard.KEY_S or 31
local MAX_TRACE_LINES = 80
local MAX_EQUIP_RESUME_TRACE_LINES = 24
local TRACE_EQUIP_RESUME = true

local traceCount = 0
local equipResumeTraceCount = 0
local missingApiLogged = {}
local sameKey = DEFAULT_SAME_KEY
local otherKey = DEFAULT_OTHER_KEY
local sameKeyOption
local otherKeyOption
local deleteBrokenWeaponOption
local deleteBrokenWeapon = true
local optionPage
local lastSettingsDiagnostic
local pendingBreakChecks = setmetatable({}, { __mode = "k" })
local lastBrokenWeapon = setmetatable({}, { __mode = "k" })
local reportedBreaks = setmetatable({}, { __mode = "k" })
local pendingEquipRequests = setmetatable({}, { __mode = "k" })
local activeEquipRequest
local originalQueueAdd = ISTimedActionQueue and ISTimedActionQueue.add
local originalQueueReset = ISTimedActionQueue and ISTimedActionQueue.resetQueue

local function trace(message)
	if traceCount >= MAX_TRACE_LINES then return end
	traceCount = traceCount + 1
	print(TAG .. tostring(message):gsub("[\r\n]", " "))
end

local function traceEquipResume(message)
	if not TRACE_EQUIP_RESUME or equipResumeTraceCount >= MAX_EQUIP_RESUME_TRACE_LINES then return end
	equipResumeTraceCount = equipResumeTraceCount + 1
	trace("equip-resume " .. tostring(message))
end

local function safeMethod(target, name, ...)
	if target == nil then return nil end
	local okLookup, method = pcall(function() return target[name] end)
	if not okLookup or type(method) ~= "function" then return nil end
	local ok, result = pcall(method, target, ...)
	if ok then return result end
	return nil
end

local function sameItem(first, second)
	if first == second then return first ~= nil end
	local firstId = safeMethod(first, "getID")
	local secondId = safeMethod(second, "getID")
	return firstId ~= nil and secondId ~= nil and firstId == secondId
end

local function installEquipResumeHooks()
	if not ISTimedActionQueue or type(originalQueueAdd) ~= "function"
			or type(originalQueueReset) ~= "function" then
		trace("fallback api=ISTimedActionQueue.add/resetQueue reason=Ctrl+A replacements will not auto-resume")
		return false
	end

	ISTimedActionQueue.add = function(action, ...)
		local request = activeEquipRequest
		local tagged = request and action and action.character == request.player
		if tagged then
			action.chilaSedaBrokenWeaponEquipRequest = request
			action.stopOnWalk = false
			action.stopOnRun = false
			action.stopOnAim = false
		end
		local results = { originalQueueAdd(action, ...) }
		if tagged then
			request.actionsQueued = (request.actionsQueued or 0) + 1
			request.hasBeenQueued = true
		end
		return unpack(results)
	end

	ISTimedActionQueue.resetQueue = function(queue, ...)
		local request = queue and pendingEquipRequests[queue.character]
		local interrupted = false
		if request and type(queue.queue) == "table" then
			for _, action in ipairs(queue.queue) do
				if action.chilaSedaBrokenWeaponEquipRequest == request then
					interrupted = true
					break
				end
			end
		end
		local results = { originalQueueReset(queue, ...) }
		if interrupted and request then
			request.pendingResume = true
			request.resumeDelay = 1
			traceEquipResume("event=queue-reset item="
				.. tostring(safeMethod(request.item, "getFullType"))
				.. " result=pending")
		end
		return unpack(results)
	end
	return true
end

local function logMissingApi(name, detail)
	if missingApiLogged[name] then return end
	missingApiLogged[name] = true
	trace("fallback api=" .. name .. " reason=" .. tostring(detail or "unavailable"))
end

local function scalarName(value)
	if type(value) == "string" and value ~= "" then return value end
	if type(value) == "number" then return tostring(value) end
	if value == nil then return nil end
	local nested = safeMethod(value, "getType") or safeMethod(value, "getId")
	if type(nested) == "string" and nested ~= "" then return nested end
	local ok, rendered = pcall(tostring, value)
	if ok and type(rendered) == "string" and rendered ~= "" then
		if not rendered:find("userdata:", 1, true) and not rendered:find("table:", 1, true) then
			return rendered
		end
	end
	return nil
end

local function fullType(item)
	return scalarName(safeMethod(item, "getFullType"))
		or scalarName(safeMethod(item, "getType"))
end

local function weaponClass(item)
	for _, method in ipairs({ "getPerk", "getWeaponCategory", "getSubCategory", "getCategories" }) do
		local value = safeMethod(item, method)
		local name = scalarName(value)
		if not name and value ~= nil then
			local size = safeMethod(value, "size")
			if type(size) == "number" and size > 0 then
				name = scalarName(safeMethod(value, "get", 0))
			end
		end
		if name then return name:lower() end
	end
	local scriptItem = safeMethod(item, "getScriptItem")
	for _, method in ipairs({ "getWeaponCategory", "getSubCategory", "getCategories" }) do
		local value = safeMethod(scriptItem, method)
		local name = scalarName(value)
		if not name and value ~= nil then
			local size = safeMethod(value, "size")
			if type(size) == "number" and size > 0 then
				name = scalarName(safeMethod(value, "get", 0))
			end
		end
		if name then return name:lower() end
	end
	return fullType(item) and fullType(item):lower() or nil
end

local function isMeleeWeapon(item)
	if not item or type(instanceof) ~= "function" then return false end
	local ok, isWeapon = pcall(instanceof, item, "HandWeapon")
	if not ok or not isWeapon then return false end
	if safeMethod(item, "isRanged") == true
			or safeMethod(item, "isAimedFirearm") == true
			or safeMethod(item, "getSwingAnim") == "Handgun" then
		return false
	end
	return true
end

local function isBroken(item)
	if safeMethod(item, "isBroken") == true then return true end
	local condition = safeMethod(item, "getCondition")
	return type(condition) == "number" and condition <= 0
end

local function isUsableMeleeWeapon(item)
	return isMeleeWeapon(item) and not isBroken(item)
end

local function playerNumber(player)
	local number = safeMethod(player, "getPlayerNum")
	return type(number) == "number" and number or 0
end

local function isLocalPlayer(player)
	if not player or type(getSpecificPlayer) ~= "function" then return false end
	local ok, localPlayer = pcall(getSpecificPlayer, playerNumber(player))
	return ok and localPlayer == player
end

local function collectionSize(collection)
	local size = safeMethod(collection, "size")
	if type(size) == "number" then return size, false end
	if type(collection) == "table" then return #collection, true end
	return nil, false
end

local function collectionItem(collection, index, isLuaArray)
	if isLuaArray then return collection[index] end
	return safeMethod(collection, "get", index)
		or safeMethod(collection, "getItemByIndex", index)
end

local function itemContainer(item)
	if not item or type(instanceof) ~= "function" then return nil end
	local ok, isContainer = pcall(instanceof, item, "InventoryContainer")
	if not ok or not isContainer then return nil end
	return safeMethod(item, "getInventory") or safeMethod(item, "getItemContainer")
end

local function collectMeleeWeapons(player)
	local found = {}
	local seenItems = {}
	local seenContainers = {}
	local scanRootAvailable = false
	local scanWornAvailable = false

	local function scanContainer(container, depth)
		if not container or seenContainers[container] then return end
		seenContainers[container] = true
		if depth > 8 then
			logMissingApi("nested-inventory-depth", "limit=8")
			return
		end
		local items = safeMethod(container, "getItems")
		if not items then
			logMissingApi("inventory-getItems", "container returned no item list")
			return
		end
		local size, isLuaArray = collectionSize(items)
		if type(size) ~= "number" then
			logMissingApi("inventory-list-size", "item list has no size method")
			return
		end
		for offset = 0, size - 1 do
			local index = isLuaArray and offset + 1 or offset
			local item = collectionItem(items, index, isLuaArray)
			if item and not seenItems[item] then
				seenItems[item] = true
				if isUsableMeleeWeapon(item) then found[#found + 1] = item end
				local nested = itemContainer(item)
				if nested then scanContainer(nested, depth + 1) end
			end
		end
	end

	local inventory = safeMethod(player, "getInventory")
	if inventory then
		scanRootAvailable = true
		scanContainer(inventory, 0)
	else
		logMissingApi("player-inventory", "getInventory unavailable")
	end

	local worn = safeMethod(player, "getWornItems")
	if worn then
		local size, isLuaArray = collectionSize(worn)
		if type(size) == "number" then
			scanWornAvailable = true
			for offset = 0, size - 1 do
				local index = isLuaArray and offset + 1 or offset
				local item = collectionItem(worn, index, isLuaArray)
				if item and not seenItems[item] then
					seenItems[item] = true
					local nested = itemContainer(item)
					if nested then scanContainer(nested, 0) end
				end
			end
		else
			logMissingApi("worn-items-size", "worn item list has no size method")
		end
	else
		logMissingApi("player-worn-items", "getWornItems unavailable")
	end

	trace("inventory-scan root=" .. tostring(scanRootAvailable)
		.. " worn=" .. tostring(scanWornAvailable) .. " meleeCandidates=" .. tostring(#found))
	return found
end

local function currentlyEquipped(player, item)
	return safeMethod(player, "getPrimaryHandItem") == item
		or safeMethod(player, "getSecondaryHandItem") == item
end

local function findReplacement(player, broken, mode)
	if not player or not broken then return nil end
	local weapons = collectMeleeWeapons(player)
	for _, item in ipairs(weapons) do
		if not currentlyEquipped(player, item) then
			local candidateType = fullType(item)
			local candidateClass = weaponClass(item)
			if mode == "same" and broken.fullType and candidateType == broken.fullType then
				return item
			end
			if mode == "other" and candidateClass ~= broken.weaponClass then
				return item
			end
		end
	end
	return nil
end

local function keyName(key)
	if Keyboard and type(Keyboard.getKeyName) == "function" then
		local ok, name = pcall(Keyboard.getKeyName, key)
		if ok and type(name) == "string" and name ~= "" then return name end
	end
	return tostring(key)
end

local function showHalo(player, message, color, protected)
	if not player then return false end
	local chosen = color or { 255, 220, 120 }
	if protected then
		local viewpointHalo = ChilaSeda_ViewpointHaloNotifications
		if type(viewpointHalo) == "table" and type(viewpointHalo.showProtected) == "function" then
			local r, g, b = tonumber(chosen[1]), tonumber(chosen[2]), tonumber(chosen[3])
			if r and g and b then
				if r > 1 or g > 1 or b > 1 then r, g, b = r / 255, g / 255, b / 255 end
				local ok, queued = pcall(viewpointHalo.showProtected, message,
					{ r = r, g = g, b = b }, nil, nil, "AutoEquipBrokenWeapon")
				if ok and queued == true then
					trace("halo-notice source=broken-weapon route=protected result=queued")
					return true
				end
				trace("fallback protected-halo route=HaloTextHelper.addText reason="
					.. tostring(ok and "viewpoint-rejected" or queued))
			else
				trace("fallback protected-halo route=HaloTextHelper.addText reason=color-unavailable")
			end
		else
			trace("fallback protected-halo route=HaloTextHelper.addText reason=viewpoint-api-unavailable")
		end
	end
	if not HaloTextHelper or type(HaloTextHelper.addText) ~= "function" then
		logMissingApi("HaloTextHelper.addText", "notice not shown")
		return false
	end
	local ok, err = pcall(HaloTextHelper.addText, player, message, " ",
		chosen[1], chosen[2], chosen[3])
	if not ok then
		trace("fallback halo-notice=failed reason=" .. tostring(err))
		return false
	end
	trace("halo-notice source=AutoEquipBrokenWeapon route=HaloTextHelper.addText priority=transient result=queued")
	return true
end

local function weaponLabel(item)
	return scalarName(safeMethod(item, "getDisplayName")) or fullType(item) or "arma melee"
end

local function reportBroken(player, item)
	if not isLocalPlayer(player) or not isMeleeWeapon(item) or not isBroken(item) then return false end
	if reportedBreaks[item] then return false end
	reportedBreaks[item] = true
	local record = {
		fullType = fullType(item),
		weaponClass = weaponClass(item),
		itemId = scalarName(safeMethod(item, "getID")),
		label = weaponLabel(item),
		item = item,
	}
	lastBrokenWeapon[player] = record
	local text = "Arma rota: Ctrl+" .. keyName(sameKey)
		.. " misma arma | Ctrl+" .. keyName(otherKey) .. " otra clase"
	showHalo(player, text, nil, true)
	trace("break-detected weapon=" .. tostring(record.fullType)
		.. " class=" .. tostring(record.weaponClass) .. " condition="
		.. tostring(safeMethod(item, "getCondition")) .. " result=prompted")
	return true
end

local function queueEquip(player, item, request)
	local playerId = playerNumber(player)
	local bothHands = safeMethod(item, "isTwoHandWeapon") == true
		or safeMethod(item, "isRequiresEquippedBothHands") == true
	request.item = item
	request.bothHands = bothHands
	request.actionsQueued = 0
	request.pendingResume = false
	local contextMenu = ISInventoryPaneContextMenu
	if contextMenu and type(contextMenu.equipWeapon) == "function" then
		local previousRequest = activeEquipRequest
		activeEquipRequest = request
		local ok, err = pcall(contextMenu.equipWeapon, item, true, bothHands, playerId)
		activeEquipRequest = previousRequest
		if request.actionsQueued > 0 then
			request.hasBeenQueued = true
			trace("equip-queued item=" .. tostring(fullType(item))
				.. " path=vanilla-context-menu actions=" .. tostring(request.actionsQueued))
			return true
		end
		if not ok then trace("fallback equip-context-menu=failed reason=" .. tostring(err)) end
	end

	local queue = ISTimedActionQueue
	local actionType = ISEquipWeaponAction
	if not queue or type(queue.add) ~= "function" or not actionType
			or type(actionType.new) ~= "function" then
		logMissingApi("vanilla-equip-action", "cannot queue replacement")
		return false
	end
	local inventory = safeMethod(player, "getInventory")
	local from = safeMethod(item, "getContainer")
	local previousRequest = activeEquipRequest
	activeEquipRequest = request
	if from and inventory and from ~= inventory and ISInventoryTransferUtil
			and type(ISInventoryTransferUtil.newInventoryTransferAction) == "function" then
		local ok, transfer = pcall(ISInventoryTransferUtil.newInventoryTransferAction,
			player, item, from, inventory)
		if ok and transfer then
			local queuedTransfer, transferError = pcall(queue.add, transfer)
			if not queuedTransfer then trace("fallback transfer-action=failed reason=" .. tostring(transferError)) end
		else trace("fallback transfer-action=failed") end
	end
	local ok, action = pcall(actionType.new, actionType, player, item, 50, true, bothHands)
	if not ok or not action then
		activeEquipRequest = previousRequest
		trace("fallback equip-action=failed reason=" .. tostring(action))
		return request.actionsQueued > 0
	end
	local queued, err = pcall(queue.add, action)
	activeEquipRequest = previousRequest
	if not queued then
		trace("fallback equip-queue=failed reason=" .. tostring(err))
		return request.actionsQueued > 0
	end
	if request.actionsQueued > 0 then
		request.hasBeenQueued = true
		trace("equip-queued item=" .. tostring(fullType(item))
			.. " path=direct-action actions=" .. tostring(request.actionsQueued))
		return true
	end
	return false
end

local function consumeKey(key)
	if GameKeyboard and type(GameKeyboard.eatKeyPress) == "function" then
		local ok = pcall(GameKeyboard.eatKeyPress, key)
		if ok then return true end
	end
	logMissingApi("GameKeyboard.eatKeyPress", "configured chord may reach base binding")
	return false
end

local function keyDown(code)
	if not Keyboard or type(Keyboard.isKeyDown) ~= "function" or code == nil then return false end
	local ok, down = pcall(Keyboard.isKeyDown, code)
	return ok and down == true
end

local function exactCtrlChord()
	local ctrl = keyDown(Keyboard and Keyboard.KEY_LCONTROL)
		or keyDown(Keyboard and Keyboard.KEY_RCONTROL)
	if not ctrl and type(isCtrlKeyDown) == "function" then
		local ok, down = pcall(isCtrlKeyDown)
		ctrl = ok and down == true
	end
	local alt = keyDown(Keyboard and Keyboard.KEY_LMENU)
		or keyDown(Keyboard and Keyboard.KEY_RMENU)
	local shift = keyDown(Keyboard and Keyboard.KEY_LSHIFT)
		or keyDown(Keyboard and Keyboard.KEY_RSHIFT)
	return ctrl and not alt and not shift
end

local function applyOptions()
	local same = safeMethod(sameKeyOption, "getValue")
	local other = safeMethod(otherKeyOption, "getValue")
	local deleteBroken = safeMethod(deleteBrokenWeaponOption, "getValue")
	if type(same) == "number" and same > 0 then sameKey = same end
	if type(other) == "number" and other > 0 then otherKey = other end
	if type(deleteBroken) == "boolean" then deleteBrokenWeapon = deleteBroken end
	if sameKey == otherKey then
		otherKey = DEFAULT_OTHER_KEY ~= sameKey and DEFAULT_OTHER_KEY or DEFAULT_SAME_KEY
		if otherKeyOption and type(otherKeyOption.setValue) == "function" then
			pcall(otherKeyOption.setValue, otherKeyOption, otherKey)
		end
		trace("settings fallback=duplicate-keys other=" .. tostring(otherKey))
	end
	local diagnostic = "settings result=ready sameKey=" .. tostring(sameKey)
		.. " otherKey=" .. tostring(otherKey) .. " modifier=CTRL"
		.. " deleteBroken=" .. tostring(deleteBrokenWeapon)
	if diagnostic ~= lastSettingsDiagnostic then
		lastSettingsDiagnostic = diagnostic
		trace(diagnostic)
	end
end

local function removeBrokenWeapon(player, broken)
	if not deleteBrokenWeapon then
		trace("broken-weapon result=retained reason=option-disabled")
		return false
	end
	local item = broken and broken.item
	if not item then
		trace("fallback broken-weapon-delete=skipped reason=item-reference-unavailable")
		return false
	end
	local container = safeMethod(item, "getContainer")
	if not container then
		local inventory = safeMethod(player, "getInventory")
		if safeMethod(inventory, "contains", item) == true then container = inventory end
	end
	if not container then
		trace("broken-weapon result=already-removed weapon=" .. tostring(broken.fullType))
		return true
	end
	local presentBefore = safeMethod(container, "contains", item)
	if presentBefore == false then
		trace("broken-weapon result=already-removed weapon=" .. tostring(broken.fullType))
		return true
	end
	local ok, err = pcall(function() container:Remove(item) end)
	if not ok then
		trace("fallback broken-weapon-delete=failed reason=" .. tostring(err))
		return false
	end
	local stillPresent = safeMethod(container, "contains", item)
	if stillPresent == true then
		trace("fallback broken-weapon-delete=not-removed weapon=" .. tostring(broken.fullType))
		return false
	end
	trace("broken-weapon result=removed weapon=" .. tostring(broken.fullType)
		.. " verified=" .. tostring(stillPresent == false))
	return true
end

local function replacementIsEquipped(player, request)
	local primary = safeMethod(player, "getPrimaryHandItem")
	local secondary = safeMethod(player, "getSecondaryHandItem")
	if request.bothHands then
		return sameItem(primary, request.item) and sameItem(secondary, request.item)
	end
	return sameItem(primary, request.item) or sameItem(secondary, request.item)
end

local function finishEquipRequest(player, request)
	if pendingEquipRequests[player] ~= request then return end
	pendingEquipRequests[player] = nil
	if lastBrokenWeapon[player] == request.broken then
		removeBrokenWeapon(player, request.broken)
		lastBrokenWeapon[player] = nil
	end
	traceEquipResume("event=complete item=" .. tostring(fullType(request.item))
		.. " attempts=" .. tostring(request.attempts or 0))
end

local function resumePendingReplacement()
	for player, request in pairs(pendingEquipRequests) do
		if safeMethod(player, "isDead") == true then
			pendingEquipRequests[player] = nil
			traceEquipResume("event=stopped reason=player-dead")
		else
			local isAttacking = safeMethod(player, "isAttacking") == true
			local queue
			if ISTimedActionQueue and type(ISTimedActionQueue.getTimedActionQueue) == "function" then
				local ok, value = pcall(ISTimedActionQueue.getTimedActionQueue, player)
				if ok then queue = value end
			end
			if not isAttacking and queue and type(queue.queue) == "table"
					and #queue.queue == 0 then
				if request.resumeDelay and request.resumeDelay > 0 then
					request.resumeDelay = request.resumeDelay - 1
				elseif replacementIsEquipped(player, request) then
					finishEquipRequest(player, request)
				elseif request.hasBeenQueued then
					local item = request.item
					if not safeMethod(item, "getContainer") then
						item = findReplacement(player, request.broken, request.mode)
					end
					if not item then
						pendingEquipRequests[player] = nil
						traceEquipResume("event=stopped reason=replacement-unavailable; broken-weapon-context-retained")
					elseif (request.attempts or 0) >= 8 then
						pendingEquipRequests[player] = nil
						traceEquipResume("event=stopped reason=retry-limit; broken-weapon-context-retained")
					else
						request.attempts = (request.attempts or 0) + 1
						request.item = item
						traceEquipResume("event=retry item=" .. tostring(fullType(item))
							.. " attempt=" .. tostring(request.attempts))
						if not queueEquip(player, item, request) then
							pendingEquipRequests[player] = nil
							traceEquipResume("event=stopped reason=queue-failed; broken-weapon-context-retained")
						end
					end
				end
			end
		end
	end
end

local function installOptions()
	if optionPage then return true end
	if type(require) == "function" then pcall(require, "PZAPI/ModOptions") end
	if not (PZAPI and PZAPI.ModOptions and type(PZAPI.ModOptions.create) == "function") then
		logMissingApi("PZAPI.ModOptions", "using defaults A/S and deleteBroken=true")
		return false
	end
	local ok, page = pcall(PZAPI.ModOptions.create, PZAPI.ModOptions, MOD_ID, PAGE_NAME)
	if not ok or not page then
		trace("fallback options-page=unavailable result=defaults-A-S")
		return false
	end
	optionPage = page
	if type(page.addTitle) == "function" then
		pcall(page.addTitle, page, "Atajos para armas melee")
	end
	if type(page.addDescription) == "function" then
		pcall(page.addDescription, page,
			"Despues de que se rompa un arma, usa Ctrl mas una tecla para equipar el reemplazo.")
	end
	if type(page.addKeyBind) == "function" then
		local sameOk, same = pcall(page.addKeyBind, page, SAME_KEY_ID,
			"Misma arma; Ctrl +", DEFAULT_SAME_KEY,
			"Elige la tecla que acompana a Ctrl. Predeterminada: A.")
		local otherOk, other = pcall(page.addKeyBind, page, OTHER_KEY_ID,
			"Arma de otra clase; Ctrl +", DEFAULT_OTHER_KEY,
			"Elige la tecla que acompana a Ctrl. Predeterminada: S.")
		if sameOk then sameKeyOption = same end
		if otherOk then otherKeyOption = other end
	else
		logMissingApi("PZAPI.ModOptions.addKeyBind", "using defaults A/S")
	end
	if type(page.addTickBox) == "function" then
		local added, option = pcall(page.addTickBox, page, DELETE_BROKEN_OPTION_ID,
			"Eliminar el arma melee rota al cambiar", true,
			"Activada por defecto. Desactiva esta opcion para conservar el arma rota en tu inventario.")
		if added then
			deleteBrokenWeaponOption = option
		else
			trace("fallback options-tickbox=failed id=" .. DELETE_BROKEN_OPTION_ID
				.. " result=delete-enabled reason=" .. tostring(option))
		end
	else
		logMissingApi("PZAPI.ModOptions.addTickBox", "delete broken weapon remains enabled by default")
	end
	page.apply = applyOptions
	applyOptions()
	trace("settings-page result=installed id=" .. MOD_ID)
	return true
end

local function onKeyStartPressed(key)
	local mode
	if key == sameKey then mode = "same"
	elseif key == otherKey then mode = "other"
	else return false end
	if not exactCtrlChord() then return false end
	local player = type(getSpecificPlayer) == "function" and getSpecificPlayer(0) or nil
	if not player then
		trace("hotkey action=" .. mode .. " result=skipped reason=player-unavailable")
		return false
	end
	local consumed = consumeKey(key)
	local activeRequest = pendingEquipRequests[player]
	if activeRequest then
		traceEquipResume("event=hotkey-ignored result=replacement-already-pending")
		return true
	end
	local broken = lastBrokenWeapon[player]
	trace("hotkey action=" .. mode .. " key=" .. tostring(key)
		.. " modifier=CTRL consumed=" .. tostring(consumed))
	if not broken then
		trace("hotkey action=" .. mode .. " result=no-break-context")
		return true
	end
	local item = findReplacement(player, broken, mode)
	if not item then
		local message = mode == "same"
			and "No hay otra arma del mismo tipo en tus bolsas"
			or "No hay un arma melee de otra clase en tus bolsas"
		showHalo(player, message, { 255, 130, 110 })
		trace("replacement mode=" .. mode .. " result=no-candidate")
		return true
	end
	local request = { player = player, broken = broken, item = item, mode = mode, attempts = 0 }
	pendingEquipRequests[player] = request
	if queueEquip(player, item, request) then
		showHalo(player, "Equipando: " .. weaponLabel(item), { 150, 255, 170 })
		traceEquipResume("event=queued item=" .. tostring(fullType(item))
			.. " result=wait-for-equipped-hand")
	else
		pendingEquipRequests[player] = nil
		showHalo(player, "No se pudo encolar el reemplazo; revisa el inventario", { 255, 130, 110 })
	end
	return true
end

local function onWeaponHit(player, weapon)
	if not isLocalPlayer(player) or not isMeleeWeapon(weapon) then return end
	if not isBroken(weapon) then reportedBreaks[weapon] = nil end
	if reportBroken(player, weapon) then return end
	if isBroken(weapon) then return end
	pendingBreakChecks[player] = { item = weapon, retries = 1 }
	trace("break-check result=pending weapon=" .. tostring(fullType(weapon)))
end

local function onPlayerUpdate(player)
	local pending = pendingBreakChecks[player]
	if not pending or not isLocalPlayer(player) then return end
	if isBroken(pending.item) then
		pendingBreakChecks[player] = nil
		reportBroken(player, pending.item)
		return
	end
	if pending.retries > 0 then
		pending.retries = pending.retries - 1
		return
	end
	pendingBreakChecks[player] = nil
	trace("break-check result=not-broken weapon=" .. tostring(fullType(pending.item)))
end

local function registerEvent(event, callback, name)
	if event and type(event.Add) == "function" then
		local ok, err = pcall(event.Add, callback)
		if ok then return true end
		trace("fallback event=" .. name .. " result=registration-failed reason=" .. tostring(err))
	else
		logMissingApi("Events." .. name, "event unavailable")
	end
	return false
end

registerEvent(Events and Events.OnWeaponHitXp, onWeaponHit, "OnWeaponHitXp")
registerEvent(Events and Events.OnWeaponHitTree, onWeaponHit, "OnWeaponHitTree")
registerEvent(Events and Events.OnPlayerUpdate, onPlayerUpdate, "OnPlayerUpdate")
installEquipResumeHooks()
registerEvent(Events and Events.OnTick, resumePendingReplacement, "OnTick")
registerEvent(Events and Events.OnKeyStartPressed, onKeyStartPressed, "OnKeyStartPressed")
registerEvent(Events and Events.OnGameBoot, installOptions, "OnGameBoot")
registerEvent(Events and Events.OnGameStart, function() installOptions(); applyOptions() end, "OnGameStart")
installOptions()
	trace("load result=ready version=1.0.1")

-- Public diagnostic seam also lets the contract suite exercise the real callbacks.
ChilaSedaAutoEquipBrokenWeapon = {
	collectMeleeWeapons = collectMeleeWeapons,
	findReplacement = findReplacement,
	onWeaponHit = onWeaponHit,
	onPlayerUpdate = onPlayerUpdate,
	onKeyStartPressed = onKeyStartPressed,
	resumePendingReplacement = resumePendingReplacement,
	pendingEquipRequests = pendingEquipRequests,
	applyOptions = applyOptions,
	removeBrokenWeapon = removeBrokenWeapon,
}
