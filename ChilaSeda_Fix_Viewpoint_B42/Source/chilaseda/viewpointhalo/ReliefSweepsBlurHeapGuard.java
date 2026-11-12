package chilaseda.viewpointhalo;

import me.zed_0xff.zombie_buddy.Patch;

/** Reuses the unblurred input instead of allocating a result under heap pressure. */
@Patch(className = "viewpoint.far.ReliefSweeps", methodName = "blurred", warmUp = true)
public final class ReliefSweepsBlurHeapGuard {
    @Patch.OnEnter(skipOn = true)
    public static boolean skipIfInsufficientHeap() {
        return ReliefSweepsHeapGuard.shouldSkipGrading();
    }

    @Patch.OnExit
    public static void reuseInputIfSkipped(
            @Patch.Return(readOnly = false) float[] result,
            @Patch.Argument(0) float[] input) {
        if (result == null && input != null && ReliefSweepsHeapGuard.shouldSkipGrading()) {
            result = input;
        }
    }

    private ReliefSweepsBlurHeapGuard() { }
}
