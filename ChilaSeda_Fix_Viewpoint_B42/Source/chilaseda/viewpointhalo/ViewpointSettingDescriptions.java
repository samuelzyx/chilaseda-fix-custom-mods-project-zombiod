package chilaseda.viewpointhalo;

import me.zed_0xff.zombie_buddy.Patch;

@Patch(className = "viewpoint.platform.LiveSettings$Setting", methodName = "describe", warmUp = true)
public final class ViewpointSettingDescriptions {
    @Patch.OnEnter
    public static void translate(@Patch.Argument(value = 0, readOnly = false) String description) {
        description = ViewpointSettingsPageScope.translate(description);
    }

    private ViewpointSettingDescriptions() { }
}
