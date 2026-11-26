package viewpoint.platform;

public final class LiveSettings {
    private static boolean saveResult = true;
    private static int saveCalls;

    public static boolean save() {
        saveCalls++;
        return saveResult;
    }

    public static void setSaveResult(boolean result) {
        saveResult = result;
    }

    public static int saveCalls() {
        return saveCalls;
    }

    public static final class Toggle {
        private volatile boolean value;

        public Toggle(boolean initial) {
            value = initial;
        }

        public boolean get() {
            return value;
        }

        public void set(boolean next) {
            value = next;
        }
    }

    private LiveSettings() { }
}
