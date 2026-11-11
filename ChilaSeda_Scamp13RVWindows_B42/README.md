# Scamp 13 RV Interior Windows - prototype

Local single-player addon for KI5 `Base.Trailer87Scamp13`. It uses the `RVHooks` API from
PROJECT RV Interior and does not replace Workshop files or map binaries.

On entry, it replaces four outer wall segments with fixed chrome-framed glass: three side windows
and one rear window. Exterior `IsoZombie` objects are removed from the reserved 60-tile room slot
on entry and every 30 game ticks. Zombies and animals within the assigned room are left alone.

The addon restores the replaced wall objects on normal RV exit. Tile-object changes now require a
loaded square chunk; cleanup skips squares that have already started unloading, avoiding
`AddTileObject`/pathfinding calls against stale squares. Do not smash or climb through the test
windows; exit through the RV context option.

The first visual pass still needs in-game review for wall selection, model layout, daylight, and
window orientation.
