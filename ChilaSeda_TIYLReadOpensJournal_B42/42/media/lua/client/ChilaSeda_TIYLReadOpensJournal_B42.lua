ChilaSedaTIYLReadOpensJournalB42 = ChilaSedaTIYLReadOpensJournalB42 or {}
local M = ChilaSedaTIYLReadOpensJournalB42

local JOURNAL_TYPE = "ThisIsYourLife.PreservedJournal"
local OPEN_LABEL = "UI_TIYL_Journal_OpenJournal"
local READ_LABEL = "ContextMenu_Read"
local REREAD_LABEL = "ContextMenu_ReRead"
local JOURNAL_KEY_BINDING = "Open Survivor Journal"
local NO_KEY = Keyboard and Keyboard.KEY_NONE or 0

local function setJournalKeyDefault()
    for _, binding in ipairs(keyBinding or {}) do
        if binding.value == JOURNAL_KEY_BINDING then
            binding.key = NO_KEY
            binding.alt = NO_KEY
            binding.altKey = false
            binding.shift = false
            binding.ctrl = false
        end
    end
end

setJournalKeyDefault()

local function unbindDefaultJournalKey()
    local core = getCore and getCore()
    if core and core.getKey and core.addKeyBinding
            and core:getKey(JOURNAL_KEY_BINDING) == Keyboard.KEY_K then
        core:addKeyBinding(JOURNAL_KEY_BINDING, NO_KEY, NO_KEY,
            false, false, false)
    end

    local options = rawget(_G, "MainOptions")
    for _, binding in ipairs(options and options.keys or {}) do
        if binding.value == JOURNAL_KEY_BINDING
                and binding.key == Keyboard.KEY_K then
            binding.key = NO_KEY
            binding.altCode = NO_KEY
            binding.shift = false
            binding.ctrl = false
            binding.alt = false
        end
    end
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(unbindDefaultJournalKey)
end

local function selectedJournal(entries)
    if type(entries) ~= "table" then return nil end

    for _, entry in ipairs(entries) do
        local selected = type(entry) == "table" and entry.items or nil
        if type(selected) == "table" then
            for _, item in ipairs(selected) do
                if item and item.getFullType
                        and item:getFullType() == JOURNAL_TYPE then
                    return item
                end
            end
        elseif entry and entry.getFullType
                and entry:getFullType() == JOURNAL_TYPE then
            return entry
        end
    end
end

local function isOwnJournal(player, item)
    local itemData = item and item:getModData()
    if not itemData or itemData.TIYLArchive then return false end

    local playerData = player and player:getModData()
    local life = playerData and playerData.TIYL or {}
    local lifeId = life.journalLifeId
    if lifeId then
        return itemData.TIYLJournalLifeId == lifeId
    end

    return not itemData.TIYLJournalLifeId
        and itemData.TIYLJournalOwner == player:getUsername()
end

local function findOption(context, name)
    if context.getOptionFromName then
        return context:getOptionFromName(name)
    end
    for _, option in ipairs(context.options or {}) do
        if option.name == name then return option end
    end
end

local function moveOptionAfterHandEquip(context, option)
    local options = context and context.options
    if type(options) ~= "table" then return end

    local equipLabels = {
        [getText("ContextMenu_Equip_Primary")] = true,
        [getText("ContextMenu_Equip_Secondary")] = true,
        [getText("ContextMenu_Equip_Two_Hands")] = true,
    }
    local optionIndex, lastEquipIndex
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
    lastEquipIndex = lastEquipIndex or math.min(1, #options)
    table.insert(options, (lastEquipIndex > 0 and lastEquipIndex + 1 or 1), option)
    for index, entry in ipairs(options) do entry.id = index end

    pcall(function()
        if context.calcHeight then context:calcHeight() end
        if context.calcWidth and context.setWidth then context:setWidth(context:calcWidth()) end
    end)
end

local function openLiveJournal(playerIndex)
    local tiyl = rawget(_G, "TIYL")
    local settings = tiyl and tiyl.Settings
    local journalClass = tiyl and tiyl.SurvivorJournal
    if not settings or not settings.survivorJournalEnabled
            or not settings.survivorJournalEnabled() or not journalClass then
        return
    end

    local journal = journalClass.instance
    local justCreated = false
    if not journal then
        journal = journalClass:new(playerIndex)
        journal:initialise()
        journal:addToUIManager()
        journalClass.instance = journal
        justCreated = true
    end

    local showing = justCreated or not journal:getIsVisible()
    if not showing and journal.diaryEditor then
        journal.diaryEditor:unfocus()
        journal.diaryTitleEditor:unfocus()
    end
    journal:setVisible(showing)
    if journal:getIsVisible() then journal:bringToTop() end
end

local function setOpenOption(context, name, playerIndex)
    local option = findOption(context, name)
    if not option then
        if context.addOptionOnTop then
            option = context:addOptionOnTop(name, playerIndex, openLiveJournal)
        else
            option = context:addOption(name, playerIndex, openLiveJournal)
        end
    end
    if not option then return end

    option.target = playerIndex
    option.onSelect = openLiveJournal
    for index = 1, 10 do
        option["param" .. index] = nil
    end
    option.notAvailable = false
    option.toolTip = nil

    local okManager, manager = pcall(getScriptManager)
    if okManager and manager then
        local okBook, book = pcall(manager.FindItem, manager, "Base.Book")
        if okBook and book then
            local okTexture, texture = pcall(book.getNormalTexture, book)
            if okTexture and texture then option.iconTexture = texture end
        end
    end

    -- Keep one option and place it after vanilla hand-equip actions.
    moveOptionAfterHandEquip(context, option)
end

function M.addReadOption(playerIndex, context, entries)
    local tiyl = rawget(_G, "TIYL")
    local settings = tiyl and tiyl.Settings
    if not settings or not settings.survivorJournalEnabled
            or not settings.survivorJournalEnabled() then
        return
    end

    local player = getSpecificPlayer(playerIndex)
    local item = selectedJournal(entries)
    if not player or player:isDead() or not isOwnJournal(player, item) then
        return
    end

    local openName = getText(OPEN_LABEL)
    if context.removeOptionByName then
        context:removeOptionByName(getText(READ_LABEL))
        context:removeOptionByName(getText(REREAD_LABEL))
    end

    setOpenOption(context, openName, playerIndex)
end

Events.OnFillInventoryObjectContextMenu.Add(M.addReadOption)
