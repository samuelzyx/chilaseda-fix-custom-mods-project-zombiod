local TAG = "[ChilaSeda_TrapBaitMenuFilter] "
local rejected = {
    ["Base.Fat"] = true,
    ["Base.Tallow"] = true,
    ["Base.Lard"] = true,
    ["Base.Salt"] = true,
}
local invalidBaitParameterLogged = false

local function safeBaitFullType(bait)
    if type(bait) ~= "userdata" then
        if not invalidBaitParameterLogged then
            invalidBaitParameterLogged = true
            print(TAG .. "event=invalid-bait-parameter result=ignored paramType=" .. type(bait))
        end
        return nil
    end
    local getter = bait.getFullType
    if type(getter) ~= "function" then
        if not invalidBaitParameterLogged then
            invalidBaitParameterLogged = true
            print(TAG .. "event=invalid-bait-parameter result=ignored paramType=userdata missing=getFullType")
        end
        return nil
    end
    return getter(bait)
end

local function removeUnsupportedFatBaits(context)
    if not context or type(context.options) ~= "table" then return 0 end
    local removed = 0
    local visited = {}
    local function walk(menu)
        if not menu or visited[menu] or type(menu.options) ~= "table" then return end
        visited[menu] = true
        for index = #menu.options, 1, -1 do
            local option = menu.options[index]
            local bait = option and option.param1
            local fullType = safeBaitFullType(bait)
            if option and option.onSelect and option.param2
                    and rejected[fullType] then
                table.remove(menu.options, index)
                menu.numOptions = math.max(1, (menu.numOptions or 1) - 1)
                removed = removed + 1
            elseif option and option.subOption and context.getSubMenu then
                local submenu = context:getSubMenu(option.subOption)
                walk(submenu)
                local addBaitLabel = type(getText) == "function"
                    and getText("ContextMenu_Add_Bait") or "ContextMenu_Add_Bait"
                if option.name == addBaitLabel and submenu
                        and type(submenu.options) == "table" and #submenu.options == 0 then
                    table.remove(menu.options, index)
                    menu.numOptions = math.max(1, (menu.numOptions or 1) - 1)
                end
            end
        end
        if removed > 0 then
            pcall(function() menu:calcHeight(); menu:setWidth(menu:calcWidth()) end)
        end
    end
    walk(context)
    return removed
end

Events.OnFillWorldObjectContextMenu.Add(function(_, context, _, test)
    if test then return end
    local removed = removeUnsupportedFatBaits(context)
    if removed > 0 then
        print(TAG .. "event=filter result=removed count=" .. removed
            .. " types=Base.Fat,Base.Tallow,Base.Lard,Base.Salt")
    end
end)
print(TAG .. "event=installed callback=OnFillWorldObjectContextMenu")
