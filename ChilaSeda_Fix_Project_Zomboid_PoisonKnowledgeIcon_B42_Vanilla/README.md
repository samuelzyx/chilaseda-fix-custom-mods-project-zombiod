# ChilaSeda Fix - Project Zomboid Poison Knowledge (B42, Vanilla) 0.2.0

Vanilla uses two different poison-knowledge checks. The inventory renames a berry or mushroom when
the player knows the `Herbalist` recipe and the food has positive poison power, while inventory and
foraging skulls only check `player:isKnownPoison(item)`. That mismatch left Jill able to recognize
the ingredient by Herbalist knowledge without matching tooltip or forage-pin feedback.

Version 0.2.0 applies the same Herbalist and poison-power rule to:

- Food tooltips and forage pickup labels, temporarily using vanilla's translated poisonous berry or
  mushroom name while the UI draws them, then restoring the item's prior name.
- Skull overlays on inventory icons, general forage pins, and world-item pins where vanilla's
  `isKnownPoison` check did not already add one.

This patch does not reveal poison to a player who has not learned Herbalist and does not add
item-ID exceptions. It leaves vanilla files unchanged. It loads after AutoCook so the poison-name
tooltip wrapper composes with AutoCook's nutrition tooltip.


---

### 🔗 Otros enlaces de interés

- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
