-- B42 port of the symbol definitions from Workshop 2701170568.
-- Keep the original `extra:` IDs so placed symbols and Recent Map Symbols
-- entries continue to resolve. The B41 UI replacement is intentionally not
-- loaded; B42 already owns the map symbol panel and Recent/Search tabs extend it.
local definitions = MapSymbolDefinitions.getInstance()

local function register(name, variant)
    local id = "extra:" .. name
    local texture = "media/ui/ExtraMapSymbols/rMap_" .. name
    if variant ~= nil then
        id = id .. "//alt=" .. tostring(variant)
        texture = texture .. "." .. tostring(variant)
    end
    local ok, err = pcall(function()
        definitions:addTexture(id, texture .. ".png")
    end)
    if not ok then
        print("[ChilaSeda Extra Map Symbols] Could not register " .. id .. ": " .. tostring(err))
    end
end

local function registerVanillaAlternative(name, variant)
    local id = name .. "//alt=" .. tostring(variant)
    local texture = "media/ui/ExtraMapSymbols/alt/" .. name .. "." .. tostring(variant) .. ".png"
    local ok, err = pcall(function()
        definitions:addTexture(id, texture)
    end)
    if not ok then
        print("[ChilaSeda Extra Map Symbols] Could not register " .. id .. ": " .. tostring(err))
    end
end

local names = {
    "book", "sledge", "pipeWrench", "sheriff", "axe2", "medic", "shirt",
    "helmet", "ammo", "vhs", "fuel", "fuel2", "water", "car", "truck",
    "helicopter", "parachute", "marine", "loot", "bed", "meet", "school",
    "warehouse", "cross", "line1", "line2", "line3", "line4", "dot",
    "x_small", "trashpanda",
}

for _, name in ipairs(names) do register(name) end
for variant = 0, 4 do
    register("dot", variant)
    register("x_small", variant)
end

-- Alternative artwork for vanilla marker IDs, using vanilla's //alt=N IDs.
local vanillaAlternatives = {
    Checkmark = 4, Z = 4, X = 4, Cross = 4, DollarSign = 4,
    Exclamation = 4, Question = 4, Asterisk = 2, Circle = 2, Club = 2,
    Diamond = 2, KnifeFork = 2, Garbage = 2, Target = 2, Sun = 2,
    Star = 2, Spade = 2, Skull = 2, Radiation = 2,
}
for name, count in pairs(vanillaAlternatives) do
    for variant = 0, count - 1 do registerVanillaAlternative(name, variant) end
end

-- Preserve legacy marker IDs from earlier Extra Map Symbols releases.
local legacy = {
    arrow1 = "ArrowNorthEast", arrow2 = "ArrowSouthEast",
    arrow3 = "ArrowSouthWest", arrow4 = "ArrowNorthWest",
    food = "KnifeFork", wrench = "Wrench",
}
for name in pairs(legacy) do register(name) end
