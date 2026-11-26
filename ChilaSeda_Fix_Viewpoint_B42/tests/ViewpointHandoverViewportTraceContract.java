package viewpoint.render;

import chilaseda.viewpointhalo.ViewpointHandoverViewportTrace;
import java.util.function.Consumer;

public final class ViewpointHandoverViewportTraceContract {
    public static void main(String[] args) {
        // This package matches Viewpoint's target. The injected methods are
        // deliberately thin calls into public bridges, which own private state.
        Runnable enterAdvice = ViewpointHandoverViewportTrace::beforeHandover;
        Consumer<Throwable> exitAdvice = ViewpointHandoverViewportTrace::afterHandover;
        require(enterAdvice != null && exitAdvice != null,
                "injected advice entry points must be public");

        int[] fullScreenViewport = new int[] {0, 0, 1920, 1080};
        require(ViewpointHandoverViewportTrace.viewportMatchesScreenForTests(
                        fullScreenViewport, 1920, 1080),
                "full-screen viewport must match the display");

        int[] partialViewport = new int[] {0, 0, 1280, 720};
        require(!ViewpointHandoverViewportTrace.viewportMatchesScreenForTests(
                        partialViewport, 1920, 1080),
                "partial camera viewport must be distinguished from the display");

        String formatted = ViewpointHandoverViewportTrace.formatStateForTests(
                partialViewport, partialViewport, true, false, 11,
                1920, 1080, 1280, 720);
        require(formatted.contains("viewport=0,0,1280,720"), "viewport must be logged");
        require(formatted.contains("scissor=on:0,0,1280,720"), "scissor state must be logged");
        require(formatted.contains("drawFbo=11"), "draw framebuffer must be logged");
        require(formatted.contains("screen=1920x1080 offscreen=1280x720"),
                "display and offscreen dimensions must be logged");
        System.out.println("Viewpoint handover viewport trace contracts passed");
    }

    private static void require(boolean condition, String message) {
        if (!condition) throw new AssertionError(message);
    }

    private ViewpointHandoverViewportTraceContract() { }
}
