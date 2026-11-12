package chilaseda.viewpointhalo;

import me.zed_0xff.zombie_buddy.Patch;

/** Skips TownPaving's scratch arrays when the far-relief heap guard is active. */
@Patch(className = "viewpoint.far.TownPaving", methodName = "join", warmUp = true, strictMatch = false)
public final class TownPavingJoinHeapGuard {
    @Patch.OnEnter(skipOn = true)
    public static boolean skipIfInsufficientHeap() {
        return ReliefSweepsHeapGuard.shouldSkipGrading();
    }

    private TownPavingJoinHeapGuard() { }
}
