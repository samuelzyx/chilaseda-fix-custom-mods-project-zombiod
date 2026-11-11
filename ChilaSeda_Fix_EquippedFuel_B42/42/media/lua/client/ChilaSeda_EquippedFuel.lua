require "Camping/ISCampingMenu"
require "TimedActions/ISTimedActionQueue"

if ISCampingMenu.ChilaSedaEquippedFuelInstalled then return end

local originalGetNearbyFuelInfo = ISCampingMenu.getNearbyFuelInfo
local originalDoAddFuelOption = ISCampingMenu.doAddFuelOption

local function isFuel(item)
	if not item or item:isFavorite() or not ISCampingMenu.shouldBurn(item, true) then
		return false
	end
	return item:hasTag(ItemTag.IS_FIRE_FUEL)
		or item:getFireFuelRatio() > 0
		or (campingFuelCategory[item:getCategory()] and campingFuelCategory[item:getCategory()] ~= 0)
		or (campingFuelType[item:getType()] and campingFuelType[item:getType()] ~= 0)
end

local function getEquippedFuel(playerObj)
	local result = {}
	local seen = {}
	local inventory = playerObj:getInventory()

	local function add(item)
		if not item or seen[item] or item:getContainer() ~= inventory then return end
		if not playerObj:isEquipped(item) or not isFuel(item) then return end
		seen[item] = true
		result[#result + 1] = item
	end

	add(playerObj:getPrimaryHandItem())
	add(playerObj:getSecondaryHandItem())
	return result
end

local function addEquippedFuel(playerObj, target, item, timedAction, fuelAmount)
	if not playerObj or not target or not item or not timedAction then return end
	if item:getContainer() ~= playerObj:getInventory()
			or not playerObj:isEquipped(item) or not isFuel(item) then
		return
	end
	if fuelAmount <= 0 or not ISCampingMenu.walkToCampfire(playerObj, target:getSquare()) then
		return
	end
	ISTimedActionQueue.add(timedAction:new(playerObj, target, item, fuelAmount))
end

ISCampingMenu.getNearbyFuelInfo = function(playerObj, ...)
	local fuelInfo = originalGetNearbyFuelInfo(playerObj, ...)
	if fuelInfo then fuelInfo.ChilaSedaEquippedFuelPlayer = playerObj end
	return fuelInfo
end

ISCampingMenu.doAddFuelOption = function(context, worldobjects, currentFuel, fuelInfo, target, timedAction, playerObj)
	local firstOption = #context.options + 1
	local result = originalDoAddFuelOption(context, worldobjects, currentFuel, fuelInfo, target, timedAction, playerObj)
	if result == false then return result end

	playerObj = playerObj or (fuelInfo and fuelInfo.ChilaSedaEquippedFuelPlayer)
	if not playerObj then return result end

	local root = context.options[firstOption]
	local subMenu = root and root.subOption and context:getSubMenu(root.subOption)
	if not subMenu then return result end

	for _, item in ipairs(getEquippedFuel(playerObj)) do
		local fuelAmount = ISCampingMenu.getFuelDurationForItem(item)
		local option = subMenu:addActionsOption(
			item:getName() .. " (en mano)",
			addEquippedFuel,
			target,
			item,
			timedAction,
			fuelAmount
		)
		option.itemForTexture = item
		if currentFuel + fuelAmount > getCampingFuelMax() then
			option.notAvailable = true
			option.toolTip = ISWorldObjectContextMenu.addToolTip()
			option.toolTip.description = getText("ContextMenu_Fuel_Full3")
		end
	end

	return result
end

ISCampingMenu.ChilaSedaEquippedFuelInstalled = true
print("[ChilaSeda_EquippedFuel] Equipped fuel options installed.")
