import java.nio.file.Files;
import java.nio.file.Path;

import se.krka.kahlua.j2se.J2SEPlatform;
import se.krka.kahlua.luaj.compiler.LuaCompiler;
import se.krka.kahlua.vm.KahluaTable;
import se.krka.kahlua.vm.KahluaThread;
import se.krka.kahlua.vm.LuaClosure;

public final class CombatGesturesKahluaContract {
    private static final String PRELUDE = """
            require = function(_) end
            print = function(_) end
            getTimestampMs = function() return 200 end
            local noopEvent = { Add = function(_) end }
            Events = { OnTick = noopEvent, OnMouseDown = noopEvent, OnGameStart = noopEvent }
            ISUIElement = {}
            function ISUIElement:derive(_) return {} end
            function ISUIElement:new()
                return {
                    initialise = function(_) end,
                    addToUIManager = function(_) end,
                    removeFromUIManager = function(_) end,
                    backMost = function(_) end,
                }
            end
            """;

    private static final String ASSERTIONS = """
            local function point(x, y) return { x = x, y = y } end
            local function expectGesture(points, length, turn, expectedKind, expectedLabel, startedAt)
                local kind, label = classifyStroke({ points = points, length = length, turn = turn, startedAt = startedAt or 0 })
                assert(kind == expectedKind, "unexpected gesture kind for " .. tostring(expectedLabel) .. ": " .. tostring(kind))
                assert(label == expectedLabel, "unexpected gesture label for " .. tostring(expectedLabel) .. ": " .. tostring(label))
            end
            expectGesture({ point(0, 0), point(-50, 0), point(-100, 0) }, 100, 0, "swing", "BOLADO")
            expectGesture({ point(0, 0), point(0, 50), point(0, 100) }, 100, 0, "overhead", "VERTICAL")
            expectGesture({ point(0, 0), point(50, -50), point(100, -100) }, 150, 0.3, "backhand", "REVES")
            expectGesture({ point(0, 0), point(0, -20), point(100, -100) }, 250, 1.6, "execute", "EJECUCION")
            expectGesture({ point(0, 0), point(10, 0), point(20, 0) }, 20, 0, nil, nil)
            expectGesture({ point(0, 0), point(-50, 0), point(-100, 0) }, 100, 0, nil, nil, -1000)
            """;

    public static void main(String[] args) throws Exception {
        String lua = Files.readString(Path.of(args[0]));
        J2SEPlatform platform = new J2SEPlatform();
        KahluaTable environment = platform.newEnvironment();
        LuaClosure chunk = LuaCompiler.loadstring(PRELUDE + lua + ASSERTIONS,
                "ViewpointCombatGestures.contract.lua", environment);
        KahluaThread thread = new KahluaThread(platform, environment);
        thread.debugOwnerThread = Thread.currentThread();
        thread.call(chunk, new Object[0]);
        System.out.println("Kahlua gesture contracts passed: " + args[0]);
    }
}
