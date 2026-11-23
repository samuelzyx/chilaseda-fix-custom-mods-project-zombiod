local LOG_TAG = "[ChilaSeda_ExpandedBeltCompat_B42]"
local ITEM_TYPE = "ExpandedBelt.ExpandedBelt"

local function verifyExpandedBelt()
    local ok, result = pcall(function()
        local scriptItem = ScriptManager.instance:FindItem(ITEM_TYPE)
        if not scriptItem then
            return "result=fallback reason=missing-item item=" .. ITEM_TYPE
        end

        local requiredTags = {
            { name = "base:hasmetal", tag = ItemTag.HAS_METAL },
            { name = "base:buckle", tag = ItemTag.BUCKLE },
            { name = "base:scrapasbelt", tag = ItemTag.SCRAP_AS_BELT },
        }
        local present = {}
        local missing = {}
        for _, entry in ipairs(requiredTags) do
            if scriptItem:hasTag(entry.tag) then
                table.insert(present, entry.name)
            else
                table.insert(missing, entry.name)
            end
        end

        local recipes = scriptItem:getResearchableRecipes()
        local forgeBuckle = false
        if recipes then
            for i = 0, recipes:size() - 1 do
                if recipes:get(i) == "Forge_Buckle" then
                    forgeBuckle = true
                    break
                end
            end
        end

        if #missing == 0 and forgeBuckle then
            return "result=ready item=" .. ITEM_TYPE
                .. " tags=" .. table.concat(present, ",")
                .. " forgeBuckle=true"
        end

        return "result=fallback item=" .. ITEM_TYPE
            .. " missingTags=" .. table.concat(missing, ",")
            .. " forgeBuckle=" .. tostring(forgeBuckle)
    end)

    if ok then
        print(LOG_TAG .. " " .. result)
    else
        print(LOG_TAG .. " result=fallback reason=check-error detail=" .. tostring(result))
    end
end

if Events and Events.OnGameBoot then
    Events.OnGameBoot.Add(verifyExpandedBelt)
else
    print(LOG_TAG .. " result=fallback reason=OnGameBoot-unavailable")
end
