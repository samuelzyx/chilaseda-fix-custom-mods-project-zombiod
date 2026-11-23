package chilaseda.viewpointhalo;

import java.lang.reflect.Field;

import me.zed_0xff.zombie_buddy.Exposer;

@Exposer.LuaClass(name = "ChilaSedaViewpointForageTuningJ")
public final class ForageTuningBridge {
    private static final long RETRY_INTERVAL_NANOS = 1_000_000_000L;
    private static volatile Field findPinHeightField;
    private static volatile Field findPinUpField;
    private static volatile double basePinHeight = Double.NaN;
    private static volatile double basePinUp = Double.NaN;
    private static volatile double groundArrowOffset;
    private static volatile long retryAfterNanos;
    private static volatile String status = "not checked";
    private static volatile boolean warnedUnavailable;
    private static volatile boolean warnedWriteFailure;

    private ForageTuningBridge() {}

    public static boolean isNativeTuningAvailable() {
        return initialize();
    }

    public static double nativeFindPinHeightBase() {
        return initialize() ? basePinHeight : Double.NaN;
    }

    public static double nativeFindPinUpBase() {
        return initialize() ? basePinUp : Double.NaN;
    }

    public static double nativeGroundArrowOffset() {
        return groundArrowOffset;
    }

    public static boolean setNativeGroundArrowOffset(double offset) {
        if (!Double.isFinite(offset) || Math.abs(offset) > 64.0) return false;
        groundArrowOffset = offset;
        return true;
    }

    public static boolean setNativePinTuning(double findPinHeight, double findPinUp) {
        if (!initialize()) return false;
        if (!Double.isFinite(findPinHeight) || !Double.isFinite(findPinUp)
                || Math.abs(findPinHeight) > Float.MAX_VALUE || Math.abs(findPinUp) > Float.MAX_VALUE) {
            status = "rejected non-finite or out-of-range tuning values";
            return false;
        }
        try {
            findPinHeightField.setFloat(null, (float) findPinHeight);
            findPinUpField.setFloat(null, (float) findPinUp);
            return true;
        } catch (Throwable error) {
            status = "write failed: " + error.getClass().getName() + ": " + String.valueOf(error.getMessage());
            if (!warnedWriteFailure) {
                warnedWriteFailure = true;
                System.out.println("[ChilaSeda_ViewpointForageTuningBridge] " + status);
            }
            return false;
        }
    }

    public static String nativeTuningStatus() {
        initialize();
        return status;
    }

    private static synchronized boolean initialize() {
        if (findPinHeightField != null && findPinUpField != null) return true;
        long now = System.nanoTime();
        if (now < retryAfterNanos) return false;
        retryAfterNanos = now + RETRY_INTERVAL_NANOS;
        try {
            Class<?> tuningClass = viewpointClass("viewpoint.platform.Tuning");
            Field height = tuningClass.getDeclaredField("findPinHeight");
            Field up = tuningClass.getDeclaredField("findPinUp");
            height.setAccessible(true);
            up.setAccessible(true);
            double heightBase = height.getFloat(null);
            double upBase = up.getFloat(null);
            if (!Double.isFinite(heightBase) || !Double.isFinite(upBase)) {
                throw new IllegalStateException("Viewpoint returned non-finite tuning defaults");
            }
            findPinHeightField = height;
            findPinUpField = up;
            basePinHeight = heightBase;
            basePinUp = upBase;
            status = "ready; fields=findPinHeight,findPinUp";
            System.out.println("[ChilaSeda_ViewpointForageTuningBridge] " + status
                    + " baseHeight=" + heightBase + " baseUp=" + upBase);
            return true;
        } catch (Throwable error) {
            status = "unavailable: " + error.getClass().getName() + ": " + String.valueOf(error.getMessage());
            if (!warnedUnavailable) {
                warnedUnavailable = true;
                System.out.println("[ChilaSeda_ViewpointForageTuningBridge] " + status);
            }
            return false;
        }
    }

    private static Class<?> viewpointClass(String name) throws ClassNotFoundException {
        ClassLoader context = Thread.currentThread().getContextClassLoader();
        if (context != null) {
            try {
                return Class.forName(name, false, context);
            } catch (ClassNotFoundException ignored) {
                // Fall back to the loader that loaded this ZombieBuddy-exposed bridge.
            }
        }
        return Class.forName(name, false, ForageTuningBridge.class.getClassLoader());
    }
}
