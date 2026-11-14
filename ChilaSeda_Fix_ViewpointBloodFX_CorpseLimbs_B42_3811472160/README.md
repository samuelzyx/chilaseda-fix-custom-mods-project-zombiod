# ChilaSeda Fix · extremidades del cadáver en Viewpoint Blood FX (B42)

> Requiere [3d Blood VFX for Viewpoint](https://steamcommunity.com/sharedfiles/filedetails/?id=3811472160) (`ViewpointBloodFX`), ZombieBuddy y Viewpoint. Se carga después de los tres.

## Qué corrige

Al recibir `OnZombieDead`, guarda la máscara de desmembramiento, identifica el `IsoDeadBody` resultante por posición y sexo, y pasa la máscara guardada a la pose del cadáver de Viewpoint antes de renderizarla. Así la cabeza o extremidad que se desprendió durante el combate permanece separada cuando el zombi se convierte en cadáver saqueable.

El parche usa el estado existente de Blood FX (`cutByPlayer`, `bodyMask` y `posesSeen`). No copia ni modifica el JAR de Workshop y no cambia los golpes, el gore ni el botín.

## Validación pendiente

En Jill, desprende una o más partes durante el combate y mata al zombi. Comprueba que el cadáver conserve exactamente las partes separadas en el último momento del combate. Repite con un segundo zombi cercano para revisar que cada máscara llegue al cadáver correcto. Conserva `console.txt` si el parche registra un error del puente o de reflexión.

---

### 🔗 Otros enlaces de interés

- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)

## Viewpoint 0.1.7 combat compatibility

When Blood FX is loaded, the patch disables Viewpoint's `lod.livePoses` GPU path for the current session. Viewpoint then uses its CPU pose path for living zombies, preserving Blood FX's cut-limb visibility during combat. This may cost some performance near zombies.

The corpse handoff remains enabled: it copies the final combat cut mask to Viewpoint's loot-corpse model. Both the living zombie and the corpse should keep the severed head or limbs; the detached parts remain on the ground.