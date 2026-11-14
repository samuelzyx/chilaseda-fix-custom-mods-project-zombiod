local M = {}

local function setButtonTitle(button, text)
    if button and type(button.setTitle) == "function" then
        button:setTitle(text)
    end
end

function M.attach(modal)
    if not modal or not modal.yes or not modal.no then
        return false
    end
    if modal.ChilaSedaConfirmationKeysInstalled then
        return true
    end

    setButtonTitle(modal.yes, getText("UI_Yes") .. " [E]")
    setButtonTitle(modal.no, getText("UI_No") .. " [Esc]")

    local inheritedOnKeyPress = modal.onKeyPress
    modal.onKeyPress = function(self, key)
        if not self.getIsVisible or self:getIsVisible() then
            if key == Keyboard.KEY_E then
                self:onClick(self.yes)
                return true
            end
            if key == Keyboard.KEY_ESCAPE then
                self:onClick(self.no)
                return true
            end
        end
        if type(inheritedOnKeyPress) == "function" then
            return inheritedOnKeyPress(self, key)
        end
        return false
    end

    if type(modal.setCapture) == "function" then
        modal:setCapture(true)
    end
    if type(modal.setWantKeyEvents) == "function" then
        modal:setWantKeyEvents(true)
    end
    modal.ChilaSedaConfirmationKeysInstalled = true
    return true
end

return M
