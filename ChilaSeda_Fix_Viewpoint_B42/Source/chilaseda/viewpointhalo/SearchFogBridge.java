package chilaseda.viewpointhalo;

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.lang.reflect.Constructor;
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
    private static volatile float strength = 0.9f;
    private static volatile boolean shaderPackFogEnabled = true;
    static volatile float ownStart = 1000000.0f;
    static volatile float ownEnd = 1000000.0f;
    static volatile float ownAlpha;
    static volatile float ownR;
    static volatile float ownG;
    static volatile float ownB;
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
    private static volatile Method settingsWindowUpdate;
    private static volatile Field freeCamActive;
    private static final Map<Object, float[]> written = new IdentityHashMap<>();
    private static final Map<Object, float[]> original = new IdentityHashMap<>();
    private static final CameraProjection cameraProjection = new CameraProjection();

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

    /** Loads Viewpoint's saved live graphics settings through ZombieBuddy's Lua bridge. */
    public static int initializeGraphicsSettings() {
        try {
            Method update = settingsWindowUpdate;
            if (update == null) {
                update = viewpointClass("viewpoint.platform.SettingsWindow").getMethod("update");
                settingsWindowUpdate = update;
            }
            update.invoke(null);
            return 1;
        } catch (ClassNotFoundException | NoSuchMethodException | LinkageError unavailable) {
            return -1;
        } catch (Throwable failed) {
            return 0;
        }
    }

    /** Returns -1 while Viewpoint is unavailable, otherwise 0 or 1 for FreeCam.active. */
    public static int movableCameraState() {
        try {
            Field active = freeCamActive;
            if (active == null) {
                active = viewpointClass("viewpoint.input.FreeCam").getField("active");
                freeCamActive = active;
            }
            return active.getBoolean(null) ? 1 : 0;
        } catch (ClassNotFoundException | NoSuchFieldException | LinkageError unavailable) {
            return -1;
        } catch (Throwable failed) {
            return -2;
        }
    }

    static Class<?> viewpointClass(String name) throws ClassNotFoundException {
        ClassLoader context = Thread.currentThread().getContextClassLoader();
        if (context != null) {
            try {
                return Class.forName(name, false, context);
            } catch (ClassNotFoundException ignored) {
                // Try the loader that loaded this ZombieBuddy-exposed bridge.
            }
        }
        return Class.forName(name, false, SearchFogBridge.class.getClassLoader());
    }

    public static void setSearchFog(boolean on, double radius, double feather,
            double darkness, double desaturation, double style, double strength) {
        SearchFogBridge.radius = Math.max(1.0f, (float) radius);
        SearchFogBridge.feather = Math.max(0.5f, (float) feather);
        SearchFogBridge.darkness = clamp01((float) darkness);
        SearchFogBridge.desaturation = clamp01((float) desaturation);
        SearchFogBridge.style = (int) style;
        SearchFogBridge.strength = Math.max(0.0f, Math.min(2.0f, (float) strength));
        wanted = on && SearchFogBridge.strength > 0.0f;
    }

    public static void setShaderPackFogEnabled(boolean enabled) {
        shaderPackFogEnabled = enabled;
        ShaderPackSearchFog.enabled = enabled;
    }

    static boolean shaderPackFogEnabled() {
        return shaderPackFogEnabled;
    }

    static boolean shaderPackPresent() {
        try {
            Method drawn = viewpointClass("viewpoint.platform.IrisPacks").getMethod("drawn");
            return active() && drawn.invoke(null) != null;
        } catch (Throwable ignored) {
            return false;
        }
    }

    /** Prepare Viewpoint's own camera projection for a batch of native forage pins. */
    public static boolean prepareNativeForagePins(double playerIndex) {
        return cameraProjection.prepare((int) playerIndex);
    }

    /** Project one native forage pin; call prepareNativeForagePins first. */
    public static boolean projectNativeForagePin(double x, double y, double z, double lift) {
        return cameraProjection.project((float) x, (float) y, (float) z, (float) lift);
    }

    public static double nativeForagePinScreenX() { return cameraProjection.screenX; }
    public static double nativeForagePinScreenY() { return cameraProjection.screenY; }
    public static double nativeForagePinScreenWidth() { return cameraProjection.width; }
    public static double nativeForagePinScreenHeight() { return cameraProjection.height; }

    /** Uses Viewpoint's own WorldToScreen so selection agrees with its 3D camera and shader projection. */
    private static final class CameraProjection {
        private Field frames;
        private Field frameNumber;
        private Field freeCamActive;
        private Field freeCamPlace;
        private Method screenWidth;
        private Method screenHeight;
        private Method setCamera;
        private Method projectPixel;
        private Object worldToScreen;
        private final float[] pixel = new float[2];
        private long preparedFrame = Long.MIN_VALUE;
        private int preparedPlayer = -1;
        private boolean initialized;
        private boolean ready;
        private boolean warnedProjection;
        private double screenX;
        private double screenY;
        private double width;
        private double height;

        private synchronized boolean prepare(int player) {
            if (!initialize()) return false;
            try {
                Object[] frameArray = (Object[]) frames.get(null);
                if (frameArray == null) return false;
                Object latest = null;
                long latestNumber = Long.MIN_VALUE;
                for (Object frame : frameArray) {
                    if (frame == null) continue;
                    long number = frameNumber.getLong(frame);
                    if (number > latestNumber) {
                        latestNumber = number;
                        latest = frame;
                    }
                }
                if (latest == null) return false;

                int viewportWidth = ((Number) screenWidth.invoke(null, player)).intValue();
                int viewportHeight = ((Number) screenHeight.invoke(null, player)).intValue();
                if (viewportWidth <= 0 || viewportHeight <= 0) return false;
                if (preparedFrame == latestNumber && preparedPlayer == player
                        && width == viewportWidth && height == viewportHeight) return true;

                Object place = freeCamActive.getBoolean(null) ? freeCamPlace.get(null) : null;
                setCamera.invoke(worldToScreen, latest, place,
                        (float) viewportWidth, (float) viewportHeight);
                preparedFrame = latestNumber;
                preparedPlayer = player;
                width = viewportWidth;
                height = viewportHeight;
                return true;
            } catch (Throwable error) {
                warnProjection("could not prepare Viewpoint camera projection: " + error);
                return false;
            }
        }

        private synchronized boolean project(float x, float y, float z, float lift) {
            if (preparedFrame == Long.MIN_VALUE || worldToScreen == null) return false;
            try {
                boolean inFront = (Boolean) projectPixel.invoke(worldToScreen,
                        x, y, z, lift, pixel);
                screenX = pixel[0];
                screenY = pixel[1];
                return inFront;
            } catch (Throwable error) {
                warnProjection("could not project native forage pin: " + error);
                return false;
            }
        }

        private boolean initialize() {
            if (initialized) return ready;
            initialized = true;
            try {
                Class<?> fp = viewpointClass("viewpoint.FP");
                Class<?> frame = viewpointClass("viewpoint.core.Frame");
                Class<?> freeCam = viewpointClass("viewpoint.input.FreeCam");
                Class<?> place = viewpointClass("viewpoint.input.FreeCam$Place");
                Class<?> camera = viewpointClass("viewpoint.game.WorldToScreen");
                Class<?> isoCamera = viewpointClass("zombie.iso.IsoCamera");

                frames = field(fp, "frames");
                frameNumber = field(frame, "number");
                freeCamActive = field(freeCam, "active");
                freeCamPlace = field(freeCam, "place");
                Constructor<?> constructor = camera.getDeclaredConstructor();
                constructor.setAccessible(true);
                worldToScreen = constructor.newInstance();
                setCamera = camera.getDeclaredMethod("set", frame, place, float.class, float.class);
                setCamera.setAccessible(true);
                projectPixel = camera.getDeclaredMethod("pixel",
                        float.class, float.class, float.class, float.class, float[].class);
                projectPixel.setAccessible(true);
                screenWidth = isoCamera.getMethod("getScreenWidth", int.class);
                screenHeight = isoCamera.getMethod("getScreenHeight", int.class);
                ready = true;
            } catch (Throwable error) {
                warnProjection("Viewpoint WorldToScreen API unavailable: " + error);
                ready = false;
            }
            return ready;
        }

        private void warnProjection(String message) {
            if (warnedProjection) return;
            warnedProjection = true;
            System.out.println("[ChilaSeda_ViewpointNativeForagePickup] " + message);
        }
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
        float targetBlend = wanted && viewOn ? 1.0f : 0.0f;
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
            boolean depthLayerDrawing = shaderPackFogEnabled
                    && !ShaderPackSearchFog.failed() && ShaderPackSearchFog.drawing();
            if (depthLayerDrawing) {
                start = base[0];
                end = base[1];
            }
            end = Math.max(end, start + 0.5f);
            float darken = style == 0 && !depthLayerDrawing
                    ? Math.min(0.98f, (0.92f + currentDarkness * 0.2f) * alpha * strength) : 0.0f;
            float desat = Math.max(base[5], lerp(base[5], currentDesaturation, alpha));
            float[] adjusted = new float[] { start, end,
                    base[2] * (1.0f - darken), base[3] * (1.0f - darken),
                    base[4] * (1.0f - darken), desat };
            write(scene, adjusted);
            written.put(scene, adjusted);
            original.put(scene, base.clone());
            ownStart = startTarget;
            ownEnd = Math.max(endTarget, startTarget + 0.5f);
            // The depth layer has its own distance mask, so Oscuridad uses black
            // instead of Viewpoint's gray scene-fog color. Neblina keeps that color.
            float layerRed = style == 0 ? 0.0f : adjusted[2];
            float layerGreen = style == 0 ? 0.0f : adjusted[3];
            float layerBlue = style == 0 ? 0.0f : adjusted[4];
            ownR = layerRed;
            ownG = layerGreen;
            ownB = layerBlue;
            ownAlpha = Math.min(1.0f, alpha * strength);
            if (shaderPackFogEnabled) ShaderPackSearchFog.queue();
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
