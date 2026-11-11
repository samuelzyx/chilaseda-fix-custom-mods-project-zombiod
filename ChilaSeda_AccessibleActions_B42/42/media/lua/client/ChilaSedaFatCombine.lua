-- Parche local independiente para Long Term Preservation Extended, B42.
-- Solo partida individual. No reemplaza funciones del juego ni otros mods.
require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
require "ISUI/ISInventoryPaneContextMenu"
require "ChilaSeda_FoodMenuOrder_B42"
require "ChilaSeda_AccessibleActions_OptionalMods"

-- Fat recipes belong to this optional Workshop mod; do not expose this feature
-- when Long Term Preservation Extended is absent.
if not ChilaSedaAccessibleActions
		or not ChilaSedaAccessibleActions.isModActive("LongTermPreservationExtended") then
	return
end

ChilaSedaFatCombine = {}
local M = ChilaSedaFatCombine
local EPS = 0.000001
local CAPACITY = 0.24 -- HungerChange -24 en items_fats.txt, expresado en unidades Food.
local weightTraceTransfers = 20
local TYPES = { ["Base.Tallow"] = true, ["Base.Fat"] = true,
    ["Base.FishFat"] = true, ["Base.Lard"] = true, ["Base.Schmaltz"] = true }
local FIELDS = {
    {"getCalories", "setCalories"}, {"getCarbohydrates", "setCarbohydrates"},
    {"getLipids", "setLipids"}, {"getProteins", "setProteins"},
    {"getThirstChangeUnmodified", "setThirstChange"},
    {"getUnhappyChangeUnmodified", "setUnhappyChange"},
    {"getBoredomChangeUnmodified", "setBoredomChange"},
}

local weightTraceActions = 8
local weightTraceTransferRejects = 16

function M.eligible(item)
    return item and instanceof(item, "Food") and TYPES[item:getFullType()]
        and item:getHungChange() < -EPS and not item:isRotten()
        and not item:isBurnt() and not item:isFrozen() and not item:isTainted()
        and item:getPoisonPower() == 0 and not item:haveExtraItems()
end

function M.compatible(a, b)
    return a ~= b and M.eligible(a) and M.eligible(b)
        and a:getFullType() == b:getFullType()
        and a:isCooked() == b:isCooked()
        and a:getOffAge() == b:getOffAge()
        and a:getOffAgeMax() == b:getOffAgeMax()
end

local function canTransfer(into, from)
    if not M.compatible(into, from) then return false end
    local room = CAPACITY + into:getHungChange()
    local sourceAmount = -from:getHungChange()
    -- A combine is useful only when the entire source portion fits and can be removed.
    return room > EPS and sourceAmount > EPS and sourceAmount <= room + EPS
end

local function snapshot(item)
    -- Eat() reduce getWeight() en objetos con peso personalizado.
    local weight = item:isCustomWeight() and item:getWeight() or item:getActualWeight()
    local s = {hunger = item:getHungChange(), weight = weight,
        age = item:getAge(), heat = item:getHeat(), values = {}}
    for n, field in ipairs(FIELDS) do s.values[n] = item[field[1]](item) end
    return s
end

local function traceWeight(stage, item)
    print("[ChilaSedaFatCombine] WEIGHT_TRACE stage=" .. stage
        .. " type=" .. tostring(item:getFullType())
        .. " actual=" .. tostring(item:getActualWeight())
        .. " weight=" .. tostring(item:getWeight())
        .. " custom=" .. tostring(item:isCustomWeight())
        .. " hunger=" .. tostring(item:getHungChange()))
end

local function traceItem(item)
    if not item then return "nil" end
    local function read(object, methodName)
        local ok, value = pcall(function()
            local method = object and object[methodName]
            if type(method) == "function" then return method(object) end
            return nil
        end)
        return ok and tostring(value or "") or "ERR"
    end
    local containerOK, container = pcall(function() return item:getContainer() end)
    local parentOK, parent = pcall(function()
        return containerOK and container and container:getParent() or nil
    end)
    local parentType = parentOK and parent and read(parent, "getFullType") or ""
    return table.concat({
        "id=" .. read(item, "getID"),
        "type=" .. read(item, "getFullType"),
        "hunger=" .. read(item, "getHungChange"),
        "actual=" .. read(item, "getActualWeight"),
        "container=" .. (not containerOK and "ERR" or container and read(container, "getType") or "nil"),
        "parent=" .. parentType,
    }, ",")
end

local function traceAction(stage, chosen, items, outcome)
    if weightTraceActions <= 0 then return end
    weightTraceActions = weightTraceActions - 1
    local details = {}
    for index, item in ipairs(items or {}) do
        if index > 10 then
            details[#details + 1] = "more=" .. tostring(#items - 10)
            break
        end
        details[#details + 1] = traceItem(item)
    end
    print("[ChilaSedaFatCombine] ACTION_TRACE stage=" .. tostring(stage)
        .. " outcome=" .. tostring(outcome or "")
        .. " chosen={" .. traceItem(chosen) .. "} candidates={"
        .. table.concat(details, "|") .. "}")
end

local function traceTransferReject(reason, into, from)
    if weightTraceTransferRejects <= 0 then return end
    weightTraceTransferRejects = weightTraceTransferRejects - 1
    print("[ChilaSedaFatCombine] TRANSFER_REJECT reason=" .. tostring(reason)
        .. " into={" .. traceItem(into) .. "} from={" .. traceItem(from) .. "}")
end

-- El peso personalizado evita recalcularlo a partir de las calorias de la receta.
local function write(item, s)
    item:setHungChange(s.hunger)
    item:setActualWeight(s.weight)
    item:setWeight(s.weight)
    item:setCustomWeight(true)
    item:setAge(s.age)
    item:setHeat(s.heat)
    for n, field in ipairs(FIELDS) do item[field[2]](item, s.values[n]) end
end

-- Transfiere solamente la fraccion necesaria; no crea ni convierte objetos.
-- Las dos grasas pueden permanecer en contenedores diferentes.
function M.transfer(into, from)
    local intoContainer = into and into:getContainer()
    local fromContainer = from and from:getContainer()
    if not intoContainer or not fromContainer then
        traceTransferReject("missing_container", into, from)
        return false
    end
    if not intoContainer:contains(into) or not fromContainer:contains(from) then
        traceTransferReject("item_not_in_current_container", into, from)
        return false
    end
    if not canTransfer(into, from) then
        traceTransferReject("incompatible_or_does_not_fit", into, from)
        return false
    end
    local traceWeightChange = weightTraceTransfers > 0
    if traceWeightChange then
        weightTraceTransfers = weightTraceTransfers - 1
        traceWeight("BEFORE_INTO", into)
        traceWeight("BEFORE_FROM", from)
    end
    local a, b = snapshot(into), snapshot(from)
    local amount = -b.hunger
    if amount <= EPS or amount > CAPACITY + a.hunger + EPS then return false end
    local fraction = 1
    local oldest = math.max(a.age, b.age)
    local temperature = math.max(a.heat, b.heat)
    local movedWeight = b.weight * fraction
    a.hunger = math.max(-CAPACITY, a.hunger - amount)
    b.hunger = 0
    a.weight = a.weight + movedWeight
    b.weight = b.weight - movedWeight
    a.age, b.age = oldest, oldest
    a.heat, b.heat = temperature, temperature
    for n = 1, #FIELDS do
        local moved = b.values[n] * fraction
        a.values[n] = a.values[n] + moved
        b.values[n] = b.values[n] - moved
    end
    write(into, a)
    if fraction == 1 then
        if traceWeightChange then
            print("[ChilaSedaFatCombine] WEIGHT_TRACE source_removed=" .. tostring(from:getFullType())
                .. " moved=" .. tostring(movedWeight) .. " fraction=1")
        end
        fromContainer:Remove(from)
    else
        write(from, b)
        if traceWeightChange then traceWeight("AFTER_FROM", from) end
    end
    if traceWeightChange then traceWeight("AFTER_INTO", into) end
    intoContainer:setDrawDirty(true)
    fromContainer:setDrawDirty(true)
    return true
end

local function accessibleContainers(character, chosen)
    local containers, visited = {}, {}
    local function addTree(container)
        if not container or visited[container] then return end
        visited[container] = true
        containers[#containers + 1] = container

        local items = container:getItems()
        if not items then return end
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item and instanceof(item, "InventoryContainer") then
                addTree(item:getInventory())
            end
        end
    end

    addTree(character and character:getInventory())
    addTree(chosen and chosen:getContainer())

    local paneMenu = rawget(_G, "ISInventoryPaneContextMenu")
    if paneMenu and paneMenu.getContainers then
        local ok, nearby = pcall(function()
            return paneMenu.getContainers(character)
        end)
        if ok and nearby then
            for i = 0, nearby:size() - 1 do
                addTree(nearby:get(i))
            end
        end
    end
    return containers
end

function M.collect(character, chosen)
    local out, seen = {}, {}
    if not M.eligible(chosen) then return out end

    for _, container in ipairs(accessibleContainers(character, chosen)) do
        local items = container:getItems()
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item then
                local id = item:getID()
                if not seen[id] then
                    seen[id] = true
                    if item == chosen or M.compatible(chosen, item) then
                        out[#out + 1] = item
                    end
                end
            end
        end
    end

    if not seen[chosen:getID()] then out[#out + 1] = chosen end
    table.sort(out, function(a, b) return a:getHungChange() > b:getHungChange() end)
    return out
end

function M.canCombine(items)
    for i = 1, #items do
        for j = 1, #items do
            if i ~= j and canTransfer(items[i], items[j]) then return true end
        end
    end
    return false
end

ISChilaSedaFatCombine = ISBaseTimedAction:derive("ISChilaSedaFatCombine")
function ISChilaSedaFatCombine:isValid()
    if isClient() or isServer() then return false end
    return M.canCombine(M.collect(self.character, self.chosen))
end
function ISChilaSedaFatCombine:start()
    self:setActionAnim("Loot")
    self:setAnimVariable("LootPosition", "Mid")
    self:setOverrideHandModels(nil, nil)
end
function ISChilaSedaFatCombine:update() end
function ISChilaSedaFatCombine:stop() ISBaseTimedAction.stop(self) end
function ISChilaSedaFatCombine:perform()
    local valid = self:isValid()
    local items = valid and M.collect(self.character, self.chosen) or {}
    traceAction("PERFORM", self.chosen, items, valid and "valid" or "invalid")
    if valid then
        for i = 1, #items do
            for j = 1, #items do
                if i ~= j then M.transfer(items[i], items[j]) end
            end
        end
        for _, container in ipairs(accessibleContainers(self.character, self.chosen)) do
            container:setDrawDirty(true)
        end
        triggerEvent("OnContainerUpdate")
    end
    ISBaseTimedAction.perform(self)
end
function ISChilaSedaFatCombine:new(character, chosen)
    local o = ISBaseTimedAction.new(self, character)
    o.chosen = chosen
    o.stopOnWalk, o.stopOnRun = true, true
    o.maxTime = character:isTimedActionInstant() and 1 or 90
    return o
end

function M.queue(character, chosen)
    if isClient() or isServer() or not character or not chosen then return false end
    local items = M.collect(character, chosen)
    local canCombine = M.canCombine(items)
    traceAction("QUEUE", chosen, items, canCombine and "valid" or "invalid")
    if not canCombine then return false end

    local function combinationKey(item)
        return table.concat({ item:getFullType(), tostring(item:isCooked()),
            tostring(item:getOffAge()), tostring(item:getOffAgeMax()) }, "|")
    end
    local key = combinationKey(chosen)
    local queue = ISTimedActionQueue.getTimedActionQueue(character)
    for _, action in ipairs(queue.queue or {}) do
        if instanceof(action, "ISChilaSedaFatCombine") and action.chosen
            and combinationKey(action.chosen) == key then
            return false
        end
    end

    ISTimedActionQueue.add(ISChilaSedaFatCombine:new(character, chosen))
    return true
end

local function setCookingPotIcon(option)
    if not option or type(getScriptManager) ~= "function" then return end
    local okManager, manager = pcall(getScriptManager)
    if not okManager or not manager then return end
    for _, fullType in ipairs({ "Base.Pot", "Base.Saucepan" }) do
        local okItem, scriptItem = pcall(manager.FindItem, manager, fullType)
        if okItem and scriptItem and type(scriptItem.getNormalTexture) == "function" then
            local okTexture, texture = pcall(scriptItem.getNormalTexture, scriptItem)
            if okTexture and texture then
                option.iconTexture = texture
                return
            end
        end
    end
end

local function actualSelectedItems(entries)
    if type(entries) ~= "table" then return {} end

    local pane = rawget(_G, "ISInventoryPane")
    if pane and type(pane.getActualItems) == "function" then
        local ok, actual = pcall(pane.getActualItems, entries)
        if ok and type(actual) == "table" then return actual end
    end

    local actual = {}
    for _, entry in ipairs(entries) do
        if instanceof(entry, "InventoryItem") then
            actual[#actual + 1] = entry
        elseif type(entry) == "table" and type(entry.items) == "table" then
            for _, item in ipairs(entry.items) do
                if instanceof(item, "InventoryItem") then
                    actual[#actual + 1] = item
                end
            end
        end
    end
    return actual
end

function M.fillMenu(playerNum, context, entries)
    if isClient() or isServer() then return end
    local character = getSpecificPlayer(playerNum)
    if not character then return end
    for _, item in ipairs(actualSelectedItems(entries)) do
        if item and M.canCombine(M.collect(character, item)) then
            local option = context:addOptionOnTop("Combinar grasas: " .. item:getDisplayName(), character, M.queue, item)
            setCookingPotIcon(option)
            ChilaSedaFoodMenuOrder.move(context, option)
            return
        end
    end
end
Events.OnFillInventoryObjectContextMenu.Add(M.fillMenu)
