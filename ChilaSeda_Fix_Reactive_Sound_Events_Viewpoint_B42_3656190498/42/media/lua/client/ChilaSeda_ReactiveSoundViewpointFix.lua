require "ReactiveSE/ReactiveSE_SoundMarker"
local MarkerHandler = require "ReactiveSE/ReactiveSE_MarkerHandler"

local Marker = ReactiveSE_SoundMarker
local originalSetAngleFromPoint = Marker and Marker.setAngleFromPoint
if not originalSetAngleFromPoint then return end

local function getViewpointAngle()
    -- ReactiveSE calls this from update() and render(), which may run off the
    -- main thread. Read Viewpoint's published render-frame snapshot through
    -- the Java bridge; never call VisualSoundsViewpoint.active/yaw here.
    local bridge = ChilaSedaVisualSoundsViewpointBridge
    if not bridge or type(bridge.angle) ~= "function" then return nil end

    local ok, angle = pcall(bridge.angle)
    if not ok or type(angle) ~= "number" or angle ~= angle then return nil end
    return angle
end

function Marker:setAngleFromPoint()
    if not self.posX or not self.posY or not self.player then return end

    local viewAngle = getViewpointAngle()
    if viewAngle == nil then
        return originalSetAngleFromPoint(self)
    end

    local dx = self.posX - self.player:getX()
    local dy = self.posY - self.player:getY()
    local radians = math.atan2(dy, dx) + math.pi + viewAngle

    -- The test marker showed Viewpoint's arrow pointing exactly opposite its target.
    -- Rotate its current calibrated result by 180 degrees; yaw tracking remains intact.
    local calibratedAngle = math.deg(radians) + 180
    self.angle = (calibratedAngle + 180) % 360
end
