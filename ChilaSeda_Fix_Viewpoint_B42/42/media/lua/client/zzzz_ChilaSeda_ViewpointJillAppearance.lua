local TAG = "[ChilaSeda_ViewpointJillAppearance]"
local INSTALLED_KEY = "ChilaSedaJillAppearanceAdapterInstalled"
local warned = false

local function isJill(player)
    if not player or not getPlayer or player ~= getPlayer() then return false end
    if not player.getDescriptor then return false end

    local ok, descriptor = pcall(player.getDescriptor, player)
    if not ok or not descriptor or not descriptor.getForename or
            not descriptor.getSurname then
        return false
    end

    local nameOk, forename = pcall(descriptor.getForename, descriptor)
    local surnameOk, surname = pcall(descriptor.getSurname, descriptor)
    if not nameOk or not surnameOk then return false end
    return string.lower(tostring(forename or "")) == "jill" and
            string.lower(tostring(surname or "")) == "valentine"
end

local function safeCall(target, methodName, ...)
    local method = target and target[methodName] or nil
    if not method then return false end
    return pcall(method, target, ...)
end

local function partCount()
    if not BloodBodyPartType or not BloodBodyPartType.MAX or
            not BloodBodyPartType.MAX.index then
        return 0
    end
    local ok, count = pcall(BloodBodyPartType.MAX.index, BloodBodyPartType.MAX)
    if not ok or type(count) ~= "number" or count < 0 then return 0 end
    return math.floor(count)
end

local function bodyPart(index)
    if not BloodBodyPartType or not BloodBodyPartType.FromIndex then return nil end
    local ok, part = pcall(BloodBodyPartType.FromIndex, index)
    if ok then return part end
    return nil
end

local function cleanVisual(visual)
    if not visual then return end
    safeCall(visual, "removeBlood")

    for index = 0, partCount() - 1 do
        local part = bodyPart(index)
        if part then
            safeCall(visual, "setBlood", part, 0)
            safeCall(visual, "setDirt", part, 0)
        end
        safeCall(visual, "removeHole", index)
        safeCall(visual, "removePatch", index)
    end
end

local function cleanItem(item)
    if not item then return end
    safeCall(item, "setWetness", 0)
    safeCall(item, "setDirtiness", 0)
    safeCall(item, "setBloodLevel", 0)

    local visualOk, visual = safeCall(item, "getVisual")
    if visualOk then cleanVisual(visual) end

    if not item.getBloodClothingType or not item.setBlood or not item.setDirt or
            not BloodClothingType or not BloodClothingType.getCoveredParts then
        return
    end
    local typeOk, clothingType = pcall(item.getBloodClothingType, item)
    if not typeOk or not clothingType then return end
    local partsOk, parts = pcall(BloodClothingType.getCoveredParts, clothingType)
    if not partsOk or not parts or not parts.size or not parts.get then return end
    local countOk, count = pcall(parts.size, parts)
    if not countOk or type(count) ~= "number" then return end

    for index = 0, count - 1 do
        local partOk, part = pcall(parts.get, parts, index)
        if partOk and part then
            safeCall(item, "setBlood", part, 0)
            safeCall(item, "setDirt", part, 0)
        end
    end
end

local function itemSet(records)
    local result = {}
    for _, record in ipairs(records or {}) do
        if record and record.item then result[record.item] = true end
    end
    return result
end

local function cleanRecords(records, protectedItems)
    for _, record in ipairs(records or {}) do
        local item = record and record.item or nil
        if item and not (protectedItems and protectedItems[item]) then
            cleanItem(item)
        end
    end
end

local function cleanVisuals(visuals)
    if not visuals then return end
    if type(visuals) == "table" then
        for _, visual in ipairs(visuals) do
            cleanVisual(visual)
        end
        return
    end
    if visuals.size and visuals.get then
        local ok, count = pcall(visuals.size, visuals)
        if not ok or type(count) ~= "number" then return end
        for index = 0, count - 1 do
            local visualOk, visual = pcall(visuals.get, visuals, index)
            if visualOk then cleanVisual(visual) end
        end
    end
end

local function sanitizeSnapshot(bridge)
    local snapshot = bridge and bridge.snapshot or nil
    if not snapshot then return end

    -- Never change the physical worn or attached items. MirageWardrobe's
    -- render bridge supplies detached snapshot records for these collections.
    cleanRecords(snapshot.wornItems, itemSet(bridge.originalWornItems))
    cleanRecords(snapshot.attachedItems, itemSet(bridge.originalAttachedItems))
    cleanRecords(snapshot.remoteItems, itemSet(bridge.originalWornItems))
    cleanVisuals(snapshot.bodyVisuals)
    cleanVisuals(snapshot.remoteVisuals)
end

local function clearHumanVisual(player)
    if not player or not player.getHumanVisual then return nil end
    local ok, humanVisual = pcall(player.getHumanVisual, player)
    if not ok or not humanVisual then return nil end

    local saved = { visual = humanVisual, parts = {} }
    for index = 0, partCount() - 1 do
        local part = bodyPart(index)
        if part then
            local bloodOk, blood = safeCall(humanVisual, "getBlood", part)
            local dirtOk, dirt = safeCall(humanVisual, "getDirt", part)
            if bloodOk or dirtOk then
                saved.parts[#saved.parts + 1] = {
                    part = part,
                    blood = bloodOk and blood or nil,
                    dirt = dirtOk and dirt or nil,
                }
                if bloodOk then safeCall(humanVisual, "setBlood", part, 0) end
                if dirtOk then safeCall(humanVisual, "setDirt", part, 0) end
            end
        end
    end
    return saved
end

local function restoreHumanVisual(saved)
    if not saved or not saved.visual then return end
    for _, entry in ipairs(saved.parts or {}) do
        if entry.blood ~= nil then
            safeCall(saved.visual, "setBlood", entry.part, entry.blood)
        end
        if entry.dirt ~= nil then
            safeCall(saved.visual, "setDirt", entry.part, entry.dirt)
        end
    end
end

local function cleanPreviewDescriptor(descriptor)
    if not descriptor then return end

    if descriptor.getWornItems then
        local ok, wornItems = pcall(descriptor.getWornItems, descriptor)
        if ok and wornItems and wornItems.size then
            local sizeOk, count = pcall(wornItems.size, wornItems)
            if sizeOk and type(count) == "number" then
                for index = 0, count - 1 do
                    local item = nil
                    if wornItems.getItemByIndex then
                        local itemOk, value = pcall(
                                wornItems.getItemByIndex, wornItems, index)
                        if itemOk then item = value end
                    end
                    if not item and wornItems.get then
                        local entryOk, entry = pcall(wornItems.get, wornItems, index)
                        if entryOk and entry and entry.getItem then
                            local itemOk, value = pcall(entry.getItem, entry)
                            if itemOk then item = value end
                        end
                    end
                    cleanItem(item)
                end
            end
        end
    end

    if descriptor.getHumanVisual then
        local ok, humanVisual = pcall(descriptor.getHumanVisual, descriptor)
        if ok and humanVisual then
            for index = 0, partCount() - 1 do
                local part = bodyPart(index)
                if part then
                    safeCall(humanVisual, "setBlood", part, 0)
                    safeCall(humanVisual, "setDirt", part, 0)
                end
            end
            local bodyOk, bodyVisuals = safeCall(humanVisual, "getBodyVisuals")
            if bodyOk then cleanVisuals(bodyVisuals) end
        end
    end

    if descriptor.getAttachedItems then
        local ok, attached = pcall(descriptor.getAttachedItems, descriptor)
        if ok and attached and attached.size and attached.get then
            local sizeOk, count = pcall(attached.size, attached)
            if sizeOk and type(count) == "number" then
                for index = 0, count - 1 do
                    local itemOk, entry = pcall(attached.get, attached, index)
                    if itemOk and entry and entry.getItem then
                        local valueOk, item = pcall(entry.getItem, entry)
                        if valueOk then cleanItem(item) end
                    end
                end
            end
        end
    end
end

local function install()
    local core = MirageWardrobeCore
    if type(core) ~= "table" then return false end
    if core[INSTALLED_KEY] then return true end
    if not core.isCleanAppearanceEnabled or not core.getCleanAppearanceOptions or
            not core.createAppearancePreviewSurvivorDesc or
            not core.captureAppearanceTexturesImpl or
            not core.beginAppearanceRenderBridge or
            not core.endAppearanceRenderBridges then
        return false
    end

    local originalIsClean = core.isCleanAppearanceEnabled
    core.isCleanAppearanceEnabled = function (player)
        if isJill(player) then return true end
        return originalIsClean(player)
    end

    local originalOptions = core.getCleanAppearanceOptions
    core.getCleanAppearanceOptions = function (player, ...)
        local options = originalOptions(player, ...)
        if isJill(player) and type(options) == "table" then
            options.blood = true
            options.holes = true
            options.patches = true
        end
        return options
    end

    local originalPreview = core.createAppearancePreviewSurvivorDesc
    core.createAppearancePreviewSurvivorDesc = function (player, cleanAppearance, state, ...)
        if not isJill(player) then
            return originalPreview(player, cleanAppearance, state, ...)
        end
        local descriptor, warning = originalPreview(player, true, state, ...)
        cleanPreviewDescriptor(descriptor)
        return descriptor, warning
    end

    local originalCapture = core.captureAppearanceTexturesImpl
    core.captureAppearanceTexturesImpl = function (player, desiredClean, requiresModelReset, ...)
        if not isJill(player) then
            return originalCapture(player, desiredClean, requiresModelReset, ...)
        end

        local saved = clearHumanVisual(player)
        local ok, result, reason = pcall(originalCapture, player, true,
                requiresModelReset, ...)
        restoreHumanVisual(saved)
        if not ok then error(result) end
        return result, reason
    end

    local originalBegin = core.beginAppearanceRenderBridge
    core.beginAppearanceRenderBridge = function (player, ...)
        local began, reason = originalBegin(player, ...)
        if began and isJill(player) then
            local bridge = core.appearanceRenderBridges and
                    core.appearanceRenderBridges[player] or nil
            local ok, err = pcall(sanitizeSnapshot, bridge)
            if not ok and not warned then
                warned = true
                print(TAG .. " snapshot sanitization skipped: " .. tostring(err))
            end
        end
        return began, reason
    end

    core[INSTALLED_KEY] = true
    print(TAG .. " MirageWardrobe render adapter installed for Jill Valentine")
    return true
end

if not install() and Events and Events.OnGameStart and Events.OnGameStart.Add then
    Events.OnGameStart.Add(install)
end
