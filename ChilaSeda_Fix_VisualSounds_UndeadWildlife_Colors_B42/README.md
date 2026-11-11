# ChilaSeda Fix - VisualSounds Undead Wildlife Colors (B42) 0.6.0

Integrates the 16 hostile animal types from Undead Wildlife with VisualSounds KA's
`SDI` sound-direction indicator. The Workshop mod does not expose a `VisualSoundsKA`
Lua table; the older patch targeted that nonexistent API and logged that it skipped.

The patch promotes hostile animal sounds to the zombie cue channel, so they remain
visible even when generic `LAMBDA` sounds are ignored. It samples nearby `IsoAnimal`
objects every 250 ms within the Workshop detector's 15-tile range and refreshes
existing cues before VisualSounds' one-second default lifetime expires. This avoids
the Workshop's duplicate-source early return from letting proximity cues blink out.
Normal animals retain the `LAMBDA` visibility/search filters and use a teal-to-amber
distance palette. Undead Wildlife `infected*` and `undead*` types use local
cyan-to-magenta textures; their cues are recognized by type prefix as well as the
original infected herd list. The original Workshop files remain untouched.

## Dependencies and load order

- VisualSounds KA (`VisualSoundsKA`)
- Visual Sounds KA Viewpoint (`VisualSoundsKAViewpoint`)
- Undead Wildlife (`UndeadWildlife`)

`mod.info` requires and loads after all three. The local ID is
`ChilaSeda_Fix_VisualSounds_UndeadWildlife_Colors_B42`.

## Supported animal types

`infectedraccoon`, `infectedcockerel`, `infectedchicken`, `infectedturkey`,
`infectedrabbit`, `infectedpiglet`, `infectedfarmpig`, `infecteddeerdoe`,
`infecteddeerstag`, `infectedcow`, `infectedcowcalf`, `infectedbull`,
`infectedewe`, `infectedram`, `infectedlamb`, and `infectedrat`, plus other Undead
Wildlife types beginning with `infected` or `undead` (including skeletal variants).

## Changelog

### 0.4.0

- Replaced hooks for nonexistent `VisualSoundsKA` color methods with hooks on `SDI`.
- Zombie-animal cues update with the live animal position and use cyan/magenta textures.
- Fixed the load dependency to require VisualSounds KA itself.

### 0.5.0

- Adds close-range detection for normal and zombified animals when they make no
  world sound, following VisualSoundsKA's zombie range and distance sampling.
- Updates live positions for both normal and hostile animal cues.

### 0.6.0

- Recognizes both `infected*` and `undead*` animal definitions as hostile cues.
- Refreshes live animal cues while they remain nearby, overcoming VisualSounds'
  duplicate-source early return and one-second default cue lifetime.
- Gives normal wildlife a teal-to-amber distance palette, separate from the
  cyan-to-magenta palette for hostile wildlife.


---

### 🔗 Otros enlaces de interés

- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
