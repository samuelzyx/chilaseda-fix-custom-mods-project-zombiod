package chilaseda.viewpointhalo;

import me.zed_0xff.zombie_buddy.Patch;

@Patch(className = "zombie.iso.IsoCell", methodName = "render")
public final class SearchFogAfterSnapshot {
    @Patch.OnExit
    public static void applyFog() {
        SearchFogBridge.apply();
    }
}
