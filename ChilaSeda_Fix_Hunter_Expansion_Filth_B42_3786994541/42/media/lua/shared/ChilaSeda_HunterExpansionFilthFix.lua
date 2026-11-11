-- Local compatibility fix for Hunter Expansion 0.6.3 / Build 42.20+.
require "HE_Detect"

if HEDetect._ChilaSedaFilthFixVersion == "1.0.0" then return end

local function callIfAvailable(object, methodName, ...)
    if not object then return nil end
    local method = object[methodName]
    -- Kahlua logs a nil-call even inside pcall. Check BEFORE invoking it.
    if type(method) ~= "function" then return nil end
    local ok, value = pcall(method, object, ...)
    if ok then return value end
    return nil
end

local function numberIfAvailable(object, methodName)
    local value = callIfAvailable(object, methodName)
    if type(value) == "number" then return value end
    return 0
end

function HEDetect.filthOf(player)
    local worn = callIfAvailable(player, "getWornItems")
    if not worn then return 0 end

    local worst = 0
    local count = numberIfAvailable(worn, "size")
    for index = 0, count - 1 do
        local wornItem = callIfAvailable(worn, "get", index)
        local item = callIfAvailable(wornItem, "getItem")
        if item then
            local dirt = numberIfAvailable(item, "getDirtiness")
            local blood = numberIfAvailable(item, "getBloodLevel")
            local total = dirt + blood * HEDetect.BLOOD_WEIGHT
            if total > worst then worst = total end
        end
    end

    -- Match the original maximum-garment calculation and upper bound.
    return math.min(worst, 100)
end

HEDetect._ChilaSedaFilthFixVersion = "1.0.0"
print("[ChilaSeda Hunter Filth Fix] Loaded v1.0.0")
