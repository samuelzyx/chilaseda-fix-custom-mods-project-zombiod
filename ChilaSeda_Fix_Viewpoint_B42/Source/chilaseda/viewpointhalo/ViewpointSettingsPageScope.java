package chilaseda.viewpointhalo;

import me.zed_0xff.zombie_buddy.Patch;
import zombie.core.Translator;

/** Translates only SettingsPages text reads that are used for drawing. */
@Patch(className = "viewpoint.platform.SettingsPages", methodName = "entry", warmUp = true)
public final class ViewpointSettingsPageScope {
    private static final String KEY_PREFIX = "IGUI_ES_PZAPI_Viewpoint_";
    private static final ThreadLocal<Frame> CURRENT = new ThreadLocal<>();

    @Patch.OnEnter
    public static void begin(@Patch.Argument(0) Object page) {
        CURRENT.set(new Frame(page));
    }

    @Patch.OnExit(onThrowable = Throwable.class)
    public static void end() {
        CURRENT.remove();
    }

    static String pageName(Object page, String value) {
        Frame frame = CURRENT.get();
        if (frame == null || frame.page != page) return value;
        int call = frame.nameCalls++;
        return call == 1 ? translate(value) : value;
    }

    static String pageLine(Object page, String value) {
        Frame frame = CURRENT.get();
        if (frame == null || frame.page != page) return value;
        int call = frame.lineCalls++;
        return call == 2 ? translate(value) : value;
    }

    static String translate(String value) {
        if (value == null || value.isEmpty()) return value;
        try {
            String translated = Translator.getTextOrNull(KEY_PREFIX + value);
            return translated == null ? value : translated;
        } catch (Throwable ignored) {
            return value;
        }
    }

    private static final class Frame {
        private final Object page;
        private int nameCalls;
        private int lineCalls;

        private Frame(Object page) {
            this.page = page;
        }
    }

    private ViewpointSettingsPageScope() { }
}
