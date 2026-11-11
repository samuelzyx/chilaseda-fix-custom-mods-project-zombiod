local advancedThrowablesLoaded = pcall(require, "VAT/VAT_Controller")
require "ViewpointForaging/VPF_Core"
require "ViewpointForaging/VPF_HUD"

local TAG = "[ChilaSeda_ViewpointForagingThrowKeyConflict] "
local VATModule = VAT
local VPF = ViewpointForaging

if not advancedThrowablesLoaded or not VATModule or not VATModule.Controller
        or type(VATModule.Controller.tick) ~= "function" then
    print(TAG .. "Advanced Throwables is unavailable; optional key guard skipped")
    return
end

if not VPF or not VPF.opt then
    print(TAG .. "Viewpoint Foraging is unavailable; no key guard installed")
    return
end

local controller = VATModule.Controller
if controller.ChilaSedaForagingKeyGuardInstalled then return end

local originalTick = controller.tick
local originalPickUp = VPF.pickUp

local function modifierDown(left, right)
    return (left and isKeyDown(left)) or (right and isKeyDown(right)) or false
end

local controlLeft = Keyboard and Keyboard.KEY_LCONTROL
local controlRight = Keyboard and Keyboard.KEY_RCONTROL
local altLeft = Keyboard and Keyboard.KEY_LMENU
local altRight = Keyboard and Keyboard.KEY_RMENU

if type(originalPickUp) == "function" then
    VPF.pickUp = function(icon)
        local controlDown = modifierDown(controlLeft, controlRight)
        local altDown = modifierDown(altLeft, altRight)
        if controlDown and altDown then return end
        return originalPickUp(icon)
    end
end

controller.tick = function(...)
    local originalIsKeyDown = isKeyDown
    local config = VATModule.Config and VATModule.Config.client
    local throwKey = config and config.keyThrow
    local pickKey = VPF.opt and VPF.opt.pickKey
    local sharesForagingKey = throwKey ~= nil and throwKey == pickKey

    if sharesForagingKey then
        isKeyDown = function(key)
            if key == throwKey then
                if not originalIsKeyDown(throwKey) then return false end

                local controlDown = (controlLeft and originalIsKeyDown(controlLeft))
                    or (controlRight and originalIsKeyDown(controlRight))
                local altDown = (altLeft and originalIsKeyDown(altLeft))
                    or (altRight and originalIsKeyDown(altRight))
                if not controlDown or not altDown then return false end
            end
            return originalIsKeyDown(key)
        end
    end

    local ok, result = pcall(originalTick, ...)
    isKeyDown = originalIsKeyDown
    if not ok then error(result) end
    return result
end

controller.ChilaSedaForagingKeyGuardInstalled = true
print(TAG .. "Shared G binding guarded: Ctrl+Alt+G throws; plain G remains for forage pickup")
