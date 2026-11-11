require "ISUI/ISInventoryPaneContextMenu"

ChilaSedaFoodMenuOrder = ChilaSedaFoodMenuOrder or {}
local M = ChilaSedaFoodMenuOrder

local function refresh(context, options)
    for index, entry in ipairs(options) do
        if entry then entry.id = index end
    end
    pcall(function()
        if context.calcHeight then context:calcHeight() end
        if context.calcWidth and context.setWidth then
            context:setWidth(context:calcWidth())
        end
    end)
end

function M.move(context, option)
    local options = context and context.options
    if type(options) ~= "table" or not option then return end
    option.chilaSedaFoodMenuAction = true

    local optionIndex, lastEquipIndex
    local equipLabels = {
        [getText("ContextMenu_Equip_Primary")] = true,
        [getText("ContextMenu_Equip_Secondary")] = true,
        [getText("ContextMenu_Equip_Two_Hands")] = true,
    }

    for index, entry in ipairs(options) do
        if entry == option then optionIndex = index end
        if entry ~= option and equipLabels[entry.name] then lastEquipIndex = index end
    end

    if optionIndex then
        table.remove(options, optionIndex)
        if lastEquipIndex and optionIndex <= lastEquipIndex then
            lastEquipIndex = lastEquipIndex - 1
        end
    end

    local insertAfter = lastEquipIndex or 0
    while options[insertAfter + 1]
        and options[insertAfter + 1].chilaSedaFoodMenuAction do
        insertAfter = insertAfter + 1
    end
    table.insert(options, insertAfter + 1, option)
    refresh(context, options)
end

return M
