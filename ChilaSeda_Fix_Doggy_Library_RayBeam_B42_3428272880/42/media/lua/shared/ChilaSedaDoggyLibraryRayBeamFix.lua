local RayBeam2D = require("DoggyObjects/RayBeam2D")

if not RayBeam2D then
    print("[ChilaSeda_DoggyLibraryRayBeamFix] RayBeam2D unavailable; compatibility patch skipped")
    return
end

function RayBeam2D:_getObjectType(object, spriteProperties)
    if not object or not spriteProperties then return nil, nil end

    -- Build 42.21 does not expose getType() on every object supplied by a square.
    -- Sprite flags remain the primary detection path; type matching is optional.
    local objectType
    local getType = object.getType
    if type(getType) == "function" then
        local ok, value = pcall(function()
            return object:getType()
        end)
        if ok and value ~= nil then
            objectType = tostring(value)
        end
    end

    local raysCollisions = self.raysCollisions
    if not raysCollisions then return nil, nil end

    local validProperties = raysCollisions.validProperties
    local hasPropertyMethod = type(spriteProperties.Is) == "function"
    for i = 1, #validProperties do
        local property = validProperties[i]
        local hasProperty = false
        if hasPropertyMethod then
            local propertyOk, result = pcall(function()
                return spriteProperties:Is(property)
            end)
            if propertyOk then hasProperty = result end
        end

        if hasProperty or (objectType ~= nil and property == objectType) then
            return property, raysCollisions.propertyToStructureType[property]
        end
    end

    return nil, nil
end

print("[ChilaSeda_DoggyLibraryRayBeamFix] Loaded")
