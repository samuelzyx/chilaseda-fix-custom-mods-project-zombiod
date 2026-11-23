package chilaseda.viewpointhalo;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.util.HashSet;
import java.util.Set;

public final class StrictModifierKeyDiagnosticsContract {
    private static void check(boolean condition, String message) {
        if (!condition) throw new AssertionError(message);
    }

    public static void main(String[] args) {
        PrintStream originalOut = System.out;
        ByteArrayOutputStream captured = new ByteArrayOutputStream();
        Set<Integer> loggedKeys = new HashSet<>();
        int keyH = org.lwjglx.input.Keyboard.KEY_H;
        try (PrintStream capture = new PrintStream(captured, true, StandardCharsets.UTF_8)) {
            System.setOut(capture);

            check(!StrictModifierKeyBindings.shouldSuppress(null),
                    "a null binding should fall back to vanilla handling");
            check(!StrictModifierKeyBindings.shouldSuppress(null),
                    "repeated null bindings should keep the vanilla fallback");

            check(!StrictModifierKeyBindings.logModifierTransition(
                    "CTRL", false, false, false, false), "stable released Ctrl should not log");
            check(StrictModifierKeyBindings.logModifierTransition(
                    "CTRL", true, false, false, false), "left Ctrl press should log");
            check(!StrictModifierKeyBindings.logModifierTransition(
                    "CTRL", true, false, true, false), "held left Ctrl should not spam logs");
            check(StrictModifierKeyBindings.logModifierTransition(
                    "CTRL", false, true, true, false), "switching Ctrl sides should log");
            check(StrictModifierKeyBindings.logModifierTransition(
                    "CTRL", false, false, false, true), "Ctrl release should log");

            check(StrictModifierKeyBindings.logSuppressedBinding(keyH, true, true,
                    true, false, false, false, false, false, loggedKeys),
                    "first suppressed H press should log");
            check(!StrictModifierKeyBindings.logSuppressedBinding(keyH, true, true,
                    true, false, false, false, false, false, loggedKeys),
                    "held H should not spam logs");
            check(!StrictModifierKeyBindings.logSuppressedBinding(keyH, false, false,
                    false, false, false, false, false, false, loggedKeys),
                    "H release should clear the per-press marker without logging");
            check(StrictModifierKeyBindings.logSuppressedBinding(keyH, true, true,
                    true, false, false, false, false, false, loggedKeys),
                    "a later H press should log again");
        } finally {
            System.setOut(originalOut);
        }

        String log = captured.toString(StandardCharsets.UTF_8);
        check(log.contains("Core.invalidBindingShiftCtrl delegated to modifier helper"),
                "missing one-time hook delegation trace");
        check(countOccurrences(log, "modifier helper fallback=allow reason=null-binding") == 1,
                "null binding fallback should be logged once");
        check(log.contains("modifier=CTRL leftDown=true rightDown=false active=true"),
                "missing left Ctrl transition values");
        check(log.contains("modifier=CTRL leftDown=false rightDown=true active=true"),
                "missing right Ctrl transition values");
        check(log.contains("modifier=CTRL leftDown=false rightDown=false active=false"),
                "missing Ctrl release values");
        check(log.contains("base binding suppressed keyCode=" + keyH
                        + " heldModifiers=[ctrl:true,alt:false,shift:false]"
                        + " bindingModifiers=[ctrl:false,alt:false,shift:false]"),
                "missing suppressed H binding values");
        check(countOccurrences(log, "base binding suppressed keyCode=") == 2,
                "expected one suppression log per H press");
        System.out.println("Strict modifier diagnostics contracts passed");
    }

    private static int countOccurrences(String value, String token) {
        int count = 0;
        int offset = 0;
        while ((offset = value.indexOf(token, offset)) >= 0) {
            count++;
            offset += token.length();
        }
        return count;
    }
}
