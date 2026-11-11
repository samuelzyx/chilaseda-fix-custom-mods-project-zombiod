package chilaseda.viewpointhalo;

import me.zed_0xff.zombie_buddy.Patch;

@Patch(className = "zombie.characters.HaloTextHelper", methodName = "addText", warmUp = true)
public final class SkillLevelHaloSuppressor {
    @Patch.OnEnter(skipOn = true)
    public static boolean suppressNativeSkillLevelHalo(@Patch.Argument(1) String text) {
        return text != null
                && text.contains("]+1 ")
                && text.contains("[/] [img=media/ui/ArrowUp.png,");
    }
}
