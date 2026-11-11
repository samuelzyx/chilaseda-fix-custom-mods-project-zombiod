package chilaseda.viewpointroofsfix;

import java.util.concurrent.atomic.AtomicBoolean;

import me.zed_0xff.zombie_buddy.Patch;
import zombie.iso.IsoGridSquare;

@Patch(className = "zombie.iso.IsoGridSquare", methodName = "AddTileObject", warmUp = true)
public final class AddTileObjectChunkGuard {
    private static final AtomicBoolean REPORTED = new AtomicBoolean(false);

    @Patch.OnEnter(skipOn = true)
    public static boolean beforeAddTileObject(@Patch.This IsoGridSquare square) {
        if (square != null && square.getChunk() != null) {
            return false;
        }

        if (REPORTED.compareAndSet(false, true)) {
            System.out.println("[ChilaSeda Viewpoint Roofs Fix] skipped AddTileObject because square.chunk was null");
        }
        return true;
    }
}
