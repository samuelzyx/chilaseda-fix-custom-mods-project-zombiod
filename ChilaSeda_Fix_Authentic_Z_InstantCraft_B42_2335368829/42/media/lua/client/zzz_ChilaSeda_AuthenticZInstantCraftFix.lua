require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISCraftAction"

AZRecipe = AZRecipe or {}
AZRecipe.Recipes = AZRecipe.Recipes or {}
AZRecipe.Recipes.OnCreate = AZRecipe.Recipes.OnCreate or {}

AZRecipe.Recipes.OnCreate.InstantCraft = function(craftRecipeData, character)
    if not character or not ISCraftAction or not ISTimedActionQueue
            or type(ISTimedActionQueue.getTimedActionQueue) ~= "function" then
        return
    end

    local ok, actionQueue = pcall(ISTimedActionQueue.getTimedActionQueue, character)
    if not ok or type(actionQueue) ~= "table" or type(actionQueue.queue) ~= "table" then
        return
    end

    local craftAction = actionQueue.queue[#actionQueue.queue]
    if craftAction and craftAction.__index == ISCraftAction then
        craftAction.is_ignore_additional_time = true
    end
end

print("[ChilaSeda_AuthenticZInstantCraftFix] installed; using getTimedActionQueue")
