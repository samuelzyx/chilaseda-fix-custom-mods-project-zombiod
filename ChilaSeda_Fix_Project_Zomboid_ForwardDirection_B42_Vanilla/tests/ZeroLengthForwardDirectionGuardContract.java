package chilaseda.viewpointfixes.forwarddirection;

import zombie.iso.Vector2;
import java.lang.reflect.Method;

public final class ZeroLengthForwardDirectionGuardContract {
    private static void check(boolean condition, String message) {
        if (!condition) throw new AssertionError(message);
    }

    public static void main(String[] args) {
        try {
            Class<?> guard = Class.forName(
                    "chilaseda.viewpointfixes.forwarddirection.ZeroLengthForwardDirectionGuard");
            Method shouldSkip = guard.getDeclaredMethod("shouldSkip", Vector2.class);
            shouldSkip.setAccessible(true);
            check((boolean) shouldSkip.invoke(null, new Vector2(0.0f, 0.0f)),
                    "zero vector should skip vanilla setter and preserve current facing");
            check(!(boolean) shouldSkip.invoke(null, new Vector2(0.0001f, 0.0f)),
                    "nonzero vector must pass through unchanged, including small vectors");
            check(!(boolean) shouldSkip.invoke(null, new Vector2(1.0f, -1.0f)),
                    "ordinary direction vector must pass through unchanged");
            check(!(boolean) shouldSkip.invoke(null, new Object[] { null }),
                    "null is not treated as a zero vector; preserve vanilla null behavior");
        } catch (ReflectiveOperationException exception) {
            throw new AssertionError("could not invoke the compiled guard contract", exception);
        }
        System.out.println("Zero-length forward-direction contract passed");
    }
}
