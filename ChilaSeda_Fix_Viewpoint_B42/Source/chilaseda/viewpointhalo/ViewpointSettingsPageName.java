package chilaseda.viewpointhalo;

import me.zed_0xff.zombie_buddy.Patch;

@Patch(className = "viewpoint.platform.SettingsPages$Page", methodName = "name", warmUp = true)
public final class ViewpointSettingsPageName {
    @Patch.OnExit
    public static void translateVisibleName(
            @Patch.This Object page,
            @Patch.Return(readOnly = false) String value) {
        value = ViewpointSettingsPageScope.pageName(page, value);
    }

    private ViewpointSettingsPageName() { }
}
