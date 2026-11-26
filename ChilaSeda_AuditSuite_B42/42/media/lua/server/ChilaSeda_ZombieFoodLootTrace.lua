local MAX_LOG_LINES = 64
local MAX_OBSERVATIONS = 10000
local TRACE_EVERY = 1000
local logLines = 0
local deaths = 0
local deathsWithFood = 0
local foodItems = 0
local capped = false

local expectedFood = {
    ["Base.Crisps"] = true,
    ["Base.Crisps2"] = true,
    ["Base.Crisps3"] = true,
    ["Base.Crisps4"] = true,
    ["Base.Pop"] = true,
    ["Base.Pop2"] = true,
    ["Base.Pop3"] = true,
    ["Base.Peanuts"] = true,
    ["Base.SunflowerSeeds"] = true,
    ["Base.GranolaBar"] = true,
    ["Base.Chocolate"] = true,
    ["Base.CookieChocolateChip"] = true,
    ["Base.JuiceBox"] = true,
    ["Base.MintCandy"] = true,
    ["Base.Lollipop"] = true,
    ["Base.Gum"] = true,
    ["Base.BeefJerky"] = true,
    ["Base.DehydratedMeatStick"] = true,
}

local function safeText(value)
    return tostring(value or ""):gsub("[%s|=]", "_")
end

local function numberOr(value, fallback)
    local number = tonumber(value)
    if number == nil then return fallback end
    return number
end

local function modEnabled(id)
    if type(getActivatedMods) ~= "function" then return "unknown" end
    local ok, mods = pcall(getActivatedMods)
    if not ok or not mods then return "unknown" end
    local contains = mods.contains
    if type(contains) ~= "function" then return "unknown" end
    local containsOk, active = pcall(contains, mods, id)
    if not containsOk then return "unknown" end
    return active and "1" or "0"
end

local function writeTrace(message)
    if logLines >= MAX_LOG_LINES then return false end
    logLines = logLines + 1
    print("[ChilaSedaZombieFoodLootTrace] " .. message .. " log=" .. logLines)
    return true
end

local function isFood(item, fullType)
    if expectedFood[fullType] then return true end
    local ok, food = pcall(function() return item:IsFood() end)
    return ok and food == true
end

local function inventoryFood(inventory)
    local ok, items = pcall(function() return inventory:getItems() end)
    if not ok or not items then return 0, 0, "inventory-unavailable" end
    local sizeOk, size = pcall(function() return items:size() end)
    if not sizeOk or type(size) ~= "number" then return 0, 0, "items-unavailable" end

    local count, examples = 0, {}
    for index = 0, size - 1 do
        local itemOk, item = pcall(function() return items:get(index) end)
        if itemOk and item then
            local typeOk, fullType = pcall(function() return item:getFullType() end)
            fullType = typeOk and tostring(fullType) or "unknown"
            if isFood(item, fullType) then
                count = count + 1
                if #examples < 6 then examples[#examples + 1] = safeText(fullType) end
            end
        end
    end
    return count, size, #examples > 0 and table.concat(examples, ",") or "none"
end

local function onZombieDead(zombie)
    if type(isClient) == "function" and isClient() then return end
    if deaths >= MAX_OBSERVATIONS then
        if not capped then
            capped = true
            writeTrace("event=cap result=observations-finished deaths=" .. deaths
                .. " deathsWithFood=" .. deathsWithFood .. " foodItems=" .. foodItems)
        end
        return
    end

    deaths = deaths + 1
    local inventoryOk, inventory = pcall(function() return zombie:getInventory() end)
    if not inventoryOk or not inventory then
        writeTrace("event=death sample=" .. deaths .. " result=no-inventory")
        return
    end

    local foodCount, itemCount, examples = inventoryFood(inventory)
    if foodCount > 0 then
        deathsWithFood = deathsWithFood + 1
        foodItems = foodItems + foodCount
    end

    if deaths <= 8 or deaths % TRACE_EVERY == 0 or foodCount > 0 then
        local vars = SandboxVars and SandboxVars.AirbobbelzLoot or {}
        local outfitOk, outfit = pcall(function() return zombie:getOutfitName() end)
        writeTrace("event=death sample=" .. deaths
            .. " modActive=" .. modEnabled("MaDZombieLootB42")
            .. " global=" .. numberOr(vars.GlobalMultiplier, 100)
            .. " otherFood=" .. numberOr(vars.OtherFoodMultiplier, 100)
            .. " cannedFood=" .. numberOr(vars.CannedFoodMultiplier, 100)
            .. " outfit=" .. safeText(outfitOk and outfit or "unknown")
            .. " inventoryItems=" .. itemCount
            .. " foodItems=" .. foodCount
            .. " foodCorpses=" .. deathsWithFood
            .. " samplesFoodItems=" .. foodItems
            .. " examples=" .. examples)
    end
end

if not Events or not Events.OnZombieDead then
    writeTrace("event=hook result=missing-OnZombieDead")
else
    Events.OnZombieDead.Add(onZombieDead)
    local vars = SandboxVars and SandboxVars.AirbobbelzLoot or {}
    writeTrace("event=hook result=ready modActive=" .. modEnabled("MaDZombieLootB42")
        .. " global=" .. numberOr(vars.GlobalMultiplier, 100)
        .. " otherFood=" .. numberOr(vars.OtherFoodMultiplier, 100)
        .. " cannedFood=" .. numberOr(vars.CannedFoodMultiplier, 100)
        .. " maxObservations=" .. MAX_OBSERVATIONS)
end
