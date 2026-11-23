import java.lang.reflect.Field;

import chilaseda.viewpointhalo.ForageTuningBridge;

public final class ForageTuningBridgeContract {
    private static void assertNear(double actual, double expected, String label) {
        if (Math.abs(actual - expected) > 0.0001) {
            throw new AssertionError(label + " expected=" + expected + " actual=" + actual);
        }
    }

    public static void main(String[] args) throws Exception {
        if (!ForageTuningBridge.isNativeTuningAvailable()) {
            throw new AssertionError("bridge unavailable: " + ForageTuningBridge.nativeTuningStatus());
        }
        Class<?> tuning = Class.forName("viewpoint.platform.Tuning");
        Field height = tuning.getDeclaredField("findPinHeight");
        Field up = tuning.getDeclaredField("findPinUp");
        height.setAccessible(true);
        up.setAccessible(true);

        double baseHeight = ForageTuningBridge.nativeFindPinHeightBase();
        double baseUp = ForageTuningBridge.nativeFindPinUpBase();
        assertNear(height.getFloat(null), baseHeight, "baseline pin height");
        assertNear(up.getFloat(null), baseUp, "baseline pin lift");

        try {
            double testHeight = baseHeight * 0.91;
            double testUp = baseUp + 2.5;
            if (!ForageTuningBridge.setNativePinTuning(testHeight, testUp)) {
                throw new AssertionError("bridge rejected valid tuning values: "
                        + ForageTuningBridge.nativeTuningStatus());
            }
            assertNear(height.getFloat(null), testHeight, "written pin height");
            assertNear(up.getFloat(null), testUp, "written pin lift");
            if (ForageTuningBridge.setNativePinTuning(Double.NaN, testUp)) {
                throw new AssertionError("bridge accepted a NaN tuning value");
            }
        } finally {
            if (!ForageTuningBridge.setNativePinTuning(baseHeight, baseUp)) {
                throw new AssertionError("bridge could not restore native tuning values");
            }
        }

        double baseArrowOffset = ForageTuningBridge.nativeGroundArrowOffset();
        assertNear(baseArrowOffset, 0.0, "baseline ground arrow offset");
        try {
            if (!ForageTuningBridge.setNativeGroundArrowOffset(2.5)) {
                throw new AssertionError("bridge rejected a valid ground arrow offset");
            }
            assertNear(ForageTuningBridge.nativeGroundArrowOffset(), 2.5,
                    "written ground arrow offset");
            if (ForageTuningBridge.setNativeGroundArrowOffset(Double.NaN)
                    || ForageTuningBridge.setNativeGroundArrowOffset(64.1)) {
                throw new AssertionError("bridge accepted an invalid ground arrow offset");
            }
        } finally {
            if (!ForageTuningBridge.setNativeGroundArrowOffset(baseArrowOffset)) {
                throw new AssertionError("bridge could not restore the ground arrow offset");
            }
        }
        System.out.println("Native forage tuning bridge contracts passed");
    }
}
