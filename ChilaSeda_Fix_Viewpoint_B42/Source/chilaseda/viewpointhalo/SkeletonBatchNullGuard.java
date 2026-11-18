package chilaseda.viewpointhalo;

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.concurrent.atomic.AtomicBoolean;

import me.zed_0xff.zombie_buddy.Patch;

/** Clears a corrupt Viewpoint skeleton batch before its null slot crashes the update loop. */
@Patch(className = "viewpoint.sim.SkeletonPort", methodName = "animated", warmUp = true)
public final class SkeletonBatchNullGuard {
    public static volatile Field batchField;
    public static volatile Field takenField;
    public static volatile Field countField;
    public static volatile Method clearMethod;
    public static final AtomicBoolean WARNED = new AtomicBoolean();

    @Patch.OnEnter(skipOn = true)
    public static boolean clearBatchWhenSlotIsMissing() {
        try {
            Class<?> port = Class.forName("viewpoint.sim.SkeletonPort");
            Field batchRef = field(port, "batch", batchField);
            batchField = batchRef;
            Object batch = batchRef.get(null);
            if (batch == null) return false;

            Field countRef = field(batch.getClass(), "count", countField);
            countField = countRef;
            int count = countRef.getInt(batch);
            if (count <= 0) return false;

            Field takenRef = field(port, "taken", takenField);
            takenField = takenRef;
            Object[] taken = (Object[]) takenRef.get(null);
            boolean missing = taken == null || count > taken.length;
            if (!missing) {
                for (int i = 0; i < count; i++) {
                    if (taken[i] == null) {
                        missing = true;
                        break;
                    }
                }
            }
            if (!missing) return false;

            Method reset = clearMethod;
            if (reset == null) {
                reset = port.getMethod("clear");
                clearMethod = reset;
            }
            reset.invoke(null);
            warnOnce("cleared an incomplete zombie skeleton batch; Viewpoint will use the normal animation path");
            return true;
        } catch (ReflectiveOperationException | RuntimeException exception) {
            warnOnce("could not inspect/reset zombie skeleton batch: " + exception.getClass().getSimpleName());
            return false;
        }
    }

    public static Field field(Class<?> owner, String name, Field cached) throws ReflectiveOperationException {
        if (cached != null) return cached;
        Field result = owner.getDeclaredField(name);
        result.setAccessible(true);
        return result;
    }

    public static void warnOnce(String message) {
        if (WARNED.compareAndSet(false, true)) {
            System.out.println("[ChilaSeda Viewpoint] " + message);
        }
    }

    private SkeletonBatchNullGuard() { }
}