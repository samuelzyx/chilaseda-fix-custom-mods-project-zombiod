package chilaseda;

import me.zed_0xff.zombie_buddy.Exposer;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

@Exposer.LuaClass(name = "ChilaWeightLogJ")
public final class WeightLogMain {
    private static final DateTimeFormatter FILE_DATE = DateTimeFormatter.ofPattern("yyyy-MM-dd_HH-mm-ss");
    private static Path sessionPath;
    private static String failure = "";
    private static boolean active;

    public static synchronized String beginGame() {
        try {
            Class<?> fs = Class.forName("zombie.ZomboidFileSystem");
            Object instance = fs.getField("instance").get(null);
            String cache = (String) fs.getMethod("getCacheDir").invoke(instance);
            Path root = Paths.get(cache).toAbsolutePath().normalize().resolve("mods").resolve("PesosLogs");
            Files.createDirectories(root);
            String id = UUID.randomUUID().toString().substring(0, 8);
            sessionPath = root.resolve("WeightMonitor_" + FILE_DATE.format(LocalDateTime.now()) + "_" + id + ".txt");
            Files.createFile(sessionPath);
            active = true;
            failure = "";
            return sessionPath.toString();
        } catch (Exception error) {
            failure = error.toString();
            return "";
        }
    }

    public static synchronized boolean append(String line) {
        if (!active || sessionPath == null || line == null) return false;
        try {
            Files.writeString(sessionPath, line + System.lineSeparator(), StandardCharsets.UTF_8,
                    StandardOpenOption.CREATE, StandardOpenOption.WRITE, StandardOpenOption.APPEND);
            failure = "";
            return true;
        } catch (IOException error) {
            failure = error.toString();
            return false;
        }
    }

    public static synchronized boolean endGame() {
        if (!active) return true;
        boolean saved = append(OffsetDateTime.now() + " SESSION_CLOSED");
        if (saved) active = false;
        return saved;
    }

    public static synchronized String lastError() { return failure; }
    public static synchronized String sessionFile() { return sessionPath == null ? "" : sessionPath.toString(); }
}
