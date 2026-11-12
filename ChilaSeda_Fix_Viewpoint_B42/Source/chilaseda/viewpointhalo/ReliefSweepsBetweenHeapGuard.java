package chilaseda.viewpointhalo;

import me.zed_0xff.zombie_buddy.Patch;

/** Skips between-sweep scratch allocations when the relief heap guard is active. */
@Patch(className = "viewpoint.far.ReliefSweeps", methodName = "between", warmUp = true, strictMatch = false)
public final class ReliefSweepsBetweenHeapGuard {
    @Patch.OnEnter(skipOn = true)
    public static boolean skipIfInsufficientHeap() {
        return ReliefSweepsHeapGuard.shouldSkipGrading();
    }

    private ReliefSweepsBetweenHeapGuard() { }
}
