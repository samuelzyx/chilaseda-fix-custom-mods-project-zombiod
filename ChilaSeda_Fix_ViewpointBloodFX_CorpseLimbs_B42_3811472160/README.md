# ChilaSeda Fix - Viewpoint Blood FX corpse limbs (B42)

Requires Workshop 3811472160 (`ViewpointBloodFX`), ZombieBuddy, and Viewpoint. Loads after all three.

## Fix

Captures the dismemberment mask on `OnZombieDead`, matches the resulting `IsoDeadBody` by position
and sex, and transfers the saved mask to Viewpoint's corpse pose before rendering. This keeps a
head or limb removed during combat detached when the zombie becomes a loot corpse.

The patch uses Blood FX's existing `cutByPlayer`, `bodyMask`, and `posesSeen` runtime state. It does
not copy, replace, or edit the Workshop JAR and does not change hit, gore, or loot behavior.

## Validation

In Jill, dismember one or more body parts during combat and kill the zombie. Confirm the corpse loot
model keeps exactly the detached parts from the final combat moment. Repeat with a nearby second
zombie to check that the saved mask is assigned to the correct corpse. Preserve `console.txt` if
the patch logs a bridge or reflection error.


---

### 🔗 Otros enlaces de interés

- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
