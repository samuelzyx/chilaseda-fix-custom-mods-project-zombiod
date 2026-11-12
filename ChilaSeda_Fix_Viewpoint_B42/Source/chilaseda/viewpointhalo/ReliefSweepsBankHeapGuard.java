package chilaseda.viewpointhalo;

import me.zed_0xff.zombie_buddy.Patch;

/** Skips bank scratch allocations when the relief heap guard is active. */
@Patch(className = "viewpoint.far.ReliefSweeps", methodName = "bank", warmUp = true, strictMatch = false)
public final class ReliefSweepsBankHeapGuard {
    @Patch.OnEnter(skipOn = true)
    public static boolean skipIfInsufficientHeap() {
        return ReliefSweepsHeapGuard.shouldSkipGrading();
    }

    private ReliefSweepsBankHeapGuard() { }
}
