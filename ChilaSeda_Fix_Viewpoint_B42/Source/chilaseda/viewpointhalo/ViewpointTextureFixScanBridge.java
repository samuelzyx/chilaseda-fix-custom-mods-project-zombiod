package chilaseda.viewpointhalo;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Locale;

import me.zed_0xff.zombie_buddy.Exposer;
import se.krka.kahlua.vm.LuaClosure;
import se.krka.kahlua.vm.Prototype;
import zombie.Lua.Event;
import zombie.Lua.LuaEventManager;

/** Removes TextureFix (Viewpoint)'s incompatible F10 diagnostic callback. */
@Exposer.LuaClass(name = "ChilaSedaViewpointTextureFixScanJ")
public final class ViewpointTextureFixScanBridge {
    private ViewpointTextureFixScanBridge() {}

    /**
     * Events.OnKeyPressed is exposed to Lua as a table with Add and Remove only.
     * The actual callback list is available on the registered Java Event.
     *
     * @return number of removed TextureFix callbacks, or -1 if the event is unavailable
     */
    public static int removeWorkshopScannerCallbacks() {
        ArrayList<Event> registeredEvents = new ArrayList<>();
        HashMap<String, Event> eventsByName = new HashMap<>();
        LuaEventManager.getEvents(registeredEvents, eventsByName);
        Event event = eventsByName.get("OnKeyPressed");
        if (event == null || event.callbacks == null) return -1;

        int removed = 0;
        for (int index = event.callbacks.size() - 1; index >= 0; index--) {
            if (isWorkshopScanner(event.callbacks.get(index))) {
                event.callbacks.remove(index);
                removed++;
            }
        }
        return removed;
    }

    private static boolean isWorkshopScanner(LuaClosure callback) {
        if (callback == null) return false;
        Prototype prototype = callback.prototype;
        return prototype != null
                && (isScannerPath(prototype.file) || isScannerPath(prototype.filename));
    }

    private static boolean isScannerPath(String value) {
        if (value == null) return false;
        String normalized = value.replace('\\', '/').toLowerCase(Locale.ROOT);
        return normalized.equals("vpfixscan.lua") || normalized.endsWith("/vpfixscan.lua");
    }
}
