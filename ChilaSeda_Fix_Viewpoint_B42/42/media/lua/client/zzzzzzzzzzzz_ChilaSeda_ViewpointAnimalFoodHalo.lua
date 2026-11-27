local viewpointLoaded = pcall(require, "Viewpoint_Loot")
if not viewpointLoaded or type(ViewpointLoot) ~= "table" then
	print("[ChilaSeda_ViewpointAnimalFoodHalo] Viewpoint unavailable; patch skipped.")
	return
end

local ANIMAL_TAG = "[ChilaSeda_ViewpointAnimalPickupHalo] "
local FOOD_TAG = "[ChilaSeda_ViewpointFoodFullHalo] "
local MAX_ANIMAL_TRACE_LINES = 16
local MAX_FOOD_TRACE_LINES = 16
local animalTraceLines = 0
local foodTraceLines = 0
local animalInstallFallbackLogged = false
local animalInstallLogged = false
local foodFallbackLogged = false
local foodStatePlayer
local foodWasAtLevelFour

if ChilaSedaViewpointAnimalPickupHaloTrace == nil then
	ChilaSedaViewpointAnimalPickupHaloTrace = true
end
if ChilaSedaViewpointFoodFullHaloTrace == nil then
	ChilaSedaViewpointFoodFullHaloTrace = true
end

local function safeDetail(value)
	return tostring(value or ""):gsub("[\r\n]+", " "):sub(1, 120)
end

local function animalTrace(event, detail)
	if ChilaSedaViewpointAnimalPickupHaloTrace ~= true
			or animalTraceLines >= MAX_ANIMAL_TRACE_LINES then return end
	animalTraceLines = animalTraceLines + 1
	print(ANIMAL_TAG .. "event=" .. tostring(event) .. " " .. safeDetail(detail))
end

local function foodTrace(event, detail)
	if ChilaSedaViewpointFoodFullHaloTrace ~= true
			or foodTraceLines >= MAX_FOOD_TRACE_LINES then return end
	foodTraceLines = foodTraceLines + 1
	print(FOOD_TAG .. "event=" .. tostring(event) .. " " .. safeDetail(detail))
end

local function isLocalPlayer(player)
	if not player or type(getSpecificPlayer) ~= "function" then return false end
	local ok, localPlayer = pcall(getSpecificPlayer, 0)
	if not ok or not localPlayer then return false end
	if player == localPlayer then return true end
	local okPlayerMethod, playerMethod = pcall(function() return player.getPlayerNum end)
	local okLocalMethod, localMethod = pcall(function() return localPlayer.getPlayerNum end)
	if not okPlayerMethod or not okLocalMethod
			or type(playerMethod) ~= "function" or type(localMethod) ~= "function" then return false end
	local okPlayerNum, playerNum = pcall(playerMethod, player)
	local okLocalNum, localNum = pcall(localMethod, localPlayer)
	return okPlayerNum and okLocalNum and playerNum == localNum
end

local function animalDisplayName(animal)
	if not animal then return nil end
	for _, methodName in ipairs({ "getCustomName", "getFullName" }) do
		local okMethod, method = pcall(function() return animal[methodName] end)
		if okMethod and type(method) == "function" then
			local okName, name = pcall(method, animal)
			if okName and type(name) == "string" then
				name = name:gsub("^%s+", ""):gsub("%s+$", "")
				if name ~= "" then return name end
			end
		end
	end
	return nil
end

local function showAnimalPickup(action, animalName)
	local notices = ChilaSeda_ViewpointHaloNotifications
	if type(notices) ~= "table" or type(notices.showProtected) ~= "function" then
		animalTrace("pickup", "result=fallback reason=halo-notes-unavailable")
		return
	end
	local ok, shown = pcall(notices.showProtected, "+1 " .. animalName,
		{ r = 0.35, g = 1, b = 0.48 },
		"media/ui/survival_guide_spiffo/category_ranching.png", nil, "Animal.Pickup")
	if ok and shown == true then
		animalTrace("pickup", "result=shown source=ISPickupAnimal.complete name=" .. safeDetail(animalName))
	else
		animalTrace("pickup", "result=fallback reason=halo-notes-rejected")
	end
end

local function installAnimalPickupHook()
	if type(ISPickupAnimal) ~= "table" or type(ISPickupAnimal.complete) ~= "function" then
		local ok = pcall(require, "TimedActions/Animals/ISPickupAnimal")
		if not ok or type(ISPickupAnimal) ~= "table"
				or type(ISPickupAnimal.complete) ~= "function" then
			if not animalInstallFallbackLogged then
				animalInstallFallbackLogged = true
				animalTrace("install", "result=retry reason=ISPickupAnimal.complete-unavailable")
			end
			return false
		end
	end
	local actionClass = ISPickupAnimal
	if actionClass.chilaSedaAnimalPickupHaloInstalled == true then return true end
	local original = actionClass.complete
	actionClass.complete = function(self, ...)
		local animal = self and self.animal
		local character = self and self.character
		local name = animalDisplayName(animal)
		local results = { n = 0 }
		local function pack(...)
			results.n = select("#", ...)
			for index = 1, results.n do results[index] = select(index, ...) end
		end
		pack(original(self, ...))
		if self and results[1] == true then
			if self.chilaSedaAnimalPickupHaloSent == true then
				animalTrace("pickup", "result=skip reason=duplicate-complete")
			elseif not isLocalPlayer(character) then
				self.chilaSedaAnimalPickupHaloSent = true
				animalTrace("pickup", "result=skip reason=not-local-player")
			elseif not name then
				self.chilaSedaAnimalPickupHaloSent = true
				animalTrace("pickup", "result=fallback reason=animal-name-unavailable")
			else
				self.chilaSedaAnimalPickupHaloSent = true
				showAnimalPickup(self, name)
			end
		elseif self then
			animalTrace("pickup", "result=skip reason=complete-failed")
		end
		return unpack(results, 1, results.n)
	end
	actionClass.chilaSedaAnimalPickupHaloInstalled = true
	if not animalInstallLogged then
		animalInstallLogged = true
		animalTrace("install", "result=installed method=ISPickupAnimal.complete")
	end
	return true
end

local function currentFoodEatenLevel(player)
	if not player then return nil end
	local okGetter, getter = pcall(function() return player.getMoodles end)
	if not okGetter or type(getter) ~= "function" then return nil end
	local okMoodles, moodles = pcall(getter, player)
	if not okMoodles or not moodles then return nil end
	local okLevelGetter, levelGetter = pcall(function() return moodles.getMoodleLevel end)
	local moodleTypes = MoodleType
	local foodType = moodleTypes and moodleTypes.FOOD_EATEN
	if not okLevelGetter or type(levelGetter) ~= "function" or foodType == nil then return nil end
	local okLevel, level = pcall(levelGetter, moodles, foodType)
	if not okLevel or type(level) ~= "number" then return nil end
	return level
end

local function showFoodFull()
	local notices = ChilaSeda_ViewpointHaloNotifications
	if type(notices) ~= "table" or type(notices.showProtected) ~= "function" then
		foodTrace("fullness", "result=fallback reason=halo-notes-unavailable")
		return
	end
	local label = "A reventar"
	if type(getText) == "function" then
		local ok, translated = pcall(getText, "Moodles_FoodEaten_lvl4")
		if ok and type(translated) == "string" and translated ~= ""
				and translated ~= "Moodles_FoodEaten_lvl4" then
			label = translated
		end
	end
	local ok, shown = pcall(notices.showProtected, label,
		{ r = 1, g = 0.78, b = 0.32 },
		"media/ui/survival_guide_spiffo/category_food_and_water.png", nil, "Nutrition.FoodEatenFull")
	if ok and shown == true then
		foodTrace("fullness", "result=shown level=4 label=" .. safeDetail(label))
	else
		foodTrace("fullness", "result=fallback reason=halo-notes-rejected level=4")
	end
end

local function onPlayerUpdate(player)
	if not isLocalPlayer(player) then return end
	local level = currentFoodEatenLevel(player)
	if level == nil then
		if not foodFallbackLogged then
			foodFallbackLogged = true
			foodTrace("fullness", "result=fallback reason=FOOD_EATEN-level-unavailable")
		end
		return
	end
	local atLevelFour = level >= 4
	if foodStatePlayer ~= player then
		foodStatePlayer = player
		foodWasAtLevelFour = atLevelFour
		foodTrace("fullness", "result=baseline level=" .. tostring(level))
		return
	end
	if atLevelFour and foodWasAtLevelFour ~= true then
		foodWasAtLevelFour = true
		showFoodFull()
	elseif not atLevelFour and foodWasAtLevelFour == true then
		foodWasAtLevelFour = false
		foodTrace("fullness", "result=left-level-4 level=" .. tostring(level))
	else
		foodWasAtLevelFour = atLevelFour
	end
end

installAnimalPickupHook()
if Events and Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then
	Events.OnGameStart.Add(installAnimalPickupHook)
end
if Events and Events.OnTick and type(Events.OnTick.Add) == "function"
		and (type(ISPickupAnimal) ~= "table" or ISPickupAnimal.chilaSedaAnimalPickupHaloInstalled ~= true) then
	local function retryAnimalPickupHook()
		if installAnimalPickupHook() and type(Events.OnTick.Remove) == "function" then
			Events.OnTick.Remove(retryAnimalPickupHook)
		end
	end
	Events.OnTick.Add(retryAnimalPickupHook)
end
if Events and Events.OnPlayerUpdate and type(Events.OnPlayerUpdate.Add) == "function" then
	Events.OnPlayerUpdate.Add(onPlayerUpdate)
else
	foodTrace("install", "result=fallback reason=OnPlayerUpdate-unavailable")
end
