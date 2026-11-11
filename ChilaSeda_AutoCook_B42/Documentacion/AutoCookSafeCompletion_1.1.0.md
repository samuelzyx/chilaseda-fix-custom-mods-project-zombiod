Historical component README, written before consolidation. Current optional-dependency handling is documented in ../README.md.

# ChilaSeda - AutoCook Safe Meal Completion (B42)

Adds the optional AutoCook action for finishing an existing prepared meal. When that action is
used, ingredients are rejected if they add positive hunger/thirst, unhappiness, boredom, stress,
food sickness, fatigue, poison, negative nutrition values, or rot. Safe candidates with nutritional or mood benefit remain
available. New meal preparation follows AutoCook's original filtering.

This local patch requires AutoCook and loads after `ChilaSeda_AutoCookMobility_B42`. It does not
modify Workshop files. Static source review only; in-game validation is still required.


---

### 🔗 Otros enlaces de interés

- [⬅️ Inicio del mod](../README.md)
- [🏠 Inicio del repositorio](../../README.md)
- [🤝 Cómo contribuir](../../CONTRIBUTING.md)
- [🚀 Releases de mods](../../docs/releases/README.md)
