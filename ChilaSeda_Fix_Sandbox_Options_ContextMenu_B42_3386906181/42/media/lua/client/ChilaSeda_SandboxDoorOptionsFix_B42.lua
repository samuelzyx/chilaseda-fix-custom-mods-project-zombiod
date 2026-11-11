-- Remove the B42 Sandbox Options entry from world-object context menus.
local SANDBOX_OPTION_NAME = "ContextMenu_SandboxOptions"

local function removeSandboxOptionFromWorldContext(_, context)
    if not context or type(context.removeOptionByName) ~= "function" then return end
    context:removeOptionByName(getText(SANDBOX_OPTION_NAME))
    if context.calcWidth and context.setWidth then
        context:setWidth(context:calcWidth())
    end
end

Events.OnFillWorldObjectContextMenu.Add(removeSandboxOptionFromWorldContext)
