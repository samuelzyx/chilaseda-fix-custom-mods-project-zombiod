package chilaseda.viewpointhalo;

import java.util.concurrent.atomic.AtomicBoolean;

import me.zed_0xff.zombie_buddy.Patch;

/** Skips far-relief grading before the JVM is close to exhausting its heap. */
@Patch(className = "viewpoint.far.ReliefSweeps", methodName = "graded", warmUp = true, strictMatch = false)
public final class ReliefSweepsHeapGuard {
    public static final long MIN_HEADROOM_BYTES = 384L * 1024L * 1024L;
    public static final long TARGET_HEADROOM_BYTES = 1536L * 1024L * 1024L;
    public static final AtomicBoolean WARNED = new AtomicBoolean();

    @Patch.OnEnter(skipOn = true)
    public static boolean skipIfInsufficientHeap() {
        return shouldSkipGrading();
    }

    public static boolean shouldSkipGrading() {
        Runtime runtime = Runtime.getRuntime();
        long used = runtime.totalMemory() - runtime.freeMemory();
        long available = Math.max(0L, runtime.maxMemory() - used);
        long threshold = Math.max(MIN_HEADROOM_BYTES,
                Math.min(TARGET_HEADROOM_BYTES, runtime.maxMemory() / 2L));
        if (available >= threshold) return false;

        if (WARNED.compareAndSet(false, true)) {
            System.out.println("[ChilaSeda Viewpoint] Relief heap guard skipped relief pass: headroomMiB="
                    + (available / (1024L * 1024L))
                    + ", thresholdMiB=" + (threshold / (1024L * 1024L))
                    + ", maxHeapMiB=" + (runtime.maxMemory() / (1024L * 1024L)));
        }
        return true;
    }

    private ReliefSweepsHeapGuard() { }
}
