package chilaseda.viewpointhalo;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import se.krka.kahlua.vm.LuaClosure;
import se.krka.kahlua.vm.Prototype;
import zombie.Lua.Event;
import zombie.Lua.LuaEventManager;

public final class ViewpointTextureFixScanBridgeContract {
    private static LuaClosure callback(String file, String filename) {
        Prototype prototype = new Prototype();
        prototype.file = file;
        prototype.filename = filename;
        return new LuaClosure(prototype, null);
    }

    private static void require(boolean condition, String message) {
        if (!condition) throw new AssertionError(message);
    }

    public static void main(String[] args) {
        ArrayList<Event> previousEvents = new ArrayList<>();
        HashMap<String, Event> previousMap = new HashMap<>();
        LuaEventManager.getEvents(previousEvents, previousMap);
        try {
            Event keyPressed = new Event("OnKeyPressed", 0);
            keyPressed.callbacks.add(callback("media/lua/client/VPFixScan.lua", "VPFixScan.lua"));
            keyPressed.callbacks.add(callback(null, "VPFixScan.lua"));
            keyPressed.callbacks.add(callback("media/lua/client/OtherMod.lua", "OtherMod.lua"));
            ArrayList<Event> events = new ArrayList<>(List.of(keyPressed));
            HashMap<String, Event> eventMap = new HashMap<>(Map.of("OnKeyPressed", keyPressed));
            LuaEventManager.setEvents(events, eventMap);

            int removed = ViewpointTextureFixScanBridge.removeWorkshopScannerCallbacks();
            require(removed == 2, "expected both Workshop scanner closures to be removed");
            require(keyPressed.callbacks.size() == 1, "unrelated key callback should remain");
            require("OtherMod.lua".equals(keyPressed.callbacks.get(0).prototype.filename),
                    "callback removal must preserve unrelated event listeners");

            LuaEventManager.setEvents(new ArrayList<>(), new HashMap<>());
            require(ViewpointTextureFixScanBridge.removeWorkshopScannerCallbacks() == -1,
                    "missing OnKeyPressed event should report an explicit unavailable result");
            System.out.println("TextureFix event bridge contracts passed: removed=" + removed);
        } finally {
            LuaEventManager.setEvents(previousEvents, previousMap);
        }
    }
}
