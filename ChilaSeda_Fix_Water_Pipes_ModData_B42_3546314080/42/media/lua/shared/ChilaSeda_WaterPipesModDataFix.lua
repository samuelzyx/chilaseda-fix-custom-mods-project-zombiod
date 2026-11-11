require "WPGMD"

local VERSION = "1.0.0"
if ChilaSedaWaterPipesModDataFixVersion == VERSION then return end

if type(GetWPModData) ~= "function" then
    print("[ChilaSeda WaterPipes ModData Fix] WaterPipes getter is unavailable")
    return
end

local originalGetWPModData = GetWPModData
local collectionNames = {
    "Pumps",
    "Pipes",
    "Valves",
    "Flowmeters",
    "Barrels",
    "Sprinklers",
    "Buildings",
}

local function hasCompleteCollections(data)
    if type(data) ~= "table" then return false end
    for _, name in ipairs(collectionNames) do
        if type(data[name]) ~= "table" then return false end
    end
    return true
end

GetWPModData = function(...)
    local data = originalGetWPModData(...)

    if not hasCompleteCollections(data) then
        -- WPGMD.lua resets WPModData to {} when Lua is reloaded. Reconnect to
        -- Project Zomboid's stored WaterPipes table before creating defaults.
        if ModData and type(ModData.getOrCreate) == "function" then
            local ok, storedData = pcall(function()
                return ModData.getOrCreate("WaterPipes")
            end)
            if ok and type(storedData) == "table" then
                data = storedData
            end
        end
    end

    if type(data) ~= "table" then data = {} end
    for _, name in ipairs(collectionNames) do
        if type(data[name]) ~= "table" then
            data[name] = {}
        end
    end

    WPModData = data
    return data
end

ChilaSedaWaterPipesModDataFixVersion = VERSION
print("[ChilaSeda WaterPipes ModData Fix] Loaded v" .. VERSION)
