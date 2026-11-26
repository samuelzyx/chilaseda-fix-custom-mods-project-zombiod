package chilaseda.viewpointhalo;

import java.lang.reflect.Field;

import me.zed_0xff.zombie_buddy.Patch;
import viewpoint.core.Frame;
import viewpoint.render.FarRelief;
import zombie.characters.IsoPlayer;

/** Re-aims Viewpoint's 3D foraging arrow at the pin as projected by the active camera. */
@Patch(className = "viewpoint.interact.ForageFinds", methodName = "arrow", warmUp = true)
public final class ForagingArrowCameraProjection {
    private static final int MAX_PROJECTION_TRACES = 32;
    private static volatile Field xsField;
    private static volatile Field ysField;
    private static volatile Field shownField;
    // ZombieBuddy injects this read into viewpoint.interact.ForageFinds, so the
    // transformed caller needs public access to the one-time fallback flag.
    public static volatile boolean warned;
    private static volatile int projectionTraceCount;
    private static volatile boolean fallbackTraceReported;
    private static volatile int lastTracedPinIndex = Integer.MIN_VALUE;
    private static volatile float lastTracedGroundOffset = Float.NaN;

    public static synchronized void traceProjection(
            int index, float groundOffset, float playerHeight, float sceneLift, float arrowY, float pinHeight) {
        if (projectionTraceCount >= MAX_PROJECTION_TRACES) return;
        if (index == lastTracedPinIndex && Float.compare(groundOffset, lastTracedGroundOffset) == 0) return;
        projectionTraceCount++;
        lastTracedPinIndex = index;
        lastTracedGroundOffset = groundOffset;
        System.out.println("[ChilaSeda Viewpoint foraging arrow] event=projected pinIndex=" + index
                + " arrowOffset=" + groundOffset + " playerHeight=" + playerHeight
                + " sceneLift=" + sceneLift + " arrowY=" + arrowY + " pinHeight=" + pinHeight);
    }

    public static synchronized void traceFallback(String reason) {
        if (fallbackTraceReported || projectionTraceCount >= MAX_PROJECTION_TRACES) return;
        fallbackTraceReported = true;
        projectionTraceCount++;
        System.out.println("[ChilaSeda Viewpoint foraging arrow] event=fallback reason=" + reason);
    }

    @Patch.OnEnter(skipOn = true)
    public static boolean drawProjectedArrow(
            @Patch.Argument(0) Frame frame,
            @Patch.Argument(1) IsoPlayer player,
            @Patch.Argument(2) FarRelief.Lift lift,
            @Patch.Argument(3) float playerHeight,
            @Patch.Argument(4) int index,
            @Patch.Argument(5) float pinHeight) {
        // This projection belongs only to Viewpoint's integrated forage API.
        // Keep the original arrow path when that API is absent.
        if (!SearchFogBridge.nativeForageEnabled()) {
            traceFallback("integrated-forage-disabled");
            return false;
        }
        try {
            int[] xs = (int[]) field("xs").get(null);
            int[] ys = (int[]) field("ys").get(null);
            boolean[] shown = (boolean[]) field("shown").get(null);
            if (index < 0 || index >= xs.length || index >= ys.length || index >= shown.length) {
                traceFallback("pin-index-out-of-range:" + index);
                return false;
            }

            float pinX = xs[index] + 0.5f;
            float pinZ = ys[index] + 0.5f;
            float dx = pinX - player.getX();
            float dz = pinZ - player.getY();
            float distance = (float) Math.hypot(dx, dz);
            if (distance < 1.0e-5f) {
                traceFallback("pin-at-player-position");
                return false;
            }

            float arrowX = player.getX() + dx / distance * viewpoint.platform.Tuning.findArrowRadius;
            float arrowZ = player.getY() + dz / distance * viewpoint.platform.Tuning.findArrowRadius;
            float localSceneLift = sceneLift(lift, arrowX, arrowZ);
            float groundArrowOffset = (float) ForageTuningBridge.nativeGroundArrowOffset();
            float arrowY = playerHeight + localSceneLift + groundArrowOffset;

            // Convert the arrow-to-pin vector to camera screen axes, then find the
            // horizontal world direction that projects along that same screen ray.
            // The rendered camera can add yaw, pitch, and roll through its shot.
            // Use those offsets as well as the base view so the world arrow tracks
            // the same screen-space ray outside the default north-facing view.
            float yaw = frame.viewYaw + frame.cameraShot.addYaw;
            float pitch = frame.viewPitch + frame.cameraShot.addPitch;
            float roll = frame.cameraShot.addRoll;
            float sinYaw = (float) Math.sin(yaw);
            float cosYaw = (float) Math.cos(yaw);
            float sinPitch = (float) Math.sin(pitch);
            float cosPitch = (float) Math.cos(pitch);
            float baseRightX = sinYaw;
            float baseRightY = 0.0f;
            float baseRightZ = -cosYaw;
            float baseUpX = cosYaw * sinPitch;
            float baseUpY = cosPitch;
            float baseUpZ = sinYaw * sinPitch;
            float cosRoll = (float) Math.cos(roll);
            float sinRoll = (float) Math.sin(roll);
            float rightX = baseRightX * cosRoll - baseUpX * sinRoll;
            float rightY = baseRightY * cosRoll - baseUpY * sinRoll;
            float rightZ = baseRightZ * cosRoll - baseUpZ * sinRoll;
            float upX = baseUpX * cosRoll + baseRightX * sinRoll;
            float upY = baseUpY * cosRoll + baseRightY * sinRoll;
            float upZ = baseUpZ * cosRoll + baseRightZ * sinRoll;

            float targetX = arrowX - pinX;
            float targetY = arrowY - pinHeight;
            float targetZ = arrowZ - pinZ;
            float screenX = targetX * rightX + targetZ * rightZ;
            float screenY = targetX * upX + targetY * upY + targetZ * upZ;
            float determinant = rightX * upZ - rightZ * upX;
            if (Math.abs(determinant) < 1.0e-4f) {
                traceFallback("camera-projection-singular");
                return false;
            }

            float worldX = (screenX * upZ - rightZ * screenY) / determinant;
            float worldZ = (rightX * screenY - upX * screenX) / determinant;
            if (Math.abs(worldX) + Math.abs(worldZ) < 1.0e-5f) {
                traceFallback("zero-projection-vector");
                return false;
            }
            float angle = (float) Math.atan2(worldZ, worldX);

            frame.scene.groundDraws.arrow(
                    frame.camX - arrowX,
                    arrowY,
                    frame.camY - arrowZ,
                    angle,
                    frame.camX - pinX,
                    pinHeight,
                    frame.camY - pinZ,
                    shown[index]);
            traceProjection(index, groundArrowOffset, playerHeight, localSceneLift, arrowY, pinHeight);
            return true;
        } catch (Throwable error) {
            traceFallback("exception:" + error.getClass().getName());
            if (!warned) {
                warned = true;
                System.err.println("[ChilaSeda Viewpoint foraging arrow] Projection fallback: " + error);
            }
            return false;
        }
    }

    // ZombieBuddy injects this helper call into viewpoint.interact.ForageFinds,
    // so the transformed caller must be able to invoke it across packages.
    public static Field field(String name) throws ReflectiveOperationException {
        Field value;
        if ("xs".equals(name)) value = xsField;
        else if ("ys".equals(name)) value = ysField;
        else value = shownField;
        if (value != null) return value;

        Class<?> owner = Class.forName("viewpoint.interact.ForageFinds");
        value = owner.getDeclaredField(name);
        value.setAccessible(true);
        if ("xs".equals(name)) xsField = value;
        else if ("ys".equals(name)) ysField = value;
        else shownField = value;
        return value;
    }

    public static float sceneLift(FarRelief.Lift lift, double x, double y) throws ReflectiveOperationException {
        if (lift == null) return 0.0f;
        Object result = lift.getClass().getMethod("scene", double.class, double.class).invoke(lift, x, y);
        return ((Number) result).floatValue();
    }

    private ForagingArrowCameraProjection() { }
}
