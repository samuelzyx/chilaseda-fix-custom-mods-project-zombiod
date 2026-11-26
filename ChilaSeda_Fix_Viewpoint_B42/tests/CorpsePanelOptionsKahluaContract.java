import java.nio.file.Files;
import java.nio.file.Path;

import se.krka.kahlua.j2se.J2SEPlatform;
import se.krka.kahlua.luaj.compiler.LuaCompiler;
import se.krka.kahlua.vm.KahluaTable;
import se.krka.kahlua.vm.KahluaThread;
import se.krka.kahlua.vm.LuaClosure;

public final class CorpsePanelOptionsKahluaContract {
    private static final String PRELUDE = """
            local logs = {}
            print = function(message) logs[#logs + 1] = tostring(message) end
            local heldKeys = {}
            Keyboard = {
                KEY_G = 34, KEY_B = 48, KEY_H = 35, KEY_F6 = 64,
                KEY_LCONTROL = 29, KEY_RCONTROL = 157,
                KEY_LMENU = 56, KEY_RMENU = 184,
                KEY_LSHIFT = 42, KEY_RSHIFT = 54,
                isKeyDown = function(key) return heldKeys[key] == true end,
                getKeyName = function(key)
                    if key == 48 then return "B" end
                    if key == 34 then return "G" end
                    if key == 32 then return "D" end
                    return tostring(key)
                end,
            }
            UIFont = { Small = "small", Medium = "medium" }
            local conditionColors = {}
            ViewpointInvStyle = {
                condition = function(fraction, broken)
                    local index = broken and 0 or math.floor(math.max(0, math.min(1, fraction)) * 100 + 0.5)
                    if not conditionColors[index] then conditionColors[index] = { index, 0, 0, 1 } end
                    return conditionColors[index]
                end,
                rect = function(ui, x, y, w, h, color)
                    ui.rects[#ui.rects + 1] = { x = x, y = y, w = w, h = h, color = color }
                end,
                text = function(ui, _, _, _, _, _, font) ui.lastFont = font end,
                textRight = function(ui, _, _, _, _, _, font) ui.lastFont = font end,
                fit = function(text) return text end,
                px = function(metrics, size) return math.max(1, math.floor(size * metrics.font / 38 + 0.5)) end,
            }
            ViewpointInvList = {}
            function ViewpointInvList.layout(grid)
                local m = grid.m
                local row = m.font + ViewpointInvStyle.px(m, 16)
                local tileIn = ViewpointInvStyle.px(m, 2)
                grid.lm = { row = row, tile = row - tileIn * 2, tileIn = tileIn,
                    tileX = grid.x + m.pad + 12, gap = m.gap }
            end
            function ViewpointInvList.height(grid, stacks)
                if #stacks == 0 then return grid.m.font + grid.m.gap * 2 end
                return grid.m.gap + #stacks * grid.lm.row
            end
            function ViewpointInvList.rows(grid, ui, section, stacks, top, bottomEdge, view)
                ui.receivedFont = grid.m.font
                local color = ViewpointInvStyle.condition(stacks[1].look.condition, stacks[1].look.broken)
                ViewpointInvStyle.rect(ui, 0, top, grid.lm.tile, 2, color)
                ViewpointInvStyle.text(ui, "item", 0, top, color)
                return grid.m.gap + #stacks * grid.lm.row
            end
            local container = { getType = function() return "inventorymale" end }
            local stack = { key = "item", look = { condition = 0.63, broken = false } }
            local section = { container = container, folded = false, stacks = { stack } }
            ViewpointInvGrid = {}
            function ViewpointInvGrid:lists(_) return true end
            function ViewpointInvGrid:narrowed() return false end
            function ViewpointInvGrid:contentHeight() return 100 end
            ViewpointInvData = { shown = function(section) return section.stacks end }
            local function event()
                return { Add = function(_) end }
            end
            Events = { OnGameBoot = event(), OnGameStart = event() }
            local registered = {}
            local titles = {}
            local page = {}
            function page:addTitle(title) titles[#titles + 1] = title end
            function page:addSeparator() end
            local function option(default)
                return { value = default, getValue = function(self) return self.value end }
            end
            function page:addTickBox(id, _, default)
                local value = option(default); registered[id] = value; return value
            end
            function page:addSlider(id, _, _, _, _, default, _)
                local value = option(default); registered[id] = value; return value
            end
            function page:addKeyBind(id, _, default)
                local value = option(default); registered[id] = value; return value
            end
            function page:addComboBox(id)
                local value = option(nil)
                value.items = {}
                function value:addItem(label, selected)
                    self.items[#self.items + 1] = label
                    if selected and self.value == nil then self.value = #self.items end
                end
                registered[id] = value
                return value
            end
            PZAPI = { ModOptions = { create = function(_, id, title)
                page.id, page.title = id, title
                return page
            end } }
            getTextOrNull = function(_) return nil end
            require = function(_) return true end
            """;

    private static final String ASSERTIONS = """
            local scaleGrid = setmetatable({
                x = 10, w = 400, bodyTop = 0, list = true, query = "", order = {}, filter = {},
                m = { font = 10, pad = 4, gap = 3 }, hits = {}, sections = { section },
            }, { __index = ViewpointInvGrid })
            ViewpointInvList.layout(scaleGrid)
            local originalRow = scaleGrid.lm.row
            local originalTile = scaleGrid.lm.tile
            """;

    private static final String TESTS = """
            assert(page.id == "ChilaSeda_Fix_Viewpoint_B42", "settings page id should be stable")
            assert(registered["nativeActionModifier"] ~= nil, "native forage modifier must remain available")
            assert(registered["animalCorpseActionModifier"] ~= nil, "animal corpse modifier selector must be registered")
            assert(registered["nativeActionModifier"].value == 2, "Alt should be the default forage modifier")
            assert(registered["animalCorpseActionModifier"].value == 2, "Alt should be the default animal modifier")
            assert(#registered["animalCorpseActionModifier"].items == 7, "animal selector should offer all modifiers")
            assert(registered["corpseWearStyle"] ~= nil, "wear indicator selector must be registered")
            assert(#registered["corpseWearStyle"].items == 2, "wear selector should offer bar and frame")
            local hasForageTitle, hasCorpseTitle = false, false
            for _, title in ipairs(titles) do
                if title == "Hallazgos con pin de rebusqueda" then hasForageTitle = true end
                if title == "Cadaveres de animales" then hasCorpseTitle = true end
            end
            assert(hasForageTitle, "native forage section title should describe pinned finds")
            assert(hasCorpseTitle, "animal corpse settings section should be visible")

            page.apply()
            assert(ChilaSedaViewpointNativeActionModifier == "ALT", "Alt should apply as the forage default")
            assert(ChilaSedaViewpointAnimalCorpseActionModifier == "ALT", "Alt should apply as the animal default")
            assert(ChilaSedaViewpointFormatNativeActionKey(34) == "Alt+G", "forage prompt should show Alt+G by default")
            assert(ChilaSedaViewpointFormatAnimalCorpseActionKey(32) == "Alt+D", "animal prompt should show Alt+D by default")
            heldKeys[56] = true
            assert(ChilaSedaViewpointNativeActionModifierMatches(), "forage actions should accept Alt by default")
            assert(ChilaSedaViewpointAnimalCorpseActionModifierMatches(), "animal actions should accept Alt by default")
            heldKeys[56] = nil

            registered["animalCorpseActionModifier"].value = "Mayús"
            registered["corpseWearStyle"].value = 2
            registered["corpseLootPanelScale"].value = 1.75
            page.apply()
            assert(ChilaSedaViewpointAnimalCorpseActionModifier == "SHIFT", "animal modifier selection should persist")
            assert(ChilaSedaViewpointCorpseWearStyle == "FRAME", "frame selection should apply")
            assert(ChilaSedaViewpointCorpsePanelScale == 1.75, "panel scale should apply")
            heldKeys[42] = true
            assert(ChilaSedaViewpointAnimalCorpseActionModifierMatches(), "animal actions should use the selected modifier")
            assert(ChilaSedaViewpointFormatAnimalCorpseActionKey(48) == "Mayús+B", "animal prompt should show its selected modifier")
            assert(not ChilaSedaViewpointNativeActionModifierMatches(), "animal selector must not change the forage modifier")

            local ui = { rects = {} }
            local height = ViewpointInvList.rows(scaleGrid, ui, section, section.stacks, 0, 100,
                { selected = { [container] = {} } })
            assert(scaleGrid.m.font == 10 and scaleGrid.lm.row == originalRow and scaleGrid.lm.tile == originalTile,
                "corpse scaling must not mutate the shared grid metrics")
            assert(ui.receivedFont == 17.5, "rows should receive scaled metrics")
            assert(ui.lastFont == "medium", "corpse text should use the larger font")
            assert(height > originalRow, "corpse row height should increase")
            assert(#ui.rects == 4, "frame mode should draw four wear-colored borders and hide the old bar")
            for _, rect in ipairs(ui.rects) do
                assert(rect.color == ViewpointInvStyle.condition(0.63, false), "frame should use the wear condition color")
            end
            local contentHeight = scaleGrid:contentHeight()
            assert(contentHeight > 100, "growing loot panel content height should account for scaled rows")

            registered["corpseWearStyle"].value = 1
            page.apply()
            ui.rects = {}
            ViewpointInvList.rows(scaleGrid, ui, section, section.stacks, 0, 100,
                { selected = { [container] = {} } })
            assert(#ui.rects == 1 and ui.rects[1].h == 2, "bar mode should preserve the native wear bar")
            local logsFound = { options = false, geometry = false }
            for _, message in ipairs(logs) do
                if string.find(message, "corpseOptions scale=1.75 wear=BAR", 1, true) then logsFound.options = true end
                if string.find(message, "panel-scale section=corpse", 1, true)
                        and string.find(message, "configured=1.75", 1, true)
                        and string.find(message, "applied=1.75", 1, true)
                        and string.find(message, "font=", 1, true)
                        and string.find(message, "row=", 1, true)
                        and string.find(message, "tile=", 1, true) then logsFound.geometry = true end
            end
            assert(logsFound.options, "settings should log effective scale and both independent modifiers")
            assert(logsFound.geometry, "panel should log configured and applied row/font/tile dimensions")
            """;

    public static void main(String[] args) throws Exception {
        String panelLua = Files.readString(Path.of(args[0]));
        String optionsLua = Files.readString(Path.of(args[1]));
        String lua = PRELUDE + "\n" + panelLua + "\n" + optionsLua + "\n" + ASSERTIONS + "\n" + TESTS;

        J2SEPlatform platform = new J2SEPlatform();
        KahluaTable environment = platform.newEnvironment();
        LuaClosure chunk = LuaCompiler.loadstring(lua, "CorpsePanelOptions.contract.lua", environment);
        KahluaThread thread = new KahluaThread(platform, environment);
        thread.debugOwnerThread = Thread.currentThread();
        thread.call(chunk, new Object[0]);
        System.out.println("Corpse panel options Kahlua contract passed");
    }
}
