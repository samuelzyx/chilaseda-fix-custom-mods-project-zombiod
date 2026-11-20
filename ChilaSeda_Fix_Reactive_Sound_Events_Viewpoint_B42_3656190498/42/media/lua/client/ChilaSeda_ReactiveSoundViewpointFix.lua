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

local testDirections = {
    { name = "Norte", dx = 0, dy = -12 },
    { name = "Este", dx = 12, dy = 0 },
    { name = "Sur", dx = 0, dy = 12 },
    { name = "Oeste", dx = -12, dy = 0 },
}
local testDirectionIndex = 0

local function cycleTestMarker()
    local player = getSpecificPlayer(0)
    if not player then return end

    if testDirectionIndex >= #testDirections then
        MarkerHandler.HideMarker(0)
        testDirectionIndex = 0
        print("[ChilaSeda_ReactiveSoundViewpointFix] Test marker hidden")
        return
    end

    testDirectionIndex = testDirectionIndex + 1
    local direction = testDirections[testDirectionIndex]
    local x = player:getX() + direction.dx
    local y = player:getY() + direction.dy

    -- This exercises the real marker renderer without creating a world sound event.
    MarkerHandler.ShowMarker(player, 0, x, y, 60, "Gunshot")
    print("[ChilaSeda_ReactiveSoundViewpointFix] Test direction: " .. direction.name)
end

local function onKeyPressed(key)
    if key ~= Keyboard.KEY_F6 then return end
    if not (Keyboard.isKeyDown(Keyboard.KEY_LCONTROL) or Keyboard.isKeyDown(Keyboard.KEY_RCONTROL)) then return end
    if not (Keyboard.isKeyDown(Keyboard.KEY_LSHIFT) or Keyboard.isKeyDown(Keyboard.KEY_RSHIFT)) then return end
    cycleTestMarker()
end

Events.OnKeyPressed.Add(onKeyPressed)
print("[ChilaSeda_ReactiveSoundViewpointFix] loaded; Ctrl+Shift+F6 cycles test directions and hides on the fifth press")
