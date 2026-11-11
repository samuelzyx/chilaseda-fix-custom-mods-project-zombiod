require "ISUI/ISInventoryPaneContextMenu"
require "ChilaSeda_FoodMenuOrder_B42"
require "Entity/ISEntityUI"
require "ChilaSeda_AccessibleCrafting_B42"
require "ChilaSeda_AccessibleActions_OptionalMods"

-- Long Term Preservation Extended is optional. This add-on stays dormant when it
-- is not active, without making the Workshop mod a hard dependency.
if not ChilaSedaAccessibleActions
		or not ChilaSedaAccessibleActions.isModActive("LongTermPreservationExtended") then
	return
end

-- LTP 42.20 references a global `pork` in ReduceMeatLard after it has already
-- found the input as a local `meat`. Supply that input during the callback.
if RecipeCodeOnCreate and type(RecipeCodeOnCreate.ReduceMeatLard) == "function"
    and not RecipeCodeOnCreate._ChilaSedaPorkScopeFix then
    local originalReduceMeatLard = RecipeCodeOnCreate.ReduceMeatLard
    RecipeCodeOnCreate.ReduceMeatLard = function(data, character)
        local previousPork = rawget(_G, "pork")
        local consumed = data and data:getAllConsumedItems()
        local sourcePork
        if consumed then
            for i = 0, consumed:size() - 1 do
                local item = consumed:get(i)
                if item and item:getFullType() == "Base.Pork" then
                    sourcePork = item
                    break
                end
            end
        end
        if sourcePork then rawset(_G, "pork", sourcePork) end
        local ok, result = pcall(originalReduceMeatLard, data, character)
        rawset(_G, "pork", previousPork)
        if not ok then error(result, 0) end
        return result
    end
    RecipeCodeOnCreate._ChilaSedaPorkScopeFix = true
end

local RECIPE_BY_INPUT = {
    ["Base.Pork"] = "ReduceMeatLard",
    ["Base.Smallbirdmeat"] = "ReduceSchmaltz",
    ["Base.ChickenFillet"] = "ReduceSchmaltz",
    ["Base.Chicken"] = "ReduceSchmaltz",
    ["Base.ChickenWings"] = "ReduceSchmaltz",
    ["Base.TurkeyFillet"] = "ReduceSchmaltz",
    ["Base.TurkeyLegs"] = "ReduceSchmaltz",
    ["Base.TurkeyWings"] = "ReduceSchmaltz",
    ["Base.Beef"] = "ReduceTallow",
    ["Base.MuttonChop"] = "ReduceTallow",
    ["Base.Venison"] = "ReduceTallow",
    ["Base.FrogMeat"] = "ReduceFat",
    ["Base.Rabbitmeat"] = "ReduceFat",
    ["Base.Smallanimalmeat"] = "ReduceFat",
    ["Base.FishFillet"] = "ReduceFishFat",
}

local reductionRecipeNames = {
    ReduceMeatLard = true, ReduceSchmaltz = true, ReduceTallow = true,
    ReduceFat = true, ReduceFishFat = true,
}

local function isRottenReductionInput(item)
    return item and RECIPE_BY_INPUT[item:getFullType()]
        and instanceof(item, "Food") and item:isRotten()
end

-- Vanilla builds the individual recipe options from this list. Filter only
-- LTP's fat recipes for rotten selected meat, leaving every other recipe intact.
local previousDynamicRecipeMenu = ISInventoryPaneContextMenu.addNewCraftingDynamicalContextMenu
if previousDynamicRecipeMenu and not ISInventoryPaneContextMenu._ChilaSedaRottenFatRecipeFilter then
    ISInventoryPaneContextMenu.addNewCraftingDynamicalContextMenu = function(
        selectedItem, context, recipeList, player, containerList, ...)
        if isRottenReductionInput(selectedItem) and recipeList and ArrayList then
            local ok, size = pcall(function() return recipeList:size() end)
            if ok and type(size) == "number" then
                local filtered = ArrayList.new()
                for index = 0, size - 1 do
                    local recipe = recipeList:get(index)
                    local nameOK, recipeName = pcall(function() return recipe:getName() end)
                    if not nameOK or not reductionRecipeNames[recipeName] then
                        filtered:add(recipe)
                    end
                end
                return previousDynamicRecipeMenu(selectedItem, context, filtered,
                    player, containerList, ...)
            end
        end
        return previousDynamicRecipeMenu(selectedItem, context, recipeList,
            player, containerList, ...)
    end
    ISInventoryPaneContextMenu._ChilaSedaRottenFatRecipeFilter = true
end

local function queueAll(item, recipe, playerNum)
    local character = getSpecificPlayer(playerNum)
    if not character or not item or isRottenReductionInput(item)
        or not recipe or not HandcraftLogic then return end

    local logic = HandcraftLogic.new(character, nil, nil)
    logic:setIsoObject(logic:findCraftSurface(character, 2))
    logic:setContainers(ISInventoryPaneContextMenu.getContainers(character, item))
    logic:setRecipeFromContextClick(recipe, item)

    local quantity = math.max(0, math.floor(tonumber(logic:getPossibleCraftCount(true)) or 0))
    if quantity < 1 then return end
    ISEntityUI.HandcraftStartMultiple(character, logic, false, quantity, true)
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

local function addReduceAllOption(playerNum, context, entries)
    local character = getSpecificPlayer(playerNum)
    if not character or not entries then return end

    local containers = ISInventoryPaneContextMenu.getContainers(character)
    for _, entry in ipairs(entries) do
        local item = instanceof(entry, "InventoryItem") and entry
            or (type(entry) == "table" and entry.items and entry.items[1])
        local recipeName = item and RECIPE_BY_INPUT[item:getFullType()]
        if recipeName and not isRottenReductionInput(item) then
            local recipe = getScriptManager():getCraftRecipe("Base." .. recipeName)
            local valid = false
            if recipe and HandcraftLogic then
                local ok, canPerform = pcall(function()
                    local logic = HandcraftLogic.new(character, nil, nil)
                    logic:setIsoObject(logic:findCraftSurface(character, 2))
                    logic:setContainers(containers)
                    logic:setRecipeFromContextClick(recipe, item)
                    return logic:canPerformCurrentRecipe()
                end)
                valid = ok and canPerform == true
            end
            if valid then
                local option = context:addOptionOnTop("Reducir todas las grasas disponibles", item,
                    queueAll, recipe, playerNum)
                setCookingPotIcon(option)
                ChilaSedaFoodMenuOrder.move(context, option)
                return
            end
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(addReduceAllOption)
