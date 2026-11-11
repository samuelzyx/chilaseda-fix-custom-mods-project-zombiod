# ChilaSeda Fix - Better Flashlights for Project Viewpoint (B42)

Custom flashlight actions reuse vanilla B42 hand-torch and battery icons; floor
light toggles follow the native take/pick-up entries.

Local lighting compatibility patch for Better Flashlights 2.4.16 (`BetterFlashlightsFixed`,
Workshop 3420478458) when used with Project Viewpoint (`ProjectViewpointQOLLegacy0.1.6`). It
overrides only the two matching Lua paths in Better Flashlights; both Workshop folders remain
untouched. `mod.info` loads this patch after both mods.

## Changes

- Keep held flashlight light sources while the player stays on the same tile and faces the same
  direction, instead of removing and recreating them every three ticks.
- Use the character's forward vector without inversion, matching Better Flashlights' own projection;
  the reversed vector points behind Jill. The 2026-11-06 screenshots show Jill facing W 270° while
  the projected beam drifts upward. The carrier halo and beam radii stay compact.
- Prevent the repeated light-source recreation from appearing as a strobe in Project Viewpoint's
  asynchronous lighting renderer.
- Reduce the fixed radius of a dropped Better Flashlights weapon torch from 6 to 3 tiles.

Load this patch after `BetterFlashlightsFixed`. If the Workshop mod changes either overridden Lua
file, compare the new version against this patch before updating it.

Runtime confirmation in Jill is still required for the beam direction, strobe, and dropped-light
radius.
