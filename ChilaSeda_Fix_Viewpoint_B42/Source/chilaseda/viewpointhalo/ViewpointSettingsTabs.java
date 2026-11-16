package chilaseda.viewpointhalo;

import me.zed_0xff.zombie_buddy.Patch;

/** Translates visible tab labels while leaving page-and-index widget IDs intact. */
@Patch(className = "viewpoint.platform.Widgets", methodName = "pages", warmUp = true)
public final class ViewpointSettingsTabs {
    @Patch.OnEnter
    public static void translateVisibleTabs(@Patch.Argument(value = 1, readOnly = false) String[] labels) {
        if (labels == null) return;
        for (int i = 0; i < labels.length; i++) {
            labels[i] = ViewpointSettingsPageScope.translate(labels[i]);
        }
    }

    private ViewpointSettingsTabs() { }
}
