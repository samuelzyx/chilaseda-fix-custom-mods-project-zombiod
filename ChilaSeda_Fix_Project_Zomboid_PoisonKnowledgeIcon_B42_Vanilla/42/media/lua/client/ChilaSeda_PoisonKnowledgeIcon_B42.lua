require "ISUI/ISInventoryPane"
require "ISUI/ISInventoryItem"
require "ISUI/ISToolTipInv"
require "Foraging/ISBaseIcon"
require "Foraging/ISWorldItemIcon"

local originalRenderDetails = ISInventoryPane.renderdetails
local originalRenderItemIcon = ISInventoryItem.renderItemIcon

if type(originalRenderDetails) == "function"
    and type(originalRenderItemIcon) == "function"
    and not ISInventoryPane._ChilaSedaPoisonKnowledgeIconInstalled then

    local activePane = nil
    local activePlayer = nil
    local activeIcons = nil

    local function isHerbalistIdentifiedPoison(player, item)
        if not player or not item or not instanceof(item, "Food") then
            return false
        end

        local herbalistType = item:getHerbalistType()
        if herbalistType ~= "Berry" and herbalistType ~= "Mushroom" then
            return false
        end

        if not player:isRecipeActuallyKnown("Herbalist") then
            return false
        end

        return item:getPoisonPower() > 0
    end

    local function poisonousLabel(item)
        if not item or not instanceof(item, "Food") then return nil end
        local herbalistType = item:getHerbalistType()
        if herbalistType == "Mushroom" then
            return getText("IGUI_PoisonousMushroom")
        end
        if herbalistType == "Berry" then
            return getText("IGUI_PoisonousBerry")
        end
        return nil
    end

    local function eachItem(collection, callback)
        if type(collection) == "table" then
            for _, item in pairs(collection) do
                if callback(item) == false then return false end
            end
            return true
        end
        if collection then
            local ok, size = pcall(function() return collection:size() end)
            if ok and type(size) == "number" then
                for index = 0, size - 1 do
                    local got, item = pcall(function() return collection:get(index) end)
                    if got and callback(item) == false then return false end
                end
            end
        end
        return true
    end

    local function collectionHasHerbalistPoison(player, collection)
        local found = false
        eachItem(collection, function(item)
            if isHerbalistIdentifiedPoison(player, item) then
                found = true
                return false
            end
            return true
        end)
        return found
    end

    -- B42 uses Herbalist knowledge for berry/mushroom names, but its inventory
    -- tooltip can retain a generic item name. Temporarily expose the same
    -- vanilla poisonous name while the tooltip is rendered, then restore it.
    local originalTooltipRender = ISToolTipInv.render
    if type(originalTooltipRender) == "function"
            and not ISToolTipInv._ChilaSedaPoisonNameTooltipInstalled then
        ISToolTipInv.render = function(self, ...)
            local item = self and self.item
            local player = getPlayer()
            if self and self.tooltip and self.tooltip.getCharacter then
                local ok, character = pcall(self.tooltip.getCharacter, self.tooltip)
                if ok and character then player = character end
            end
            local oldName
            local label = isHerbalistIdentifiedPoison(player, item)
                    and poisonousLabel(item) or nil
            if label and type(item.setName) == "function" then
                oldName = item:getDisplayName()
                if oldName ~= label then item:setName(label) else oldName = nil end
            end

            local ok, result = pcall(originalTooltipRender, self, ...)
            if oldName then pcall(item.setName, item, oldName) end
            if not ok then error(result, 0) end
            return result
        end
        ISToolTipInv._ChilaSedaPoisonNameTooltipInstalled = true
    end

    -- Search pins also use isKnownPoison(), which does not follow the
    -- Herbalist naming rule used by the inventory. Keep the pin skull in sync.
    local originalBaseCheckForPoison = ISBaseIcon.checkForPoison
    if type(originalBaseCheckForPoison) == "function"
            and not ISBaseIcon._ChilaSedaHerbalistPoisonInstalled then
        ISBaseIcon.checkForPoison = function(self, ...)
            local result = originalBaseCheckForPoison(self, ...)
            if not self.isKnownPoison and not self.isTrack
                    and collectionHasHerbalistPoison(self.character, self.itemList) then
                self.isKnownPoison = true
            end
            return result
        end
        ISBaseIcon._ChilaSedaHerbalistPoisonInstalled = true
    end

    local originalWorldCheckForPoison = ISWorldItemIcon.checkForPoison
    if type(originalWorldCheckForPoison) == "function"
            and not ISWorldItemIcon._ChilaSedaHerbalistPoisonInstalled then
        ISWorldItemIcon.checkForPoison = function(self, ...)
            local result = originalWorldCheckForPoison(self, ...)
            if not self.isKnownPoison then
                if isHerbalistIdentifiedPoison(self.character, self.itemObj)
                        or collectionHasHerbalistPoison(self.character, self.itemObjTable) then
                    self.isKnownPoison = true
                end
            end
            return result
        end
        ISWorldItemIcon._ChilaSedaHerbalistPoisonInstalled = true
    end

    -- Use the same poisonous name in forage right-click entries as in the
    -- inventory; restore the temporary item name immediately after building it.
    local originalBaseContextMenu = ISBaseIcon.doContextMenu
    if type(originalBaseContextMenu) == "function"
            and not ISBaseIcon._ChilaSedaHerbalistPoisonNameInstalled then
        ISBaseIcon.doContextMenu = function(self, ...)
            local item = self.itemObj
            if not item and self.itemList and self.itemList.size
                    and self.itemList:size() > 0 then
                item = self.itemList:get(0)
            end
            local oldName
            local player = self.character
            local label = isHerbalistIdentifiedPoison(player, item)
                    and poisonousLabel(item) or nil
            if label and type(item.setName) == "function" then
                oldName = item:getDisplayName()
                if oldName ~= label then item:setName(label) else oldName = nil end
            end
            local ok, result = pcall(originalBaseContextMenu, self, ...)
            if oldName then pcall(item.setName, item, oldName) end
            if not ok then error(result, 0) end
            return result
        end
        ISBaseIcon._ChilaSedaHerbalistPoisonNameInstalled = true
    end

    ISInventoryItem.renderItemIcon = function(pane, item, x, y, ...)
        local result = originalRenderItemIcon(pane, item, x, y, ...)

        if activePane == pane
            and activeIcons
            and isHerbalistIdentifiedPoison(activePlayer, item)
            and not activePlayer:isKnownPoison(item) then
            activeIcons[#activeIcons + 1] = { x = x, y = y }
        end

        return result
    end

    local function renderWithPoisonOverlay(self, doDragged)
        local previousPane = activePane
        local previousPlayer = activePlayer
        local previousIcons = activeIcons
        local icons = self._ChilaSedaPoisonKnowledgeIcons or {}
        table.wipe(icons)

        activePane = self
        activePlayer = getSpecificPlayer(self.player)
        activeIcons = icons

        local ok, result = pcall(originalRenderDetails, self, doDragged)

        activePane = previousPane
        activePlayer = previousPlayer
        activeIcons = previousIcons

        if not ok then
            error(result, 0)
        end

        self._ChilaSedaPoisonKnowledgeIcons = icons
        if self.poisonIcon then
            local texWH = math.min(self.itemHgt - 2, 32)
            local auxDXY = self.itemHgt - (self.itemHgt - texWH) / 2 - 13
            for i = 1, #icons do
                local icon = icons[i]
                self:drawTexture(
                    self.poisonIcon,
                    icon.x + auxDXY,
                    icon.y + auxDXY - 1,
                    1, 1, 1, 1
                )
            end
        end

        return result
    end

    ISInventoryPane.renderdetails = function(self, doDragged)
        return renderWithPoisonOverlay(self, doDragged)
    end

    ISInventoryPane._ChilaSedaPoisonKnowledgeIconInstalled = true
    print("[ChilaSeda Poison Knowledge Icon] Herbalist tooltip, inventory icon, and forage marker fix loaded")
end
