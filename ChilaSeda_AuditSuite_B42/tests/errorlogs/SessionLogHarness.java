package chilaseda.errorlogs;

import chilaseda.ErrorLogsMain;

import java.nio.file.*;
import java.nio.charset.StandardCharsets;
import java.util.stream.Stream;

public final class SessionLogHarness {
    private static void check(boolean condition, String name) {
        if (!condition) throw new AssertionError(name);
    }
    private static int occurrences(String value, String text) {
        int count = 0, index = 0;
        while ((index = value.indexOf(text, index)) >= 0) { count++; index += text.length(); }
        return count;
    }
    public static void main(String[] args) throws Exception {
        Path cache = Paths.get(args[0]).toAbsolutePath().normalize();
        Path mods = Files.createDirectories(cache.resolve("mods"));
        Path oldReport = mods.resolve("Errors.txt");
        Files.writeString(oldReport, "EXISTING MANUAL REPORT", StandardCharsets.UTF_8);
        String header = "=== Zomboid Settings ===\nVersion: fixture\nMode: SINGLE PLAYER\n";
        Path first = Paths.get(ErrorLogsErrorLogsMain.begin(cache.toString(), header));
        check(first.getParent().equals(mods.resolve("ErrorLogs")), "output directory");
        check(first.getFileName().toString().matches("Error_\\d{4}-\\d{2}-\\d{2}_\\d{2}-\\d{2}-\\d{2}_[a-f0-9]{8}\\.txt"), "filename");
        check(ErrorLogsErrorLogsMain.flush(), "initial report");
        check(Files.readString(first).contains("No errors detected"), "empty session");
        String a = "Lua((MOD:Hunter Expansion)).filthOf(HE_Detect.lua:105)\njava.lang.RuntimeException: Tried to call nil\n";
        String b = "Lua((MOD:Prueba española)).call(Test.lua:2)\njava.lang.RuntimeException: Otro fallo\n";
        check(ErrorLogsErrorLogsMain.record(a, "10") && ErrorLogsErrorLogsMain.record(a, "2") && ErrorLogsErrorLogsMain.record(b, "1"), "record counts");
        check(ErrorLogsErrorLogsMain.flush(), "first write");
        String report = Files.readString(first, StandardCharsets.UTF_8);
        check(report.contains("Distinct errors: 2") && report.contains("(x12)"), "unique error totals");
        check(occurrences(report, a) == 1 && occurrences(report, b) == 1, "one full trace per error");
        check(report.contains("First observed:") && report.contains("Last observed:"), "dates");
        for (int i = 0; i < 5000; i++) check(ErrorLogsMain.record(a, "1"), "repeat");
        check(ErrorLogsMain.flush(), "repeat write");
        report = Files.readString(first, StandardCharsets.UTF_8);
        check(report.contains("(x5012)") && occurrences(report, a) == 1, "5000 repetitions stay one entry");
        check(report.length() < 10000, "report does not grow with repeated stack bodies");
        check(ErrorLogsMain.endGame() && !ErrorLogsMain.record(a, "1"), "closed session");
        String preservedFirst = Files.readString(first);
        Path second = Paths.get(ErrorLogsMain.begin(cache.toString(), header));
        check(!second.equals(first), "separate session, even in same second/JVM");
        check(ErrorLogsMain.flush() && Files.readString(second).contains("Distinct errors: 0"), "new session reset");
        check(Files.readString(first).equals(preservedFirst), "previous session retained");
        check(Files.readString(oldReport).equals("EXISTING MANUAL REPORT"), "no Errors.txt mirror or modification");
        // A directory at the report path forces a real replacement failure on disk.
        Files.delete(second);
        Files.createDirectory(second);
        check(ErrorLogsMain.record(b, "3") && !ErrorLogsMain.flush(), "real I/O failure returned, not thrown");
        check(!ErrorLogsMain.lastError().isEmpty(), "I/O diagnostic");
        Files.delete(second);
        check(ErrorLogsMain.flush(), "retry after failure");
        report = Files.readString(second, StandardCharsets.UTF_8);
        check(report.contains("(x3)") && occurrences(report, b) == 1, "retry retains data without duplication");
        try (Stream<Path> files = Files.list(mods.resolve("ErrorLogs"))) {
            check(files.filter(Files::isRegularFile).count() == 2, "exactly one final file per game session");
        }
        check(ErrorLogsMain.endGame(), "finish");
        System.out.println("PASS Java: dated per-game-session files, unique traces, xN counters, timestamps, UTF-8, 5000 repeats, I/O retry, prior sessions retained, no Errors.txt copy.");
    }
}
