package chilaseda.viewpointhalo;

import java.lang.reflect.Field;
import java.util.concurrent.atomic.AtomicBoolean;

import me.zed_0xff.zombie_buddy.Patch;

/** Returns no menu icon when a charger has no sprite, preserving its other actions. */
@Patch(className = "zombie.iso.objects.IsoCarBatteryCharger", methodName = "getTexture", warmUp = true)
public final class CarBatteryChargerTextureGuard {
    private static volatile Field chargerSpriteField;
    private static final AtomicBoolean WARNED = new AtomicBoolean();

    @Patch.OnEnter(skipOn = true)
    public static boolean skipWhenSpriteIsMissing(@Patch.This Object charger) {
        // A skipped reference-returning method keeps its JVM default (null). Patch.Return
        // is only valid in OnExit; using it here made ZombieBuddy reject this advice.
        return !hasChargerSprite(charger);
    }

    /** Called by injected bytecode, so keep this method public across the game package boundary. */
    public static boolean hasChargerSprite(Object charger) {
        if (charger == null) return false;
        try {
            Field field = chargerSpriteField;
            if (field == null) {
                field = charger.getClass().getDeclaredField("chargerSprite");
                field.setAccessible(true);
                chargerSpriteField = field;
            }
            if (field.get(charger) != null) return true;
            warnOnce("chargerSprite is null; returning no texture");
            return false;
        } catch (ReflectiveOperationException | RuntimeException exception) {
            warnOnce("could not inspect chargerSprite: " + exception.getClass().getSimpleName());
            return true;
        }
    }

    private static void warnOnce(String message) {
        if (WARNED.compareAndSet(false, true)) {
            System.out.println("[ChilaSeda Viewpoint] " + message);
        }
    }

    private CarBatteryChargerTextureGuard() { }
}
