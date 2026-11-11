require "Fluids/ISFluidUtil"

local TAG = "[ChilaSeda_AccessibleFluidTransfer] "
local originalValidate = ISFluidUtil and ISFluidUtil.validateContainer

if type(originalValidate) ~= "function" or ISFluidUtil.ChilaSedaAccessibleOwners then
	print(TAG .. "fluid validation unavailable or already patched; skipped")
	return
end

local function addAccessibleRoots(player, roots)
	if not player then return end
	local inventory = player:getInventory()
	if inventory then roots[inventory] = true end
	local playerNum = player:getPlayerNum()
	local page = type(getPlayerInventory) == "function" and getPlayerInventory(playerNum) or nil
	local loot = type(getPlayerLoot) == "function" and getPlayerLoot(playerNum) or nil
	local function addPageRoot(ui)
		local pane = ui and ui.inventoryPane
		local container = pane and pane.inventory
		if container and container:getType() ~= "floor" then
			roots[container] = true
		end
	end
	addPageRoot(page)
	addPageRoot(loot)
end

local function itemHasAccessibleRoot(item)
	if not item or type(getSpecificPlayer) ~= "function" then return false end
	local player = getSpecificPlayer(0)
	if not player then return false end
	local roots = {}
	addAccessibleRoots(player, roots)
	local container = item:getContainer()
	local visited = {}
	while container and not visited[container] do
		if roots[container] then return true end
		visited[container] = true
		local ok, parentItem = pcall(function() return container:getContainingItem() end)
		if not ok or not parentItem then return false end
		local okParent, parentContainer = pcall(function() return parentItem:getContainer() end)
		if not okParent then return false end
		container = parentContainer
	end
	return false
end

ISFluidUtil.validateContainer = function(container)
	local ok, valid = pcall(originalValidate, container)
	if ok and valid then return true end
	if not container or container.Type ~= "ISFluidContainer" then return false end
	local okOwner, owner = pcall(function() return container:getOwner() end)
	if not okOwner or not owner or not instanceof(owner, "InventoryItem") then return false end
	local okAccessible, accessible = pcall(itemHasAccessibleRoot, owner)
	return okAccessible and accessible == true
end

ISFluidUtil.ChilaSedaAccessibleOwners = true
print(TAG .. "nested and open inventory fluid containers are valid without moving items")
