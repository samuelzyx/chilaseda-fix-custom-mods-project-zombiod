package chilaseda.viewpointhalo;

import java.lang.reflect.Field;
import java.util.Arrays;
import java.util.IdentityHashMap;
import java.util.Map;

import me.zed_0xff.zombie_buddy.Exposer;

@Exposer.LuaClass(name = "ChilaSedaViewpointFogJ")
public final class SearchFogBridge {
    private static volatile boolean nativeForageEnabled;
    private static volatile boolean wanted;
    private static volatile float radius = 10.0f;
    private static volatile float feather = 3.0f;
    private static volatile float darkness = 0.1f;
    private static volatile float desaturation;
    private static volatile int style;
    private static volatile float strength = 1.0f;
    private static float blend;
    private static float currentRadius = -1.0f;
    private static float currentDarkness;
    private static float currentDesaturation;
    private static long lastNanos;
    private static boolean initialized;
    private static boolean ready;
    private static boolean warned;
    private static Field framesField;
    private static Field viewEnabled;
    private static Field frameNumber;
    private static Field sceneField;
    private static Field fogStart;
    private static Field fogEnd;
    private static Field fogR;
    private static Field fogG;
    private static Field fogB;
    private static Field sceneDesaturation;
    private static final Map<Object, float[]> written = new IdentityHashMap<>();
    private static final Map<Object, float[]> original = new IdentityHashMap<>();

    private SearchFogBridge() {}

    public static void setNativeForageEnabled(boolean enabled) {
        nativeForageEnabled = enabled;
    }

    public static boolean nativeForageEnabled() {
        return nativeForageEnabled;
    }

    public static boolean available() {
        return init();
    }

    public static boolean active() {
        if (!init()) return false;
        try {
            return viewEnabled.getBoolean(null);
        } catch (Throwable ignored) {
            return false;
        }
    }

    public static void setSearchFog(boolean on, double radius, double feather,
            double darkness, double desaturation, double style, double strength) {
        SearchFogBridge.radius = Math.max(1.0f, (float) radius);
        SearchFogBridge.feather = Math.max(0.5f, (float) feather);
        SearchFogBridge.darkness = clamp01((float) darkness);
        SearchFogBridge.desaturation = clamp01((float) desaturation);
        SearchFogBridge.style = (int) style;
        SearchFogBridge.strength = clamp01((float) strength);
        wanted = on && SearchFogBridge.strength > 0.0f;
    }

    private static synchronized boolean init() {
        if (initialized) return ready;
        initialized = true;
        try {
            ClassLoader loader = Thread.currentThread().getContextClassLoader();
            if (loader == null) loader = SearchFogBridge.class.getClassLoader();
            Class<?> fp = Class.forName("viewpoint.FP", false, loader);
            Class<?> frame = Class.forName("viewpoint.core.Frame", false, loader);
            Class<?> view = Class.forName("viewpoint.core.View", false, loader);
            framesField = field(fp, "frames");
            viewEnabled = field(view, "enabled");
            frameNumber = field(frame, "number");
            sceneField = field(frame, "scene");
            Class<?> scene = sceneField.getType();
            fogStart = field(scene, "fogStart");
            fogEnd = field(scene, "fogEnd");
            fogR = field(scene, "fogR");
            fogG = field(scene, "fogG");
            fogB = field(scene, "fogB");
            sceneDesaturation = field(scene, "desaturation");
            ready = true;
        } catch (Throwable error) {
            ready = false;
            warnOnce("native Viewpoint fog fields unavailable: " + error);
        }
        return ready;
    }

    private static Field field(Class<?> type, String name) throws ReflectiveOperationException {
        Field value = type.getDeclaredField(name);
        value.setAccessible(true);
        return value;
    }

    private static float clamp01(float value) {
        return Math.max(0.0f, Math.min(1.0f, value));
    }

    private static void warnOnce(String message) {
        if (warned) return;
        warned = true;
        System.out.println("[ChilaSeda_ViewpointSearchFog] " + message);
    }

    private static float step(boolean viewOn) {
        long now = System.nanoTime();
        float dt = lastNanos == 0L ? 0.0f : Math.min(0.1f, (now - lastNanos) / 1.0e9f);
        lastNanos = now;
        float targetBlend = wanted && viewOn ? strength : 0.0f;
        if (blend < targetBlend) blend = Math.min(targetBlend, blend + dt * 2.0f);
        else if (blend > targetBlend) blend = Math.max(targetBlend, blend - dt * 2.0f);
        float smoothing = dt <= 0.0f ? 1.0f : (float) (1.0 - Math.exp(-dt / 0.6));
        if (currentRadius < 0.0f) {
            currentRadius = radius;
            currentDarkness = darkness;
            currentDesaturation = desaturation;
        } else {
            currentRadius += (radius - currentRadius) * smoothing;
            currentDarkness += (darkness - currentDarkness) * smoothing;
            currentDesaturation += (desaturation - currentDesaturation) * smoothing;
        }
        return blend;
    }

    public static void apply() {
        if (!init()) return;
        try {
            Object[] frames = (Object[]) framesField.get(null);
            Object frame = latestFrame(frames);
            float alpha = step(active());
            if (frame == null) return;
            Object scene = sceneField.get(frame);
            if (scene == null) return;
            float[] values = read(scene);
            float[] lastWritten = written.get(scene);
            float[] base = lastWritten != null && Arrays.equals(lastWritten, values)
                    ? original.get(scene) : values;
            if (base == null) base = values;
            if (alpha <= 0.0f) {
                write(scene, base);
                written.remove(scene);
                original.remove(scene);
                return;
            }

            float startTarget = (style == 1 ? currentRadius * 0.55f : currentRadius * 0.75f);
            float endTarget = style == 1 ? currentRadius + feather * 2.5f : currentRadius + feather;
            float start = Math.min(lerp(base[0], startTarget, alpha), base[0]);
            float end = Math.min(lerp(base[1], endTarget, alpha), base[1]);
            end = Math.max(end, start + 0.5f);
            float darken = style == 0 ? Math.min(0.92f, 0.55f + currentDarkness * 0.6f) * alpha : 0.0f;
            float desat = Math.max(base[5], lerp(base[5], currentDesaturation, alpha));
            float[] adjusted = new float[] { start, end,
                    base[2] * (1.0f - darken), base[3] * (1.0f - darken),
                    base[4] * (1.0f - darken), desat };
            write(scene, adjusted);
            written.put(scene, adjusted);
            original.put(scene, base.clone());
        } catch (Throwable error) {
            warnOnce("could not apply search fog: " + error);
        }
    }

    private static Object latestFrame(Object[] frames) throws IllegalAccessException {
        if (frames == null) return null;
        Object latest = null;
        long latestNumber = Long.MIN_VALUE;
        for (Object frame : frames) {
            if (frame == null) continue;
            long number = frameNumber.getLong(frame);
            if (number > latestNumber) {
                latestNumber = number;
                latest = frame;
            }
        }
        return latest;
    }

    private static float[] read(Object scene) throws IllegalAccessException {
        return new float[] { fogStart.getFloat(scene), fogEnd.getFloat(scene),
                fogR.getFloat(scene), fogG.getFloat(scene), fogB.getFloat(scene),
                sceneDesaturation.getFloat(scene) };
    }

    private static void write(Object scene, float[] values) throws IllegalAccessException {
        fogStart.setFloat(scene, values[0]);
        fogEnd.setFloat(scene, values[1]);
        fogR.setFloat(scene, values[2]);
        fogG.setFloat(scene, values[3]);
        fogB.setFloat(scene, values[4]);
        sceneDesaturation.setFloat(scene, values[5]);
    }

    private static float lerp(float start, float end, float alpha) {
        return start + (end - start) * alpha;
    }
}
