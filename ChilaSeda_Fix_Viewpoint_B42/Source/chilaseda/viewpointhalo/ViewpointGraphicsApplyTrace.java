package chilaseda.viewpointhalo;

import java.lang.reflect.Method;
import java.util.function.Supplier;

import me.zed_0xff.zombie_buddy.Patch;

/** Records Viewpoint graphics re-application around settings-window changes. */
@Patch(
        className = "viewpoint.platform.Graphics",
        methodName = "changed",
        warmUp = true,
        strictMatch = false)
public final class ViewpointGraphicsApplyTrace {
    public static final String TAG = "[ChilaSedaViewpointSettingsTrace]";
    public static final ThreadLocal<Long> START_NANOS = new ThreadLocal<>();
    public static volatile Supplier<String> shownReader = ViewpointGraphicsApplyTrace::readSettingsShown;

    @Patch.OnEnter
    public static void beforeApply() {
        START_NANOS.set(System.nanoTime());
        System.out.println(TAG + " graphics.apply enter settingsShown=" + settingsShown());
    }

    @Patch.OnExit(onThrowable = Throwable.class)
    public static void afterApply(
            @Patch.Return boolean changed,
            @Patch.Thrown Throwable failure) {
        Long started = START_NANOS.get();
        START_NANOS.remove();
        long elapsedMs = started == null ? -1L : Math.max(0L, (System.nanoTime() - started) / 1_000_000L);
        String elapsed = elapsedMs < 0L ? "unavailable" : Long.toString(elapsedMs);
        String result = failure != null ? "failed" : changed ? "changed" : "unchanged";
        String failureName = failure == null ? "none" : failure.getClass().getName();
        System.out.println(TAG + " graphics.apply exit durationMs=" + elapsed
                + " result=" + result + " failure=" + failureName);
    }

    public static String settingsShown() {
        try {
            return shownReader.get();
        } catch (Throwable ignored) {
            return "unavailable";
        }
    }

    private static String readSettingsShown() {
        try {
            ClassLoader context = Thread.currentThread().getContextClassLoader();
            Class<?> window = context == null
                    ? Class.forName("viewpoint.platform.SettingsWindow")
                    : Class.forName("viewpoint.platform.SettingsWindow", false, context);
            Method shown = window.getMethod("shown");
            return Boolean.toString(Boolean.TRUE.equals(shown.invoke(null)));
        } catch (Throwable ignored) {
            return "unavailable";
        }
    }

    static void setShownReaderForTests(Supplier<String> reader) {
        shownReader = reader == null ? ViewpointGraphicsApplyTrace::readSettingsShown : reader;
    }

    private ViewpointGraphicsApplyTrace() { }
}
