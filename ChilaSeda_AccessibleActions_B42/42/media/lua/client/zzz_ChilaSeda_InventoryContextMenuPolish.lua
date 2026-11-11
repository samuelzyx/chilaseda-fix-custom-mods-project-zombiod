require "ISUI/ISInventoryPaneContextMenu"

local iconPaths = {
	recipe = "media/ui/inventoryPanes/craftok.png",
	salad = "media/textures/WorldItems/BowlSalad.png",
	drop = "media/ui/MP/mp_ui_droplist.png",
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

local function hasWord(name, word)
	return name:find("%f[%w]" .. word .. "%f[%W]") ~= nil
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
		or name == "soltar" or name == "drop" then
		key = "drop"
	elseif name:find("dividir objetos", 1, true)
		or name == "split" or name:find("split items", 1, true) then
		key = "split"
	elseif name == "tetris" or name:find("tetris", 1, true) then
		key = "inventory"
	end
	if key then option.iconTexture = iconFor(key) end
end

local function optionOrder(option)
	local name = normalizedName(option)
	if name == "" then return 90 end
	if name:find("mas acciones", 1, true) or name == "mas" or name == "more" then return 100 end
	if name:find("equipar", 1, true) or name:find("equip", 1, true)
		or name:find("vestir", 1, true) or name:find("wear", 1, true) then return 10 end
	-- Keep the two reported action labels immediately after the hand-equip block.
	if name:find("cortar cabeza", 1, true) or name:find("quitar cabeza", 1, true)
		or name:find("decap", 1, true) or name:find("cut head", 1, true)
		or name:find("remove head", 1, true) then return 16 end
	if name:find("xxanyarms", 1, true) or name:find("diagnost", 1, true)
		or name:find("recargar", 1, true) or name:find("reload", 1, true)
		or name:find("cargador", 1, true) or name:find("weapon", 1, true) then return 15 end
	if (name:find("cintur", 1, true) or name:find("belt", 1, true))
		and (name:find("acoplar", 1, true) or name:find("attach", 1, true)
			or name:find("poner", 1, true) or name:find("equip", 1, true)) then return 16 end
	if name:find("abrir", 1, true) or name:find("open", 1, true)
		or name:find("inspeccionar", 1, true) or name:find("inspect", 1, true)
		or name:find("leer", 1, true) or hasWord(name, "read") then return 20 end
	if name:find("comer", 1, true) or name:find("beber", 1, true)
		or name:find("usar", 1, true) or name:find("eat", 1, true)
		or name:find("drink", 1, true) or hasWord(name, "use") then return 25 end
	if name:find("receta", 1, true) or name:find("recipe", 1, true)
		or name:find("ensalada", 1, true) or name:find("salad", 1, true)
		or name:find("cocinar", 1, true) or name:find("cooking", 1, true)
		or name:find("fabric", 1, true) or name:find("craft", 1, true)
		or name:find("cordel", 1, true) or name:find("thread", 1, true) then return 30 end
	if name:find("procesar", 1, true) or name:find("desarmar", 1, true)
		or name:find("desmantelar", 1, true) or name:find("despiez", 1, true)
		or name:find("reparar", 1, true) or name:find("repair", 1, true)
		or name:find("lavar", 1, true) or name:find("limpiar", 1, true)
		or name:find("butcher", 1, true) or name:find("process", 1, true) then return 40 end
	if name:find("transferir", 1, true) or name:find("transfer", 1, true)
		or name:find("guardar", 1, true) or name:find("contenedor", 1, true)
		or name:find("mover", 1, true) or name:find("move", 1, true)
		or name:find("recoger", 1, true) or name:find("take", 1, true)
		or name:find("saquear", 1, true) or name:find("loot", 1, true)
		or name:find("desempacar", 1, true) or name:find("unpack", 1, true)
		or name:find("anadir a", 1, true) or name:find("add to", 1, true)
		or name:find("tetris", 1, true) then return 50 end
	if name:find("dividir", 1, true) or name:find("split", 1, true) then return 60 end
	if name:find("colocar", 1, true) or name:find("constru", 1, true)
		or name:find("place", 1, true) or name:find("build", 1, true) then return 70 end
	if name:find("soltar", 1, true) or name:find("verter", 1, true)
		or name:find("drop", 1, true) or name:find("tirar", 1, true) then return 80 end
	if name:find("eliminar", 1, true) or name:find("borrar", 1, true)
		or name:find("delete", 1, true) or name:find("remove", 1, true) then return 85 end
	return 90
end

local function polishInventoryMenu(player, context)
	local options = context and context.options
	if type(options) ~= "table" then return end

	local sortable = {}
	for index, option in ipairs(options) do
		local name = normalizedName(option)
		name = cleanXannyLabel(option, name)
		assignContextIcon(option, name)
		sortable[#sortable + 1] = { option = option, index = index, rank = optionOrder(option) }
	end
	table.sort(sortable, function(left, right)
		if left.rank ~= right.rank then return left.rank < right.rank end
		return left.index < right.index
	end)
	for index, entry in ipairs(sortable) do
		options[index] = entry.option
		entry.option.id = index
	end
	for index = #sortable + 1, #options do options[index] = nil end
	pcall(function()
		if context.calcHeight then context:calcHeight() end
		if context.calcWidth and context.setWidth then
			context:setWidth(context:calcWidth())
		end
	end)
end

Events.OnFillInventoryObjectContextMenu.Add(polishInventoryMenu)
