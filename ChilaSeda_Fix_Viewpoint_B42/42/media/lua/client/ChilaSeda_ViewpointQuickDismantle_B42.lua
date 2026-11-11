local registryLoaded = pcall(require, "ViewpointUI/Interaction/Registry")
local bridgeLoaded = pcall(require, "ViewpointUI/Bridge")
if not registryLoaded or not bridgeLoaded then
    print("[ChilaSeda_ViewpointQuickDismantle] Viewpoint UI unavailable; patch skipped.")
    return
end

local VPUI = ViewpointUI
local Registry = VPUI and VPUI.Interaction and VPUI.Interaction.Registry
local Bridge = VPUI and VPUI.Bridge
if not Registry or not Bridge or not Bridge.KIND then return end

Registry.arrangers = Registry.arrangers or {}

local function isMoveableTarget(target)
    if not target or (target.kind ~= Bridge.KIND.OBJECT
        and target.kind ~= Bridge.KIND.THING) then
        return false
    end

    local object = target.object
    if not object or not ISMoveableSpriteProps
        or type(ISMoveableSpriteProps.fromObject) ~= "function" then
        return false
    end

    local ok, props = pcall(ISMoveableSpriteProps.fromObject, object)
    return ok and props ~= nil
end

local function runHarvestedDisassembly(action, player)
    local index = tonumber(string.match(tostring(action.id or ""), "^viewpoint.context:(%d+)$"))
    local entry = index and ViewpointInteract and ViewpointInteract.actions
        and ViewpointInteract.actions[index]
    if not entry or entry.enabled ~= true or type(entry.fn) ~= "function"
        or type(entry.args) ~= "table" or type(entry.n) ~= "number" then
        return false
    end

    if entry.menu then ISContextMenu.globalPlayerContext = player:getPlayerNum() end
    entry.fn(unpack(entry.args, 1, entry.n))
    return true
end

table.insert(Registry.arrangers, function(target, result)
    if not isMoveableTarget(target) or not result or not result.actions then return end

    local hasPrimary = false
    for _, action in ipairs(result.actions) do
        if action.enabled and action.primary then
            hasPrimary = true
            break
        end
    end

    local disassembleLabel = getText("ContextMenu_Disassemble")
    if type(disassembleLabel) ~= "string" or disassembleLabel == "" then return end

    -- Route the harvested disassembly through its captured Lua handler even
    -- when another action already owns the primary slot.
    for _, action in ipairs(result.actions) do
        local label = type(action.label) == "string" and action.label or ""
        if action.enabled and action.provider == "viewpoint.context"
            and label:sub(1, #disassembleLabel) == disassembleLabel then
            if not hasPrimary then action.primary = true end
            local selectedAction = action
            selectedAction.run = function(player)
                return runHarvestedDisassembly(selectedAction, player)
            end
            return
        end
    end

    if hasPrimary then return end

    -- Some moveables only expose the Viewpoint furniture-cursor action.
    for _, action in ipairs(result.actions) do
        if action.enabled and action.provider == "vpui.moveable" and action.scrap then
            action.primary = true
            return
        end
    end
end)
