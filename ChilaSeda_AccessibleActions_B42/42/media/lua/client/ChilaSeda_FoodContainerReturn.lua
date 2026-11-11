require "TimedActions/ISEatFoodAction"

local originalEatComplete = ISEatFoodAction and ISEatFoodAction.complete
local RETURN_CONTAINER_TYPES = {
    ["Base.Bowl"] = true,
    ["Base.ClayBowl"] = true,
    ["Base.Pot"] = true,
    ["Base.PotForged"] = true,
}

local function replacementFullType(item)
    if not item or type(item.getReplaceOnUse) ~= "function" then return nil end
    local ok, replacement = pcall(item.getReplaceOnUse, item)
    if not ok or not replacement then return nil end
    local fullType = tostring(replacement)
    if not string.find(fullType, "%." ) then
        local okModule, module = pcall(item.getModuleName, item)
        if not okModule or not module then return nil end
        fullType = tostring(module) .. "." .. fullType
    end
    if RETURN_CONTAINER_TYPES[fullType] then return fullType end
    return nil
end

local function visitItems(container, callback, visitedContainers)
    if not container or visitedContainers[container] then return end
    visitedContainers[container] = true
    local okItems, items = pcall(container.getItems, container)
    if not okItems or not items then return end
    local okSize, size = pcall(items.size, items)
    if not okSize or type(size) ~= "number" then return end
    for index = 0, size - 1 do
        local okItem, item = pcall(items.get, items, index)
        if okItem and item then
            callback(item)
            local isContainer = false
            if type(instanceof) == "function" then
                local okType, result = pcall(instanceof, item, "InventoryContainer")
                isContainer = okType and result == true
            end
            if isContainer and type(item.getInventory) == "function" then
                local okInventory, nested = pcall(item.getInventory, item)
                if okInventory and nested then
                    visitItems(nested, callback, visitedContainers)
                end
            end
        end
    end
end

local function itemId(item)
    if not item or type(item.getID) ~= "function" then return nil end
    local ok, id = pcall(item.getID, item)
    if not ok or id == nil then return nil end
    return tostring(id)
end

local function snapshotReplacementIds(character, fullType)
    local ids = {}
    local inventory = character and character:getInventory()
    if not inventory then return ids end
    visitItems(inventory, function(item)
        local ok, candidateType = pcall(item.getFullType, item)
        local id = itemId(item)
        if ok and tostring(candidateType) == fullType and id then ids[id] = true end
    end, {})
    return ids
end

local function findNewReplacement(character, fullType, previousIds)
    local found = nil
    local inventory = character and character:getInventory()
    if not inventory then return nil end
    visitItems(inventory, function(item)
        if found then return end
        local ok, candidateType = pcall(item.getFullType, item)
        local id = itemId(item)
        if ok and tostring(candidateType) == fullType and id and not previousIds[id] then
            found = item
        end
    end, {})
    return found
end

local function returnReplacementToSource(character, sourceContainer, item)
    if not character or not sourceContainer or not item then return end
    local inventory = character:getInventory()
    local okRoot, root = pcall(sourceContainer.getOutermostContainer, sourceContainer)
    if not okRoot or root ~= inventory or sourceContainer == inventory then return end

    local okCurrent, currentContainer = pcall(item.getContainer, item)
    if not okCurrent or not currentContainer or currentContainer == sourceContainer then return end
    local okRemove = pcall(currentContainer.Remove, currentContainer, item)
    if not okRemove then return end
    local okDetached, remainingContainer = pcall(item.getContainer, item)
    if okDetached and remainingContainer == currentContainer then return end
    local okAdd = pcall(sourceContainer.AddItem, sourceContainer, item)
    if not okAdd then
        pcall(inventory.AddItem, inventory, item)
        return
    end
    print("[ChilaSeda_FoodContainerReturn] returned " .. tostring(item:getFullType())
        .. " to the container where its prepared food came from")
end

if originalEatComplete then
    function ISEatFoodAction:complete()
        local sourceContainer = self.container
        local item = self.item
        local character = self.character
        local fullType = replacementFullType(item)
        local previousIds = fullType and snapshotReplacementIds(character, fullType) or {}
        local result = originalEatComplete(self)

        if fullType then
            local replacement = findNewReplacement(character, fullType, previousIds)
            returnReplacementToSource(character, sourceContainer, replacement)
        end
        return result
    end
end
