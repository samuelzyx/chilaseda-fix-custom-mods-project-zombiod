package chilaseda.viewpointhalo;

import java.lang.reflect.Field;
import java.lang.reflect.Method;

import me.zed_0xff.zombie_buddy.Exposer;

@Exposer.LuaClass(name = "ChilaSedaViewpointInventoryOptionsJ")
public final class ViewpointInventoryOptionsBridge {
    private static volatile Field uiSetting;
    private static volatile Method getValue;
    private static volatile Method setValue;
    private static volatile Method saveSettings;

    private ViewpointInventoryOptionsBridge() { }

    /** Returns -1 when native Viewpoint settings are unavailable, otherwise 0 or 1. */
    public static int integratedInventoryEnabled() {
        if (!initialize()) return -1;
        try {
            Object setting = uiSetting.get(null);
            return Boolean.TRUE.equals(getValue.invoke(setting)) ? 1 : 0;
        } catch (Throwable unavailable) {
            return -1;
        }
    }

    /** Sets Viewpoint's existing UI toggle and persists it; returns 1 on success, 0 on save failure, -1 if unavailable. */
    public static int setIntegratedInventoryEnabled(boolean enabled) {
        if (!initialize()) return -1;
        Object setting = null;
        Boolean previous = null;
        try {
            setting = uiSetting.get(null);
            previous = Boolean.TRUE.equals(getValue.invoke(setting));
            setValue.invoke(setting, enabled);
            boolean saved = Boolean.TRUE.equals(saveSettings.invoke(null));
            boolean current = Boolean.TRUE.equals(getValue.invoke(setting));
            if (saved && current == enabled) return 1;
            restore(setting, previous);
            return 0;
        } catch (Throwable failed) {
            restore(setting, previous);
            return -1;
        }
    }

    private static void restore(Object setting, Boolean value) {
        if (setting == null || value == null || setValue == null) return;
        try {
            setValue.invoke(setting, value);
            if (saveSettings != null) saveSettings.invoke(null);
        } catch (Throwable ignored) {
            // Preserve the original failure result; Lua logs a bounded fallback marker.
        }
    }

    private static synchronized boolean initialize() {
        if (uiSetting != null && getValue != null && setValue != null && saveSettings != null) return true;
        try {
            Class<?> inventory = viewpointClass("viewpoint.interact.InventorySettings");
            Field ui = inventory.getField("UI");
            Object setting = ui.get(null);
            Method get = setting.getClass().getMethod("get");
            Method set = setting.getClass().getMethod("set", boolean.class);
            Class<?> liveSettings = viewpointClass("viewpoint.platform.LiveSettings");
            Method save = liveSettings.getDeclaredMethod("save");
            save.setAccessible(true);
            uiSetting = ui;
            getValue = get;
            setValue = set;
            saveSettings = save;
            return true;
        } catch (Throwable unavailable) {
            return false;
        }
    }

    private static Class<?> viewpointClass(String name) throws ClassNotFoundException {
        ClassLoader context = Thread.currentThread().getContextClassLoader();
        if (context != null) {
            try {
                return Class.forName(name, true, context);
            } catch (ClassNotFoundException ignored) {
                // Try the class loader that loaded this bridge.
            }
        }
        return Class.forName(name, true, ViewpointInventoryOptionsBridge.class.getClassLoader());
    }
}
