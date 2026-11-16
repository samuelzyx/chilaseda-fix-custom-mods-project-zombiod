package chilaseda.viewpointhalo;

import me.zed_0xff.zombie_buddy.Patch;

/** Localizes captions immediately before the Viewpoint widget draws them. */
@Patch(className = "viewpoint.platform.Widgets", methodName = "caption", warmUp = true)
public final class ViewpointSettingsCaption {
    @Patch.OnEnter
    public static void translateCaption(@Patch.Argument(value = 0, readOnly = false) String value) {
        value = ViewpointSettingsPageScope.translate(value);
    }

    private ViewpointSettingsCaption() { }
}
