# ChilaSeda - AutoCook Fixes (B42) 2.0.9

This package combines AutoCook mobility and auto-resume with safe meal
completion and a poisoned-ingredient repair action. Each behavior remains in
its own Lua script.

The **Reanudar AutoCook** inventory option uses a vanilla B42 pot icon and sits
after native recipe/equip actions when those entries are present.

The **Remove poisonous ingredients** option reuses B42's vanilla rat-poison
item icon; no custom texture is required.

- **Mobility and resume:** allows movement and aiming during AutoCook actions,
  resumes after other queued actions, and supports explicit cancellation.
- **Ingredient cleanup:** removes exhausted ingredients after AutoCook uses
  them.
- **Safe meal completion:** allows finishing an existing prepared meal with
  safe ingredients while keeping AutoCook's original filter for normal meal
  preparation.
- **Poisoned ingredients:** records toxic ingredients and their food-stat
  changes as they are added to a meal. A prepared meal with recorded poison
  can remove those exact ingredients from its right-click menu and reverse
  their recorded nutrition and poison contribution. The menu handles the
  Java collections used by the inventory context menu when resolving the
  selected food. Vanilla meals created
  before this patch have no per-ingredient poison history, so they cannot be
  repaired reliably by this option.
- **Container return:** remembers the source bag when AutoCook takes its bowl or
  pot from a carried container, returns the finished meal container there, and
  reports the destination with Halo. If the source has no capacity, the item is
  left on the floor and the message names that destination.
- **B42 compatibility:** avoids the unavailable `next` global when completing
  poison removal.
- **Food nutrition tooltip:** shows the item's calories, carbohydrates,
  proteins, and fat for all characters. It uses the game's translated labels
  and values; Nutritionist characters keep the native tooltip output. Layout
  height values are normalized before arithmetic for B42's Java-backed fields.
  It uses vanilla's fixed layout origin because `ISToolTipInv` has no `padLeft`
  value to pass to Java's integer-based renderer.
- **Nutrition tooltip layout:** measures vanilla food details first, then adds
  the custom macro block once below them. It no longer adds the block during
  both measurement and visible rendering or places it over the native rows.
- **Food-only nutrition:** skips non-edible B42 `Food` objects with no nutrition
  values, including chicken and turkey feathers.

AutoCook is optional. Each script loads it with `pcall`, checks the functions
it patches, and skips with a short log message if AutoCook is missing or its
API has changed. `loadModAfter=AutoCook` only affects order when it is present.

Workshop files are unchanged. The unified local mod ID is
`ChilaSeda_AutoCook_B42`. Historical component notes are in
`Documentacion/AutoCookSafeCompletion_1.1.0.md` and `LEEME.txt`.


---

### 🔗 Otros enlaces de interés

- [ChilaSeda - AutoCook Safe Meal Completion (B42)](Documentacion/AutoCookSafeCompletion_1.1.0.md)
- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
