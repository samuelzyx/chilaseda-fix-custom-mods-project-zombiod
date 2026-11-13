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
end

return M
