require "TimedActions/ISEatFoodAction"
require "ISUI/ISModalDialog"
local confirmationKeys = require "ChilaSeda_ConfirmationDialogKeys_B42"

if ChilaSedaKnownPoisonEatingConfirmInstalled then return end
if not ISTimedActionQueue or type(ISTimedActionQueue.add) ~= "function" then
    print("[ChilaSeda_PoisonEatConfirm] Timed action queue is unavailable; patch skipped.")
    return
end

local originalQueueAdd = ISTimedActionQueue.add

local function onPoisonConfirmation(target, button, payload)
    if not button or button.internal ~= "YES" or not payload or not payload.action then return end
    local action = payload.action
    action.ChilaSedaKnownPoisonConfirmed = true
    return originalQueueAdd(action, unpack(payload.args, 1, payload.args.n))
end

ISTimedActionQueue.add = function(action, ...)
    if action and not action.ChilaSedaKnownPoisonConfirmed
            and instanceof(action, "ISEatFoodAction")
            and action.item and action.character
            and action.character:isKnownPoison(action.item) then
        local playerNum = action.character:getPlayerNum()
        local payload = { action = action, args = { n = select("#", ...), ... } }
        local text = getText("UI_ChilaSeda_ConfirmKnownPoisonEat", action.item:getName())
        local modal = ISModalDialog:new(0, 0, 420, 150, text, true,
            nil, onPoisonConfirmation, playerNum, payload)
        modal:initialise()
        confirmationKeys.attach(modal)
        modal:addToUIManager()
        modal:setAlwaysOnTop(true)
        modal:bringToTop()
        return nil
    end
    return originalQueueAdd(action, ...)
end

ChilaSedaKnownPoisonEatingConfirmInstalled = true
print("[ChilaSeda_PoisonEatConfirm] Known-poison eating confirmation enabled.")
