package chilaseda.viewpointhalo;

import me.zed_0xff.zombie_buddy.Patch;
import org.lwjglx.input.Keyboard;
import zombie.core.Core;
import zombie.input.GameKeyboard;
import java.util.HashSet;
import java.util.Set;

/** Treats held modifiers as part of a key chord instead of also firing its base key. */
@Patch(className = "zombie.core.Core", methodName = "invalidBindingShiftCtrl", warmUp = true)
public final class StrictModifierKeyBindings {
    private static final String LOG_TAG = "[ChilaSedaViewpointHalo]";
    private static final Set<Integer> LOGGED_SUPPRESSED_KEYS = new HashSet<>();
    private static boolean lastCtrlLeftDown;
    private static boolean lastCtrlRightDown;
    private static boolean lastAltLeftDown;
    private static boolean lastAltRightDown;
    private static boolean lastShiftLeftDown;
    private static boolean lastShiftRightDown;
    private static boolean loggedHelperCall;
    private static boolean loggedNullBindingFallback;

    @Patch.OnEnter(skipOn = true)
    public static boolean rejectBaseBindingWhenExtraModifierIsDown(
            @Patch.Argument(0) Core.KeyBinding binding) {
        return shouldSuppress(binding);
    }

    /** Called by the injected Core hook so its bytecode never reads this class's private state. */
    public static boolean shouldSuppress(Core.KeyBinding binding) {
        if (!loggedHelperCall) {
            System.out.println(LOG_TAG + " Core.invalidBindingShiftCtrl delegated to modifier helper");
            loggedHelperCall = true;
        }
        if (binding == null) {
            if (!loggedNullBindingFallback) {
                System.out.println(LOG_TAG + " modifier helper fallback=allow reason=null-binding");
                loggedNullBindingFallback = true;
            }
            return false;
        }

        int key = binding.keyValue();
        boolean ctrlDown = isDown(Keyboard.KEY_LCONTROL, Keyboard.KEY_RCONTROL);
        boolean altDown = isDown(Keyboard.KEY_LMENU, Keyboard.KEY_RMENU);
        boolean shiftDown = isDown(Keyboard.KEY_LSHIFT, Keyboard.KEY_RSHIFT);

        boolean ctrlIsKey = key == Keyboard.KEY_LCONTROL || key == Keyboard.KEY_RCONTROL;
        boolean altIsKey = key == Keyboard.KEY_LMENU || key == Keyboard.KEY_RMENU;
        boolean shiftIsKey = key == Keyboard.KEY_LSHIFT || key == Keyboard.KEY_RSHIFT;

        boolean rejected = (ctrlDown && !ctrlIsKey && !binding.ctrl())
                || (altDown && !altIsKey && !binding.alt())
                || (shiftDown && !shiftIsKey && !binding.shift());

        if (rejected || LOGGED_SUPPRESSED_KEYS.contains(key)) {
            boolean keyDown = GameKeyboard.isKeyDownRaw(key);
            logSuppressedBinding(key, rejected, keyDown, ctrlDown, altDown, shiftDown,
                    binding.ctrl(), binding.alt(), binding.shift(), LOGGED_SUPPRESSED_KEYS);
        }
        return rejected;
    }

    public static boolean isDown(int left, int right) {
        boolean leftDown = GameKeyboard.isKeyDownRaw(left);
        boolean rightDown = GameKeyboard.isKeyDownRaw(right);
        if (left == Keyboard.KEY_LCONTROL && right == Keyboard.KEY_RCONTROL
                && logModifierTransition("CTRL", leftDown, rightDown,
                        lastCtrlLeftDown, lastCtrlRightDown)) {
            lastCtrlLeftDown = leftDown;
            lastCtrlRightDown = rightDown;
        } else if (left == Keyboard.KEY_LMENU && right == Keyboard.KEY_RMENU
                && logModifierTransition("ALT", leftDown, rightDown,
                        lastAltLeftDown, lastAltRightDown)) {
            lastAltLeftDown = leftDown;
            lastAltRightDown = rightDown;
        } else if (left == Keyboard.KEY_LSHIFT && right == Keyboard.KEY_RSHIFT
                && logModifierTransition("SHIFT", leftDown, rightDown,
                        lastShiftLeftDown, lastShiftRightDown)) {
            lastShiftLeftDown = leftDown;
            lastShiftRightDown = rightDown;
        }
        return leftDown || rightDown;
    }

    static boolean logModifierTransition(String modifier, boolean leftDown, boolean rightDown,
            boolean previousLeftDown, boolean previousRightDown) {
        if (leftDown == previousLeftDown && rightDown == previousRightDown) return false;
        System.out.println(LOG_TAG + " modifier=" + modifier + " leftDown=" + leftDown
                + " rightDown=" + rightDown + " active=" + (leftDown || rightDown));
        return true;
    }

    static boolean logSuppressedBinding(int key, boolean rejected, boolean keyDown,
            boolean ctrlDown, boolean altDown, boolean shiftDown,
            boolean bindingCtrl, boolean bindingAlt, boolean bindingShift,
            Set<Integer> loggedKeys) {
        if (!keyDown) {
            loggedKeys.remove(key);
            return false;
        }
        if (!rejected || !loggedKeys.add(key)) return false;
        System.out.println(LOG_TAG + " base binding suppressed keyCode=" + key
                + " heldModifiers=[ctrl:" + ctrlDown + ",alt:" + altDown + ",shift:" + shiftDown
                + "] bindingModifiers=[ctrl:" + bindingCtrl + ",alt:" + bindingAlt
                + ",shift:" + bindingShift + "]");
        return true;
    }

    private StrictModifierKeyBindings() { }
}
