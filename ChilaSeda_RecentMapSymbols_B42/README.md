# ChilaSeda Recent Map Symbols (B42)

Adds a `Recientes` tab as the first tab and a `Buscar` tab after it in the normal map symbol palette. `Recientes` shows up to 20 distinct symbols, ordered from most recently placed to least recent. Placing a symbol on the map moves it to the front of the list.

Recent symbol IDs are stored in character ModData, world ModData keyed by player, and mirrored to a per-player Lua data file. This preserves the list through a game reload even if character ModData is absent or reset. Unknown IDs are kept in storage so a temporarily unavailable symbol pack does not erase their recent history; icons appear again when their definitions are registered.

The search tab scans the same symbol definitions used to build the vanilla palette. Search by Spanish or English symbol name, ID, texture name, or category. Matching is token-based and relevance-ranked, so `bag de backpag` can find backpack aliases without matching unrelated names such as Garbage. Results are selectable map symbols and retain the current marker color.

The tab uses the same symbol definitions and placement action as the vanilla palette. It works independently of Viewpoint and does not require Extra Map Symbols.

When the normal player-map shortcut opens the map, the view recenters on the current character after vanilla restores the previous view. Calls that provide explicit map coordinates keep their requested center.

## Changes

- 0.2.6: Refreshes recent symbols after map-panel creation and while the recent tab is visible if saved IDs or definitions arrive late; empty reads are not cached. Search now accepts exact, prefix, and substring matches within symbol-name tokens, so `flech` and `flecha` both find `Flechas`.
- 0.2.5: Fixes a reserved Lua keyword in the stop-word table that prevented the entire symbol tabs script from loading.
- 0.2.4: Adds B42 JSON locale files for Spanish and English tab labels, Spanish names for common symbols, tokenized accent-insensitive search with backpack aliases and relevance ranking, and world ModData persistence per player alongside character ModData and the Lua file.
- 0.2.3: Mirrors recent symbol IDs to a per-player file, preserves IDs whose symbol packs are temporarily unavailable, and adds a searchable symbol tab with localized labels.
- 0.2.2: Recent-symbol icons now inherit the currently selected symbol color when the tab is built or refreshed. Vanilla color changes continue to update them through the shared button list.
