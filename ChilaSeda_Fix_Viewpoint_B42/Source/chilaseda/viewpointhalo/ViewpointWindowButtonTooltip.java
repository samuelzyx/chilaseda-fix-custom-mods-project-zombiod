package chilaseda.viewpointhalo;

import me.zed_0xff.zombie_buddy.Patch;

/** Localizes the separate tooltip argument without changing the button ID. */
@Patch(className = "viewpoint.platform.Icons", methodName = "windowButton", warmUp = true)
public final class ViewpointWindowButtonTooltip {
    @Patch.OnEnter
    public static void translateTooltip(@Patch.Argument(value = 3, readOnly = false) String value) {
        value = ViewpointSettingsPageScope.translate(value);
    }

    private ViewpointWindowButtonTooltip() { }
}
