package chilaseda.viewpointhalo;

import me.zed_0xff.zombie_buddy.Patch;

@Patch(className = "viewpoint.platform.SettingsPages$Page", methodName = "line", warmUp = true)
public final class ViewpointSettingsPageLine {
    @Patch.OnExit
    public static void translateVisibleLine(
            @Patch.This Object page,
            @Patch.Return(readOnly = false) String value) {
        value = ViewpointSettingsPageScope.pageLine(page, value);
    }

    private ViewpointSettingsPageLine() { }
}
