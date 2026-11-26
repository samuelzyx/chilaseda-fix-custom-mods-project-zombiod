package chilaseda.viewpointhalo;

import me.zed_0xff.zombie_buddy.Patch;

@Patch(className = "viewpoint.platform.LiveSettings$Setting", methodName = "<init>", warmUp = true)
public final class ViewpointSettingLabels {
    @Patch.OnEnter
    public static void translate(
            @Patch.Argument(value = 1, readOnly = false) String label,
            @Patch.Argument(value = 2, readOnly = false) String section) {
        label = ViewpointSettingsPageScope.translate(label);
        section = ViewpointSettingsPageScope.translate(section);
    }

    private ViewpointSettingLabels() { }
}
