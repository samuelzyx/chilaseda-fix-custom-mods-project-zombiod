Historical component README, written before consolidation. Current package ID and optional-dependency behavior are documented in ../README.md.

# Viewpoint UI Workshop Fixes

This single local package groups fixes targeting the Workshop mod **Viewpoint UI**. It retains the active package ID `ChilaSeda_Fix_Viewpoint_B42`.

- **Action progress:** actions queued while Viewpoint is active use the custom orange progress bar, at least 10 pixels high, with a short label naming the current action. The patch disables vanilla timed-action progress and temporarily hides the separate inventory-row progress overlay for the active item's `jobDelta`, restoring that value immediately after drawing the pane. Native behavior is restored for actions outside Viewpoint or when returning to isometric mode.
- **Quick dismantling:** prioritizes movable furniture and executes the selected dismantling action directly from Lua.
- **Corpse and container loot:** fingerprints the actual contents when refreshing Viewpoint UI lists, so replacements with the same item count and total weight still invalidate cached rows. Loot lists put weapons first, other items next, and clothing last.
- **Halo notifications:** routes local notifications into a centered text overlay with trait icons and readable change arrows, without the background cards used for trait notices.
- **Action progress:** draws a labeled orange progress bar with a thin, visible 3 px minimum fill.

Requires Viewpoint and Viewpoint UI. It loads after NeatUI ProgressBar so the custom progress integration can wrap it. Workshop originals are unchanged. Local package 2.0.16 includes Halo presentation, inline vanilla texture support, multiline action rows, localized destination names, an alternate loot destination picker that does not spill into other worn bags, the Spanish «Apagando fogata» progress label, and the explicit «Remove Broken Glass» progress label translation; confirm them in Jill.
