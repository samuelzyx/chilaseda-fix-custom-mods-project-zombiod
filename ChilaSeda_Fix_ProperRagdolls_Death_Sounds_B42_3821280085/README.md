# ChilaSeda Fix - Proper Ragdolls Death Sounds (B42)

Requires Proper Ragdolls (Workshop 3821280085) and loads after it.

The early-loot option uses a vanilla B42 hiking-bag icon and follows the first
native loot action in its context menu.

## Changes

- Keeps all Proper Ragdolls death animation XML and `PlayDeathSound` events intact.
- Stops the `MaleZombieDeath` and `FemaleZombieDeath` voice aliases as soon as Proper Ragdolls starts its custom death clip.
- Preserves the `BodyHitGround` impact event and the original animation speed and duration.
- As soon as the voice stops, right-click the still-falling dead zombie and choose **Loot dead zombie** / **Saquear zombi muerto**. The vanilla loot pane opens on the zombie inventory and the option stays available for the entire animation.
- When the corpse spawns, the open pane switches to its corpse container if the game created a separate one; the handoff waits for that container to become available.

## Pending behavior

Proper Ragdolls sets `prdDone=true` at 90% of its custom death clips and then enables `ragdollFall`. This addon does not change the clip or corpse conversion timing.

## Version 1.3.0

Version 1.3.0 removes the fixed two-second timer. The patch clears a stale
`prdDeath` marker on `OnZombieDead` and watches for Proper Ragdolls' XML
`SetVariable prdDeath=PRDeath_*` event, which runs at the start of its custom
death clips. It cuts the voice and enables early loot on that marker without
changing the clip, impact sound, or corpse-conversion timing.

## Origin

https://steamcommunity.com/sharedfiles/filedetails/?id=3821280085

The Workshop source remains unmodified.


---

### 🔗 Otros enlaces de interés

- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
