-- ViewpointUI's registry is an optional extra. Keep the Viewpoint core action
-- cleanup available when only Viewpoint itself is installed.
pcall(require, "ViewpointUI/Interaction/Registry")

local function normalizeLabel(value)
    if type(value) ~= "string" then return "" end
    value = string.gsub(value, "<[bB][rR]%s*/?>", " ")
    value = string.gsub(value, "[%c]+", " ")
    value = string.gsub(value, "%s+", " ")
    return string.lower(string.gsub(value, "^%s*(.-)%s*$", "%1"))
end

local function spanishGlassLabel(value)
    local label = normalizeLabel(value)
    local glass = string.find(label, "broken glass", 1, true)
        or string.find(label, "vidrio roto", 1, true)
        or string.find(label, "cristales rotos", 1, true)
        or string.find(label, "vidrios rotos", 1, true)
    if not glass then return nil end

    if string.find(label, "remove", 1, true) or string.find(label, "quitar", 1, true) then
        return "Quitar cristales rotos", "remove"
    end
    if string.find(label, "pick up", 1, true) or string.find(label, "pickup", 1, true)
        or string.find(label, "take", 1, true) or string.find(label, "recoger", 1, true)
        or string.find(label, "juntar", 1, true) then
        return "Juntar cristales rotos", "pickup"
    end
    return nil
end

local function isFunctionalGlassPickup(action)
    local callback = action and action.fn
    if callback == ISContextMenu.onGetUpAndThen then
        callback = action.args and action.args[2]
    end
    return callback ~= nil
        and ISWorldObjectContextMenu
        and callback == ISWorldObjectContextMenu.onPickupBrokenGlass
end

local function filterViewpointActions(result)
    local source = ViewpointInteract and ViewpointInteract.actions
    if type(source) ~= "table" or type(result.labels) ~= "table" then return end

    local preferredPickup
    local preferredDismantle
    local preferredPriority = 0
    for i, action in ipairs(source) do
        local _, kind = spanishGlassLabel(action.name)
        local normalized = normalizeLabel(action.name)
        local genericPickup = normalized == "juntar" or normalized == "pick up" or normalized == "pickup"
        local functionalPickup = isFunctionalGlassPickup(action)
        if kind == "pickup" or genericPickup or functionalPickup then
            local priority = functionalPickup and 3
                or (string.find(normalized, "juntar", 1, true)
                    or string.find(normalized, "gather", 1, true)) and 2 or 1
            if priority > preferredPriority then
                preferredPickup = action
                preferredPriority = priority
            end
        end
        local disassembleLabel = getText and getText("ContextMenu_Disassemble")
        if type(action.name) == "string" and type(disassembleLabel) == "string"
            and disassembleLabel ~= "" and action.name:sub(1, #disassembleLabel) == disassembleLabel
            and result.enabled and result.enabled[i] == true then
            preferredDismantle = action
        end
    end

    local primary, rest, seen = {}, {}, {}
    for i, action in ipairs(source) do
        local localized, kind = spanishGlassLabel(action.name)
        local normalized = normalizeLabel(action.name)
        local genericPickup = normalized == "juntar" or normalized == "pick up" or normalized == "pickup"
        local functionalPickup = isFunctionalGlassPickup(action)
        local pickupCandidate = kind == "pickup" or genericPickup or functionalPickup
        local duplicate = kind and seen[kind]
        if pickupCandidate then duplicate = action ~= preferredPickup end
        if not duplicate then
            if action == preferredPickup then
                action.name = "Juntar cristales rotos"
                action.first = true
                seen.pickup = true
            elseif action == preferredDismantle then
                action.first = true
            elseif localized then
                action.name = localized
                action.first = true
                seen[kind] = true
            end
            local entry = { action = action, enabled = result.enabled and result.enabled[i] }
            if action == preferredPickup or action == preferredDismantle then
                table.insert(primary, 1, entry)
            else
                table.insert(action.first and primary or rest, entry)
            end
        end
    end
    local actions, labels, enabled = {}, {}, {}
    for _, group in ipairs({ primary, rest }) do
        for _, entry in ipairs(group) do
            actions[#actions + 1] = entry.action
            labels[#labels + 1] = entry.action.name
            enabled[#enabled + 1] = entry.enabled
        end
    end
    ViewpointInteract.actions = actions
    result.labels = labels
    result.enabled = enabled
end

local function installViewpointActionFilter()
    local view = ViewpointInteract
    if not view or type(view.harvest) ~= "function" or view.chilaGlassLabelsInstalled then return end
    local original = view.harvest
    view.harvest = function(...)
        local result = original(...)
        if type(result) == "table" then filterViewpointActions(result) end
        return result
    end
    view.chilaGlassLabelsInstalled = true
end

local function installViewpointUIDedup()
    local registry = ViewpointUI and ViewpointUI.Interaction and ViewpointUI.Interaction.Registry
    if not registry or type(registry.resolve) ~= "function" or registry.chilaBrokenGlassInstalled then return end

    local original = registry.resolve
    registry.resolve = function(target, player)
        local result = original(target, player)
        local nativeLabels = {}
        local preferredGlassPickup
        local preferredGlassPriority = 0
        for _, action in ipairs(result.actions or {}) do
            if action.provider == "viewpoint.context" then
                local localized = spanishGlassLabel(action.label)
                if localized then action.label = localized end
                local _, kind = spanishGlassLabel(action.label)
                if kind == "remove" then nativeLabels[normalizeLabel(action.label)] = true end
            end
            local _, kind = spanishGlassLabel(action.label)
            if kind == "pickup" then
                local normalized = normalizeLabel(action.label)
                local priority = isFunctionalGlassPickup(action) and 3
                    or (string.find(normalized, "juntar", 1, true)
                        or string.find(normalized, "gather", 1, true)) and 2 or 1
                if priority > preferredGlassPriority then
                    preferredGlassPickup = action
                    preferredGlassPriority = priority
                end
            end
        end

        for i = #(result.actions or {}), 1, -1 do
            local action = result.actions[i]
            if action.id == "vpuix.door:jiggle" then
                action.label = "Forcejear con la cerradura"
            elseif action.id == "vpuix.corpse:all" then
                local count = type(action.label) == "string" and string.match(action.label, "(%d+)")
                action.label = count and ("Revisar todos los cadáveres aquí (" .. count .. ")")
                    or "Revisar todos los cadáveres aquí"
            end
            local _, kind = spanishGlassLabel(action.label)
            if action.id == "vpuix.window:glass" and kind == "remove"
                and nativeLabels[normalizeLabel(action.label)] then
                table.remove(result.actions, i)
            elseif kind == "pickup" and preferredGlassPickup and action ~= preferredGlassPickup then
                table.remove(result.actions, i)
            end
        end

        if preferredGlassPickup then
            preferredGlassPickup.label = "Juntar cristales rotos"
            preferredGlassPickup.primary = true
            for _, action in ipairs(result.actions or {}) do
                if action ~= preferredGlassPickup then action.primary = false end
            end
        end

        result.primary = nil
        result.blocked = nil
        for _, action in ipairs(result.actions or {}) do
            if action.primary and action.enabled then result.primary = action; break end
        end
        if not result.primary then
            local only, count = nil, 0
            for _, action in ipairs(result.actions or {}) do
                if action.enabled then only = action; count = count + 1 end
            end
            if count == 1 then result.primary = only end
        end
        if not result.primary then
            for _, action in ipairs(result.actions or {}) do
                if action.primary then result.blocked = action; break end
            end
        end
        return result
    end
    registry.chilaBrokenGlassInstalled = true
end

Events.OnGameStart.Add(function()
    installViewpointActionFilter()
    installViewpointUIDedup()
    print("[ChilaSeda_ViewpointGlassMenu] installed without requiring Isometric No More")
end)
