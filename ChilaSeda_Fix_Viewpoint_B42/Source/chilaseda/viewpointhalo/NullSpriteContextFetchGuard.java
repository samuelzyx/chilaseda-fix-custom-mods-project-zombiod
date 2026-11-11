package chilaseda.viewpointhalo;

import me.zed_0xff.zombie_buddy.Patch;
import zombie.iso.IsoObject;
import zombie.iso.sprite.IsoSprite;

/** Skips invalid world objects before Viewpoint's context menu reaches the vanilla fetch logic. */
@Patch(className = "zombie.iso.ISWorldObjectContextMenuLogic", methodName = "fetch", warmUp = true)
public final class NullSpriteContextFetchGuard {
    private static volatile boolean warned;

    @Patch.OnEnter(skipOn = true)
    public static boolean skipObjectWithoutSpriteName(@Patch.Argument(1) IsoObject object) {
        if (object == null) {
            warnOnce("null world object");
            return true;
        }

        IsoSprite sprite = object.getSprite();
        if (sprite != null && sprite.getName() != null) return false;

        warnOnce(object.getClass().getName());
        return true;
    }

    public static void warnOnce(String objectType) {
        if (warned) return;
        warned = true;
        System.out.println("[ChilaSeda Viewpoint] Skipped world-object menu fetch without a sprite name: " + objectType);
    }

    private NullSpriteContextFetchGuard() { }
}
