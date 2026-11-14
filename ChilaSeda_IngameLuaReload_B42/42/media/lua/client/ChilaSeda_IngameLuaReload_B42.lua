require "ISUI/ISModalDialog"

ChilaSedaIngameLuaReload = ChilaSedaIngameLuaReload or {}
local M = ChilaSedaIngameLuaReload
local TAG = "[ChilaSeda_IngameLuaReload_B42] "

local function addConfirmationKeys(modal)
    if not modal.yes or not modal.no then return end

    modal.yes:setTitle(getText("UI_Yes") .. " [E]")
    modal.no:setTitle(getText("UI_No") .. " [Esc]")

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

    modal:setCapture(true)
    modal:setWantKeyEvents(true)
end

local function isSinglePlayerSession()
    if isClient() or isServer() then return false end
    return getSpecificPlayer(0) ~= nil
end

local function onConfirmReload(_, button)
    M.dialog = nil
    if not button or button.internal ~= "YES" then return end
    if not isSinglePlayerSession() then return end

    local core = getCore()
    if not core then return end

    print(TAG .. "confirmed; resetting Lua and continuing the current save")
    setGameSpeed(1)
    core:ResetLua("currentGame", "continueSave")
end

local function askToReload()
    if M.dialog or not isSinglePlayerSession() then return end

    local core = getCore()
    if not core then return end

    local width, height = 430, 150
    local x = (core:getScreenWidth() - width) / 2
    local y = (core:getScreenHeight() - height) / 2
    local message = "Recargar Lua saldra de esta sesion y volvera a cargar el guardado actual. "
        .. "Guarda primero para conservar tus avances. ¿Continuar?"

    M.dialog = ISModalDialog:new(x, y, width, height, message, true, nil, onConfirmReload)
    M.dialog:initialise()
    addConfirmationKeys(M.dialog)
    M.dialog:addToUIManager()
    M.dialog:setAlwaysOnTop(true)
    M.dialog:bringToTop()
end

local function onKeyPressed(key)
    if key ~= Keyboard.KEY_F10 then return end
    if not (Keyboard.isKeyDown(Keyboard.KEY_LCONTROL) or Keyboard.isKeyDown(Keyboard.KEY_RCONTROL)) then return end
    if not (Keyboard.isKeyDown(Keyboard.KEY_LSHIFT) or Keyboard.isKeyDown(Keyboard.KEY_RSHIFT)) then return end
    askToReload()
end

Events.OnKeyPressed.Add(onKeyPressed)
print(TAG .. "loaded; press Ctrl+Shift+F10 in single-player to open the confirmation")
