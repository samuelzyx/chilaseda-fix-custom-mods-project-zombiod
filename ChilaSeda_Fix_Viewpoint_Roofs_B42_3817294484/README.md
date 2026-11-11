# ChilaSeda Fix · descarga de chunks en Viewpoint Roofs

## Causa y protección

Viewpoint Roofs 0.9.2 puede llamar `IsoGridSquare.AddTileObject` desde `ViewpointRoofs_Backs.lua:add` mientras `LoadChunk` corre dentro de `IsoChunk.removeFromWorld`. Si el chunk ya se descargó, el juego recibe un cuadrado con `chunk == null` y falla al entrar al pathfinding nativo en `SquareUpdateTask.init`.

El hook de entrada de ZombieBuddy omite únicamente la inserción de baldosa inválida. Las llamadas de cuadrados cargados siguen igual; el original de Workshop no se modifica. Un mensaje de log único indica cuándo se omitió una inserción.

## Dependencias y orden

Requiere [Viewpoint - Roofs (WIP)](https://steamcommunity.com/sharedfiles/filedetails/?id=3817294484) (`ViewpointRoofs`) y ZombieBuddy 2.3.4 o posterior. Este parche se carga después de ambos.

---

### 🔗 Otros enlaces de interés

- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
