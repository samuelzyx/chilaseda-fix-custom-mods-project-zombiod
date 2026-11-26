import java.nio.file.Files;
import java.nio.file.Path;

import se.krka.kahlua.j2se.J2SEPlatform;
import se.krka.kahlua.luaj.compiler.LuaCompiler;
import se.krka.kahlua.vm.KahluaTable;
import se.krka.kahlua.vm.LuaClosure;

public final class LuaCompileContract {
    public static void main(String[] args) throws Exception {
        Path luaPath = Path.of(args[0]);
        String lua = Files.readString(luaPath);
        J2SEPlatform platform = new J2SEPlatform();
        KahluaTable environment = platform.newEnvironment();
        LuaClosure chunk = LuaCompiler.loadstring(lua, luaPath.toString(), environment);
        System.out.println("Map symbols Kahlua syntax compile passed: " + luaPath);
    }
}
