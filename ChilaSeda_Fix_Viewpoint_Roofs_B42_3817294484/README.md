# ChilaSeda Fix - Viewpoint Roofs Chunk Unload

Guards `IsoGridSquare.AddTileObject` when the square no longer belongs to a loaded chunk.
Viewpoint Roofs 0.9.2 can call this method from `ViewpointRoofs_Backs.lua:add` while its
`LoadChunk` callback runs during `IsoChunk.removeFromWorld`. The game then passes a square
with `chunk == null` into native pathfinding and throws from `SquareUpdateTask.init`.

The ZombieBuddy entry hook skips only the invalid tile insertion. Calls on loaded squares
continue unchanged. The Workshop original is untouched. The one-time log message identifies
when the guard skips an insertion.

Requires Workshop `ViewpointRoofs` and ZombieBuddy 2.3.4 or newer. It loads after both.


---

### 🔗 Otros enlaces de interés

- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
