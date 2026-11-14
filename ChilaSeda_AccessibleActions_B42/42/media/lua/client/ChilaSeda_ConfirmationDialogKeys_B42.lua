require "ISUI/ISModalDialog"

local M = {}

local registry = rawget(_G, "ChilaSedaConfirmationDialogKeysState")
if not registry then
    registry = { modals = {} }
    registry.onKeyPressed = function(key)
        local modals = registry.modals
        for index = #modals, 1, -1 do
            local modal = modals[index]
            local visible = modal and (type(modal.getIsVisible) ~= "function" or modal:getIsVisible())
            if not visible then
                table.remove(modals, index)
            elseif key == Keyboard.KEY_E or key == Keyboard.KEY_ESCAPE then
                table.remove(modals, index)
                modal.ChilaSedaConfirmationKeyHandled = true
                if type(modal.onClick) == "function" then
                    modal:onClick(key == Keyboard.KEY_E and modal.yes or modal.no)
                end
                return
            end
        end
    end
    rawset(_G, "ChilaSedaConfirmationDialogKeysState", registry)
    if Events and Events.OnKeyPressed then
        Events.OnKeyPressed.Add(registry.onKeyPressed)
    end
end

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

    setButtonTitle(modal.yes, getText("UI_Yes"))
    setButtonTitle(modal.no, getText("UI_No"))

    local inheritedPrerender = modal.prerender
    modal.prerender = function(self)
        if type(inheritedPrerender) == "function" then inheritedPrerender(self) end
        if self.yes then
            self:drawTextCentre(getText("UI_Yes") .. " [E]",
                self.yes.x + self.yes.width / 2, self.yes.y - 18, 1, 1, 1, 1, UIFont.Small)
        end
        if self.no then
            self:drawTextCentre(getText("UI_No") .. " [Esc]",
                self.no.x + self.no.width / 2, self.no.y - 18, 1, 1, 1, 1, UIFont.Small)
        end
    end

    local inheritedOnClick = modal.onClick
    modal.onClick = function(self, ...)
        for index = #registry.modals, 1, -1 do
            if registry.modals[index] == self then
                table.remove(registry.modals, index)
                break
            end
        end
        if type(inheritedOnClick) == "function" then
            return inheritedOnClick(self, ...)
        end
    end

    registry.modals[#registry.modals + 1] = modal

    if type(modal.setCapture) == "function" then
        modal:setCapture(true)
    end
    if type(modal.setWantKeyEvents) == "function" then modal:setWantKeyEvents(true) end
    modal.ChilaSedaConfirmationKeysInstalled = true
    return true
end

if ISModalDialog and type(ISModalDialog.initialise) == "function"
        and not ISModalDialog.ChilaSedaGlobalConfirmationKeysInstalled then
    local originalInitialise = ISModalDialog.initialise
    ISModalDialog.initialise = function(modal, ...)
        originalInitialise(modal, ...)
        if modal.yesno and not modal.ChilaSedaSkipGlobalConfirmationKeys then
            M.attach(modal)
        end
    end
    ISModalDialog.ChilaSedaGlobalConfirmationKeysInstalled = true
end

return M
