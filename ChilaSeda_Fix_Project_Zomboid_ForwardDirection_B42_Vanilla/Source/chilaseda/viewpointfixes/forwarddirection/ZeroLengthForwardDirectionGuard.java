package chilaseda.viewpointfixes.forwarddirection;

import java.util.concurrent.atomic.AtomicInteger;

import me.zed_0xff.zombie_buddy.Patch;
import me.zed_0xff.zombie_buddy.Patch.Argument;
import me.zed_0xff.zombie_buddy.Patch.OnEnter;
import me.zed_0xff.zombie_buddy.Patch.This;
import zombie.characters.IsoGameCharacter;
import zombie.iso.Vector2;

/** Guards the vanilla Vector2 overload while preserving its previous actor facing. */
@Patch(className = "zombie.characters.IsoGameCharacter", methodName = "setForwardDirection", warmUp = true)
public final class ZeroLengthForwardDirectionGuard {
    private static final String LOG_TAG = "[ChilaSeda_ForwardDirectionFix] ";
    private static volatile boolean TRACE_ENABLED = true;
    private static final int MAX_TRACE_LINES = 32;
    private static final AtomicInteger TRACE_LINES = new AtomicInteger();

    @OnEnter(skipOn = true)
    public static boolean skipZeroDirection(
            @This IsoGameCharacter character,
            @Argument(0) Vector2 direction) {
        if (!shouldSkip(direction)) return false;

        int traceLine = TRACE_LINES.getAndIncrement();
        if (TRACE_ENABLED && traceLine < MAX_TRACE_LINES) {
            float facingX = character == null ? Float.NaN : character.getForwardDirectionX();
            float facingY = character == null ? Float.NaN : character.getForwardDirectionY();
            String actor = character == null ? "unknown" : character.getClass().getSimpleName();
            String oldDirection = Float.isNaN(facingX) || Float.isNaN(facingY) ? "unavailable"
                    : String.format("%.4f,%.4f", facingX, facingY);
            System.out.println(LOG_TAG + "guard=zero-vector actor=" + actor
                    + " source=IsoGameCharacter.setForwardDirection(Vector2)"
                    + " fallback=preserve-current-facing current=" + oldDirection
                    + " trace=" + (traceLine + 1) + "/" + MAX_TRACE_LINES);
        }
        return true;
    }

    public static void setTraceEnabled(boolean enabled) {
        TRACE_ENABLED = enabled;
    }

    /** Public because ZombieBuddy injects the caller into zombie.characters. */
    public static boolean shouldSkip(Vector2 direction) {
        return direction != null && direction.getLengthSquared() == 0.0f;
    }

    private ZeroLengthForwardDirectionGuard() { }
}
