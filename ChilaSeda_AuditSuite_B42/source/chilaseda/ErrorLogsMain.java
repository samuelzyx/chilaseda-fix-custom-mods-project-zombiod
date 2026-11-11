package chilaseda;

import me.zed_0xff.zombie_buddy.Exposer;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

@Exposer.LuaClass(name = "ChilaErrorLogJ")
public final class ErrorLogsMain {
    private static final DateTimeFormatter FILE_DATE = DateTimeFormatter.ofPattern("yyyy-MM-dd_HH-mm-ss");
    private static final Map<String, Entry> ERRORS = new LinkedHashMap<>();
    private static Path sessionPath;
    private static String id, started, settings = "", failure = "";
    private static boolean dirty, shutdownRegistered, active;

    private static final class Entry {
        final String text, first;
        String last;
        long count;
        Entry(String text, long count, String timestamp) {
            this.text = text;
            this.count = count;
            first = last = timestamp;
        }
    }

    public static synchronized String beginGame(String header) {
        try {
            Class<?> fs = Class.forName("zombie.ZomboidFileSystem");
            Object instance = fs.getField("instance").get(null);
            String cache = (String) fs.getMethod("getCacheDir").invoke(instance);
            return begin(cache, header);
        } catch (Exception error) {
            failure = error.toString();
            return "";
        }
    }

    public static synchronized String begin(String cacheDir, String header) {
        try {
            if (active && !flush()) return "";
            Path root = Paths.get(cacheDir).toAbsolutePath().normalize().resolve("mods");
            if (!Files.isDirectory(root)) throw new IOException("mods directory unavailable: " + root);
            Path directory = root.resolve("ErrorLogs");
            Files.createDirectories(directory);
            String newId = UUID.randomUUID().toString().substring(0, 8);
            Path newPath = directory.resolve("Error_" + FILE_DATE.format(LocalDateTime.now()) + "_" + newId + ".txt");
            ERRORS.clear();
            id = newId;
            started = OffsetDateTime.now().toString();
            settings = header == null ? "" : header;
            sessionPath = newPath;
            dirty = active = true;
            failure = "";
            if (!shutdownRegistered) {
                Runtime.getRuntime().addShutdownHook(new Thread(Main::flush, "ChilaErrorLogs-shutdown"));
                shutdownRegistered = true;
            }
            return sessionPath.toString();
        } catch (Exception error) {
            failure = error.toString();
            return "";
        }
    }

    public static synchronized boolean record(String text, String occurrences) {
        if (!active || text == null || text.isBlank()) return false;
        try {
            long count = Long.parseLong(occurrences);
            if (count <= 0) return false;
            String now = OffsetDateTime.now().toString();
            Entry entry = ERRORS.get(text);
            if (entry == null) {
                ERRORS.put(text, new Entry(text, count, now));
            } else {
                entry.count = Math.addExact(entry.count, count);
                entry.last = now;
            }
            dirty = true;
            return true;
        } catch (RuntimeException error) {
            failure = error.toString();
            return false;
        }
    }

    private static String report() {
        StringBuilder text = new StringBuilder("CHILASEDA ERROR MAGNIFIER SESSION REPORT\n");
        text.append("Session: ").append(id).append('\n');
        text.append("Started: ").append(started).append('\n');
        text.append("Updated: ").append(OffsetDateTime.now()).append("\n\n");
        text.append(settings).append('\n');
        text.append("Distinct errors: ").append(ERRORS.size()).append('\n');
        text.append("Each trace appears once; xN counts all observed repetitions.\n\n");
        if (ERRORS.isEmpty()) text.append("No errors detected in this game session.\n");
        int index = 0;
        for (Entry entry : ERRORS.values()) {
            text.append("=== Error #").append(++index).append(" (x").append(entry.count).append(") ===\n");
            text.append("First observed: ").append(entry.first).append('\n');
            text.append("Last observed: ").append(entry.last).append('\n');
            text.append(entry.text).append("\n\n");
        }
        return text.toString();
    }

    private static void replaceFile(Path target, byte[] bytes) throws IOException {
        Path temporary = target.resolveSibling(target.getFileName() + ".tmp");
        Files.write(temporary, bytes);
        try {
            Files.move(temporary, target, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE);
        } catch (AtomicMoveNotSupportedException unsupported) {
            Files.move(temporary, target, StandardCopyOption.REPLACE_EXISTING);
        }
    }

    public static synchronized boolean flush() {
        if (sessionPath == null) return false;
        if (!dirty) return true;
        try {
            replaceFile(sessionPath, report().getBytes(StandardCharsets.UTF_8));
            dirty = false;
            failure = "";
            return true;
        } catch (IOException error) {
            failure = error.toString();
            return false;
        }
    }

    public static synchronized boolean endGame() {
        if (!active) return true;
        if (!flush()) return false;
        active = false;
        return true;
    }

    public static synchronized String lastError() { return failure; }
    public static synchronized String sessionFile() { return sessionPath == null ? "" : sessionPath.toString(); }
}
