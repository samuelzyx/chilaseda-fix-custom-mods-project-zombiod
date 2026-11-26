import java.nio.file.Files;
import java.nio.file.Path;

import se.krka.kahlua.j2se.J2SEPlatform;
import se.krka.kahlua.luaj.compiler.LuaCompiler;
import se.krka.kahlua.vm.KahluaTable;
import se.krka.kahlua.vm.KahluaThread;
import se.krka.kahlua.vm.LuaClosure;

public final class AnomalousStormHudTraceKahluaContract {
    private static final String PRELUDE = """
            local logs = {}
            print = function(message) logs[#logs + 1] = tostring(message) end
            local callbacks = {}
            Events = { OnPlayerUpdate = { Add = function(callback) callbacks[#callbacks + 1] = callback end } }
            local storm = nil
            ModData = { get = function(key) if key == "AnomalousStorm" then return storm end end }
            local nowMs = 1000
            getTimestampMs = function() return nowMs end
            local coreWidth, coreHeight, fontSize, zoomAllowed = 1920, 1080, 2, true
            local core = {
                getScreenWidth = function() return coreWidth end,
                getScreenHeight = function() return coreHeight end,
                getOptionFontSizeReal = function() return fontSize end,
                getOptionZoom = function() return zoomAllowed end,
            }
            getCore = function() return core end
            getGameTime = function() return { getWorldAgeHours = function() return 108.5 end } end
            local coreClass = { scale = 1.25, width = 1920, height = 1080 }
            local frame = { zoom = 2, offscreenWidth = 1920, offscreenHeight = 1080 }
            local playerCamera = { width = 1920, height = 1080 }
            local isoCamera = { frameState = frame, cameras = { [0] = playerCamera } }
            local provideJavaBridge = true
            if provideJavaBridge then
                luajava = { bindClass = function(name)
                    if name == "zombie.core.Core" then return coreClass end
                    if name == "zombie.iso.IsoCamera" then return isoCamera end
                    error("unexpected class " .. tostring(name))
                end }
            else
                luajava = {}
            end
            VTWJ = { getState = function(state)
                state.firstPerson, state.thirdPerson, state.view = false, true, true
                return true
            end }
            ChilaSeda_AnomalousStorm_Rect = { instance = { width = 1920, height = 1080, a = 0 } }
            local function fire() callbacks[1]() end
            local function setNow(value) nowMs = value end
            local function setStorm(value) storm = value end
            local function contains(text)
                for _, line in ipairs(logs) do
                    if string.find(line, text, 1, true) then return true end
                end
                return false
            end
            local function countContaining(text)
                local count = 0
                for _, line in ipairs(logs) do
                    if string.find(line, text, 1, true) then count = count + 1 end
                end
                return count
            end
            """;

    private static final String ASSERTIONS = """
            assert(#callbacks == 1, "HUD trace should register one player-update listener")
            assert(contains("event=loaded"), "load marker missing")
            fire()
            assert(not contains("event=cycle-start"), "inactive weather should not start a trace cycle")

            setStorm({ Active = true, RainActive = true, Thunder = false, Warning = false,
                Phase = "rain-ramping", StormAt = 108 })
            ChilaSeda_AnomalousStorm_Rect.instance.a = 0.2
            fire()
            assert(contains("event=cycle-start cycle=scheduled:108"), "storm cycle marker missing")
            assert(contains("event=sample"), "initial metric sample missing")
            assert(contains("screenW=1920") and contains("screenH=1080"), "screen dimensions missing")
            assert(contains("uiScale=1.25") and contains("fontSize=2"), "UI scale metrics missing")
            assert(contains("cameraZoom=2") and contains("cameraW=1920"), "camera metrics missing")
            assert(contains("viewThird=true") and contains("overlayAlpha=0.2"), "Viewpoint or overlay metrics missing")

            setNow(1500)
            coreClass.scale = 1.5
            frame.zoom = 3
            fire()
            assert(not contains("event=metrics-change"), "poll throttle should suppress a sub-second update")
            setNow(2100)
            fire()
            assert(contains("event=metrics-change") and contains("uiScale=1.5") and contains("cameraZoom=3"),
                "scale and camera changes should be recorded")

            setStorm({ Active = false, RainActive = false, Thunder = false, Warning = false, Phase = "idle" })
            ChilaSeda_AnomalousStorm_Rect.instance.a = 0
            setNow(3100)
            fire()
            assert(contains("event=cycle-end cycle=scheduled:108"), "storm cycle end marker missing")
            core.getOptionZoom = nil
            setStorm({ Active = true, RainActive = true, Thunder = false, Warning = false,
                Phase = "rain-ramping", StormAt = 109 })
            setNow(4100)
            fire()
            assert(contains("event=fallback api=core.zoomAllowed"), "unavailable API fallback should be logged")
            print("HUD trace contract assertions passed")
            """;

    private static final String NO_BIND_CLASS_ASSERTIONS = """
            assert(#callbacks == 1, "HUD trace should register one player-update listener")
            setStorm({ Active = true, RainActive = true, Thunder = false, Warning = false,
                Phase = "rain-ramping", StormAt = 110 })
            ChilaSeda_AnomalousStorm_Rect.instance.a = 0.2
            fire()
            assert(contains("event=sample") and contains("screenW=1920"),
                "Lua UI metrics must continue when Java class binding is unavailable")
            assert(contains("event=fallback api=luajava.bindClass reason=unavailable"),
                "missing Java bridge should report a fallback")
            assert(contains("uiScale=na") and contains("cameraZoom=na"),
                "unavailable Java metrics should remain explicitly unavailable")
            setNow(2100)
            fire()
            assert(countContaining("api=luajava.bindClass") == 1,
                "missing Java bridge should be checked and logged only once")
            print("unavailable bindClass assertions passed")
            """;

    public static void main(String[] args) throws Exception {
        String lua = Files.readString(Path.of(args[0]));
        J2SEPlatform platform = new J2SEPlatform();
        KahluaTable environment = platform.newEnvironment();
        boolean noBindClass = args.length > 1 && "no-bind-class".equals(args[1]);
        String prelude = noBindClass
                ? PRELUDE.replace("local provideJavaBridge = true", "local provideJavaBridge = false")
                : PRELUDE;
        String assertions = noBindClass ? NO_BIND_CLASS_ASSERTIONS : ASSERTIONS;
        LuaClosure chunk = LuaCompiler.loadstring(prelude + "\n" + lua + "\n" + assertions,
                "AnomalousStormHudTrace.contract.lua", environment);
        KahluaThread thread = new KahluaThread(platform, environment);
        thread.debugOwnerThread = Thread.currentThread();
        thread.call(chunk, new Object[0]);
        if (noBindClass) System.out.println("unavailable bindClass assertions passed");
        System.out.println("Anomalous storm HUD trace Kahlua contract passed");
    }
}
