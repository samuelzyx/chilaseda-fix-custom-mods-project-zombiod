require "ISUI/ISUIElement"

ChilaSeda_AnomalousStorm_Rect = ISUIElement:derive("ChilaSeda_AnomalousStorm_Rect")

function ChilaSeda_AnomalousStorm_Rect:initialise()
	ISUIElement.initialise(self)
	self:backMost()
end

function ChilaSeda_AnomalousStorm_Rect:instantiate()
	self.javaObject = UIElement.new(self)
	self.javaObject:setConsumeMouseEvents(false)
	self.javaObject:setForceCursorVisible(true)
end

function ChilaSeda_AnomalousStorm_Rect:containsPoint()
	return false
end

function ChilaSeda_AnomalousStorm_Rect:containsPointLocal()
	return false
end

function ChilaSeda_AnomalousStorm_Rect:onMouseMove()
	self.mouseOver = false
end

function ChilaSeda_AnomalousStorm_Rect:isMouseOver()
	return false
end

function ChilaSeda_AnomalousStorm_Rect:onMouseDown()
	return false
end

function ChilaSeda_AnomalousStorm_Rect:onMouseUp()
	return false
end

function ChilaSeda_AnomalousStorm_Rect:onRightMouseDown()
	return false
end

function ChilaSeda_AnomalousStorm_Rect:onRightMouseUp()
	return false
end

function ChilaSeda_AnomalousStorm_Rect:prerender()
	local core = getCore()
	local width = core:getScreenWidth()
	local height = core:getScreenHeight()
	if self.width ~= width then self:setWidth(width) end
	if self.height ~= height then self:setHeight(height) end
	self:drawRect(0, 0, self.width, self.height, self.a, self.r, self.g, self.b)
end

function ChilaSeda_AnomalousStorm_Rect:setAlpha(alpha)
	self.a = alpha
	if self.a <= 0 then
		ChilaSeda_AnomalousStorm_Rect.instance = nil
		self:removeFromUIManager()
	end
end

function ChilaSeda_AnomalousStorm_Rect:new(alpha, red, green, blue)
	local core = getCore()
	local object = ISUIElement.new(self, 0, 0, core:getScreenWidth(), core:getScreenHeight())
	setmetatable(object, self)
	self.__index = self
	object.mouseOver = false
	object.a = alpha
	object.r = red
	object.g = green
	object.b = blue
	ChilaSeda_AnomalousStorm_Rect.instance = object
	return object
end
