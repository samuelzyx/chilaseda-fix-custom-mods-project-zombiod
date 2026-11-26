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
            local fakeClock = 200
            local fakeControlDown = false
            local fakeLeftDown = false
            local mouseDX, mouseDY = 0, 0
            local fakeArmCount, fakeArmClock, fakeClickClock = 0, nil, nil
            local overlayAlwaysOnTop, overlayBroughtToTop = false, false
            getTimestampMs = function() return fakeClock end
            local noopEvent = { Add = function(_) end }
            Events = { OnTick = noopEvent, OnMouseDown = noopEvent, OnGameStart = noopEvent }
            ISUIElement = {}
            function ISUIElement:derive(_) return {} end
            function ISUIElement:new()
                return {
                    initialise = function(_) end,
                    addToUIManager = function(_) end,
                    removeFromUIManager = function(_) end,
                    setAlwaysOnTop = function(_, value) overlayAlwaysOnTop = value end,
                    bringToTop = function(_) overlayBroughtToTop = true end,
                }
            end
            """;

    private static final String ASSERTIONS = """
            local function point(x, y) return { x = x, y = y } end
            assert(overlayAlwaysOnTop and overlayBroughtToTop,
                "gesture overlay must render above the world and other UI")
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
            expectGesture({ point(0, 0), point(-50, 0), point(-100, 0) }, 100, 0, "swing", "BOLADO", -1000)

            ChilaSedaViewpointFogJ = { available = function() return true end }
            local player = { isAttackStarted = function() return false end }
            getSpecificPlayer = function(_) return player end
            Keyboard = {
                KEY_LCONTROL = 341,
                KEY_RCONTROL = 345,
                isKeyDown = function(_) return fakeControlDown end,
            }
            ChilaSedaViewpointCombatGesturesJ = {
                mouseDeltaX = function() local value = mouseDX; mouseDX = 0; return value end,
                mouseDeltaY = function() local value = mouseDY; mouseDY = 0; return value end,
                leftMouseDown = function()
                    if fakeLeftDown then fakeClickClock = fakeClock end
                    return fakeLeftDown
                end,
                armAttack = function(_, kind)
                    fakeArmCount = fakeArmCount + 1
                    fakeArmClock = fakeClock
                    return kind == "swing" and "AttackType.SWING" or "AttackType.OVERHEAD"
                end,
                restoreAttackOverride = function(_) return "restored" end,
                attackTypeName = function(_) return "AttackType.SWING" end,
            }
            isGamePaused = function() return false end
            local drawCount = 0
            local testOverlay = {
                drawRect = function(_, ...) drawCount = drawCount + 1 end,
                drawTextCentre = function(_, ...) end,
            }
            fakeControlDown = true
            mouseDX = 5
            fakeClock = fakeClock + 100
            sampleCameraGesture()
            CombatGestureOverlay.render(testOverlay)
            assert(drawCount > 0, "raw camera movement should draw a visible live stroke")
            assert(display.label == nil, "the live trace must not wait for gesture recognition")
            mouseDX = -30
            fakeClock = fakeClock + 600
            sampleCameraGesture()
            mouseDX = -30
            fakeClock = fakeClock + 600
            sampleCameraGesture()
            assert(fakeClock - stroke.startedAt > 900, "contract stroke intentionally lasts over one second")
            assert(pending and pending.kind == "swing", "slow camera stroke remains recognized")
            assert(armed and activeAttackOverride and fakeArmCount == 1,
                "vanilla attack choice must be prepared when the gesture is recognized")
            mouseDX = 60
            fakeClock = fakeClock + 100
            sampleCameraGesture()
            assert(pending and pending.kind == "swing",
                "noisy tail must not erase a recognized gesture before release")
            fakeControlDown = false
            fakeClock = fakeClock + 100
            sampleCameraGesture()
            fakeLeftDown = true
            armGestureOnClick()
            assert(armed and activeAttackOverride, "slow recognized gesture arms the next attack")
            assert(fakeArmCount == 1 and fakeArmClock < fakeClickClock,
                "the click must use a choice prepared before vanilla processes the click")
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
