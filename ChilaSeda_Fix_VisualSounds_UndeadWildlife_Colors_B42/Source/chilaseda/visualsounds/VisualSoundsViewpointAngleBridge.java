package chilaseda.visualsounds;

import java.lang.reflect.Field;

import me.zed_0xff.zombie_buddy.Exposer;

/** Reads the camera yaw Viewpoint already published for its current render frame. */
@Exposer.LuaClass(name = "ChilaSedaVisualSoundsViewpointBridge")
public final class VisualSoundsViewpointAngleBridge {
    private static final String TAG = "[ChilaSeda_VisualSoundsViewpointBridge] ";
    private static volatile boolean initialized;
    private static volatile boolean ready;
    private static volatile boolean warned;
    private static Field frames;
    private static Field enabled;
    private static Field frameNumber;
    private static Field viewYaw;
    private static Field cameraShot;
    private static Field cameraShotAddYaw;

    private VisualSoundsViewpointAngleBridge() {}

    /** Returns the Workshop SDI angle, or NaN when Viewpoint is inactive/unavailable. */
    public static double angle() {
        if (!initialize()) return Double.NaN;
        try {
            if (!enabled.getBoolean(null)) return Double.NaN;
            Object[] frameArray = (Object[]) frames.get(null);
            if (frameArray == null) return Double.NaN;

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
            if (latest == null) return Double.NaN;

            // Match the camera heading used by Viewpoint's rendered frame, including
            // the yaw offset applied by the active camera shot. VisualSoundsKAViewpoint
            // uses this heading to rotate its direction arrows with the camera.
            Object shot = cameraShot.get(latest);
            float shotYaw = shot == null ? 0.0f : cameraShotAddYaw.getFloat(shot);
            return -(viewYaw.getFloat(latest) + shotYaw) - Math.PI / 2.0;
        } catch (Throwable error) {
            warnOnce("could not read Viewpoint's current camera frame: " + error);
            return Double.NaN;
        }
    }

    private static synchronized boolean initialize() {
        if (initialized) return ready;
        initialized = true;
        try {
            ClassLoader loader = Thread.currentThread().getContextClassLoader();
            if (loader == null) loader = VisualSoundsViewpointAngleBridge.class.getClassLoader();
            Class<?> fp = Class.forName("viewpoint.FP", false, loader);
            Class<?> frame = Class.forName("viewpoint.core.Frame", false, loader);
            Class<?> view = Class.forName("viewpoint.core.View", false, loader);
            frames = field(fp, "frames");
            enabled = field(view, "enabled");
            frameNumber = field(frame, "number");
            viewYaw = field(frame, "viewYaw");
            cameraShot = field(frame, "cameraShot");
            cameraShotAddYaw = field(cameraShot.getType(), "addYaw");
            ready = true;
        } catch (Throwable error) {
            warnOnce("Viewpoint frame fields unavailable: " + error);
            ready = false;
        }
        return ready;
    }

    private static Field field(Class<?> type, String name) throws ReflectiveOperationException {
        Field value = type.getDeclaredField(name);
        value.setAccessible(true);
        return value;
    }

    private static void warnOnce(String message) {
        if (warned) return;
        warned = true;
        System.out.println(TAG + message);
    }
}
