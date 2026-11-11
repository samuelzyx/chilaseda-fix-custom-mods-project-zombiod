-- Show the vehicle battery's remaining charge above RetroDashboard's original
-- battery warning icon. Keep the Workshop layer, texture, and warning logic intact.

require "RetroDashboard/Dashboard"

local battery = RetroDashboard.Coords
    and RetroDashboard.Coords.buttons
    and RetroDashboard.Coords.buttons.battery

if type(battery) ~= "table" then
    print("[ChilaSeda_RetroDashboardChargeIndicator] battery coordinates unavailable; patch not installed")
    return
end

local render = ISVehicleDashboard and ISVehicleDashboard.render
if type(render) ~= "function" then
    print("[ChilaSeda_RetroDashboardChargeIndicator] dashboard render unavailable; patch not installed")
    return
end

local function batteryCharge(vehicle)
    if not vehicle then return nil end

    local ok, charge = pcall(function()
        local part = vehicle:getPartById("Battery")
        local item = part and part:getInventoryItem()
        if item then return item:getCurrentUsesFloat() end
        return vehicle:getBatteryCharge()
    end)
    if not ok or type(charge) ~= "number" then
        ok, charge = pcall(function() return vehicle:getBatteryCharge() end)
    end
    if not ok or type(charge) ~= "number" then return nil end

    return math.max(0, math.min(1, charge))
end

function ISVehicleDashboard:render(...)
    render(self, ...)

    local charge = batteryCharge(self.vehicle)
    if charge == nil then return end

    local percent = math.floor(charge * 100 + 0.5)
    local label = tostring(percent) .. "%"
    local red, green, blue
    if percent <= 20 then
        red, green, blue = 1.0, 0.20, 0.16
    elseif percent <= 50 then
        red, green, blue = 1.0, 0.72, 0.12
    else
        red, green, blue = 0.25, 1.0, 0.38
    end

    local scale = RetroDashboard.scale or 1.0
    local font = UIFont.Small
    local textWidth = getTextManager():MeasureStringX(font, label)
    local centerX = (battery.x + battery.w / 2) * scale
    local textY = (battery.y - 17) * scale
    local textX = centerX - textWidth / 2

    -- A subtle dark outline keeps the small value legible over either dashboard.
    self:drawText(label, textX - 1, textY, 0, 0, 0, 1, font)
    self:drawText(label, textX + 1, textY, 0, 0, 0, 1, font)
    self:drawText(label, textX, textY - 1, 0, 0, 0, 1, font)
    self:drawText(label, textX, textY + 1, 0, 0, 0, 1, font)
    self:drawText(label, textX, textY, red, green, blue, 1, font)
end

print("[ChilaSeda_RetroDashboardChargeIndicator] installed; charge percentage appears above the original battery icon")
