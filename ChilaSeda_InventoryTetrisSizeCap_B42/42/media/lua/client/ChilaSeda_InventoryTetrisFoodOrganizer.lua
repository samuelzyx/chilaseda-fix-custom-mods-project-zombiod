local TAG = "[ChilaSeda_InventoryTetrisFoodOrganizer] "
local ORGANIZER_ENABLED = true
local MAX_TRACE_LINES = 64
local traceLines = 0
local TRACE_SORT_LAYOUT = true
local MAX_SORT_TRACE_LINES = 96
local sortTraceLines = 0
local sortTraceLimitLogged = false
local api = {}
local apiWarningLogged = false
local foodApiDiagnosticLogged = false
local menuHookInstalled = false
local stackHooksInstalled = false
local Organizer = {}

local function trace(message)
    if traceLines >= MAX_TRACE_LINES then return end
    traceLines = traceLines + 1
    print(TAG .. tostring(message))
end

local function traceSort(event, fields)
    if not TRACE_SORT_LAYOUT then return end
    if sortTraceLines >= MAX_SORT_TRACE_LINES then
        if not sortTraceLimitLogged then
            sortTraceLimitLogged = true
            print(TAG .. "sort_trace event=limit limit=" .. tostring(MAX_SORT_TRACE_LINES))
        end
        return
    end
    sortTraceLines = sortTraceLines + 1
    local message = TAG .. "sort_trace event=" .. tostring(event) .. " " .. tostring(fields or "")
    if #message > 1000 then message = message:sub(1, 997) .. "..." end
    print(message)
end

local function safeMethod(object, methodName, ...)
    local okMethod, method = pcall(function()
        return object and object[methodName]
    end)
    if not okMethod or type(method) ~= "function" then
        return nil, false
    end
    local ok, first, second, third = pcall(method, object, ...)
    if not ok then return nil, false end
    return first, true, second, third
end

local function safeFunction(method, ...)
    if type(method) ~= "function" then return nil, false end
    local ok, first, second, third = pcall(method, ...)
    if not ok then return nil, false end
    return first, true, second, third
end

local function isFiniteNumber(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function getFoodHandle(item)
    if not item then return nil, false, true end

    local isVanillaFood, okVanillaFood = safeFunction(instanceof, item, "Food")
    if okVanillaFood and isVanillaFood == true then
        return item, true, true
    end

    local isDirectFood, okDirectFood = safeMethod(item, "isFood")
    if okDirectFood and type(isDirectFood) == "boolean" then
        if not isDirectFood then return nil, false, true end
        return item, true, true
    end

    -- Build 42's InventoryItem hierarchy uses instanceof(item, "Food") as the
    -- canonical type check. If that check succeeded and ruled this item out,
    -- do not probe an unrelated mod-provided getFood() object and abort the
    -- entire sort because that object lacks Food's API.
    if okVanillaFood and type(isVanillaFood) == "boolean" then
        return nil, false, true
    end

    local food, ok = safeMethod(item, "getFood")
    if not ok or not food then return nil, false, true end
    local isFood, okFood = safeMethod(food, "isFood")
    if not okFood or type(isFood) ~= "boolean" then
        if not foodApiDiagnosticLogged then
            foodApiDiagnosticLogged = true
            local fullType = safeMethod(item, "getFullType")
            local itemClass, okItemClass = safeMethod(item, "getClass")
            local itemClassName = okItemClass and safeMethod(itemClass, "getName") or nil
            local foodClass, okFoodClass = safeMethod(food, "getClass")
            local foodClassName = okFoodClass and safeMethod(foodClass, "getName") or nil
            trace("food classification failed fullType=" .. tostring(fullType)
                .. " itemClass=" .. tostring(itemClassName)
                .. " instanceof=" .. tostring(isVanillaFood)
                .. " directIsFood=" .. tostring(isDirectFood)
                .. " foodClass=" .. tostring(foodClassName)
                .. " foodIsFood=" .. tostring(isFood))
        end
        return nil, nil, false
    end
    if not isFood then return nil, false, true end
    return food, true, true
end

local function freshnessRank(food)
    local burnt, okBurnt = safeMethod(food, "isBurnt")
    local rotten, okRotten = safeMethod(food, "isRotten")
    local fresh, okFresh = safeMethod(food, "isFresh")
    local canAge, okCanAge = safeMethod(food, "canAge")
    if not okBurnt or not okRotten or not okFresh or not okCanAge then
        return nil, false
    end
    if burnt then return 4, true end
    if rotten then return 1, true end
    if not canAge then return 4, true end
    if fresh then return 3, true end
    return 2, true
end

local function readFoodInfo(item, mode)
    local food, isFood, okFood = getFoodHandle(item)
    if not okFood then return nil, false, "food-api" end
    if not isFood then return nil, true end

    local itemType, okType = safeMethod(item, "getFullType")
    local itemId, okId = safeMethod(item, "getID")
    if not okType or type(itemType) ~= "string" or not okId or itemId == nil then
        return nil, false, "item-identity"
    end

    local age, okAge = safeMethod(food, "getAge")
    if not okAge or not isFiniteNumber(age) then
        return nil, false, "food-age"
    end

    local info = {
        item = item,
        id = itemId,
        fullType = itemType,
        age = age,
    }
    if mode == "freshness" then
        local rank, okRank = freshnessRank(food)
        if not okRank then return nil, false, "freshness-api" end
        info.rank = rank
    end
    if mode == "calories" then
        local calories, okCalories = safeMethod(food, "getCalories")
        if not okCalories or not isFiniteNumber(calories) then
            return nil, false, "food-calories"
        end
        info.calories = calories
    end
    return info, true
end

local function traceGridLayout(phase, gridIndex, plan, stacks, mode)
    if not TRACE_SORT_LAYOUT then return end
    local stackEntries = {}
    local stackLimit = 12
    for stackIndex, stack in ipairs(stacks or {}) do
        if stackIndex > stackLimit then
            stackEntries[#stackEntries + 1] = "...+" .. tostring(#stacks - stackLimit)
            break
        end
        local members = {}
        local items, okItems = safeFunction(api.ItemStack and api.ItemStack.getAllItems,
            stack, plan.grid.inventory)
        if okItems and type(items) == "table" then
            local memberLimit = 8
            for itemIndex, item in ipairs(items) do
                if itemIndex > memberLimit then
                    members[#members + 1] = "...+" .. tostring(#items - memberLimit)
                    break
                end
                local itemId, okId = safeMethod(item, "getID")
                local fullType, okType = safeMethod(item, "getFullType")
                local member = tostring(okId and itemId or "?") .. ":"
                    .. tostring(okType and fullType or "?")
                local info, okInfo = readFoodInfo(item, mode)
                if mode == "calories" then
                    member = member .. ":cal=" .. tostring(okInfo and info and info.calories or "?")
                elseif mode == "freshness" then
                    member = member .. ":freshRank=" .. tostring(okInfo and info and info.rank or "?")
                end
                members[#members + 1] = member
            end
        else
            members[1] = "items=unavailable"
        end
        stackEntries[#stackEntries + 1] = tostring(stack.itemType or "?")
            .. "@" .. tostring(stack.x or "?") .. "," .. tostring(stack.y or "?")
            .. ",rot=" .. tostring(stack.isRotated)
            .. ",count=" .. tostring(stack.count or "?")
            .. "{" .. table.concat(members, ",") .. "}"
    end
    traceSort("layout", "phase=" .. tostring(phase)
        .. " mode=" .. tostring(mode)
        .. " grid=" .. tostring(gridIndex)
        .. " size=" .. tostring(plan.grid.width) .. "x" .. tostring(plan.grid.height)
        .. " stacks=" .. tostring(#(stacks or {}))
        .. " layout=" .. table.concat(stackEntries, ";"))
end

local function getInventoryItems(inventory)
    local list, okList = safeMethod(inventory, "getItems")
    if not okList or not list then return nil, false end

    local size, okSize = safeMethod(list, "size")
    if okSize and isFiniteNumber(size) and size >= 0 then
        local result = {}
        for index = 0, size - 1 do
            local item, okItem = safeMethod(list, "get", index)
            if not okItem or not item then return nil, false end
            result[#result + 1] = item
        end
        return result, true
    end

    if type(list) == "table" then
        local result = {}
        for _, item in ipairs(list) do
            result[#result + 1] = item
        end
        return result, true
    end
    return nil, false
end

local function getItemSize(item, rotated)
    local width, ok, height = safeFunction(api.TetrisItemData.getItemSize, item, rotated)
    width = tonumber(width)
    height = tonumber(height)
    if not ok or not isFiniteNumber(width) or not isFiniteNumber(height)
        or width < 1 or height < 1 then
        return nil, nil, false
    end
    return math.floor(width), math.floor(height), true
end

local function sortedFoodItems(items, mode)
    table.sort(items, function(left, right)
        if mode == "freshness" then
            if left.age ~= right.age then return left.age > right.age end
        else
            if left.calories ~= right.calories then return left.calories > right.calories end
            if left.age ~= right.age then return left.age > right.age end
        end
        return tostring(left.id) < tostring(right.id)
    end)
    return items
end

local function compareGroups(mode, left, right)
    if mode == "freshness" then
        if left.rank ~= right.rank then return left.rank < right.rank end
        if left.fullType ~= right.fullType then return left.fullType < right.fullType end
    else
        local leftTop = left.items[1]
        local rightTop = right.items[1]
        if leftTop.calories ~= rightTop.calories then
            return leftTop.calories > rightTop.calories
        end
        if leftTop.age ~= rightTop.age then return leftTop.age > rightTop.age end
        if left.fullType ~= right.fullType then return left.fullType < right.fullType end
    end
    return tostring(left.items[1].id) < tostring(right.items[1].id)
end

local function itemIdCount(itemIDs)
    local count = 0
    for _ in pairs(itemIDs) do count = count + 1 end
    return count
end

local function markArea(occupied, gridWidth, gridHeight, x, y, width, height)
    if x < 0 or y < 0 or x + width > gridWidth or y + height > gridHeight then
        return false
    end
    for cellY = y, y + height - 1 do
        for cellX = x, x + width - 1 do
            local index = cellY * gridWidth + cellX
            if occupied[index] then return false end
        end
    end
    for cellY = y, y + height - 1 do
        for cellX = x, x + width - 1 do
            occupied[cellY * gridWidth + cellX] = true
        end
    end
    return true
end

local function areaIsFree(occupied, gridWidth, gridHeight, x, y, width, height)
    if x < 0 or y < 0 or x + width > gridWidth or y + height > gridHeight then
        return false
    end
    for cellY = y, y + height - 1 do
        for cellX = x, x + width - 1 do
            if occupied[cellY * gridWidth + cellX] then return false end
        end
    end
    return true
end

local function makeFoodGroups(records, mode)
    local byKey = {}
    for _, record in ipairs(records) do
        local key = record.fullType
        if mode == "freshness" then
            key = tostring(record.rank) .. "|" .. record.fullType
        elseif mode == "calories" then
            key = tostring(record.calories) .. "|" .. record.fullType
        end
        local group = byKey[key]
        if not group then
            group = {
                key = key,
                rank = record.rank,
                fullType = record.fullType,
                items = {},
            }
            byKey[key] = group
        end
        group.items[#group.items + 1] = record
    end

    local groups = {}
    for _, group in pairs(byKey) do
        sortedFoodItems(group.items, mode)
        groups[#groups + 1] = group
    end
    table.sort(groups, function(left, right) return compareGroups(mode, left, right) end)
    return groups
end

local function makeStackPlans(records, mode)
    local groups = makeFoodGroups(records, mode)
    local stackPlans = {}
    for _, group in ipairs(groups) do
        local maxSize, okMax = safeFunction(api.TetrisItemData.getMaxStackSize, group.items[1].item)
        maxSize = tonumber(maxSize)
        if not okMax or not isFiniteNumber(maxSize) or maxSize < 1 then
            return nil, "stack-size-api"
        end
        maxSize = math.floor(maxSize)
        local category, okCategory = safeFunction(api.TetrisItemCategory.getCategory, group.items[1].item)
        if not okCategory or category == nil then
            return nil, "category-api"
        end

        local startIndex = 1
        while startIndex <= #group.items do
            local items = {}
            local endIndex = math.min(startIndex + maxSize - 1, #group.items)
            for index = startIndex, endIndex do
                items[#items + 1] = group.items[index]
            end
            stackPlans[#stackPlans + 1] = {
                mode = mode,
                rank = group.rank,
                fullType = group.fullType,
                category = category,
                item = items[1].item,
                items = items,
            }
            startIndex = endIndex + 1
        end
    end
    return stackPlans
end

local function planGrid(grid, inventory, mode, seenItems)
    if type(grid) ~= "table" or grid.inventory ~= inventory
        or type(grid.persistentData) ~= "table"
        or type(grid.persistentData.stacks) ~= "table"
        or type(grid._rebuildStackMap) ~= "function"
        or type(grid._sendModData) ~= "function" then
        return nil, "grid-api"
    end

    local gridWidth = tonumber(grid.width)
    local gridHeight = tonumber(grid.height)
    if not isFiniteNumber(gridWidth) or not isFiniteNumber(gridHeight)
        or gridWidth < 1 or gridHeight < 1 then
        return nil, "grid-size"
    end
    gridWidth = math.floor(gridWidth)
    gridHeight = math.floor(gridHeight)

    local foodRecords = {}
    local foodStacks = {}
    local retainedStacks = {}
    for _, stack in ipairs(grid.persistentData.stacks) do
        if type(stack) ~= "table" or type(stack.itemIDs) ~= "table" then
            return nil, "stack-data"
        end
        local expectedCount = itemIdCount(stack.itemIDs)
        if tonumber(stack.count) ~= expectedCount then
            return nil, "stack-count"
        end
        local items, okItems = safeFunction(api.ItemStack.getAllItems, stack, inventory)
        if not okItems or type(items) ~= "table" or #items ~= expectedCount then
            return nil, "stale-item"
        end

        local foodInStack = 0
        local stackRecords = {}
        for _, item in ipairs(items) do
            local itemInventory, okInventory = safeMethod(item, "getContainer")
            if not okInventory or itemInventory ~= inventory then
                return nil, "foreign-item"
            end
            local info, okInfo, reason = readFoodInfo(item, mode)
            if not okInfo then return nil, reason end
            if info then
                foodInStack = foodInStack + 1
                stackRecords[#stackRecords + 1] = info
            end
            local id = safeMethod(item, "getID")
            if id == nil or seenItems[id] then return nil, "duplicate-item" end
            seenItems[id] = item
        end

        if foodInStack > 0 and foodInStack ~= #items then
            return nil, "mixed-stack"
        end
        if foodInStack > 0 then
            foodStacks[stack] = true
            for _, record in ipairs(stackRecords) do foodRecords[#foodRecords + 1] = record end
        else
            retainedStacks[#retainedStacks + 1] = { stack = stack, items = items }
        end
    end

    local stackPlans, reason = makeStackPlans(foodRecords, mode)
    if not stackPlans then return nil, reason end
    local occupied = {}
    for _, entry in ipairs(retainedStacks) do
        local stack = entry.stack
        if #entry.items > 0 then
            local item = entry.items[1]
            local width, height, okSize = getItemSize(item, stack.isRotated)
            if not okSize then return nil, "item-size-api" end
            local x, y = tonumber(stack.x), tonumber(stack.y)
            if not isFiniteNumber(x) or not isFiniteNumber(y)
                or not markArea(occupied, gridWidth, gridHeight, math.floor(x), math.floor(y), width, height) then
                return nil, "nonfood-position"
            end
        end
    end

    local cursor = 0
    local cellCount = gridWidth * gridHeight
    for _, stackPlan in ipairs(stackPlans) do
        local placed = false
        for cellIndex = cursor, cellCount - 1 do
            local x = cellIndex % gridWidth
            local y = math.floor(cellIndex / gridWidth)
            local rotations = { false, true }
            for _, rotated in ipairs(rotations) do
                if not (rotated and stackPlan._triedSquare) then
                    local width, height, okSize = getItemSize(stackPlan.item, rotated)
                    if not okSize then return nil, "item-size-api" end
                    if areaIsFree(occupied, gridWidth, gridHeight, x, y, width, height) then
                        stackPlan.x = x
                        stackPlan.y = y
                        stackPlan.rotated = rotated
                        stackPlan.width = width
                        stackPlan.height = height
                        markArea(occupied, gridWidth, gridHeight, x, y, width, height)
                        cursor = cellIndex + 1
                        placed = true
                        break
                    end
                    if width == height then stackPlan._triedSquare = true end
                end
            end
            if placed then break end
        end
        stackPlan._triedSquare = nil
        if not placed then return nil, "no-space" end
    end

    local newFoodStacks = {}
    for _, stackPlan in ipairs(stackPlans) do
        local stack, okCreate = safeFunction(
            api.ItemStack.create,
            stackPlan.x,
            stackPlan.y,
            stackPlan.rotated,
            stackPlan.fullType,
            stackPlan.category
        )
        if not okCreate or type(stack) ~= "table" then return nil, "stack-create" end
        for _, record in ipairs(stackPlan.items) do
            local _, okAdd = safeFunction(api.ItemStack.addItem, stack, record.item)
            if not okAdd then return nil, "stack-create" end
        end
        stack.chilaFoodOrganizerMode = mode
        if mode == "freshness" then stack.chilaFoodOrganizerRank = stackPlan.rank end
        newFoodStacks[#newFoodStacks + 1] = stack
    end

    local newStacks = {}
    for _, entry in ipairs(retainedStacks) do newStacks[#newStacks + 1] = entry.stack end
    for _, stack in ipairs(newFoodStacks) do newStacks[#newStacks + 1] = stack end
    table.sort(newStacks, function(left, right)
        local leftY, rightY = tonumber(left.y), tonumber(right.y)
        if leftY and rightY and leftY ~= rightY then return leftY < rightY end
        local leftX, rightX = tonumber(left.x), tonumber(right.x)
        if leftX and rightX and leftX ~= rightX then return leftX < rightX end
        return tostring(left.itemType or "") < tostring(right.itemType or "")
    end)

    return {
        grid = grid,
        stacks = newStacks,
        oldStacks = grid.persistentData.stacks,
        foodCount = #foodRecords,
        groupCount = #stackPlans,
        foodStackMap = foodStacks,
    }
end

local function checkOverflow(containerGrid, inventory, mode)
    if type(containerGrid.overflow) ~= "table" then return true end
    for _, stack in ipairs(containerGrid.overflow) do
        if type(stack) ~= "table" or type(stack.itemIDs) ~= "table" then
            return false, "overflow-data"
        end
        local items, okItems = safeFunction(api.ItemStack.getAllItems, stack, inventory)
        local expectedCount = itemIdCount(stack.itemIDs)
        if not okItems or type(items) ~= "table" or #items ~= expectedCount then
            return false, "overflow-data"
        end
        for _, item in ipairs(items) do
            local info, okInfo, reason = readFoodInfo(item, mode)
            if not okInfo then return false, reason end
            if info then return false, "overflow-food" end
        end
    end
    return true
end

local function verifyInventoryFoods(inventory, mode, seenItems)
    local items, okItems = getInventoryItems(inventory)
    if not okItems then return false, "inventory-list-api" end
    local listIDs = {}
    for _, item in ipairs(items) do
        local info, okInfo, reason = readFoodInfo(item, mode)
        if not okInfo then return false, reason end
        if info then
            if listIDs[info.id] then return false, "duplicate-inventory-item" end
            listIDs[info.id] = true
            if not seenItems[info.id] then return false, "untracked-food" end
        end
    end
    return true
end

local function replaceArrayContents(target, values)
    for index = #target, 1, -1 do target[index] = nil end
    for index, value in ipairs(values) do target[index] = value end
end

local function restorePlans(plans, snapshots)
    local restored = true
    for index = #plans, 1, -1 do
        local plan = plans[index]
        local okRestore = pcall(replaceArrayContents, plan.oldStacks, snapshots[index])
        if not okRestore then restored = false end
        local okRebuild = pcall(plan.grid._rebuildStackMap, plan.grid, false)
        if not okRebuild then restored = false end
    end
    for _, plan in ipairs(plans) do
        pcall(plan.grid._sendModData, plan.grid)
    end
    return restored
end

local function commitPlans(plans)
    local snapshots = {}
    for index, plan in ipairs(plans) do
        snapshots[index] = {}
        for _, stack in ipairs(plan.oldStacks) do snapshots[index][#snapshots[index] + 1] = stack end
    end

    local okCommit, commitError = pcall(function()
        for _, plan in ipairs(plans) do
            replaceArrayContents(plan.oldStacks, plan.stacks)
        end
        for _, plan in ipairs(plans) do
            plan.grid:_rebuildStackMap(false)
        end
        for _, plan in ipairs(plans) do
            plan.grid:_sendModData()
        end
    end)
    if not okCommit then
        local restored = restorePlans(plans, snapshots)
        trace("sort fallback=commit-error restored=" .. tostring(restored) .. " error=" .. tostring(commitError))
        return false, restored and "commit-failed" or "commit-uncertain"
    end
    return true
end

local function buildPlans(inventory, containerGrid, mode)
    if mode ~= "freshness" and mode ~= "calories" then return nil, "unknown-mode" end
    if not api.ItemStack or not api.TetrisItemData or not api.TetrisItemCategory
        or type(api.ItemStack.getAllItems) ~= "function"
        or type(api.ItemStack.create) ~= "function"
        or type(api.ItemStack.addItem) ~= "function"
        or type(api.TetrisItemData.getItemSize) ~= "function"
        or type(api.TetrisItemData.getMaxStackSize) ~= "function" then
        return nil, "api-unavailable"
    end
    if type(SandboxVars) == "table" and type(SandboxVars.InventoryTetris) == "table"
        and SandboxVars.InventoryTetris.EnableGravity == true then
        return nil, "gravity-enabled"
    end
    if type(containerGrid) ~= "table" or type(containerGrid.grids) ~= "table"
        or #containerGrid.grids == 0 then
        return nil, "grid-unavailable"
    end

    local okOverflow, overflowReason = checkOverflow(containerGrid, inventory, mode)
    if not okOverflow then return nil, overflowReason end

    local seenItems = {}
    local plans = {}
    local totalFood = 0
    local totalGroups = 0
    for _, grid in ipairs(containerGrid.grids) do
        local plan, reason = planGrid(grid, inventory, mode, seenItems)
        if not plan then return nil, reason end
        plans[#plans + 1] = plan
        totalFood = totalFood + plan.foodCount
        totalGroups = totalGroups + plan.groupCount
    end
    local okFoods, foodReason = verifyInventoryFoods(inventory, mode, seenItems)
    if not okFoods then return nil, foodReason end
    if totalFood == 0 then return nil, "no-foods" end
    return plans, nil, totalFood, totalGroups
end

local localizationFallbacks = {
    ContextMenu_Equip_Primary = "Equipar en mano primaria",
    ContextMenu_Equip_Secondary = "Equipar en mano secundaria",
    ContextMenu_ChilaSeda_InventoryTetris_OrganizeFood = "Organizar alimentos",
    ContextMenu_ChilaSeda_InventoryTetris_FoodFreshness = "Por frescura",
    ContextMenu_ChilaSeda_InventoryTetris_FoodCalories = "Por calorias",
    UI_ChilaSeda_InventoryTetris_FoodSortSuccessFreshness = "Organizados por frescura: %1 alimentos.",
    UI_ChilaSeda_InventoryTetris_FoodSortSuccessCalories = "Organizados por calorias: %1 alimentos.",
    UI_ChilaSeda_InventoryTetris_FoodSortNoSpace = "Sin cambios: no caben todos los alimentos junto a los otros objetos.",
    UI_ChilaSeda_InventoryTetris_FoodSortOverflow = "Sin cambios: coloca primero en la cuadricula los alimentos del area de desbordamiento.",
    UI_ChilaSeda_InventoryTetris_FoodSortGravity = "Sin cambios: desactiva la gravedad de Inventory Tetris para conservar el orden solicitado.",
    UI_ChilaSeda_InventoryTetris_FoodSortNoFoods = "No se encontraron alimentos para organizar.",
    UI_ChilaSeda_InventoryTetris_FoodSortUnavailable = "Sin cambios: la cuadricula actual de Inventory Tetris no esta disponible.",
    UI_ChilaSeda_InventoryTetris_FoodSortFailed = "Sin cambios: el organizador no pudo terminar de forma segura.",
    UI_ChilaSeda_InventoryTetris_FoodSortReview = "No se pudo confirmar la restauracion completa de la cuadricula. Revisala antes de mover objetos.",
    UI_ChilaSeda_InventoryTetris_FoodSortFoodData = "Sin cambios: no se pudo leer de forma segura la frescura o las calorias.",
    UI_ChilaSeda_InventoryTetris_FoodSortItemData = "Sin cambios: no se pudo leer el tamano, limite de apilado o categoria del objeto.",
    UI_ChilaSeda_InventoryTetris_FoodSortGridData = "Sin cambios: la cuadricula contiene una pila ausente, mezclada o inconsistente.",
    UI_ChilaSeda_InventoryTetris_FoodSortInventoryData = "Sin cambios: hay alimentos que esta cuadricula no registra; revisa el contenedor.",
}
local localizationFallbackLogged = {}

local function localize(key, count)
    if type(getText) == "function" then
        local ok, value
        if count ~= nil then
            ok, value = pcall(getText, key, tostring(count))
        else
            ok, value = pcall(getText, key)
        end
        if ok and type(value) == "string" and value ~= "" and value ~= key then return value end
    end
    local fallback = localizationFallbacks[key]
    if type(fallback) == "string" then
        if count ~= nil then fallback = string.gsub(fallback, "%%1", tostring(count)) end
        if not localizationFallbackLogged[key] then
            localizationFallbackLogged[key] = true
            trace("localization fallback key=" .. tostring(key))
        end
        return fallback
    end
    return count ~= nil and ("Texto no disponible (" .. tostring(count) .. ")") or "Texto no disponible"
end

local function showHalo(playerNum, key, count, isSuccess)
    local player = type(getSpecificPlayer) == "function" and getSpecificPlayer(playerNum) or nil
    if not player then
        trace("halo fallback=player-unavailable")
        return false
    end
    local message = localize(key, count)
    if HaloTextHelper and type(HaloTextHelper.addText) == "function" then
        local r, g, b = isSuccess and 135 or 255, isSuccess and 255 or 185, isSuccess and 150 or 90
        local ok = pcall(HaloTextHelper.addText, player, message, " ", r, g, b)
        if ok then return true end
    end
    local said, okSay = safeMethod(player, "Say", message)
    if okSay then
        trace("halo fallback=player-say")
        return true
    end
    trace("halo fallback=unavailable")
    return false
end

local failureKeys = {
    ["api-unavailable"] = "UI_ChilaSeda_InventoryTetris_FoodSortUnavailable",
    ["grid-unavailable"] = "UI_ChilaSeda_InventoryTetris_FoodSortUnavailable",
    ["grid-api"] = "UI_ChilaSeda_InventoryTetris_FoodSortUnavailable",
    ["grid-size"] = "UI_ChilaSeda_InventoryTetris_FoodSortItemData",
    ["gravity-enabled"] = "UI_ChilaSeda_InventoryTetris_FoodSortGravity",
    ["no-space"] = "UI_ChilaSeda_InventoryTetris_FoodSortNoSpace",
    ["overflow-food"] = "UI_ChilaSeda_InventoryTetris_FoodSortOverflow",
    ["overflow-data"] = "UI_ChilaSeda_InventoryTetris_FoodSortGridData",
    ["no-foods"] = "UI_ChilaSeda_InventoryTetris_FoodSortNoFoods",
    ["commit-failed"] = "UI_ChilaSeda_InventoryTetris_FoodSortFailed",
    ["commit-uncertain"] = "UI_ChilaSeda_InventoryTetris_FoodSortReview",
    ["food-api"] = "UI_ChilaSeda_InventoryTetris_FoodSortFoodData",
    ["item-identity"] = "UI_ChilaSeda_InventoryTetris_FoodSortFoodData",
    ["food-age"] = "UI_ChilaSeda_InventoryTetris_FoodSortFoodData",
    ["freshness-api"] = "UI_ChilaSeda_InventoryTetris_FoodSortFoodData",
    ["food-calories"] = "UI_ChilaSeda_InventoryTetris_FoodSortFoodData",
    ["stack-size-api"] = "UI_ChilaSeda_InventoryTetris_FoodSortItemData",
    ["category-api"] = "UI_ChilaSeda_InventoryTetris_FoodSortItemData",
    ["item-size-api"] = "UI_ChilaSeda_InventoryTetris_FoodSortItemData",
    ["stack-create"] = "UI_ChilaSeda_InventoryTetris_FoodSortItemData",
    ["stack-data"] = "UI_ChilaSeda_InventoryTetris_FoodSortGridData",
    ["stack-count"] = "UI_ChilaSeda_InventoryTetris_FoodSortGridData",
    ["stale-item"] = "UI_ChilaSeda_InventoryTetris_FoodSortGridData",
    ["foreign-item"] = "UI_ChilaSeda_InventoryTetris_FoodSortGridData",
    ["duplicate-item"] = "UI_ChilaSeda_InventoryTetris_FoodSortGridData",
    ["mixed-stack"] = "UI_ChilaSeda_InventoryTetris_FoodSortGridData",
    ["nonfood-position"] = "UI_ChilaSeda_InventoryTetris_FoodSortGridData",
    ["inventory-list-api"] = "UI_ChilaSeda_InventoryTetris_FoodSortInventoryData",
    ["untracked-food"] = "UI_ChilaSeda_InventoryTetris_FoodSortInventoryData",
    ["duplicate-inventory-item"] = "UI_ChilaSeda_InventoryTetris_FoodSortInventoryData",
    ["unknown-mode"] = "UI_ChilaSeda_InventoryTetris_FoodSortFailed",
}

local function findContainerGrid(inventory, playerNum)
    if not api.ItemContainerGrid or type(api.ItemContainerGrid.FindInstance) ~= "function" then
        return nil
    end
    local grid, ok = safeFunction(api.ItemContainerGrid.FindInstance, inventory, playerNum)
    if not ok then return nil end
    return grid
end

local function organize(mode, playerNum, inventory)
    local containerGrid = findContainerGrid(inventory, playerNum)
    if not containerGrid then
        traceSort("result", "mode=" .. tostring(mode) .. " result=abort reason=grid-unavailable")
        trace("sort fallback=container-grid-unavailable mode=" .. tostring(mode))
        showHalo(playerNum, failureKeys["grid-unavailable"], nil, false)
        return
    end
    traceSort("begin", "mode=" .. tostring(mode)
        .. " grids=" .. tostring(type(containerGrid.grids) == "table" and #containerGrid.grids or 0))

    local okRun, plans, reason, itemCount, groupCount = pcall(buildPlans, inventory, containerGrid, mode)
    if not okRun then
        traceSort("plan_end", "mode=" .. tostring(mode) .. " result=error error=" .. tostring(plans))
        trace("sort fallback=plan-error mode=" .. tostring(mode) .. " error=" .. tostring(plans))
        showHalo(playerNum, "UI_ChilaSeda_InventoryTetris_FoodSortFailed", nil, false)
        return
    end
    if not plans then
        traceSort("plan_end", "mode=" .. tostring(mode) .. " result=abort reason=" .. tostring(reason))
        trace("sort abort=unchanged mode=" .. tostring(mode) .. " reason=" .. tostring(reason))
        showHalo(playerNum, failureKeys[reason] or "UI_ChilaSeda_InventoryTetris_FoodSortFailed", nil, false)
        return
    end

    traceSort("plan_end", "mode=" .. tostring(mode) .. " result=ready items=" .. tostring(itemCount)
        .. " groups=" .. tostring(groupCount) .. " grids=" .. tostring(#plans))
    for gridIndex, plan in ipairs(plans) do
        traceGridLayout("before", gridIndex, plan, plan.oldStacks, mode)
        traceGridLayout("planned", gridIndex, plan, plan.stacks, mode)
    end
    traceSort("commit_begin", "mode=" .. tostring(mode) .. " grids=" .. tostring(#plans))
    local committed, commitReason = commitPlans(plans)
    traceSort("commit_end", "mode=" .. tostring(mode)
        .. " result=" .. tostring(committed and "success" or "abort")
        .. " reason=" .. tostring(commitReason or "none"))
    for gridIndex, plan in ipairs(plans) do
        traceGridLayout(committed and "after" or "after_abort", gridIndex, plan,
            plan.grid.persistentData and plan.grid.persistentData.stacks or nil, mode)
    end
    if not committed then
        trace("sort abort mode=" .. tostring(mode) .. " reason=" .. tostring(commitReason))
        showHalo(playerNum, failureKeys[commitReason] or "UI_ChilaSeda_InventoryTetris_FoodSortFailed", nil, false)
        return
    end
    traceSort("result", "mode=" .. tostring(mode) .. " result=success"
        .. " items=" .. tostring(itemCount) .. " groups=" .. tostring(groupCount))
    trace("sort success mode=" .. tostring(mode) .. " items=" .. tostring(itemCount)
        .. " groups=" .. tostring(groupCount) .. " grids=" .. tostring(#plans))
    local key = mode == "freshness"
        and "UI_ChilaSeda_InventoryTetris_FoodSortSuccessFreshness"
        or "UI_ChilaSeda_InventoryTetris_FoodSortSuccessCalories"
    showHalo(playerNum, key, itemCount, true)
end

local function onSortSelected(target, mode, playerNum, inventory)
    if not inventory then
        trace("sort abort=inventory-unavailable mode=" .. tostring(mode))
        showHalo(playerNum or 0, "UI_ChilaSeda_InventoryTetris_FoodSortUnavailable", nil, false)
        return
    end
    organize(mode, tonumber(playerNum) or 0, inventory)
end

local function getActualItems(items)
    if ISInventoryPane and type(ISInventoryPane.getActualItems) == "function" then
        local actual, ok = safeFunction(ISInventoryPane.getActualItems, items)
        if ok and type(actual) == "table" then return actual end
    end
    local result = {}
    if type(items) ~= "table" then return result end
    for _, entry in ipairs(items) do
        if type(entry) == "table" and type(entry.items) == "table" then
            for _, item in ipairs(entry.items) do result[#result + 1] = item end
        elseif entry then
            result[#result + 1] = entry
        end
    end
    return result
end

local function inventoryHasFood(inventory)
    local items, okItems = getInventoryItems(inventory)
    if not okItems then return true end
    for _, item in ipairs(items) do
        local _, isFood, okFood = getFoodHandle(item)
        if not okFood then return true end
        if isFood then return true end
    end
    return false
end

local function addContextOption(context, label, playerNum, inventory)
    local option
    local anchors = {
        localize("ContextMenu_Equip_Secondary"),
        localize("ContextMenu_Equip_Primary"),
    }
    if type(context.insertOptionAfter) == "function" then
        for _, anchor in ipairs(anchors) do
            local beforeCount = type(context.options) == "table" and #context.options or nil
            local ok, inserted = pcall(context.insertOptionAfter, context, anchor, label, nil, nil)
            if ok and inserted then
                option = inserted
                break
            end
            if ok and beforeCount and type(context.options) == "table"
                and #context.options > beforeCount then
                for _, candidate in ipairs(context.options) do
                    if candidate and (candidate.name == label or candidate.text == label) then
                        option = candidate
                        break
                    end
                end
                if option then break end
            end
        end
    end
    if not option and type(context.addOption) == "function" then
        local ok, added = pcall(context.addOption, context, label, nil, nil)
        if ok then option = added end
    end
    if not option then return false end

    if type(context.getNew) == "function" and type(context.addSubMenu) == "function" then
        local submenu, okNew = safeMethod(context, "getNew", context)
        if okNew and submenu then
            local _, okSubmenu = safeMethod(context, "addSubMenu", option, submenu)
            if okSubmenu and type(submenu.addOption) == "function" then
                safeMethod(submenu, "addOption", localize("ContextMenu_ChilaSeda_InventoryTetris_FoodFreshness"),
                    Organizer, onSortSelected, "freshness", playerNum, inventory)
                safeMethod(submenu, "addOption", localize("ContextMenu_ChilaSeda_InventoryTetris_FoodCalories"),
                    Organizer, onSortSelected, "calories", playerNum, inventory)
                return true
            end
        end
    end

    if type(context.addOption) == "function" then
        safeMethod(context, "addOption", localize("ContextMenu_ChilaSeda_InventoryTetris_FoodFreshness"),
            Organizer, onSortSelected, "freshness", playerNum, inventory)
        safeMethod(context, "addOption", localize("ContextMenu_ChilaSeda_InventoryTetris_FoodCalories"),
            Organizer, onSortSelected, "calories", playerNum, inventory)
        trace("menu fallback=flat-options")
        return true
    end
    return false
end

local function onFillInventoryContextMenu(playerNum, context, items)
    playerNum = tonumber(playerNum) or 0
    if not context or type(context) ~= "table" then return end
    local selected = getActualItems(items)
    local inventory
    for _, item in ipairs(selected) do
        inventory = safeMethod(item, "getContainer")
        if inventory then break end
    end
    if not inventory or not inventoryHasFood(inventory) then return end
    local okMenu = addContextOption(
        context,
        localize("ContextMenu_ChilaSeda_InventoryTetris_OrganizeFood"),
        playerNum,
        inventory
    )
    if okMenu then
        trace("menu added player=" .. tostring(playerNum) .. " foods=available")
    else
        trace("menu fallback=option-api-unavailable")
    end
end

local function installStackHooks()
    if stackHooksInstalled then return true end
    if not api.ItemStack or type(api.ItemStack.getAllItems) ~= "function"
        or type(api.ItemStack.getFrontItem) ~= "function" then
        if not apiWarningLogged then
            apiWarningLogged = true
            trace("install fallback=ItemStack API unavailable")
        end
        return false
    end
    if api.ItemStack.__ChilaSedaFoodOrganizerInstalled then
        stackHooksInstalled = true
        return true
    end

    local ItemStack = api.ItemStack
    local originalGetAllItems = ItemStack.getAllItems
    local originalGetFrontItem = ItemStack.getFrontItem
    local originalCanAddItem = ItemStack.canAddItem
    local originalCopyWithoutItems = ItemStack.copyWithoutItems
    local function getOrderedItems(stack, inventory)
        local items = originalGetAllItems(stack, inventory)
        if type(items) ~= "table" or not stack or not stack.chilaFoodOrganizerMode then
            return items
        end
        local mode = stack.chilaFoodOrganizerMode
        for index = #items, 1, -1 do
            local info, okInfo = readFoodInfo(items[index], mode)
            if not okInfo or not info then return originalGetAllItems(stack, inventory) end
            items[index] = info
        end
        sortedFoodItems(items, mode)
        local ordered = {}
        for index, info in ipairs(items) do ordered[index] = info.item end
        return ordered
    end

    ItemStack.getAllItems = function(stack, inventory)
        if stack and stack.chilaFoodOrganizerMode then
            return getOrderedItems(stack, inventory)
        end
        return originalGetAllItems(stack, inventory)
    end
    ItemStack.getFrontItem = function(stack, inventory)
        if stack and stack.chilaFoodOrganizerMode then
            local items = getOrderedItems(stack, inventory)
            local item = items and items[1]
            if item then
                stack._frontItem = item
                stack._frontItemId = item:getID()
                return item
            end
            stack._frontItem = nil
            stack._frontItemId = nil
            return nil
        end
        return originalGetFrontItem(stack, inventory)
    end

    if type(originalCanAddItem) == "function" then
        ItemStack.canAddItem = function(stack, item)
            if stack and stack.chilaFoodOrganizerMode == "freshness" then
                local info, okInfo = readFoodInfo(item, "freshness")
                if not okInfo or not info or info.rank ~= stack.chilaFoodOrganizerRank then
                    return false
                end
            end
            return originalCanAddItem(stack, item)
        end
    end
    if type(originalCopyWithoutItems) == "function" then
        ItemStack.copyWithoutItems = function(stack)
            local copy = originalCopyWithoutItems(stack)
            if copy and stack and stack.chilaFoodOrganizerMode then
                copy.chilaFoodOrganizerMode = stack.chilaFoodOrganizerMode
                copy.chilaFoodOrganizerRank = stack.chilaFoodOrganizerRank
            end
            return copy
        end
    end
    ItemStack.__ChilaSedaFoodOrganizerInstalled = true
    stackHooksInstalled = true
    trace("install ItemStack food-order hooks ready")
    return true
end

local function installGatherGuard()
    if not api.ItemGrid or type(api.ItemGrid.gatherSameItems) ~= "function"
        or api.ItemGrid.__ChilaSedaFoodOrganizerGatherGuard then
        return
    end
    local original = api.ItemGrid.gatherSameItems
    api.ItemGrid.gatherSameItems = function(grid, targetStack, ...)
        local itemType = targetStack and targetStack.itemType
        if itemType and type(grid.persistentData) == "table"
            and type(grid.persistentData.stacks) == "table" then
            for _, stack in ipairs(grid.persistentData.stacks) do
                if stack and stack.itemType == itemType and stack.chilaFoodOrganizerMode then
                    trace("gather blocked=organized-food type=" .. tostring(itemType))
                    return
                end
            end
        end
        return original(grid, targetStack, ...)
    end
    api.ItemGrid.__ChilaSedaFoodOrganizerGatherGuard = true
    trace("install same-type merge guard ready")
end

local function loadApi()
    local okStack, ItemStack = pcall(require, "InventoryTetris/Model/ItemStack")
    local okData, TetrisItemData = pcall(require, "InventoryTetris/Data/TetrisItemData")
    local okCategory, TetrisItemCategory = pcall(require, "InventoryTetris/Data/TetrisItemCategory")
    local okContainer, ItemContainerGrid = pcall(require, "InventoryTetris/Model/ItemContainerGrid")
    local okGrid, ItemGrid = pcall(require, "InventoryTetris/Model/ItemGrid")
    if okStack then api.ItemStack = ItemStack end
    if okData then api.TetrisItemData = TetrisItemData end
    if okCategory then api.TetrisItemCategory = TetrisItemCategory end
    if okContainer then api.ItemContainerGrid = ItemContainerGrid end
    if okGrid then api.ItemGrid = ItemGrid end
    return okStack and okData and okCategory and okContainer
end

local function install()
    if not ORGANIZER_ENABLED then
        if not menuHookInstalled then
            menuHookInstalled = true
            trace("disabled feature=freshness-and-calories reason=Jill isolation test")
        end
        return false
    end
    local apiReady = loadApi()
    if apiReady then
        installStackHooks()
        installGatherGuard()
    elseif not apiWarningLogged then
        apiWarningLogged = true
        trace("install fallback=Inventory Tetris API unavailable")
    end

    if not menuHookInstalled and Events
        and Events.OnFillInventoryObjectContextMenu
        and type(Events.OnFillInventoryObjectContextMenu.Add) == "function" then
        Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryContextMenu)
        menuHookInstalled = true
        trace("install context-menu hook ready")
    end
    return menuHookInstalled
end

if ORGANIZER_ENABLED then
    install()
    if Events then
        if Events.OnGameBoot then Events.OnGameBoot.Add(install) end
        if Events.OnGameStart then Events.OnGameStart.Add(install) end
    end
else
    trace("disabled feature=freshness-and-calories reason=Jill isolation test")
end
