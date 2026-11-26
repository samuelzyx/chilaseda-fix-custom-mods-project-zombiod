package chilaseda.viewpointhalo;

import me.zed_0xff.zombie_buddy.Patch;

@Patch(className = "viewpoint.platform.LiveSettings$Choice", methodName = "labels", warmUp = true)
public final class ViewpointChoiceLabels {
    @Patch.OnExit
    public static void translate(@Patch.Return(readOnly = false) String[] labels) {
        labels = ViewpointSettingsPageScope.translateLabels(labels);
    }

    private ViewpointChoiceLabels() { }
}
