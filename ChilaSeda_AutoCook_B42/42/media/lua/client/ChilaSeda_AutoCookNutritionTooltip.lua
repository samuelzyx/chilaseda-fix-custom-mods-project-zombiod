require "ISUI/ISToolTipInv"

if ISToolTipInv.ChilaSedaNutritionTooltipInstalled then return end

local originalRender = ISToolTipInv.render

local nutritionRows = {
    { "Tooltip_food_Calories", "getCalories" },
    { "Tooltip_food_Carbs", "getCarbohydrates" },
    { "Tooltip_food_Prots", "getProteins" },
    { "Tooltip_food_Fat", "getLipids" },
}

local function numericValue(value)
    if type(value) == "number" then return value end
    local ok, text = pcall(tostring, value)
    if ok then return tonumber(text) or 0 end
    return 0
end

local nutritionGetters = {
    "getHungChange",
    "getThirstChange",
    "getCalories",
    "getCarbohydrates",
    "getProteins",
    "getLipids",
}

local function foodNumber(item, getterName)
    local getter = item and item[getterName]
    if type(getter) ~= "function" then return 0 end
    local ok, value = pcall(getter, item)
    if ok and type(value) == "number" then return value end
    return 0
end

local function hasNutritionData(item)
    if not item or not instanceof(item, "Food") then return false end

    local scriptItem = item.getScriptItem and item:getScriptItem()
    if scriptItem and scriptItem.isCantEat then
        local ok, cantEat = pcall(scriptItem.isCantEat, scriptItem)
        if ok and cantEat then return false end
    end

    -- B42 classifies animal parts such as ChickenFeather/TurkeyFeather as
    -- Food objects for inventory purposes, even though they carry no edible
    -- nutrition. Only add this block when the item has real food values.
    for _, getterName in ipairs(nutritionGetters) do
        if foodNumber(item, getterName) ~= 0 then return true end
    end
    return false
end

local function tooltipAlreadyShowsNutrition(self)
    local character
    if self.tooltip and self.tooltip.getCharacter then
        local ok, value = pcall(self.tooltip.getCharacter, self.tooltip)
        if ok then character = value end
    end
    if not character and getPlayer then character = getPlayer() end
    if not character or not character.hasTrait or not CharacterTrait then return false end

    local okNutritionist, nutritionist = pcall(character.hasTrait, character,
        CharacterTrait.NUTRITIONIST)
    local okNutritionist2, nutritionist2 = pcall(character.hasTrait, character,
        CharacterTrait.NUTRITIONIST2)
    return (okNutritionist and nutritionist) or (okNutritionist2 and nutritionist2)
end

local function appendNutrition(tooltip, item, startY)
    if not tooltip or not hasNutritionData(item) then return end

    local layout = tooltip:beginLayout()
    if not layout then return end
    layout:setMinLabelWidth(80)
    layout:setMinValueWidth(80)

    local header = layout:addItem()
    -- Use solid white for the custom rows so they stay crisp over the translucent tooltip.
    header:setLabel(getText("Tooltip_food_Nutrition") .. ":", 1, 1, 1, 1)
    for _, row in ipairs(nutritionRows) do
        local getter = item[row[2]]
        if type(getter) == "function" then
            local ok, value = pcall(getter, item)
            if ok and type(value) == "number" then
                local line = layout:addItem()
                line:setLabel(getText(row[1]) .. ":", 1, 1, 1, 1)
                line:setValueRightNoPlus(value)
                -- setValueRightNoPlus chooses its own dim value color; override
                -- the public LayoutItem color fields to match the bright labels.
                line.r1, line.g1, line.b1, line.a1 = 1, 1, 1, 1
            end
        end
    end
    -- Start after vanilla's measured food rows. Starting just below the title
    -- draws over the native hunger and nutrition details.
    local layoutY = numericValue(startY)
    if layoutY <= 0 then
        layoutY = 5 + getTextManager():getFontHeight(tooltip:getFont())
    end
    local endY = layout:render(5, layoutY, tooltip)
    tooltip:setHeight(math.max(numericValue(tooltip:getHeight()), numericValue(endY) + 5))
    tooltip:endLayout(layout)
end

local function renderFoodTooltip(self)
    local mx = getMouseX() + 24
    local my = getMouseY() + 24
    if not self.followMouse then
        mx = self:getX()
        my = self:getY()
        if self.anchorBottomLeft then
            mx = self.anchorBottomLeft.x
            my = self.anchorBottomLeft.y
        end
    end

    self.tooltip:setX(mx)
    self.tooltip:setY(my)
    self.tooltip:setWidth(50)
    self.tooltip:setMeasureOnly(true)
    self.item:DoTooltip(self.tooltip)
    local nativeTooltipHeight = numericValue(self.tooltip:getHeight())
    -- Measure the custom rows too, but do not draw them yet. ISToolTipInv's
    -- background must render before ObjectTooltip text or it tints every row.
    appendNutrition(self.tooltip, self.item, nativeTooltipHeight + 3)

    local core = getCore()
    local maxX = core:getScreenWidth()
    local maxY = core:getScreenHeight()
    local tooltipWidth = numericValue(self.tooltip:getWidth())
    local tooltipHeight = numericValue(self.tooltip:getHeight())
    self.tooltip:setMeasureOnly(false)
    self.tooltip:setX(math.max(0, math.min(mx, maxX - tooltipWidth - 1)))
    if not self.followMouse and self.anchorBottomLeft then
        self.tooltip:setY(math.max(0, math.min(my - tooltipHeight, maxY - tooltipHeight - 1)))
    else
        self.tooltip:setY(math.max(0, math.min(my, maxY - tooltipHeight - 1)))
    end

    if self.contextMenu and self.contextMenu.joyfocus then
        local playerNum = self.contextMenu.player
        self.tooltip:setX(getPlayerScreenLeft(playerNum) + 60)
        self.tooltip:setY(getPlayerScreenTop(playerNum) + 60)
    end

    self:setX(self.tooltip:getX())
    self:setY(self.tooltip:getY())
    self:setWidth(tooltipWidth)
    self:setHeight(tooltipHeight)
    if self.contextMenu and not self.contextMenu.joyfocus
            and self.contextMenu.currentOptionRect then
        if self.contextMenu.currentOptionRect.height > 32 then
            self:setY(my + self.contextMenu.currentOptionRect.height)
        end
        self:adjustPositionToAvoidOverlap(self.contextMenu.currentOptionRect)
    end

    if self.followMouse and self.contextMenu == nil then
        self:adjustPositionToAvoidOverlap({
            x = mx - 48, y = my - 48, width = 48, height = 48,
        })
    end

    self:drawRect(0, 0, self.width, self.height,
        self.backgroundColor.a, self.backgroundColor.r,
        self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height,
        self.borderColor.a, self.borderColor.r,
        self.borderColor.g, self.borderColor.b)

    -- Vanilla ISToolTipInv draws its background before DoTooltip. Match that
    -- order, then append the custom rows in the same final text pass.
    self.item:DoTooltip(self.tooltip)
    appendNutrition(self.tooltip, self.item, nativeTooltipHeight + 3)
end

ISToolTipInv.render = function(self)
    if self and self.item and self.tooltip and hasNutritionData(self.item)
            and not tooltipAlreadyShowsNutrition(self)
            and (not ISContextMenu.instance or not ISContextMenu.instance.visibleCheck) then
        local ok, rendered = pcall(renderFoodTooltip, self)
        if ok then return rendered end
    end
    if type(originalRender) == "function" then return originalRender(self) end
end

ISToolTipInv.ChilaSedaNutritionTooltipInstalled = true
print("[ChilaSeda_AutoCookNutritionTooltip] Food calories and macros shown in item tooltips")
