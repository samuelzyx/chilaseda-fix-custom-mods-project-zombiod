package viewpoint.platform;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;

import chilaseda.viewpointhalo.ViewpointGraphicsApplyTrace;

public final class ViewpointGraphicsApplyTraceContract {
    public static void main(String[] args) throws Exception {
        PrintStream original = System.out;
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        try (PrintStream capture = new PrintStream(output, true, StandardCharsets.UTF_8)) {
            System.setOut(capture);
            ViewpointGraphicsApplyTrace.shownReader = () -> "true";
            ViewpointGraphicsApplyTrace.START_NANOS.set(System.nanoTime());
            if (!"true".equals(ViewpointGraphicsApplyTrace.settingsShown())) {
                throw new AssertionError("injected settings reader should be visible across packages");
            }
            ViewpointGraphicsApplyTrace.beforeApply();
            ViewpointGraphicsApplyTrace.afterApply(true, null);

            ViewpointGraphicsApplyTrace.shownReader = () -> {
                throw new IllegalStateException("settings bridge unavailable");
            };
            ViewpointGraphicsApplyTrace.beforeApply();
            ViewpointGraphicsApplyTrace.afterApply(false, new IllegalArgumentException("probe"));
        } finally {
            System.setOut(original);
            ViewpointGraphicsApplyTrace.START_NANOS.remove();
        }

        String trace = output.toString(StandardCharsets.UTF_8);
        if (!trace.contains("graphics.apply enter settingsShown=true")
                || !trace.contains("graphics.apply exit durationMs=")
                || !trace.contains("result=changed failure=none")
                || !trace.contains("graphics.apply enter settingsShown=unavailable")
                || !trace.contains("result=failed failure=java.lang.IllegalArgumentException")) {
            throw new AssertionError("settings apply trace missed transition, timing, or failure fallback: " + trace);
        }
        System.out.println("Viewpoint graphics apply trace contracts passed");
    }

    private ViewpointGraphicsApplyTraceContract() { }
}
