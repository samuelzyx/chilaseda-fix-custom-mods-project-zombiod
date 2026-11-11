-- Presentation-only Spanish layer for Hunter Expansion's feeder and journal.
-- The Workshop files contain hard-coded English strings, so this file adapts
-- only their visible UI after the original mod has loaded.
local VERSION = "1.1.0"
local PREFIX = "IGUI_HE_ES_"

local EXACT = {
    ["Feeding zone information"] = "FeederInfo",
    ["Open the journal"] = "OpenJournal",
    ["Feeding zone"] = "FeederTitle",
    ["Feeder"] = "Feeder",
    ["Bread pile"] = "BreadPile",
    ["This feeder is no longer here."] = "FeederGone",
    ["Empty."] = "Empty",
    ["No sounder has been here yet."] = "NoSounderYet",
    ["A sounder was here within the hour."] = "SounderWithinHour",
    ["feed"] = "Feed",
    ["Stale bread"] = "StaleBread",
    ["Grain mix"] = "GrainMix",
    ["Acorns and mast"] = "AcornsMast",
    ["Bread pile"] = "BreadPile",
    ["Modern feeder"] = "ModernFeeder",
    ["no feed left"] = "NoFeed",
    ["full"] = "Full",
    ["Map"] = "Map",
    ["Weather"] = "Weather",
    ["Wildlife"] = "Wildlife",
    ["Notebook"] = "Notebook",
    ["Close"] = "Close",
    ["or right-click"] = "RightClick",
    ["Still to be written."] = "StillToWrite",
    ["No reading."] = "NoReading",
    ["Right now"] = "RightNow",
    ["precipitation"] = "Precipitation",
    ["temperature"] = "Temperature",
    ["visibility"] = "Visibility",
    ["First light  "] = "FirstLight",
    ["Last light   "] = "LastLight",
    ["Wind"] = "Wind",
    ["thunderstorm"] = "Thunderstorm",
    ["thunder"] = "Thunder",
    ["dry"] = "Dry",
    ["light rain"] = "LightRain",
    ["heavy snow"] = "HeavySnow",
    ["snow"] = "Snow",
    ["light snow"] = "LightSnow",
    ["heavy rain"] = "HeavyRain",
    ["rain"] = "Rain",
    ["light air"] = "LightAir",
    ["a breeze"] = "Breeze",
    ["fresh"] = "FreshWind",
    ["strong"] = "StrongWind",
    ["gale"] = "Gale",
    ["strength"] = "Strength",
    ["direction"] = "Direction",
    ["no forecast"] = "NoForecast",
    ["What may come"] = "ForecastHeading",
    ["Tomorrow"] = "Tomorrow",
    ["In two days"] = "InTwoDays",
    ["In three days"] = "InThreeDays",
    ["calm"] = "Calm",
    ["breezy"] = "Breezy",
    ["windy"] = "Windy",
    ["thick fog"] = "ThickFog",
    ["fog"] = "Fog",
    ["haze"] = "Haze",
    ["overcast"] = "Overcast",
    ["cloudy"] = "Cloudy",
    ["some cloud"] = "SomeCloud",
    ["mostly clear"] = "MostlyClear",
    ["clear"] = "Clear",
    ["Noted, not yet used - the animals do not smell you yet."] = "WindNote",
    ["A spread for each animal: tracks, sounds, signs of presence, and its day."] = "WildlifeDescription",
    ["Ground"] = "Ground",
    ["Nothing walked yet."] = "NothingWalked",
    ["you are here"] = "YouAreHere",
    ["What the colours mean"] = "LegendHeading",
    ["Worth a wait"] = "WorthWait",
    ["enough here to draw a sounder"] = "WorthWaitNote",
    ["Something, not enough"] = "SomeNotEnough",
    ["a crop or two; they will not come for it"] = "SomeNotEnoughNote",
    ["Walked, nothing here"] = "WalkedEmpty",
    ["you have been through and it was bare"] = "WalkedEmptyNote",
    ["Not walked"] = "NotWalked",
    ["you have not been here - it may be anything"] = "NotWalkedNote",
    ["The map fills in as you walk; it shows what you know."] = "MapNote",
    ["nothing yet"] = "NothingYet",
    ["within the hour"] = "WithinHour",
    ["Feed"] = "FeedLabel",
    ["Kind"] = "Kind",
    ["Spoils in"] = "SpoilsIn",
    ["Keeps for"] = "KeepsFor",
    ["empty"] = "EmptyLower",
    ["Prepared by"] = "PreparedBy",
    ["Sounder seen"] = "SounderSeen",
    ["Visits in all"] = "VisitsInAll",
    ["Chance at dawn and dusk"] = "ChanceLabel",
    ["Put feed in it. Nothing else matters while it is empty."] = "AdviceEmpty",
    ["Top it up - under half costs more than the kind of feed does."] = "AdviceTopUp",
    ["Better feed: grain is worth half again, mast nearly double."] = "AdviceBetterFeed",
    ["Animal Care. 3% per level, recorded when you fill it."] = "AdviceSkill",
    ["About as good as a feeder this size gets."] = "AdviceBest",
    ["Not the same as there being none - it means this feeder has not caught one."] = "NoVisitNote",
}

local function text(key, ...)
    local fullKey = PREFIX .. key
    local translated = getTextOrNull and getTextOrNull(fullKey)
    if translated and translated ~= fullKey then
        if select("#", ...) > 0 then return getText(fullKey, ...) end
        return translated
    end
    return nil
end

local function localize(value)
    if type(value) ~= "string" then return value end
    local key = EXACT[value]
    if key then return text(key) or value end

    local feedName = value:match("^Fill with (.+)$")
    if feedName then return "Llenar con " .. localize(feedName) end

    local n, m, kind = value:match("^(%d+) of (%d+) units of (.+)%.$")
    if n then return text("UnitsOfFeed", n, m, localize(kind)) or (n .. " de " .. m .. " unidades de " .. localize(kind) .. ".") end
    n = value:match("^Spoils in about (%d+) hours%.$")
    if n then return text("SpoilsHours", n) or ("Se echa a perder en unas " .. n .. " h.") end
    n = value:match("^Keeps for about (%d+) more days%.$")
    if n then return text("KeepsDays", n) or ("Se conserva unos " .. n .. " días más.") end
    n = value:match("^A sounder was here (%d+) hours ago%.$")
    if n then return text("SounderHoursAgo", n) or ("Una piara pasó hace " .. n .. " h.") end
    n = value:match("^Nothing for (%d+) days%. Last one %d+ days ago%.$")
    if n then return text("NothingDays", n) or ("Nada en " .. n .. " días. La última pasó hace " .. n .. " días.") end
    n = value:match("^Nothing for over a week %((%d+) days%)%.$")
    if n then return text("NothingWeek", n) or ("Nada en más de una semana (" .. n .. " días).") end
    n, m = value:match("^(%d+) visit(s?) in all%.$")
    if n then return text("Visits", n) or ("Visitas en total: " .. n .. ".") end
    n = value:match("^About (%d+)%% at each dawn and dusk%.$")
    if n then return text("Chance", n) or ("Aproximadamente " .. n .. "% al amanecer y al anochecer.") end
    n, m = value:match("^(%d+)/(%d+), about (%d+)%%$")
    if n then return text("FillResult", n, m, value:match("about (%d+)%%")) or (n .. "/" .. m .. ", aprox. " .. value:match("about (%d+)%%") .. "%") end
    n, m = value:match("^(%d+) units, worth x([%d%.]+) to a boar%.$")
    if n then return text("FeedWorth", n, m) or (n .. " unidades; valor x" .. m .. " para un jabalí.") end
    n, m = value:match("^Animal Care (%d+)  x([%d%.]+)$")
    if n then return text("AnimalCare", n, m) or ("Cuidado de animales " .. n .. "  x" .. m) end
    n = value:match("^Each square is (%d+) tiles across%.$")
    if n then return text("SquareSize", n) or ("Cada casilla mide " .. n .. " baldosas por lado.") end
    n = value:match("^from the ([A-Z]+)$")
    if n then return text("WindFrom", localize(n)) or ("Desde " .. localize(n):lower()) end
    local compass = { N="Norte", NE="noreste", E="este", SE="sureste", S="sur", SW="suroeste", W="oeste", NW="noroeste" }
    if compass[value] then return compass[value] end
    n = value:match("^about ([%d%.]+) km/h$")
    if n then return text("WindSpeed", n) or ("aprox. " .. n .. " km/h") end
    n = value:match("^(%d+) hours$")
    if n then return n .. " h" end
    n = value:match("^(%d+) days$")
    if n then return n .. " días" end
    n = value:match("^%.?([%d%.]+) C$")
    if n then return n .. " °C" end
    local time = value:match("^First light%s+(.+)$")
    if time then return "Primeras luces  " .. time end
    time = value:match("^Last light%s+(.+)$")
    if time then return "Últimas luces   " .. time end
    return value
end

local function localizeRichText(value)
    -- Rich text contains markup and generated values; translate its plain text
    -- fragments while leaving tags and formatting controls intact.
    local replacements = {}
    for english in pairs(EXACT) do replacements[#replacements + 1] = english end
    table.sort(replacements, function(a, b) return #a > #b end)
    for _, english in ipairs(replacements) do
        local spanish = localize(english)
        if spanish ~= english then
            value = value:gsub(english:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"), function() return spanish end)
        end
    end
    value = value:gsub("No sounder has been here yet%.", "Aún no ha pasado ninguna piara.")
    value = value:gsub("A sounder was here within the hour%.", "Una piara pasó durante la última hora.")
    value = value:gsub("A sounder was here (%d+) hours ago%.", "Una piara pasó hace %1 h.")
    value = value:gsub("Nothing for (%d+) days%. Last one (%d+) days ago%.", "Nada en %1 días. La última piara pasó hace %2 días.")
    value = value:gsub("Nothing for over a week %((%d+) days%)%.", "Nada en más de una semana (%1 días).")
    value = value:gsub("Spoils in about (%d+) hours%.", "Se echa a perder en unas %1 h.")
    value = value:gsub("Keeps for about (%d+) more days%.", "Se conserva unos %1 días más.")
    value = value:gsub("About (%d+)%% at each dawn and dusk%.", "Aproximadamente %1%% al amanecer y al anochecer.")
    value = value:gsub("(%d+) hours ago", function(n) return n .. " h" end)
    value = value:gsub("(%d+) days ago", function(n) return n .. " días" end)
    value = value:gsub("(%d+) hours", function(n) return n .. " h" end)
    value = value:gsub("(%d+) days", function(n) return n .. " días" end)
    value = value:gsub("Animal Care (%d+)  x([%d%.]+)", function(a, b) return "Cuidado de animales " .. a .. "  x" .. b end)
    value = value:gsub("(%d+) of (%d+) units of ([^%.<]+)%.", function(a, b, c) return localize(a .. " of " .. b .. " units of " .. c .. ".") end)
    value = value:gsub("(%d+) / (%d+)", function(a, b) return a .. " / " .. b end)
    return localize(value)
end

local function localizeOption(option)
    if not option then return end
    if type(option.name) == "string" then option.name = localize(option.name) end
    local tip = option.toolTip
    if tip then
        if type(tip.name) == "string" then tip.name = localize(tip.name) end
        if type(tip.description) == "string" then tip.description = localizeRichText(tip.description) end
    end
end

local function install()
    if HEJournalUI and not HEJournalUI._ChilaSedaSpanishUI then
        local original = HEJournalUI.drawText
        if type(original) == "function" then
            HEJournalUI.drawText = function(self, value, ...)
                return original(self, localize(value), ...)
            end
        end
        for _, tab in ipairs(HEJournalUI.TABS or {}) do
            if tab.title then tab.title = localize(tab.title) end
        end
        HEJournalUI._ChilaSedaSpanishUI = VERSION
    end
    if HEFeederUI and not HEFeederUI._ChilaSedaSpanishUI then
        local originalRichText = HEFeederUI.getRichText
        if type(originalRichText) == "function" then
            HEFeederUI.getRichText = function(item)
                return localizeRichText(originalRichText(item))
            end
        end
        local originalSetObject = HEFeederUI.setObject
        if type(originalSetObject) == "function" then
            HEFeederUI.setObject = function(self, item, ...)
                local result = originalSetObject(self, item, ...)
                local tier = item and HEFeeder and HEFeeder.isFeeder(item)
                if self.panel and tier and tier.name then self.panel:setName(localize(tier.name)) end
                return result
            end
        end
        local originalSetTitle = HEFeederUI.setTitle
        if type(originalSetTitle) == "function" then
            HEFeederUI.setTitle = function(self, value, ...)
                return originalSetTitle(self, localize(value), ...)
            end
        end
        HEFeederUI._ChilaSedaSpanishUI = VERSION
    end
    if HaloTextHelper and type(HaloTextHelper.addTextWithArrow) == "function"
        and not HaloTextHelper._ChilaSedaSpanishUI then
        local original = HaloTextHelper.addTextWithArrow
        HaloTextHelper.addTextWithArrow = function(player, value, ...)
            return original(player, localize(value), ...)
        end
        HaloTextHelper._ChilaSedaSpanishUI = VERSION
    end
end

Events.OnGameBoot.Add(install)
Events.OnFillWorldObjectContextMenu.Add(function(_, context)
    if not context or type(context.options) ~= "table" then return end
    for _, option in ipairs(context.options) do
        localizeOption(option)
        if option.subOption and type(context.getSubMenu) == "function" then
            local sub = context:getSubMenu(option.subOption)
            for _, child in ipairs((sub and sub.options) or {}) do localizeOption(child) end
        end
    end
end)

print("[ChilaSeda Hunter Spanish UI] Loaded v" .. VERSION)
