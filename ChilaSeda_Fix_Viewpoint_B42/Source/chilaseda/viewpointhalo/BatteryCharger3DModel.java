package chilaseda.viewpointhalo;

import me.zed_0xff.zombie_buddy.Patch;
import viewpoint.packs.ModelPacks;
import viewpoint.packs.PackBind;
import viewpoint.render.PackModel;
import zombie.iso.IsoObject;
import zombie.iso.objects.IsoCarBatteryCharger;

/** Supplies authored third-person models for empty and connected battery chargers. */
@Patch(className = "viewpoint.packs.ModelPacks", methodName = "bind", warmUp = true, strictMatch = false)
public final class BatteryCharger3DModel {
    private static final String MOD_ID = "ChilaSeda_Fix_Viewpoint_B42";
    private static final String PACK_ID = "chilaseda-battery-charger";
    private static final String MANIFEST = "media/models/battery_charger/package.properties";
    private static volatile boolean registered;
    private static volatile boolean warned;
    private static volatile PackBind emptyBind;
    private static volatile PackBind connectedBind;

    @Patch.OnEnter(skipOn = true)
    public static boolean skipSpriteBindingForCharger(@Patch.Argument(0) IsoObject object) {
        return object instanceof IsoCarBatteryCharger && bindFor((IsoCarBatteryCharger) object) != null;
    }

    @Patch.OnExit
    public static void provideChargerModel(
            @Patch.Argument(0) IsoObject object,
            @Patch.Return(readOnly = false) PackBind result) {
        if (object instanceof IsoCarBatteryCharger) {
            PackBind bind = bindFor((IsoCarBatteryCharger) object);
            if (bind != null) result = bind;
        }
    }

    private static PackBind bindFor(IsoCarBatteryCharger charger) {
        if (!registerPack()) return null;

        boolean connected = charger.getBattery() != null;
        PackBind cached = connected ? connectedBind : emptyBind;
        if (cached != null) return cached;

        String modelId = connected ? "charger_connected" : "charger_empty";
        PackModel model = ModelPacks.model(PACK_ID, modelId);
        if (model == null) {
            warnOnce("could not resolve model pack entry " + modelId);
            return null;
        }

        cached = new PackBind(model, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f);
        if (connected) connectedBind = cached;
        else emptyBind = cached;
        return cached;
    }

    private static boolean registerPack() {
        if (registered) return true;
        synchronized (BatteryCharger3DModel.class) {
            if (registered) return true;
            try {
                registered = ModelPacks.register(MOD_ID, MANIFEST);
                if (!registered) warnOnce("ModelPacks.register returned false for " + MANIFEST);
            } catch (RuntimeException exception) {
                warnOnce("model pack registration failed: " + exception.getClass().getSimpleName());
            }
        }
        return registered;
    }

    private static void warnOnce(String message) {
        if (warned) return;
        warned = true;
        System.out.println("[ChilaSeda Viewpoint] " + message);
    }

    private BatteryCharger3DModel() { }
}
