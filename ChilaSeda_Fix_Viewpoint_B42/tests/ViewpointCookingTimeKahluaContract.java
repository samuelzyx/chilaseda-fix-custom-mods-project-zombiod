import java.nio.file.Files;
import java.nio.file.Path;

import se.krka.kahlua.j2se.J2SEPlatform;
import se.krka.kahlua.luaj.compiler.LuaCompiler;
import se.krka.kahlua.vm.KahluaTable;
import se.krka.kahlua.vm.KahluaThread;
import se.krka.kahlua.vm.LuaClosure;

public final class ViewpointCookingTimeKahluaContract {
    public static void main(String[] args) throws Exception {
        Path luaPath = Path.of(args[0]);
        String lua = Files.readString(luaPath);
        J2SEPlatform platform = new J2SEPlatform();
        KahluaTable environment = platform.newEnvironment();
        LuaClosure chunk = LuaCompiler.loadstring(lua, luaPath.toString(), environment);
        KahluaThread thread = new KahluaThread(platform, environment);
        thread.debugOwnerThread = Thread.currentThread();
        thread.call(chunk, new Object[0]);
        Object result = environment.rawget("CONTRACT_RESULT");
        if (!Boolean.TRUE.equals(result)) {
            Object diagnostics = environment.rawget("CONTRACT_DIAGNOSTICS");
            if (diagnostics instanceof String text) System.out.println(text);
            throw new AssertionError("Viewpoint cooking time contract failed: "
                    + environment.rawget("CONTRACT_ERROR"));
        }
        System.out.println("Viewpoint cooking time Kahlua contract passed");
        Object diagnostics = environment.rawget("CONTRACT_DIAGNOSTICS");
        if (diagnostics instanceof String text) System.out.println(text);
    }
}
