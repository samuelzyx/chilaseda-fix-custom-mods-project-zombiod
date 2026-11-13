require "ISUI/ISInventoryPaneContextMenu"

local iconPaths = {
	recipe = "media/ui/inventoryPanes/craftok.png",
	salad = "media/textures/WorldItems/BowlSalad.png",
	drop = "media/ui/MP/mp_ui_droplist.png",
	pour = "media/ui/Entity/fluid_drop_icon.png",
	split = "media/ui/Icon_RecipeGroup_Partial_48x48.png",
	inventory = "media/ui/Sidebar/48/Inventory_On_48.png",
}

local iconCache = {}
local function iconFor(key)
	if iconCache[key] ~= nil then return iconCache[key] or nil end
	local ok, texture = pcall(getTexture, iconPaths[key])
	iconCache[key] = ok and texture or false
	return iconCache[key] or nil
end

local function normalizedName(option)
	local name = option and option.name
	if type(name) ~= "string" then return "" end
	name = name:gsub("<[^>]+>", " "):gsub("[%c]+", " ")
	name = name:gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
	name = string.lower(name)
	local accents = { ["á"] = "a", ["é"] = "e", ["í"] = "i", ["ó"] = "o", ["ú"] = "u", ["ü"] = "u", ["ñ"] = "n" }
	for accented, plain in pairs(accents) do name = name:gsub(accented, plain) end
	return name
end

local function cleanXannyLabel(option, name)
	if not name:find("xxanyarms:", 1, true) then return name end
	local suffix = name:gsub("^.-xxanyarms:%s*", "")
	if suffix:find("diagnost", 1, true) then
		option.name = "Diagnósticos de armas"
	elseif suffix:find("test kit", 1, true) or suffix:find("kit de prueba", 1, true) then
		option.name = "Kits de prueba de armas"
	elseif suffix:find("clear blood", 1, true) or suffix:find("limpiar sangre", 1, true) then
		option.name = "Limpiar sangre (prueba)"
	else
		option.name = suffix:gsub("^%l", string.upper)
	end
	return normalizedName(option)
end

local function assignContextIcon(option, name)
	if option.iconTexture then return end
	local key
	if name:find("completar receta", 1, true)
		or name:find("complementar receta", 1, true)
		or name:find("complete recipe", 1, true) then
		key = "recipe"
	elseif name == "ensalada" or name:find("evolvedrecipe_salad", 1, true) then
		key = "salad"
	elseif name:find("verter en el suelo", 1, true)
		or name:find("verter al suelo", 1, true)
		then
		key = "pour"
	elseif name == "soltar" or name == "drop" then
		key = "drop"
	elseif name:find("dividir objetos", 1, true)
		or name == "split" or name:find("split items", 1, true) then
		key = "split"
	elseif name == "tetris" or name:find("tetris", 1, true) then
		key = "inventory"
	elseif name == "secarse" or name == "dry off" or name == "dry yourself" then
		local okManager, manager = pcall(getScriptManager)
		if okManager and manager then
			local okItem, item = pcall(manager.FindItem, manager, "Base.BathTowel")
			if okItem and item and type(item.getNormalTexture) == "function" then
				local okTexture, texture = pcall(item.getNormalTexture, item)
				if okTexture and texture then option.iconTexture = texture end
			end
		end
	end
	if key then option.iconTexture = iconFor(key) end
end

local function findLastNamed(options, keys)
	local labels = {}
	for _, key in ipairs(keys) do labels[getText(key)] = true end
	local found
	for index, option in ipairs(options) do
		if labels[option.name] then found = index end
	end
	return found
end

local function removeMarked(options, predicate)
	local found = {}
	for index = #options, 1, -1 do
		local option = options[index]
		if predicate(option) then
			option.chilaSedaOriginalMenuIndex = index
			table.remove(options, index)
			table.insert(found, 1, option)
		end
	end
	return found
end

local function insertAfter(options, option, index)
	if not option then return index end
	local at = index and (index + 1) or (#options + 1)
	table.insert(options, at, option)
	return at
end

local function defaultAnchor(options)
	local more = findLastNamed(options, { "ContextMenu_More", "ContextMenu_MoreActions" })
	return more and (more - 1) or nil
end

local foodCategoryOrder = { rotten = 1, stale = 2, fresh = 3, burnt = 4 }

local function organizeLocalOptions(context)
	local options = context.options
	local attach
	for _, option in ipairs(options) do
		local name = normalizedName(option)
		if name == "acoplar" or name == "attach" or name:find("acoplar ", 1, true) == 1 or name:find("attach ", 1, true) == 1 then attach = option end
	end
	if attach then
		local index = findLastNamed(options, { "ContextMenu_Equip_Secondary" })
		if index then
			for current, option in ipairs(options) do
				if option == attach then table.remove(options, current); break end
			end
			insertAfter(options, attach, findLastNamed(options, { "ContextMenu_Equip_Secondary" }))
		end
	end

	local foodGroup = removeMarked(options, function(option)
		return option.chilaSedaPoisonMealAction
			or option.chilaSedaDeleteFoodCategory ~= nil
			or option.chilaSedaDeleteObject
	end)
	if #foodGroup > 0 then
		table.sort(foodGroup, function(left, right)
			local function rank(option)
				if option.chilaSedaPoisonMealAction then return 0 end
				if option.chilaSedaDeleteFoodCategory then
					return foodCategoryOrder[option.chilaSedaDeleteFoodCategory] or 10
				end
				return 20
			end
			local leftRank, rightRank = rank(left), rank(right)
			if leftRank ~= rightRank then return leftRank < rightRank end
			return left.chilaSedaOriginalMenuIndex < right.chilaSedaOriginalMenuIndex
		end)
		local anchor = findLastNamed(options, { "ContextMenu_Eat", "ContextMenu_OpenAndEat" })
		if not anchor then anchor = defaultAnchor(options) end
		for _, option in ipairs(foodGroup) do
			anchor = insertAfter(options, option, anchor)
			option.chilaSedaOriginalMenuIndex = nil
		end
	end

	local craftGroup = removeMarked(options, function(option)
		return option.chilaSedaFoodMenuAction
			or option.chilaSedaResumeAutoCook
			or option.chilaSedaDismantleAll
	end)
	if #craftGroup > 0 then
		local anchor = findLastNamed(options, {
			"ContextMenu_Recipes", "ContextMenu_Craft",
			"ContextMenu_ShowCraftRecipesUsed", "ContextMenu_ResearchCraft",
		})
		if not anchor then anchor = defaultAnchor(options) end
		for _, option in ipairs(craftGroup) do
			local recipeName = option.chilaSedaDismantleRecipeName
			local recipeAnchor
			if recipeName then
				for index, candidate in ipairs(options) do
					if candidate.name == recipeName
						or (type(candidate.name) == "string" and candidate.name:find(recipeName .. " (", 1, true) == 1) then
						recipeAnchor = index
					end
				end
			end
			anchor = insertAfter(options, option, recipeAnchor or anchor)
			option.chilaSedaOriginalMenuIndex = nil
		end
	end
end

local function polishInventoryMenu(player, context)
	local options = context and context.options
	if type(options) ~= "table" then return end

	for _, option in ipairs(options) do
		local name = normalizedName(option)
		cleanXannyLabel(option, name)
		assignContextIcon(option, name)
	end
	organizeLocalOptions(context)
	for index, option in ipairs(options) do option.id = index end
	pcall(function()
		if context.calcHeight then context:calcHeight() end
		if context.calcWidth and context.setWidth then
			context:setWidth(context:calcWidth())
		end
	end)
end

Events.OnFillInventoryObjectContextMenu.Add(polishInventoryMenu)
Events.OnFillWorldObjectContextMenu.Add(function(_, context)
	local options = context and context.options
	if type(options) ~= "table" then return end
	for _, option in ipairs(options) do
		local name = normalizedName(option)
		cleanXannyLabel(option, name)
		assignContextIcon(option, name)
	end
	organizeLocalOptions(context)
	for index, option in ipairs(options) do option.id = index end
	pcall(function()
		if context.calcHeight then context:calcHeight() end
		if context.calcWidth and context.setWidth then context:setWidth(context:calcWidth()) end
	end)
end)
