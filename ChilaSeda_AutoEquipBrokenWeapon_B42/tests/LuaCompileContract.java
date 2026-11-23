import java.nio.file.Files;
import java.nio.file.Path;

import se.krka.kahlua.j2se.J2SEPlatform;
import se.krka.kahlua.luaj.compiler.LuaCompiler;
import se.krka.kahlua.vm.KahluaTable;
import se.krka.kahlua.vm.KahluaThread;
import se.krka.kahlua.vm.LuaClosure;

public final class LuaCompileContract {
    public static void main(String[] args) throws Exception {
        Path luaPath = Path.of(args[0]);
        String lua = Files.readString(luaPath);
        J2SEPlatform platform = new J2SEPlatform();
        KahluaTable environment = platform.newEnvironment();
        LuaClosure chunk = LuaCompiler.loadstring(lua, luaPath.toString(), environment);
        boolean compileOnly = args.length > 1 && "--compile-only".equals(args[1]);
        if (!compileOnly) {
            KahluaThread thread = new KahluaThread(platform, environment);
            thread.debugOwnerThread = Thread.currentThread();
            thread.call(chunk, new Object[0]);
        }
        System.out.println((compileOnly ? "Kahlua syntax compile passed: " : "Kahlua contract passed: ") + luaPath);
    }
}
