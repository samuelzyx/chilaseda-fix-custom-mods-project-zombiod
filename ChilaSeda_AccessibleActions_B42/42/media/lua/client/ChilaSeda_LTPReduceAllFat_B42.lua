require "ISUI/ISInventoryPaneContextMenu"
require "ChilaSeda_FoodMenuOrder_B42"
require "Entity/ISEntityUI"
require "ChilaSeda_AccessibleCrafting_B42"
require "ChilaSeda_AccessibleActions_OptionalMods"

-- Long Term Preservation Extended is optional. This add-on stays dormant when it
-- is not active, without making the Workshop mod a hard dependency.
if not ChilaSedaAccessibleActions or type(ChilaSedaAccessibleActions.isModActive) ~= "function" then
	print("[ChilaSeda_LTPFatRendering] stage=install result=skipped fallback=accessible-actions-api-unavailable")
	return
end

local ltpStateOK, ltpActive = pcall(ChilaSedaAccessibleActions.isModActive,
	"LongTermPreservationExtended")
if not ltpStateOK or not ltpActive then
	local fallback = ltpStateOK and "ltp-inactive" or "mod-state-query-failed"
	print("[ChilaSeda_LTPFatRendering] stage=install result=skipped fallback=" .. fallback)
	return
end

RecipeCodeOnCreate = RecipeCodeOnCreate or {}
local renderTraceCount = 0
local function traceReduction(message)
	if renderTraceCount >= 32 then return end
	renderTraceCount = renderTraceCount + 1
	print("[ChilaSeda_LTPFatRendering] " .. message)
end

local function findRecipeItem(items, fullType)
	if not items then return nil end
	local sizeOK, size = pcall(function() return items:size() end)
	if not sizeOK or type(size) ~= "number" then return nil end
	for index = 0, size - 1 do
		local itemOK, item = pcall(function() return items:get(index) end)
		if itemOK and item then
			local typeOK, itemType = pcall(function() return item:getFullType() end)
			local foodOK, isFood = pcall(function() return instanceof(item, "Food") end)
			if typeOK and itemType == fullType and foodOK and isFood then return item end
		end
	end
	return nil
end

local function renderFoodReduction(data, recipeName, inputType, outputType,
	offAge, offAgeMax, factorMin, factorMax)
	local consumedOK, consumed = pcall(function() return data:getAllConsumedItems() end)
	local createdOK, created = pcall(function() return data:getAllCreatedItems() end)
	if not consumedOK or not createdOK or not consumed or not created then
		traceReduction("recipe=" .. recipeName .. " stage=oncreate result=skipped input=" .. inputType
			.. " output=" .. outputType .. " fallback=recipe-data-unavailable")
		return
	end

	local source = findRecipeItem(consumed, inputType)
	if not source then
		traceReduction("recipe=" .. recipeName .. " stage=oncreate result=skipped input=" .. inputType
			.. " output=" .. outputType .. " fallback=source-not-found")
		return
	end
	local result = findRecipeItem(created, outputType)
	if not result then
		traceReduction("recipe=" .. recipeName .. " stage=oncreate result=skipped input=" .. inputType
			.. " output=" .. outputType .. " fallback=output-not-found")
		return
	end

	local factor = (factorMin + factorMax) / 2
	local factorFallback = "random-api-unavailable"
	if type(ZombRandFloat) == "function" then
		local randomOK, randomFactor = pcall(ZombRandFloat, factorMin, factorMax)
		if randomOK and type(randomFactor) == "number"
				and randomFactor >= factorMin and randomFactor <= factorMax then
			factor = randomFactor
			factorFallback = nil
		else
			factorFallback = "random-api-failed"
		end
	end

	local writeOK, writeError = pcall(function()
		result:setOffAge(offAge)
		result:setOffAgeMax(offAgeMax)
		result:setCarbohydrates(source:getCarbohydrates() * factor)
		result:setLipids(source:getLipids() * factor)
		result:setProteins(source:getProteins() * factor)
		result:setCalories(source:getCalories() * factor)
		result:setHungChange(source:getHungChange() * factor)
	end)
	if not writeOK then
		traceReduction("recipe=" .. recipeName .. " stage=oncreate result=partial input=" .. inputType
			.. " output=" .. outputType .. " fallback=output-write-failed error=" .. tostring(writeError))
		return
	end

	traceReduction("recipe=" .. recipeName .. " stage=oncreate result=success input=" .. inputType
		.. " output=" .. outputType .. " factor=" .. tostring(factor)
		.. " fallback=" .. tostring(factorFallback or "none"))
end

function RecipeCodeOnCreate.ChilaSedaReduceDeadRabbitFat(data, character)
	renderFoodReduction(data, "ChilaSedaReduceDeadRabbitFat", "Base.DeadRabbit", "Base.Fat",
		5, 10, 0.05, 0.10)
end

function RecipeCodeOnCreate.ChilaSedaReducePorkChopLard(data, character)
	renderFoodReduction(data, "ChilaSedaReducePorkChopLard", "Base.PorkChop", "Base.Lard",
		180, 365, 0.20, 0.30)
end

traceReduction("stage=install result=ready recipes=Base.ChilaSedaReduceDeadRabbitFat,Base.ChilaSedaReducePorkChopLard")

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
    ["Base.PorkChop"] = "ChilaSedaReducePorkChopLard",
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
    ["Base.DeadRabbit"] = "ChilaSedaReduceDeadRabbitFat",
    ["Base.Smallanimalmeat"] = "ReduceFat",
    ["Base.FishFillet"] = "ReduceFishFat",
}

local reductionRecipeNames = {
    ReduceMeatLard = true, ReduceSchmaltz = true, ReduceTallow = true,
    ReduceFat = true, ReduceFishFat = true,
    ChilaSedaReduceDeadRabbitFat = true, ChilaSedaReducePorkChopLard = true,
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
    ChilaSedaAccessibleConsolidation.queueHandcraftBatch(character, logic, quantity)
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
