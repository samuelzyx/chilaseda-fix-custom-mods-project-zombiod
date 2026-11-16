package chilaseda.viewpointhalo;

import me.zed_0xff.zombie_buddy.Patch;
import org.luaj.kahluafork.compiler.FuncState;

/** Logs the source path when the Lua compiler throws before its error can be formatted. */
@Patch(
        className = "se.krka.kahlua.luaj.compiler.LuaCompiler",
        methodName = "loadis",
        warmUp = true,
        strictMatch = false)
public final class LuaCompileFailureTrace {
    @Patch.OnExit(onThrowable = Throwable.class)
    public static void logFailedChunk(
            @Patch.Argument(1) String chunkName,
            @Patch.Thrown Throwable failure) {
        if (failure == null) return;

        String path = FuncState.currentfullFile;
        System.err.println("[ChilaSedaLuaCompileFailure] file=" + path
                + " chunk=" + chunkName
                + " exception=" + failure.getClass().getName());
    }

    private LuaCompileFailureTrace() { }
}
