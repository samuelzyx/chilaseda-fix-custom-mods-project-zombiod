local modelLoaded = pcall(require, "ViewpointUI/Inventory/Model")
local filterLoaded = pcall(require, "ViewpointUI/Inventory/Filter")
local quickLootLoaded = pcall(require, "ViewpointUI/Interaction/QuickLoot")
local tabLoaded = pcall(require, "ViewpointUI/Screens/InventoryTab")
if not modelLoaded or not filterLoaded or not quickLootLoaded or not tabLoaded then
    print("[ChilaSeda_ViewpointCorpseLoot] Viewpoint UI unavailable; patch skipped.")
    return
end

local VPUI = ViewpointUI
local Model = VPUI and VPUI.Inventory and VPUI.Inventory.Model
local Filter = VPUI and VPUI.Inventory and VPUI.Inventory.Filter
local QuickLoot = VPUI and VPUI.Interaction and VPUI.Interaction.QuickLoot
local Tab = VPUI and VPUI.Screens and VPUI.Screens.Inventory

local function itemFingerprint(container)
    local ok, value = pcall(function()
        local items = container:getItems()
        local parts = { tostring(items:size()) }
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            local id = ""
            if item.getID then
                local idOk, itemId = pcall(item.getID, item)
                if idOk then id = tostring(itemId) end
            end
            parts[#parts + 1] = table.concat({
                id,
                item:getFullType() or "",
                item:getName() or "",
                tostring(item:isHidden()),
            }, "\31")
        end
        return table.concat(parts, "\30")
    end)
    return ok and value or tostring(container)
end

local function combatClothingPriority(group)
    local item = group and group.first
    if not item then return 1 end
    local okWeapon, weapon = pcall(instanceof, item, "HandWeapon")
    local okCategory, category = pcall(function() return item:getDisplayCategory() end)
    category = okCategory and tostring(category or "") or ""
    if (okWeapon and weapon) or string.find(category, "Weapon", 1, true) then return 0 end
    local okClothing, clothing = pcall(instanceof, item, "Clothing")
    local okContainer, isContainer = pcall(instanceof, item, "InventoryContainer")
    if okClothing and clothing and not (okContainer and isContainer) then return 2 end
    if string.find(category, "Clothing", 1, true) then return 2 end
    return 1
end

local function stablePriorityPartition(groups)
    local originalPosition = {}
    for i, group in ipairs(groups) do originalPosition[group] = i end
    table.sort(groups, function(a, b)
        local pa, pb = combatClothingPriority(a), combatClothingPriority(b)
        if pa ~= pb then return pa < pb end
        return originalPosition[a] < originalPosition[b]
    end)
end

if Model and type(Model.groups) == "function" and not Model.ChilaSedaCorpseLootOrder then
    local originalGroups = Model.groups
    Model.groups = function(...)
        local groups = originalGroups(...)
        stablePriorityPartition(groups)
        return groups
    end
    Model.ChilaSedaCorpseLootOrder = true
end

if Filter and type(Filter.sort) == "function" and not Filter.ChilaSedaCorpseLootOrder then
    local originalSort = Filter.sort
    Filter.sort = function(groups, ...)
        originalSort(groups, ...)
        stablePriorityPartition(groups)
    end
    Filter.ChilaSedaCorpseLootOrder = true
end

if QuickLoot and type(QuickLoot.tick) == "function" and type(QuickLoot.reset) == "function"
        and not QuickLoot.ChilaSedaContentRefresh then
    local originalTick = QuickLoot.tick
    local previousFingerprint = nil
    local invalidEntriesReported = false
    QuickLoot.tick = function(target, player, resolved, entries, now, ctx)
        local function validEntries(candidate)
            if type(candidate) ~= "table" then return false end
            for _, entry in ipairs(candidate) do
                if type(entry) ~= "table" or entry.container == nil then return false end
            end
            return true
        end

        if not validEntries(entries) then
            local ok, recovered = pcall(QuickLoot.wants, target, player, resolved, now)
            if ok and validEntries(recovered) then
                entries = recovered
            else
                previousFingerprint = nil
                QuickLoot.reset()
                if not invalidEntriesReported then
                    print("[ChilaSeda_ViewpointCorpseLoot] skipped QuickLoot tick with invalid entries; controller remains active")
                    invalidEntriesReported = true
                end
                return
            end
        else
            invalidEntriesReported = false
        end

        local parts = {}
        for _, entry in ipairs(entries) do
            parts[#parts + 1] = tostring(entry.container)
            parts[#parts + 1] = itemFingerprint(entry.container)
        end
        local fingerprint = table.concat(parts, "\29")
        if previousFingerprint ~= nil and previousFingerprint ~= fingerprint then
            QuickLoot.reset()
        end
        previousFingerprint = fingerprint
        return originalTick(target, player, resolved, entries, now, ctx)
    end
    QuickLoot.ChilaSedaContentRefresh = true
end

if Tab and type(Tab.groupsOf) == "function" and not Tab.ChilaSedaContentRefresh then
    local originalGroupsOf = Tab.groupsOf
    local fingerprints = setmetatable({}, { __mode = "k" })
    Tab.groupsOf = function(self, container, player, hideEquipped, equipSig)
        local key = tostring(container) .. (hideEquipped and "|h" or "")
        local fingerprint = itemFingerprint(container)
        fingerprints[self] = fingerprints[self] or {}
        if fingerprints[self][key] ~= fingerprint then
            if self.groupCache then self.groupCache[key] = nil end
            fingerprints[self][key] = fingerprint
        end
        return originalGroupsOf(self, container, player, hideEquipped, equipSig)
    end
    Tab.ChilaSedaContentRefresh = true
end

if Tab and type(Tab.computeSignature) == "function" and not Tab.ChilaSedaContentSignature then
    local originalSignature = Tab.computeSignature
    Tab.computeSignature = function(self, ...)
        local signature = originalSignature(self, ...)
        local parts = { signature }
        for _, entry in ipairs(self.playerEntries or {}) do
            parts[#parts + 1] = itemFingerprint(entry.container)
        end
        for _, entry in ipairs(self.lootEntries or {}) do
            parts[#parts + 1] = itemFingerprint(entry.container)
        end
        return table.concat(parts, "\28")
    end
    Tab.ChilaSedaContentSignature = true
end

print("[ChilaSeda_ViewpointCorpseLoot] content refresh and loot ordering installed")
