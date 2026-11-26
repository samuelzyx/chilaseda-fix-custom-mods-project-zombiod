import java.nio.file.Files;
import java.nio.file.Path;

import se.krka.kahlua.j2se.J2SEPlatform;
import se.krka.kahlua.luaj.compiler.LuaCompiler;
import se.krka.kahlua.vm.KahluaTable;
import se.krka.kahlua.vm.KahluaThread;
import se.krka.kahlua.vm.LuaClosure;

public final class LiteralUiTranslationKahluaContract {
    private static final String PRELUDE = """
            require = function(_) end
            local translations = {
                UI_MiniHealthPanel_NoActionAvailable = "No hay acciones disponibles",
                UI_HunterExpansion_OpenJournal = "Abrir el diario",
                UI_HunterExpansion_FeederZoneInfo = "Informacion de la zona de alimentacion",
                UI_HunterExpansion_FeederFillPrefix = "Llenar con ",
                UI_HunterExpansion_FeederTooltip = "%s unidades; valor para un jabali: x%s.",
                UI_Viewpoint_MenuFramerate = "FPS del menu",
            }
            getText = function(key) return translations[key] or key end
            local traceLines = {}
            print = function(value) traceLines[#traceLines + 1] = tostring(value) end
            ISContextMenu = {
                addOption = function(self, name, target, onSelect, param1)
                    return { name = name, target = target, onSelect = onSelect, param1 = param1 }
                end,
            }
            local comboCalls = {}
            MainOptions = {
                addCombo = function(page, x, y, width, height, name, options, selected, target, onchange)
                    comboCalls[#comboCalls + 1] = name
                    return { name = name }
                end,
            }
            local noopEvent = { Add = function(_) end }
            Events = { OnGameBoot = noopEvent, OnMainMenuEnter = noopEvent }
            """;

    private static final String ASSERTIONS = """
            local menu = setmetatable({}, { __index = ISContextMenu })
            local journalTarget = {}
            local journal = menu:addOption("Open the journal", journalTarget, function() end, 7)
            assert(journal.name == "Abrir el diario", "journal context label should be Spanish")
            assert(journal.target == journalTarget and journal.param1 == 7, "context callback parameters must be preserved")

            local empty = menu:addOption("No action available")
            assert(empty.name == "No hay acciones disponibles", "Mini Health fallback label should be Spanish")
            local feeder = menu:addOption("Feeding zone information")
            assert(feeder.name == "Informacion de la zona de alimentacion", "feeder information label should be Spanish")

            local fill = menu:addOption("Fill with Corn")
            assert(fill.name == "Llenar con Corn", "dynamic feeder label should keep the item name")
            fill.toolTip = { description = "12 units, worth x1.5 to a boar." }
            assert(fill.toolTip.description == "12 unidades; valor para un jabali: x1.5.", "feeder tooltip should preserve values in Spanish")

            local unrelated = menu:addOption("Drop")
            assert(unrelated.name == "Drop", "unrelated menu labels must pass through unchanged")
            unrelated.toolTip = { description = "unchanged" }
            assert(unrelated.toolTip.description == "unchanged", "unrelated tooltips must pass through unchanged")

            local display = MainOptions.addCombo({}, 0, 0, 10, 10, "Menu framerate", {}, 1, nil, nil)
            assert(display.name == "FPS del menu", "Viewpoint menu framerate label should be Spanish")
            local otherDisplay = MainOptions.addCombo({}, 0, 0, 10, 10, "Gameplay", {}, 1, nil, nil)
            assert(otherDisplay.name == "Gameplay", "unrelated graphics labels must pass through unchanged")

            translations.UI_HunterExpansion_OpenJournal = nil
            local fallback = menu:addOption("Open the journal")
            assert(fallback.name == "Open the journal", "missing translation should keep the source label")
            assert(ISContextMenu.chilaLiteralUiSpanishInstalled, "context menu hook should report installed")
            assert(MainOptions.chilaLiteralUiSpanishInstalled, "Viewpoint options hook should report installed")

            local markers = table.concat(traceLines, "\\n")
            assert(string.find(markers, "event=context-menu-hook-installed", 1, true), "context hook trace missing")
            assert(string.find(markers, "event=feeder-tooltip-translated", 1, true), "tooltip result trace missing")
            assert(string.find(markers, "event=translation-fallback", 1, true), "translation fallback trace missing")
            assert(string.find(markers, "event=viewpoint-options-hook-installed", 1, true), "Viewpoint hook trace missing")
            """;

    public static void main(String[] args) throws Exception {
        String lua = Files.readString(Path.of(args[0]));
        J2SEPlatform platform = new J2SEPlatform();
        KahluaTable environment = platform.newEnvironment();
        LuaClosure chunk = LuaCompiler.loadstring(PRELUDE + lua + ASSERTIONS,
                "LiteralUiTranslation.contract.lua", environment);
        KahluaThread thread = new KahluaThread(platform, environment);
        thread.debugOwnerThread = Thread.currentThread();
        thread.call(chunk, new Object[0]);
        System.out.println("Literal UI translation Kahlua contracts passed: " + args[0]);
    }
}
