package chilaseda.viewpointhalo;

import me.zed_0xff.zombie_buddy.Patch;
import zombie.core.Translator;

import java.util.Collections;
import java.util.IdentityHashMap;
import java.util.Map;

/** Translates only SettingsPages text reads that are used for drawing. */
@Patch(className = "viewpoint.platform.SettingsPages", methodName = "entry", warmUp = true)
public final class ViewpointSettingsPageScope {
    private static final String KEY_PREFIX = "IGUI_ES_PZAPI_Viewpoint_";
    private static final ThreadLocal<Frame> CURRENT = new ThreadLocal<>();
    private static final Map<String[], String[]> CHOICE_LABELS =
            Collections.synchronizedMap(new IdentityHashMap<>());

    @Patch.OnEnter
    public static void begin(@Patch.Argument(0) Object page) {
        beginScope(page);
    }

    public static void beginScope(Object page) {
        CURRENT.set(new Frame(page));
    }

    @Patch.OnExit(onThrowable = Throwable.class)
    public static void end() {
        endScope();
    }

    public static void endScope() {
        CURRENT.remove();
    }

    public static String pageName(Object page, String value) {
        Frame frame = CURRENT.get();
        if (frame == null || frame.page != page) return value;
        int call = frame.nameCalls++;
        return call == 1 ? translate(value) : value;
    }

    public static String pageLine(Object page, String value) {
        Frame frame = CURRENT.get();
        if (frame == null || frame.page != page) return value;
        int call = frame.lineCalls++;
        return call == 2 ? translate(value) : value;
    }

    public static String translate(String value) {
        if (value == null || value.isEmpty()) return value;
        try {
            String translated = Translator.getTextOrNull(KEY_PREFIX + value);
            return translated == null ? value : translated;
        } catch (Throwable ignored) {
            return value;
        }
    }

    public static String[] translateLabels(String[] labels) {
        if (labels == null || labels.length == 0) return labels;
        synchronized (CHOICE_LABELS) {
            String[] cached = CHOICE_LABELS.get(labels);
            if (cached != null) return cached;
            String[] localized = labels.clone();
            boolean changed = false;
            for (int i = 0; i < labels.length; i++) {
                localized[i] = translate(labels[i]);
                changed |= !java.util.Objects.equals(localized[i], labels[i]);
            }
            String[] result = changed ? localized : labels;
            if (CHOICE_LABELS.size() >= 256) CHOICE_LABELS.clear();
            CHOICE_LABELS.put(labels, result);
            return result;
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
