require "ISUI/ISInventoryPage"
require "ISUI/PlayerData/ISPlayerData"

local pending = setmetatable({}, { __mode = "k" })
local ready = setmetatable({}, { __mode = "k" })
local opened = setmetatable({}, { __mode = "k" })
local activeTarget = {}

local function stopDeathVoice(zombie)
    if not zombie then return end
    local ok, emitter = pcall(function() return zombie:getEmitter() end)
    if not ok or not emitter then return end
    -- These are the two aliases used by the native PlayDeathSound animation event.
    pcall(function() emitter:stopSoundByName("MaleZombieDeath") end)
    pcall(function() emitter:stopSoundByName("FemaleZombieDeath") end)
end

local function onZombieDead(zombie)
    if not zombie then return end
    -- Proper Ragdolls marks the start of each custom death clip with prdDeath.
    -- Clear a stale marker left by an earlier knockdown so the next clip start is detectable.
    pcall(function() zombie:setVariable("prdDeath", "") end)
    pending[zombie] = true
end

local function sameBody(zombie, body, sourceContainer)
    local ok, bodyContainer = pcall(function() return body:getContainer() end)
    if ok and bodyContainer == sourceContainer then return true, bodyContainer end

    local zok, zx, zy, zz = pcall(function() return zombie:getX(), zombie:getY(), zombie:getZ() end)
    local bok, bx, by, bz = pcall(function() return body:getX(), body:getY(), body:getZ() end)
    if not (zok and bok) then return false end
    if math.abs(zx - bx) > 0.75 or math.abs(zy - by) > 0.75 or math.abs(zz - bz) > 0.1 then return false end

    local zfok, zf = pcall(function() return zombie:isFemale() end)
    local bfok, bf = pcall(function() return body:isFemale() end)
    if zfok and bfok and zf ~= bf then return false end
    return true, bodyContainer
end

local function onDeadBodySpawn(body)
    if not body then return end
    for zombie, data in pairs(opened) do
        local matches = sameBody(zombie, body, data.container)
        if matches then
            data.body = body
        end
    end
end

local function finishCorpseHandoff(zombie, data)
    local body = data.body
    if not body then return end

    local ok, bodyContainer = pcall(function() return body:getContainer() end)
    if not ok or not bodyContainer then return end

    local playerNum = data.player
    local page = getPlayerLoot(playerNum)
    if activeTarget[playerNum] == zombie and page and page.inventory == data.container then
        page:setNewContainer(bodyContainer)
        page.inventoryPane.lastinventory = bodyContainer
        page.title = getText("IGUI_ItemCat_Corpse")
    end
    if activeTarget[playerNum] == zombie then activeTarget[playerNum] = nil end
    opened[zombie] = nil
    ready[zombie] = nil
end

local function onTick()
    for zombie in pairs(pending) do
        local deadOk, dead = pcall(function() return zombie:isDead() end)
        local markerOk, marker = pcall(function() return zombie:getVariableString("prdDeath") end)
        if deadOk and dead and markerOk and type(marker) == "string"
            and marker:sub(1, 8) == "PRDeath_" then
            stopDeathVoice(zombie)
            -- Unlock as soon as the custom death clip starts, then keep it available
            -- until the zombie is replaced by its corpse.
            ready[zombie] = true
            pending[zombie] = nil
        elseif not deadOk or not dead then
            pending[zombie] = nil
        end
    end

    for zombie, data in pairs(opened) do
        if data.body then finishCorpseHandoff(zombie, data) end
    end
end

local function openEarlyLoot(playerNum, zombie)
    if not zombie or not ready[zombie] then return end
    local ok, dead = pcall(function() return zombie:isDead() end)
    if not ok or not dead then return end

    local player = getSpecificPlayer(playerNum)
    local loot = getPlayerLoot(playerNum)
    local inventory = zombie:getInventory()
    if not player or not loot or not inventory then return end

    if not inventory:isExplored() then
        if not isClient() then
            ItemPicker.fillContainer(inventory, player)
        else
            inventory:requestServerItemsForContainer()
        end
        inventory:setExplored(true)
    end

    local previous = activeTarget[playerNum]
    if previous then opened[previous] = nil end
    activeTarget[playerNum] = zombie
    opened[zombie] = { player = playerNum, container = inventory }

    loot:setNewContainer(inventory)
    loot.inventoryPane.lastinventory = inventory
    loot.title = getText("ContextMenu_ChilaEarlyZombieLoot")
    loot.isCollapsed = false
    loot.collapseCounter = 0
    loot:clearMaxDrawHeight()
    loot:setVisible(true)
    loot:bringToTop()

    local playerInventory = getPlayerInventory(playerNum)
    if playerInventory then
        playerInventory:setVisible(true)
        playerInventory:bringToTop()
        loot:bringToTop()
    end
end

local function onFillWorldObjectContextMenu(playerNum, context, worldobjects, test)
    if not (IsoObjectPicker and IsoObjectPicker.Instance) then return end
    local ok, target = pcall(function()
        return IsoObjectPicker.Instance:PickTarget(getMouseX(), getMouseY())
    end)
    if not ok or not target or not instanceof(target, "IsoZombie") then return end
    if not ready[target] then return end
    local deadOk, dead = pcall(function() return target:isDead() end)
    if not deadOk or not dead then return end

    local option = context:addOption(getText("ContextMenu_ChilaEarlyZombieLoot"), worldobjects,
        openEarlyLoot, playerNum, target)
    if not option then return end
    local okManager, manager = pcall(getScriptManager)
    if okManager and manager then
        local okBag, bag = pcall(manager.FindItem, manager, "Base.Bag_NormalHikingBag")
        if okBag and bag then
            local okTexture, texture = pcall(bag.getNormalTexture, bag)
            if okTexture and texture then option.iconTexture = texture end
        end
    end

    local nativeLabels = {
        [getText("ContextMenu_Loot")] = true,
        [getText("ContextMenu_Take")] = true,
        [getText("ContextMenu_Grab")] = true,
    }
    local optionIndex, insertAfter
    for index, entry in ipairs(context.options or {}) do
        if entry == option then optionIndex = index end
        if entry ~= option and nativeLabels[entry.name] then insertAfter = index end
    end
    if optionIndex then
        table.remove(context.options, optionIndex)
        insertAfter = insertAfter or math.min(1, #context.options)
        if insertAfter > 0 then
            table.insert(context.options, insertAfter + 1, option)
            for index, entry in ipairs(context.options) do entry.id = index end
            pcall(function()
                if context.calcHeight then context:calcHeight() end
                if context.calcWidth and context.setWidth then context:setWidth(context:calcWidth()) end
            end)
        else
            table.insert(context.options, 1, option)
        end
    end
end

if Events and Events.OnZombieDead and Events.OnZombieDead.Add then
    Events.OnZombieDead.Add(onZombieDead)
end
if Events and Events.OnTick and Events.OnTick.Add then
    Events.OnTick.Add(onTick)
end
if Events and Events.OnDeadBodySpawn and Events.OnDeadBodySpawn.Add then
    Events.OnDeadBodySpawn.Add(onDeadBodySpawn)
end
if Events and Events.OnFillWorldObjectContextMenu and Events.OnFillWorldObjectContextMenu.Add then
    Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
end

print("[ChilaSeda_ProperRagdolls_DeathSounds] v1.3.0 loaded; voice cutoff=death animation start; early loot enabled")
