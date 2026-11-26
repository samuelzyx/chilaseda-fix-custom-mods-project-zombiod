package chilaseda.viewpointhalo;

import java.lang.reflect.Field;
import java.nio.IntBuffer;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;

import me.zed_0xff.zombie_buddy.Patch;
import org.lwjgl.BufferUtils;
import org.lwjgl.opengl.GL11;
import org.lwjgl.opengl.GL30;
import zombie.core.Core;

/** Captures bounded OpenGL state around Viewpoint's camera-to-screen handover. */
@Patch(
        className = "viewpoint.render.HandOver",
        methodName = "draw",
        warmUp = true,
        strictMatch = false)
public final class ViewpointHandoverViewportTrace {
    private static final String TAG = "[ChilaSedaViewpointViewportTrace]";
    private static final long SAMPLE_INTERVAL_NANOS = 5_000_000_000L;
    private static final int MAX_SAMPLES = 120;
    private static final AtomicBoolean HOOK_REPORTED = new AtomicBoolean();
    private static final AtomicInteger SAMPLE_COUNT = new AtomicInteger();
    private static final AtomicLong NEXT_SAMPLE_NANOS = new AtomicLong();
    private static final ThreadLocal<Sample> ACTIVE_SAMPLE = new ThreadLocal<>();

    @Patch.OnEnter
    public static void beforeHandover() {
        runBeforeHandover();
    }

    /** The injected target calls this public bridge; private trace state stays inside this class. */
    public static void runBeforeHandover() {
        if (SAMPLE_COUNT.get() >= MAX_SAMPLES || !sampleWindowOpen()) return;
        String due = readHandoverDue();
        if (HOOK_REPORTED.compareAndSet(false, true)) {
            System.out.println(TAG + " hook-active due=" + due + " intervalSeconds=5 maxSamples=" + MAX_SAMPLES);
        }
        if ("false".equals(due)) return;

        int sequence = claimSample();
        if (sequence == 0) return;

        State before = readState();
        ACTIVE_SAMPLE.set(new Sample(sequence, due, before));
        System.out.println(TAG + " handover.enter seq=" + sequence + " due=" + due
                + " " + before.format());
    }

    @Patch.OnExit(onThrowable = Throwable.class)
    public static void afterHandover(@Patch.Thrown Throwable failure) {
        runAfterHandover(failure);
    }

    /** The injected target calls this public bridge; private trace state stays inside this class. */
    public static void runAfterHandover(Throwable failure) {
        Sample sample = ACTIVE_SAMPLE.get();
        ACTIVE_SAMPLE.remove();
        if (sample == null) return;

        State after = readState();
        String failureName = failure == null ? "none" : failure.getClass().getName();
        System.out.println(TAG + " handover.exit seq=" + sample.sequence
                + " stateChanged=" + !sample.before.sameOpenGlState(after)
                + " failure=" + failureName + " " + after.format());
    }

    private static boolean sampleWindowOpen() {
        long now = System.nanoTime();
        while (true) {
            long next = NEXT_SAMPLE_NANOS.get();
            if (now < next) return false;
            if (NEXT_SAMPLE_NANOS.compareAndSet(next, now + SAMPLE_INTERVAL_NANOS)) {
                return true;
            }
        }
    }

    private static int claimSample() {
        while (true) {
            int current = SAMPLE_COUNT.get();
            if (current >= MAX_SAMPLES) return 0;
            if (SAMPLE_COUNT.compareAndSet(current, current + 1)) return current + 1;
        }
    }

    private static String readHandoverDue() {
        try {
            ClassLoader loader = Thread.currentThread().getContextClassLoader();
            Class<?> handOver = loader == null
                    ? Class.forName("viewpoint.render.HandOver")
                    : Class.forName("viewpoint.render.HandOver", false, loader);
            Field due = handOver.getDeclaredField("due");
            if (!due.trySetAccessible()) return "unavailable";
            return Boolean.toString(due.getBoolean(null));
        } catch (Throwable ignored) {
            return "unavailable";
        }
    }

    private static State readState() {
        try {
            int[] viewport = readVector(GL11.GL_VIEWPORT);
            int[] scissor = readVector(GL11.GL_SCISSOR_BOX);
            Core core = Core.getInstance();
            int screenWidth = core == null ? -1 : core.getScreenWidth();
            int screenHeight = core == null ? -1 : core.getScreenHeight();
            int offscreenWidth = core == null ? -1 : core.getOffscreenTrueWidth();
            int offscreenHeight = core == null ? -1 : core.getOffscreenTrueHeight();
            int drawFramebuffer = GL11.glGetInteger(GL30.GL_DRAW_FRAMEBUFFER_BINDING);
            boolean scissorEnabled = GL11.glIsEnabled(GL11.GL_SCISSOR_TEST);
            boolean blendEnabled = GL11.glIsEnabled(GL11.GL_BLEND);
            return new State(viewport, scissor, scissorEnabled, blendEnabled,
                    drawFramebuffer, screenWidth, screenHeight, offscreenWidth, offscreenHeight, null);
        } catch (Throwable failure) {
            return State.unavailable(failure.getClass().getName());
        }
    }

    private static int[] readVector(int key) {
        IntBuffer values = BufferUtils.createIntBuffer(4);
        GL11.glGetIntegerv(key, values);
        return new int[] {values.get(0), values.get(1), values.get(2), values.get(3)};
    }

    public static String formatStateForTests(
            int[] viewport, int[] scissor, boolean scissorEnabled, boolean blendEnabled,
            int drawFramebuffer, int screenWidth, int screenHeight,
            int offscreenWidth, int offscreenHeight) {
        return new State(viewport, scissor, scissorEnabled, blendEnabled, drawFramebuffer,
                screenWidth, screenHeight, offscreenWidth, offscreenHeight, null).format();
    }

    public static boolean viewportMatchesScreenForTests(int[] viewport, int screenWidth, int screenHeight) {
        return viewport != null && screenWidth >= 0 && screenHeight >= 0
                && viewport[0] == 0 && viewport[1] == 0
                && viewport[2] == screenWidth && viewport[3] == screenHeight;
    }

    private static final class State {
        private final int[] viewport;
        private final int[] scissor;
        private final boolean scissorEnabled;
        private final boolean blendEnabled;
        private final int drawFramebuffer;
        private final int screenWidth;
        private final int screenHeight;
        private final int offscreenWidth;
        private final int offscreenHeight;
        private final String error;

        State(
                int[] viewport,
                int[] scissor,
                boolean scissorEnabled,
                boolean blendEnabled,
                int drawFramebuffer,
                int screenWidth,
                int screenHeight,
                int offscreenWidth,
                int offscreenHeight,
                String error) {
            this.viewport = viewport;
            this.scissor = scissor;
            this.scissorEnabled = scissorEnabled;
            this.blendEnabled = blendEnabled;
            this.drawFramebuffer = drawFramebuffer;
            this.screenWidth = screenWidth;
            this.screenHeight = screenHeight;
            this.offscreenWidth = offscreenWidth;
            this.offscreenHeight = offscreenHeight;
            this.error = error;
        }

        static State unavailable(String error) {
            return new State(null, null, false, false, -1, -1, -1, -1, -1, error);
        }

        boolean sameOpenGlState(State other) {
            if (other == null) return false;
            return vectorEquals(viewport, other.viewport)
                    && vectorEquals(scissor, other.scissor)
                    && scissorEnabled == other.scissorEnabled
                    && blendEnabled == other.blendEnabled
                    && drawFramebuffer == other.drawFramebuffer;
        }

        String format() {
            return "viewport=" + vector(viewport)
                    + " scissor=" + (scissorEnabled ? "on:" : "off:") + vector(scissor)
                    + " blend=" + blendEnabled
                    + " drawFbo=" + drawFramebuffer
                    + " screen=" + screenWidth + "x" + screenHeight
                    + " offscreen=" + offscreenWidth + "x" + offscreenHeight
                    + (error == null ? "" : " readError=" + error);
        }

        private static String vector(int[] values) {
            return values == null ? "unavailable"
                    : values[0] + "," + values[1] + "," + values[2] + "," + values[3];
        }

        private static boolean vectorEquals(int[] left, int[] right) {
            if (left == null || right == null) return left == right;
            return left[0] == right[0] && left[1] == right[1]
                    && left[2] == right[2] && left[3] == right[3];
        }
    }

    private static final class Sample {
        private final int sequence;
        private final String due;
        private final State before;

        Sample(int sequence, String due, State before) {
            this.sequence = sequence;
            this.due = due;
            this.before = before;
        }
    }

    private ViewpointHandoverViewportTrace() { }
}
