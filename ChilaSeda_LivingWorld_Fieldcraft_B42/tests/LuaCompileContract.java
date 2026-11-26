import java.nio.file.Files;
import java.nio.file.Path;

import se.krka.kahlua.j2se.J2SEPlatform;
import se.krka.kahlua.luaj.compiler.LuaCompiler;
import se.krka.kahlua.vm.KahluaTable;

public final class LuaCompileContract {
    public static void main(String[] args) throws Exception {
        Path luaPath = Path.of(args[0]);
        KahluaTable environment = new J2SEPlatform().newEnvironment();
        LuaCompiler.loadstring(Files.readString(luaPath), luaPath.toString(), environment);
        System.out.println("Living World Fieldcraft Kahlua syntax compile passed: " + luaPath);
    }
}
