local loaded = pcall(function()
    require "UndeadWildlife_Core"
    require "UndeadWildlife_CorpseMenu"
end)
if not loaded or type(UndeadWildlife) ~= "table" then return end

require "ISUI/Animal/ISAnimalContextMenu"
require "ISUI/ISInventoryPaneContextMenu"
require "TimedActions/Animals/ISDropAnimalCorpseAndThen"
require "TimedActions/ISBaseTimedAction"

local equivalents = {
    infectedraccoon = "raccoonboar", infectedcockerel = "cockerel",
    infectedchicken = "hen", infectedturkey = "turkeyhen",
    infectedrabbit = "rabdoe", infectedpiglet = "piglet",
    infectedfarmpig = "sow", infecteddeerdoe = "doe",
    infecteddeerstag = "buck", infectedcow = "cow",
    infectedcowcalf = "cowcalf", infectedbull = "bull",
    infectedewe = "ewe", infectedram = "ram", infectedlamb = "lamb",
    infectedrat = "rat",
}

local vanillaMenuFromInv = AnimalContextMenu.doAnimalBodyMenuFromInv
local vanillaMenuOnGround = AnimalContextMenu.doAnimalBodyMenu

local function repairMissingPartsFlag(body)
    local data = body and body:getModData()
    if not data or data.parts == true or data.skeleton then return end
    local source = equivalents[data.AnimalType]
    if not source then return end
    local breed = data.AnimalBreed
    if not breed then return end
    local definitions = AnimalPartsDefinitions and AnimalPartsDefinitions.animals
    if definitions and definitions[source .. breed] and definitions[data.AnimalType .. breed] then
        -- UW can leave this false when the copied parts definition was unavailable at death.
        -- Vanilla finished bodies have skeleton=true; never restore parts on those.
        data.parts = true
    end
end

local function isInAccessibleContainer(playerObj, body)
    local inventory = playerObj:getInventory()
    local container = body:getContainer()
    if not container or container == inventory then return false end
    local outermost = container:getOutermostContainer()
    if outermost == inventory then return true end
    local accessible = ISInventoryPaneContextMenu.getContainers(playerObj)
    return accessible and (accessible:contains(container) or (outermost and accessible:contains(outermost)))
end

local function findAccessibleButcheringKnife(playerObj)
    local inventory = playerObj:getInventory()
    local knife = inventory:getFirstTagEvalRecurse(ItemTag.BUTCHER_ANIMAL, function(item)
        return not item:isBroken()
    end)
    if knife then return knife end

    local accessible = ISInventoryPaneContextMenu.getContainers(playerObj)
    if not accessible then return nil end
    for i = 0, accessible:size() - 1 do
        local container = accessible:get(i)
        local items = container:getAllTagRecurse(ItemTag.BUTCHER_ANIMAL, ArrayList.new())
        for j = 0, items:size() - 1 do
            local item = items:get(j)
            if not item:isBroken() then return item end
        end
    end
    return nil
end

local ChilaSeda_DropAnimalCorpseAndThen = ISDropAnimalCorpseAndThen:derive("ChilaSeda_DropAnimalCorpseAndThen")

function ChilaSeda_DropAnimalCorpseAndThen:isValid()
    if not self.character:getCurrentSquare() or not self.srcContainer then return false end
    if not isInAccessibleContainer(self.character, self.item) then return false end
    if isClient() then return self.srcContainer:containsID(self.item:getID()) end
    return self.srcContainer:contains(self.item)
end

function ChilaSeda_DropAnimalCorpseAndThen:start()
    if isClient() and self.item then
        self.item = self.srcContainer:getItemById(self.item:getID())
    end
    self.item:setJobType(getText("IGUI_JobType_Dropping"))
    self.item:setJobDelta(0.0)
    local sound = self.item:getDropSound()
    if sound ~= nil and not self.character:getEmitter():isPlaying(sound) then
        self.sound = self.character:playSound(sound)
    end
end

function ChilaSeda_DropAnimalCorpseAndThen:complete()
    self:stopSound()
    self.item:setJobDelta(0.0)
    ISInventoryPage.renderDirty = true
    self.srcContainer:Remove(self.item)
    sendRemoveItemFromContainer(self.srcContainer, self.item)
    self.srcContainer:setDrawDirty(true)
    local corpse = self.character:getCurrentSquare():tryAddCorpseToWorld(self.item, 0.5, 0.5)
    if not corpse then
        self.srcContainer:AddItem(self.item)
        sendAddItemToContainer(self.srcContainer, self.item)
        return false
    end
    if corpse and self.andThen then
        if isServer() then
            local args = { corpse = corpse, onlineID = self.character:getOnlineID() }
            sendServerCommand(self.character, "animalCorpse", self.andThen, args)
        elseif not isClient() and self.andThen == "butcher" then
            if luautils.walkAdj(self.character, corpse:getSquare()) then
                ISTimedActionQueue.add(ISButcherAnimal:new(self.character, corpse))
            end
        end
    end
    return true
end

function ChilaSeda_DropAnimalCorpseAndThen:new(character, item, srcContainer, andThen)
    local action = ISBaseTimedAction.new(self, character)
    action.item = item
    action.srcContainer = srcContainer
    action.andThen = andThen
    action.maxTime = action:getDuration()
    return action
end

local function queueButcherFromContainer(playerObj, body)
    local source = body:getContainer()
    if not source or not isInAccessibleContainer(playerObj, body) then return false end
    ISTimedActionQueue.add(ChilaSeda_DropAnimalCorpseAndThen:new(playerObj, body, source, "butcher"))
    return true
end

AnimalContextMenu.doAnimalBodyMenuFromInv = function(context, playerObj, body)
    repairMissingPartsFlag(body)
    vanillaMenuFromInv(context, playerObj, body)

    if not isInAccessibleContainer(playerObj, body) or not body:hasAnimalParts() then return end
    local knife = findAccessibleButcheringKnife(playerObj)
    local option = context:addOption(getText("ContextMenu_ButcherAnimal"), body,
        function(target, player, tool)
            queueButcherFromContainer(player, target)
        end, playerObj, knife)
    local okManager, manager = pcall(getScriptManager)
    if okManager and manager then
        local okTool, toolItem = pcall(manager.FindItem, manager, "Base.MeatCleaver")
        if not okTool or not toolItem then
            okTool, toolItem = pcall(manager.FindItem, manager, "Base.KitchenKnife")
        end
        if okTool and toolItem then
            local okTexture, texture = pcall(toolItem.getNormalTexture, toolItem)
            if okTexture and texture then option.iconTexture = texture end
        end
    end

    local equipLabels = {
        [getText("ContextMenu_Equip_Primary")] = true,
        [getText("ContextMenu_Equip_Secondary")] = true,
        [getText("ContextMenu_Equip_Two_Hands")] = true,
        [getText("ContextMenu_Recipes")] = true,
    }
    local optionIndex, insertAfter
    for index, entry in ipairs(context.options or {}) do
        if entry == option then optionIndex = index end
        if entry ~= option and equipLabels[entry.name] then insertAfter = index end
    end
    if optionIndex then
        table.remove(context.options, optionIndex)
        insertAfter = insertAfter or math.min(1, #context.options)
        table.insert(context.options, (insertAfter > 0 and insertAfter + 1 or 1), option)
        for index, entry in ipairs(context.options) do entry.id = index end
        pcall(function()
            if context.calcHeight then context:calcHeight() end
            if context.calcWidth and context.setWidth then context:setWidth(context:calcWidth()) end
        end)
    end
    if not knife then
        option.notAvailable = true
        local tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip:setName(getText("Tooltip_Animal_NoKnifeButcher"))
        option.toolTip = tooltip
    end
end

AnimalContextMenu.doAnimalBodyMenu = function(context, player, body)
    repairMissingPartsFlag(body)
    return vanillaMenuOnGround(context, player, body)
end

print("[ChilaSeda_AnimalBalance] optional Undead Wildlife container butchering loaded")
