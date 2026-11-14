local TAG = "[ChilaSeda_InventoryTetrisContextMenuGuard] "
local GUARD_FLAG = "__ChilaSedaContextMenuGuardInstalled"

local function installGuard()
    local devTool = TetrisDevTool
    if type(devTool) ~= "table" then return false end

    local original = devTool.insertDebugOptions
    if type(original) ~= "function" or devTool[GUARD_FLAG] then return false end

    devTool[GUARD_FLAG] = true
    devTool.insertDebugOptions = function(context, ...)
        local ok, options = pcall(function()
            return context and context.options
        end)
        if not ok or type(options) ~= "table" then return end
        return original(context, ...)
    end

    print(TAG .. "Tetris debug context-menu guard installed")
    return true
end

installGuard()
if Events then
    if Events.OnGameBoot then Events.OnGameBoot.Add(installGuard) end
    if Events.OnGameStart then Events.OnGameStart.Add(installGuard) end
end
