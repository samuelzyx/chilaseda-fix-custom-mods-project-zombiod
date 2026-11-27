# ChilaSeda Fix - Loot Tracker

Local compatibility patch for Loot Tracker 2.0 on Project Zomboid Build 42. It handles only `IGUI_LootTracker_MyCar_LeftDays`.

Loot Tracker calls `getTextOrNull(key)` for this label and replaces `%1` itself. Build 42's Translator treats `%1` as a format token and reports a missing argument. The patch passes `%1` as the format argument, then leaves the placeholder for Loot Tracker's existing day-count formatter. Other Loot Tracker text keys continue through the original function.

The patch loads after `LootTrackerB42`. It does not modify the Workshop copy.

## Diagnostic trace

The bounded trace uses `[ChilaSeda_LootTrackerFormatGuard]` and emits installation and translation/fallback results, up to eight lines per Lua load. It is enabled by default for Jill validation. To toggle it in the Lua console, set `LootTracker.TRACE_FORMAT_GUARD` to `false` or `true`.

## Compatibility

- Target: Project Zomboid Build 42.20+
- Dependency: Loot Tracker Workshop mod `LootTrackerB42`
- Local mod ID: `ChilaSeda_Fix_LootTracker_B42`
