local ok, DragAndDrop = pcall(require, "EquipmentUI/DragAndDrop")
if not ok or type(DragAndDrop) ~= "table"
    or type(DragAndDrop.processCancelation) ~= "function" then
    print("[ChilaSeda_InventoryTetrisPausedDrop] Inventory Tetris drag cancellation API unavailable; paused drop fix skipped")
    return
end

local pausedTick = Events and Events.OnTickEvenPaused
if not pausedTick or type(pausedTick.Add) ~= "function" then
    print("[ChilaSeda_InventoryTetrisPausedDrop] OnTickEvenPaused is unavailable; paused drop fix skipped")
    return
end

local function processPausedDragCancellation()
    if type(isGamePaused) ~= "function" or not isGamePaused() then
        return
    end

    DragAndDrop.processCancelation()
end

pausedTick.Add(processPausedDragCancellation)
