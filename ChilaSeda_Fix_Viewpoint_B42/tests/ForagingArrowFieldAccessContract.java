package viewpoint.interact;

import chilaseda.viewpointhalo.ForagingArrowCameraProjection;
import java.lang.reflect.Field;

public final class ForagingArrowFieldAccessContract {
    public static void main(String[] args) throws Exception {
        Field field = ForagingArrowCameraProjection.field("xs");
        if (!"xs".equals(field.getName()) || !field.canAccess(null)) {
            throw new AssertionError("the injected caller could not read the forage pin field");
        }
        System.out.println("cross-package field helper access passed");
    }
}
