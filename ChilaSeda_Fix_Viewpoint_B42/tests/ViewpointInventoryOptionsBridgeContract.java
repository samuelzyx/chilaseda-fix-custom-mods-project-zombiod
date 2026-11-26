import chilaseda.viewpointhalo.ViewpointInventoryOptionsBridge;
import viewpoint.interact.InventorySettings;
import viewpoint.platform.LiveSettings;

public final class ViewpointInventoryOptionsBridgeContract {
    public static void main(String[] args) {
        require(ViewpointInventoryOptionsBridge.integratedInventoryEnabled() == 1,
                "bridge must read the native enabled setting");

        require(ViewpointInventoryOptionsBridge.setIntegratedInventoryEnabled(false) == 1,
                "successful native save must report success");
        require(!InventorySettings.UI.get(), "successful apply must update the native toggle");

        int beforeFailure = LiveSettings.saveCalls();
        LiveSettings.setSaveResult(false);
        require(ViewpointInventoryOptionsBridge.setIntegratedInventoryEnabled(true) == 0,
                "failed settings save must report a recoverable failure");
        require(!InventorySettings.UI.get(), "failed save must roll the native toggle back");
        require(LiveSettings.saveCalls() == beforeFailure + 2,
                "failed apply must attempt persistence, then persist the rollback");

        LiveSettings.setSaveResult(true);
        require(ViewpointInventoryOptionsBridge.setIntegratedInventoryEnabled(true) == 1,
                "bridge must remain usable after rolling back a failed save");
        require(InventorySettings.UI.get(), "successful retry must update the native toggle");
        System.out.println("Viewpoint inventory bridge contract passed");
    }

    private static void require(boolean condition, String message) {
        if (!condition) throw new AssertionError(message);
    }

    private ViewpointInventoryOptionsBridgeContract() { }
}
