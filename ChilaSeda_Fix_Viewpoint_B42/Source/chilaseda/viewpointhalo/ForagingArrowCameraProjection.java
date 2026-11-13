package chilaseda.viewpointhalo;

import java.lang.reflect.Field;

import me.zed_0xff.zombie_buddy.Patch;
import viewpoint.core.Frame;
import viewpoint.render.FarRelief;
import zombie.characters.IsoPlayer;

/** Re-aims Viewpoint's 3D foraging arrow at the pin as projected by the active camera. */
@Patch(className = "viewpoint.interact.ForageFinds", methodName = "arrow", warmUp = true)
public final class ForagingArrowCameraProjection {
    private static volatile Field xsField;
    private static volatile Field ysField;
    private static volatile Field shownField;
    private static volatile boolean warned;

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
        if (!SearchFogBridge.nativeForageEnabled()) return false;
        try {
            int[] xs = (int[]) field("xs").get(null);
            int[] ys = (int[]) field("ys").get(null);
            boolean[] shown = (boolean[]) field("shown").get(null);
            if (index < 0 || index >= xs.length || index >= ys.length || index >= shown.length) {
                return false;
            }

            float pinX = xs[index] + 0.5f;
            float pinZ = ys[index] + 0.5f;
            float dx = pinX - player.getX();
            float dz = pinZ - player.getY();
            float distance = (float) Math.hypot(dx, dz);
            if (distance < 1.0e-5f) return false;

            float arrowX = player.getX() + dx / distance * viewpoint.platform.Tuning.findArrowRadius;
            float arrowZ = player.getY() + dz / distance * viewpoint.platform.Tuning.findArrowRadius;
            float arrowY = playerHeight + sceneLift(lift, arrowX, arrowZ);

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
            if (Math.abs(determinant) < 1.0e-4f) return false;

            float worldX = (screenX * upZ - rightZ * screenY) / determinant;
            float worldZ = (rightX * screenY - upX * screenX) / determinant;
            if (Math.abs(worldX) + Math.abs(worldZ) < 1.0e-5f) return false;
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
            return true;
        } catch (Throwable error) {
            if (!warned) {
                warned = true;
                System.err.println("[ChilaSeda Viewpoint foraging arrow] Projection fallback: " + error);
            }
            return false;
        }
    }

    private static Field field(String name) throws ReflectiveOperationException {
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

    private static float sceneLift(FarRelief.Lift lift, double x, double y) throws ReflectiveOperationException {
        if (lift == null) return 0.0f;
        Object result = lift.getClass().getMethod("scene", double.class, double.class).invoke(lift, x, y);
        return ((Number) result).floatValue();
    }

    private ForagingArrowCameraProjection() { }
}
