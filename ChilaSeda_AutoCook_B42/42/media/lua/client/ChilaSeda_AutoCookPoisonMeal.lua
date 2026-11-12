require "TimedActions/ISAddItemInRecipe"

local TAG = "[ChilaSeda_AutoCookPoisonMeal] "
local RECORDS_KEY = "ChilaSeda_AutoCookPoisonIngredients"

if ISAddItemInRecipe.ChilaSedaPoisonMealInstalled then return end

local statFields = {
    { "hunger", "getHungChange", "setHungChange" },
    { "thirst", "getThirstChange", "setThirstChange" },
    { "endurance", "getEnduranceChange", "setEnduranceChange" },
    { "calories", "getCalories", "setCalories" },
    { "carbohydrates", "getCarbohydrates", "setCarbohydrates" },
    { "lipids", "getLipids", "setLipids" },
    { "proteins", "getProteins", "setProteins" },
    { "foodSickness", "getFoodSicknessChange", "setFoodSicknessChange" },
    { "painReduction", "getPainReduction", "setPainReduction" },
    { "fluReduction", "getFluReduction", "setFluReduction" },
}

local function safeCall(object, method, ...)
    if not object or type(object[method]) ~= "function" then return nil end
    local ok, value = pcall(object[method], object, ...)
    if ok and type(value) == "number" then return value end
    return nil
end

local function snapshotFood(item)
    if not item or not instanceof(item, "Food") then return nil end
    local snapshot = { poison = safeCall(item, "getPoisonPower") or 0 }
    for _, field in ipairs(statFields) do
        snapshot[field[1]] = safeCall(item, field[2])
    end
    return snapshot
end

local function hasExtraType(item, fullType)
    local extras = item and item:getExtraItems()
    if not extras then return false end
    for index = 0, extras:size() - 1 do
        if extras:get(index) == fullType then return true end
    end
    return false
end

local originalComplete = ISAddItemInRecipe.complete
ISAddItemInRecipe.complete = function(action, ...)
    local previousItem = action.baseItem
    local before = snapshotFood(previousItem)
    local previousRecords
    if previousItem and previousItem.getModData then
        local previousData = previousItem:getModData()
        previousRecords = previousData and previousData[RECORDS_KEY]
    end

    local ingredient = action.usedItem
    local ingredientType = ingredient and ingredient:getFullType()
    local ingredientPoison = safeCall(ingredient, "getPoisonPower") or 0
    local result = originalComplete(action, ...)

    if ingredientType and ingredientPoison > 0 then
        local meal = action.baseItem
        if meal and instanceof(meal, "Food") and hasExtraType(meal, ingredientType) then
            local after = snapshotFood(meal)
            local modData = meal:getModData()
            local records = modData[RECORDS_KEY]
            if type(records) ~= "table" then
                records = {}
            end
            if type(previousRecords) == "table" and records ~= previousRecords then
                local merged = {}
                for _, record in ipairs(previousRecords) do
                    merged[#merged + 1] = record
                end
                for _, record in ipairs(records) do
                    merged[#merged + 1] = record
                end
                records = merged
            end
            modData[RECORDS_KEY] = records

            local poisonDelta = math.max(0, (after and after.poison or 0)
                - (before and before.poison or 0))
            if poisonDelta == 0 then poisonDelta = ingredientPoison end

            local statDeltas = {}
            for _, field in ipairs(statFields) do
                local afterValue = after and after[field[1]]
                local beforeValue = before and before[field[1]]
                if afterValue ~= nil then
                    statDeltas[field[1]] = afterValue - (beforeValue or 0)
                end
            end

            records[#records + 1] = {
                itemType = ingredientType,
                poisonPower = poisonDelta,
                stats = statDeltas,
            }
        end
    end

    return result
end

local function getSingleSelectedFood(entries)
    local selected
    local function eachValue(collection, callback)
        if type(collection) == "table" then
            for _, value in ipairs(collection) do
                if callback(value) == false then return false end
            end
            return true
        end

        -- Inventory context menus can pass Java ArrayList instances in the
        -- nested `entry.items` field. `ipairs` and type(... ) == "table" do not
        -- see those values, so walk the Java collection explicitly.
        if collection then
            local ok, size = pcall(function() return collection:size() end)
            if ok and type(size) == "number" then
                for index = 0, size - 1 do
                    local got, value = pcall(function() return collection:get(index) end)
                    if got and callback(value) == false then return false end
                end
            end
        end
        return true
    end

    local function consider(item)
        if not item or not instanceof(item, "Food") then return true end
        if selected and selected ~= item then return false end
        selected = item
        return true
    end

    local ok = eachValue(entries, function(entry)
        if type(entry) == "table" and entry.items ~= nil then
            return eachValue(entry.items, consider)
        end
        return consider(entry)
    end)
    if not ok then
        return nil
    end
    return selected
end

local function countExtraTypes(item)
    local counts = {}
    local extras = item and item:getExtraItems()
    if not extras then return counts end
    for index = 0, extras:size() - 1 do
        local fullType = extras:get(index)
        counts[fullType] = (counts[fullType] or 0) + 1
    end
    return counts
end

local function getRemovableRecords(item)
    local modData = item and item:getModData()
    local records = modData and modData[RECORDS_KEY]
    if type(records) ~= "table" then return nil end

    local counts = countExtraTypes(item)
    local available = {}
    for _, record in ipairs(records) do
        if record and record.itemType and (record.poisonPower or 0) > 0
                and (counts[record.itemType] or 0) > 0 then
            available[#available + 1] = record
            counts[record.itemType] = counts[record.itemType] - 1
        end
    end
    return #available > 0 and available or nil
end

local function itemDisplayName(fullType)
    if type(getItemNameFromFullType) == "function" then
        local ok, name = pcall(getItemNameFromFullType, fullType)
        if ok and type(name) == "string" and name ~= "" then
            return name
        end
    end

    if type(getScriptManager) == "function" then
        local ok, name = pcall(function()
            local manager = getScriptManager()
            local scriptItem = manager and manager:FindItem(fullType)
            return scriptItem and scriptItem:getDisplayName() or nil
        end)
        if ok and type(name) == "string" and name ~= "" then
            return name
        end
    end

    return tostring(fullType)
end

local function poisonousIngredientSummary(records)
    local counts = {}
    for _, record in ipairs(records or {}) do
        if record and type(record.itemType) == "string" then
            counts[record.itemType] = (counts[record.itemType] or 0) + 1
        end
    end

    local entries = {}
    local duplicateNames = {}
    for fullType, count in pairs(counts) do
        local name = itemDisplayName(fullType)
        entries[#entries + 1] = {
            fullType = fullType,
            name = name,
            count = count,
        }
        duplicateNames[name] = (duplicateNames[name] or 0) + 1
    end

    table.sort(entries, function(left, right)
        if left.name == right.name then
            return left.fullType < right.fullType
        end
        return left.name < right.name
    end)

    local labels = {}
    for _, entry in ipairs(entries) do
        local label = entry.name
        local lowerName = string.lower(label)
        if duplicateNames[label] > 1
                or string.find(lowerName, "unknown", 1, true)
                or string.find(lowerName, "desconocido", 1, true) then
            label = label .. " [" .. entry.fullType .. "]"
        end
        if entry.count > 1 then
            label = label .. " x" .. tostring(entry.count)
        end
        labels[#labels + 1] = label
    end

    return table.concat(labels, ", ")
end

local function subtractIngredientStats(meal, record)
    local stats = record.stats or {}
    for _, field in ipairs(statFields) do
        local delta = stats[field[1]]
        if type(delta) == "number" then
            local current = safeCall(meal, field[2])
            if current ~= nil and type(meal[field[3]]) == "function" then
                pcall(meal[field[3]], meal, current - delta)
            end
        end
    end
end

local function removePoisonousIngredients(meal)
    local removable = getRemovableRecords(meal)
    local extras = meal and meal:getExtraItems()
    if not removable or not extras then return end

    local modData = meal:getModData()
    local records = modData[RECORDS_KEY]
    local removedRecords = {}
    local removedIngredients = {}
    local poisonToRemove = 0
    local removedCount = 0

    for index = #removable, 1, -1 do
        local record = removable[index]
        local foundIndex
        for index = extras:size() - 1, 0, -1 do
            if extras:get(index) == record.itemType then
                foundIndex = index
                break
            end
        end
        if foundIndex ~= nil then
            extras:remove(foundIndex)
            subtractIngredientStats(meal, record)
            poisonToRemove = poisonToRemove + record.poisonPower
            removedRecords[record] = true
            removedIngredients[#removedIngredients + 1] = {
                itemType = record.itemType,
            }
            removedCount = removedCount + 1
        end
    end

    if removedCount == 0 then return end

    local remainingRecords = {}
    for _, record in ipairs(records) do
        if not removedRecords[record] then
            remainingRecords[#remainingRecords + 1] = record
        end
    end
    modData[RECORDS_KEY] = #remainingRecords > 0 and remainingRecords or nil

    local remainingPoison = math.max(0, meal:getPoisonPower() - poisonToRemove)
    meal:setPoisonPower(remainingPoison)
    if meal:haveExtraItems() then
        for index = 0, getEvolvedRecipes():size() - 1 do
            local recipe = getEvolvedRecipes():get(index)
            if recipe:isResultItem(meal) then
                pcall(ISAddItemInRecipe.checkName, meal, recipe)
                break
            end
        end
    end

    if not isServer() and ISInventoryPage and ISInventoryPage.dirtyUI then
        ISInventoryPage.dirtyUI()
    end
    print(TAG .. "removed " .. tostring(removedCount)
        .. " poisoned ingredient(s) from " .. tostring(meal:getFullType())
        .. "; sources=" .. poisonousIngredientSummary(removedIngredients))
end

local function moveAfterEquipOptions(context, option)
    local labels = {
        [getText("ContextMenu_Equip_Primary")] = true,
        [getText("ContextMenu_Equip_Secondary")] = true,
        [getText("ContextMenu_Equip_Two_Hands")] = true,
    }
    local optionIndex, insertAfter
    for index, entry in ipairs(context.options or {}) do
        if entry == option then optionIndex = index end
        if entry ~= option and labels[entry.name] then insertAfter = index end
    end
    if not optionIndex then return end

    table.remove(context.options, optionIndex)
    if insertAfter and optionIndex <= insertAfter then insertAfter = insertAfter - 1 end
    table.insert(context.options, (insertAfter and insertAfter + 1 or 1), option)
    for index, entry in ipairs(context.options) do entry.id = index end
    pcall(function()
        if context.calcHeight then context:calcHeight() end
        if context.calcWidth and context.setWidth then context:setWidth(context:calcWidth()) end
    end)
end

local function addRemovePoisonedIngredientsOption(playerIndex, context, entries)
    if not context or not context.addOption then return end
    local meal = getSingleSelectedFood(entries)
    if not meal or meal:getPoisonPower() <= 0 then return end

    local records = getRemovableRecords(meal)
    if not records then return end

    local sourceSummary = poisonousIngredientSummary(records)
    local optionLabel = getText("ContextMenu_ChilaSeda_RemovePoisonedMeal")
    if sourceSummary ~= "" then
        optionLabel = getText("ContextMenu_ChilaSeda_RemovePoisonedMealWithSources",
            sourceSummary)
    end
    local option = context:addOption(optionLabel, meal, removePoisonousIngredients)
    if option then
        -- Reuse the vanilla B42 rat-poison item icon to make the cleanup action
        -- recognizable without adding a custom texture to this patch.
        if type(getScriptManager) == "function" then
            local okManager, manager = pcall(getScriptManager)
            if okManager and manager then
                local okItem, scriptItem = pcall(manager.FindItem, manager, "Base.RatPoison")
                if okItem and scriptItem and type(scriptItem.getNormalTexture) == "function" then
                    local okTexture, texture = pcall(scriptItem.getNormalTexture, scriptItem)
                    if okTexture and texture then option.iconTexture = texture end
                end
            end
        end
        moveAfterEquipOptions(context, option)
    end
end

Events.OnPreFillInventoryObjectContextMenu.Add(addRemovePoisonedIngredientsOption)
ISAddItemInRecipe.ChilaSedaPoisonMealInstalled = true
print(TAG .. "ingredient tracking and salad repair enabled")
