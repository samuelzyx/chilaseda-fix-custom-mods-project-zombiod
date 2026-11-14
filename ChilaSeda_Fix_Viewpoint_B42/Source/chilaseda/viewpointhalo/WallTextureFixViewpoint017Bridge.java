package chilaseda.viewpointhalo;

import java.lang.reflect.Method;
import java.util.concurrent.atomic.AtomicBoolean;

import me.zed_0xff.zombie_buddy.Patch;

/** Adapts Viewpoint 0.1.7's inserted square argument to Wall Texture Fix's renderer API. */
@Patch(className = "viewpoint.world.WallMesher", methodName = "wall", warmUp = true, strictMatch = false)
public final class WallTextureFixViewpoint017Bridge {
    private static volatile Method renderer;
    private static final AtomicBoolean WARNED = new AtomicBoolean();

    @Patch.OnEnter(skipOn = true)
    public static boolean renderWithAddon(
            @Patch.Argument(0) Object object,
            @Patch.Argument(1) Object sprite,
            @Patch.Argument(2) Object mesh,
            @Patch.Argument(3) Object texture,
            @Patch.Argument(4) Object square,
            @Patch.Argument(5) float x,
            @Patch.Argument(6) float y,
            @Patch.Argument(7) float z,
            @Patch.Argument(8) boolean exterior,
            @Patch.Argument(9) boolean[] flags) {
        if (square == null || !"zombie.iso.IsoGridSquare".equals(square.getClass().getName())) return false;

        try {
            Method method = renderer;
            if (method == null) {
                Class<?> type = Class.forName("walltexturefixforviewpoint.Renderer", false,
                        Thread.currentThread().getContextClassLoader());
                method = type.getMethod("wall", Object.class, Object.class, Object.class, Object.class,
                        float.class, float.class, float.class, boolean.class, boolean[].class);
                renderer = method;
            }
            return (Boolean) method.invoke(null, object, sprite, mesh, texture, x, y, z, exterior, flags);
        } catch (ReflectiveOperationException | LinkageError | ClassCastException exception) {
            if (WARNED.compareAndSet(false, true)) {
                System.out.println("[ChilaSeda Viewpoint] Wall Texture Fix 0.1.7 bridge inactive: "
                        + exception.getClass().getSimpleName() + ": " + exception.getMessage());
            }
            return false;
        }
    }

    private WallTextureFixViewpoint017Bridge() { }
}
