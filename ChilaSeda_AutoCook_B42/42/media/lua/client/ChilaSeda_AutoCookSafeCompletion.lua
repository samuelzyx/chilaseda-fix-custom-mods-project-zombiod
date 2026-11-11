local autoCookLoaded = pcall(require, "AutoCook")
if not autoCookLoaded or type(AutoCook) ~= "table"
        or type(AutoCook.init) ~= "function"
        or type(AutoCook.new) ~= "function"
        or type(AutoCook.filterFood) ~= "function" then
    print("[ChilaSeda_AutoCookSafeCompletion] AutoCook is unavailable or has an incompatible API; patch skipped.")
    return
end

if AutoCook.ChilaSedaSafeCompletionInstalled then return end

local originalInit = AutoCook.init
local originalNew = AutoCook.new
local originalFilterFood = AutoCook.filterFood

local function enableFinishedMealCompletion(playerObj)
	AutoCook.CompleteExistingMeal = true
	local modData = playerObj and playerObj:getModData()
	if modData then
		modData.AutoCook = modData.AutoCook or {}
		modData.AutoCook.CompleteExistingMeal = true
	end
end

local function hasPositiveBenefit(item)
	local positiveNutrition = item:getHungerChange() < 0
		or item:getCalories() > 0
		or item:getCarbohydrates() > 0
		or item:getLipids() > 0
		or item:getProteins() > 0
	local positiveMood = item:getUnhappyChange() < 0 or item:getBoredomChange() < 0
	return positiveNutrition or positiveMood
end

local function hasHarmfulMealEffect(item)
	return item:getHungerChange() > 0
		or item:getThirstChange() > 0
		or item:getUnhappyChange() > 0
		or item:getBoredomChange() > 0
		or item:getStressChange() > 0
		or item:getFoodSicknessChange() > 0
		or item:getFatigueChange() > 0
		or item:getPoisonPower() > 0
		or item:getCalories() < 0
		or item:getCarbohydrates() < 0
		or item:getLipids() < 0
		or item:getProteins() < 0
		or item:isRotten()
end

AutoCook.init = function(self, playerObj, ...)
	local result = originalInit(self, playerObj, ...)
	enableFinishedMealCompletion(playerObj)
	return result
end

AutoCook.new = function(self, playerObj, recipe, baseItem, ...)
	local job = originalNew(self, playerObj, recipe, baseItem, ...)
	if job and recipe and recipe:isResultItem(baseItem) then
		job.ChilaSedaSafeCompletion = true
	end
	return job
end

AutoCook.filterFood = function(self, item, ...)
	if self.ChilaSedaSafeCompletion then
		if hasHarmfulMealEffect(item)
				or not hasPositiveBenefit(item) then
			return nil
		end
	end
	return originalFilterFood(self, item, ...)
end

local function markFinishedMealOptions(playerNum, context, items)
	if not context or type(context.options) ~= "table" then return end
	for _, option in ipairs(context.options or {}) do
		local job = option.target
		if job and job.ChilaSedaSafeCompletion then
			option.name = "Complementar receta: " .. job.recipe:getName()
		end
	end
end

Events.OnGameStart.Add(function()
	enableFinishedMealCompletion(getPlayer())
end)
Events.OnPreFillInventoryObjectContextMenu.Add(markFinishedMealOptions)

AutoCook.ChilaSedaSafeCompletionInstalled = true
print("[ChilaSeda_AutoCookSafeCompletion] Finished-meal completion enabled with safe-ingredient filtering.")
