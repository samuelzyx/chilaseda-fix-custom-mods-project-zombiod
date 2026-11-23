# ChilaSeda Fix - Viewpoint Workshop Fixes (B42) 2.0.128

<div align="center">

[Repo](../README.md) | [Contribuir](../CONTRIBUTING.md) | [Releases](../docs/releases/README.md)

</div>

---

## Version 2.0.128

- Adds an independent, per-area height control for Viewpoint's projected floor arrows. It applies live, saves with each area anchor, and stays separate from the forage pin height.

## Version 2.0.127

- Preserves an explicit destination chosen in the vanilla forage-icon submenu, including the main inventory when a different backpack is selected in the inventory pane. Direct forage clicks still inherit the selected pane container.
- Adds `Put in container` destination choices to native Viewpoint interactions for forage loot, butchering, bones, corpse pickup, and ground pickup. The selected container is applied before the original action callback runs.

## Version 2.0.126

- Colors unclassified downward trait arrows red while preserving trait-specific semantic colors and the existing sleep-trait direction rules. Bounded `generic-trait-arrow` DebugLog entries identify the trait and applied direction color.

## Version 2.0.125

- Adds only `Base.Dung_Rat` world-object icons to Viewpoint's native 3D forage-pin provider. The shortcut could already target the ground item through `worldObjectIcons`, while Viewpoint's pin provider only serialized `activeIcons`; unrelated floor objects remain excluded. Bounded DebugLog traces record bridge installation, appended pin coordinates/state, empty results, or fallback.

## Version 2.0.124

- Makes the fixed Halo notification overlay follow vanilla `Toggle UI`: inventory-destination and trait notices hide with the HUD and return only while still active. Notifications expire during hidden-HUD time; bounded DebugLog traces record HUD state and overlay visibility.

## Version 2.0.123

- Scans registered timed-action queues instead of relying on a single Java-character table key. Repeated Ctrl+D and bone shortcuts now match the queued player and corpse by player number and stable corpse ID; Ctrl+G matches the same active forage pin across registered queues. Bounded lifecycle traces distinguish a forage action that only starts and plays its sound from one that completes or stops.
- Moves the animal corpse prompt farther above the target so the action rows clear Viewpoint's native tree-search menu.

## Version 2.0.122

- Replaces the confusing `Insomne` trait notice with `Menor necesidad de sueño (menos duración al dormir)` and explains the opposite `MoreSleep` trait. Sleep trait arrows consistently point up in green for beneficial changes and down in red for harmful changes; bounded DebugLog traces report the source direction, displayed direction, effect, color and translation fallback.

- Scales the floating corpse loot panel's rows, icons and text, and includes the scaled rows in the panel's content height so growing loot panels do not clip items. Bounded DebugLog entries record the selected scale and the font, row and tile dimensions before and after scaling.
- Adds separate animal corpse shortcut modifier and wear indicator selectors. The corpse panel can show its existing colored wear bar or a frame in the same wear color. Renames the native forage settings section to `Hallazgos con pin de rebusqueda`.
- Connects combat gesture capture to Project Zomboid and ZombieBuddy through an exposed Java bridge and records bounded stroke, classification and attack-selection diagnostics.

## Version 2.0.120

- Prevents repeated Ctrl+butcher or Ctrl+bones input from calling vanilla `walkAdj` again while that same action is queued for the same animal. Since `walkAdj` clears the current timed-action queue, retries could restart the action before completion. Moves the animal prompt upward to keep its action rows clear of the native Viewpoint tree menu.

## Version 2.0.119

- Prevents the modifier-key hook from querying `GameKeyboard.isKeyDownRaw` with Project Zomboid's unsupported key sentinel `10000`. Out-of-range binding codes preserve the original base-key decision and emit one bounded fallback diagnostic.

## Version 2.0.118

- Fixes a Viewpoint crash while drawing 3D forage arrows. ZombieBuddy injects the camera projection hook into `viewpoint.interact.ForageFinds`, so the transformed caller needs public access to the one-time warning flag. Projection failures now reach the existing bounded fallback diagnostic instead of disabling Viewpoint with `IllegalAccessError`.

## Version 2.0.117

- Removes TextureFix (Viewpoint)'s F10 scan callback from Project Zomboid's Java event registry before installing the bounded local replacement. The Lua event table exposes only `Add` and `Remove`, so the earlier 2.0.113 lookup through `event.callbacks` left the Workshop callback active. The local replacement avoids the Kahlua `getSimpleName` failure and logs the number of callbacks removed.

## Version 2.0.116

- Keeps fire-lighting tinder, kindle, and petrol transfers in the character's root inventory while their vanilla actions are queued. The selected-backpack routing no longer sends an ingredient into a nested bag that `ISLightFromLiterature` rejects on the first attempt. Bounded DebugLog traces record the callback, item type, and source container.

## Version 2.0.115

- Uses the animal corpse currently shown in the Viewpoint prompt if a fresh camera projection fails during the shortcut press. Bounded traces record the configured modifier, selected target, vanilla `walkAdj` result, and whether the expected butcher, bones, or corpse pickup action entered the queue.

## Version 2.0.114

- Opens native forage pin height calibration with F6 or Ctrl+F6 through a local Java bridge to Viewpoint's tuning fields. The bridge retries while Viewpoint loads and writes one bounded diagnostic when unavailable.
- Lets Ctrl+G collect a seen forage pin directly when Jill is already within 1.5 tiles and the vanilla forage action is valid there. Farther pins keep vanilla's `walkAdj` route. Bounded DebugLog traces record whether the forage action entered the queue.

## Version 2.0.113

- Adds a bounded local replacement for TextureFix (Viewpoint)'s broken F10 object scan. Version 2.0.117 fixes removal of the original Workshop callback; the replacement uses `getObjectName()` and sprite names, caps output at 64 objects, and logs failures only once.

## Version 2.0.112

- Records Ctrl/Alt/Shift left/right key transitions and logs each suppressed base-key binding once per physical press, including held modifier values and the binding's required modifiers. These bounded DebugLog entries help diagnose modifier shortcuts without logging every keyboard poll.

## Version 2.0.111

- Repairs Ctrl-drawn combat gesture selection. Vanilla `CombatManager.pressedAttack()` chooses from `WeaponType.getPossibleAttack()` through `WeightedList.getRandom()`; the prototype treated that weighted list as if it had `size()` and `get()`, so it rejected every gesture. The local patch temporarily narrows the vanilla choices to the gesture variant for the next click, then restores the original list.
- Uses Viewpoint availability for gesture sampling in first and third person. The stroke overlay can draw with a solid-dot fallback if the white texture is unavailable, and the DebugLog records recognition, arming, and vanilla fallback details.
- Fixes a startup `IllegalAccessError` in the strict modifier-key patch: the injected hook in `zombie.core.Core` calls `StrictModifierKeyBindings.isDown`, so that helper is public in the packaged 2.0.111 Java archive.

## Version 2.0.104

- Detects Ctrl+Shift+Delete directly on key start/press using the event's Delete key, so the shortcut does not depend on the Delete key still appearing held during the callback. The held-key polling remains as a fallback.

## Version 2.0.103

- Fixes Viewpoint native-tooltip pickup of ground logs, branches, and stones. The selected-container resolver compared the selected pane with `page.inventory`, but Build 42 updates both to the selected bag; it therefore mistook that bag for the root inventory. The resolver now compares against the character's actual root inventory. Items go to the selected bag first, overflow falls back per item to the main inventory, and a Halo explains why.

## Version 2.0.102

- Draws trait-change direction with a filled up/down triangle, matching the compact direction marker used by skill level-up notices. Trait notices keep their positive or negative colors.

## Version 2.0.101

- Removes the redundant Jill appearance renderer adapter. MirageWardrobe already cleans detached render snapshots according to its saved options; the extra adapter ignored those options and also altered the live HumanVisual during texture capture.

## Version 2.0.100

- Routes Viewpoint floor and forage pickups to the selected backpack when the native menu initially supplies the main inventory as its destination.
- Keeps the Viewpoint search-fog option labels and help text in Spanish even when a translation key is not resolved during page creation.
- Brightens native 3D raindrop tint from the base rain color when ClimateManager reports strong daylight; the adjustment is skipped at night and leaves the native tint values untouched.

## Version 2.0.99

- Sets native search fog intensity to 0.9 by default and expands its slider to 2.0. Values above 1 strengthen the fog opacity without changing the search radius.
- Translates the fog styles as `Oscuridad` and `Neblina`.

## Version 2.0.98

- Uses the native `ArrowUp` texture with the green `+1` text for skill level-ups, without a redundant skill icon. XP notices use the Carpentry icon for Woodwork and the B42 DumbBell item icon for Strength.

## Version 2.0.97

- Preflights Viewpoint floating-loot single-item and take-all actions. When the selected backpack cannot hold the pickup, it opens the alternate-destination menu instead of silently moving the item to the main inventory.

## Version 2.0.96

- Passes formatted arguments to the translator for item destination Halo notes, avoiding missing-argument warnings and preserving the item and destination names.
- Exposes the floor-destination Halo helper so animal-yield outputs can report each item's actual destination.

## Version 2.0.95

- Adds Mod Options sliders for the floating corpse-loot panel zoom and item wear marker size. Panel zoom also enlarges text and icons.

## Version 2.0.94

- The native search `Dark` depth layer now uses black instead of Viewpoint's gray scene-fog color. `Mist` keeps the scene color. The Spanish Mod Options page is titled `Ajustes de rebusqueda Viewpoint`.
- Butchered animal items now show a Halo with each item's backpack or floor destination.

## Version 2.0.93

- Adds aimed prompts and configurable keys for butchering, picking up animal corpses, and extracting bones from animal skeletons in Viewpoint. Bone extraction calls the vanilla `AnimalContextMenu.onGetAnimalBones` action; butchered items go to the selected backpack, and items that do not fit are dropped on the floor.

## Version 2.0.92

- The native forage height panel now opens with configurable F6 by default, with `Ctrl+Shift+Delete` retained. It uses Viewpoint's public tuning fields even when the Lua forage projection API is unavailable.

## Version 2.0.91

- Translates observed native and Workshop timed actions through the local Spanish overlay instead of showing their internal English class names.
- Adds Spanish labels for entering and exiting vehicles, changing seats, engine and door controls, windows, trailers, washing, and fuel transfers.
- Keeps the native forage pickup prompt synchronized with Viewpoint's projected pin and shows its key hint and identified item name above it.

## Version 2.0.90

- Routes custom progress, XP, level-up, and destination Halo text through the Spanish translation overlay. AutoMoveTo cursor travel now uses its localized action label.

## Version 2.0.89

- Translates the Viewpoint "Zombies nearby - slowing down" Halo notice into Spanish even when the custom translation key is not available at hook time.

## Version 2.0.88

- Adds context-matched vanilla B42 icons to XP and level-up notes, item destination notes, and recognized trait notices. Skill icons map to the closest matching B42 activity; unrecognized perks use the B42 skill-progress tile. Generic notices without a clear visual meaning stay text-only.

## Version 2.0.87

- Colors level-up text and its direction arrow green. Trait changes use the native arrow direction as a graphic shape instead of `+`/`-` text; beneficial traits are green and harmful traits pink-red, with matching arrow color.

## Version 2.0.86

- Shows one Halo note after each successful ground pickup, native forage pickup with G, or fish catch. Each note names the item and its actual destination, such as the selected backpack or main inventory; the catch note appears after vanilla fishing bookkeeping and any selected-backpack move.

## Version 2.0.85

- Routes vanilla `ISGrabItemAction` ground pickups, including stones, branches, and twigs, into the selected backpack when the item is allowed and fits. The destination is set on the timed action before it validates or queues; if it does not fit, the main inventory remains the destination. Caught fish use the same priority after vanilla catch bookkeeping.

## Version 2.0.84

- Replaces Viewpoint 0.1.7's thin condition strip in inventory-list rows with a compact square while preserving its wear colors and selection behavior, including floating corpse-loot lists.

## Version 2.0.83

- Centers the configured pickup key label above the native 3D forage pin targeted by the crosshair, with a small gap and screen-edge clamping.

## Version 2.0.82

- Shows the configured pickup key in a small label beside the native 3D forage pin targeted by the crosshair. The prompt uses the same pin selection and key binding as pickup, and hides when no eligible pin is aimed.

## Version 2.0.81

- Ports Viewpoint Foraging's default level-based search-bubble formula: the visible radius grows from the search minimum to maximum with Foraging level, applies profession/trait bonuses and visibility effects, and lets stacked penalties shrink it only to half of the level-based radius. It does not change the game's actual detection radius, search penalties, or item rolls. If manager modifiers are unavailable, it falls back to the exact game radius.

## Version 2.0.80

- Ports Viewpoint Foraging's separate circular depth-buffer fog renderer into this local fix.
  It draws a round search-radius layer over Viewpoint's 3D scene and reads the active Viewpoint
  depth/projection data, including the Iris path used by shader packs. The new `Round depth fog
  layer` option defaults on; turn it off to keep only Viewpoint's built-in fog. Viewpoint
  Foraging itself remains optional and is not enabled by this port.
- Keeps the fog layer tied to the existing native search-mode state, radius, style, intensity,
  and feather settings. Local compile and archive checks passed; Jill runtime behavior still
  needs confirmation.

## Version 2.0.79

- Retargets the assignable forage key to the closest seen native 3D search pin around
  the screen centre, using Viewpoint's own camera projection. Pressing the key delegates to the
  pin's normal `ISForageIcon` pickup callback; it does not enable Viewpoint Foraging.
- Uses the addon's former targeting limits as defaults: within 110 screen pixels and 12 tiles.

## Version 2.0.78

- Adds local controls for native search fog: enable/disable, Dark or Mist style, intensity,
  and edge feather. These options feed the existing Viewpoint fog bridge without enabling
  Viewpoint Foraging.

## Version 2.0.77

- Adds an assignable key in the local fix options to pick up the identified native forage pin
  under the cursor through the vanilla `ISForageIcon` action.
- Labels the fog and search-pin bridges as Viewpoint 0.1.7 native API integrations; the separate
  Viewpoint Foraging addon remains optional and is not needed for these functions.

## Version 2.0.76

- Fixes the 2.0.75 guard crash by exposing all injected helper state/methods to Viewpoint's package; the DebugLog showed an IllegalAccessError at the first game tick.

## Version 2.0.75

- Adds a null-slot guard for Viewpoint's zombie skeleton batch; if a batch is incomplete, the local patch clears it so animation falls back to the game's normal path.

## Version 2.0.74

- Fixes Viewpoint disabling its settings window when `SettingsPages` opens. The `@Patch` entry and exit advice now call public bridge methods, keeping private state access inside the patch class.

## Version 2.0.73

- Adds a temporary diagnostic hook around the Lua compiler. If parsing a script throws, it prints the active source path and chunk basename to `DebugLog.txt`; it does not suppress or alter the error.

## Version 2.0.72

- Adds a local Viewpoint model-pack provider for `IsoCarBatteryCharger`. It selects an empty or battery-connected 3D model from the charger's live battery state; the isometric sprite and the Viewpoint Workshop files remain untouched.
- Fixes the battery-charger texture guard advice so ZombieBuddy can apply it. The previous hook put `@Patch.Return` on `OnEnter`; the DebugLog showed ZombieBuddy rejecting it, which left the original null-sprite crash unguarded. The entry hook now skips `getTexture()` when the charger has no sprite, naturally returning null for the reference type.

## Version 2.0.70

- The Jill appearance adapter now respects MirageWardrobe's saved Clean Appearance state and per-option settings. Its renderer cleanup runs only while the setting is enabled, so the wardrobe can read, toggle, and verify the setting without showing the change-failed message.

## Version 2.0.69

- Prevents a Viewpoint battery charger menu error when `IsoCarBatteryCharger.chargerSprite` is null. The Java getter returns a null texture in that case, allowing the vanilla menu to omit only its icon and continue building the charger's actions.

## Version 2.0.68

- Fixes an `IllegalAccessError` that disabled Viewpoint's settings window: helper methods used by injected settings-page hooks are now public across the Viewpoint package boundary.

## Version 2.0.67

- Localizes Viewpoint settings page titles, descriptions, section captions, subtab labels, and window button tooltips through the Spanish catalog. Page widget IDs remain unchanged: title hooks translate only the visible read, and tab IDs use page plus index while the label array is translated. Top-level header literals drawn directly through native ImGui calls remain outside these hooks.

## Version 2.0.66

- Adds a Jill-only appearance adapter for MirageWardrobe. Render snapshots use detached, dry clothing copies with blood, dirt, holes, and patches removed; the real worn items and character visual values remain available to gameplay. The patch is ordered after MirageWardrobe42. Runtime validation in Jill is pending.

## Version 2.0.65

- Calls Viewpoint graphics settings and movable-camera state through the existing ZombieBuddy-exposed Java bridge. The bridge resolves and caches `SettingsWindow.update` and `FreeCam.active`, so the Lua code does not depend on the unavailable `luajava.bindClass` global.

## Version 2.0.64

- Waited quietly for the Lua Java bridge during startup and movable-camera monitoring. Version 2.0.65 now uses the existing ZombieBuddy-exposed bridge instead.

## Version 2.0.63

- Detects the transition into Viewpoint's movable-camera state, not the key press itself. It closes visible unpinned windows and collapses pinned windows, including vanilla inventory pages and Inventory Tetris windows/popups. If hiding an unpinned inventory page would also close a pinned Tetris popup, that page is collapsed to preserve the pinned popup. Pin states are preserved; windows stay closed or collapsed after the camera is released.
- Uses Viewpoint's `FreeCam.active` state from its local 0.1.7-rc4 JAR. No key bindings or Workshop files are changed.

## Version 2.0.62

- Schedules Viewpoint's graphics settings initialization once on the first game tick after OnGameStart, using its regular SettingsWindow.update path. This loads the saved live properties and links the selected shader pack before the player needs to open the panel with Delete. The bridge retries for up to 120 ticks if the Java class is not ready; runtime validation in Jill is pending.

## Version 2.0.61

- Adds a local adapter for Wall Texture Fix's `WallMesher.wall` hook on Viewpoint 0.1.7, whose new `IsoGridSquare` argument shifted the addon's expected float argument. The adapter calls the addon's renderer with its original argument layout and leaves Viewpoint's renderer in control when the addon is absent or the adapter cannot run.
- Orders this patch after Wall Texture Fix and PV Map Fix. The latter remains self-disabled until its Viewpoint 0.1.7 compatibility can be verified safely.
- Does not bridge `WallMesher.back`: Wall Texture Fix `PatchBack.enter` expects six object arguments, boolean/int/boolean, five floats, and a flags array; Viewpoint 0.1.7 supplies a `HiddenFaces.Face`, three other objects, five floats, and flags. No safe one-to-one mapping is documented, so the adapter only covers `wall`.

## Version 2.0.60

- Adds Spanish action labels for the logged `ISOpenMechanicsUIAction` and `ISDetachItemHotbar` classes.

## Version 2.0.59

- Localizes the native search-fog controls and Viewpoint's menu framerate labels in Spanish.

## Version 2.0.58

- Offers the alternate destination menu for mixed Viewpoint loot batches whenever any item exceeds the selected container's capacity, while retaining items that already fit there.


> **Resumen:** paquete local de compatibilidad para Viewpoint y sus integraciones. Cada ajuste comprueba si existe la API correspondiente; las funciones que dependen de una API aún no publicada permanecen inactivas.

## Version 2.0.49

- Adds the same heap-pressure fallback to `TownPaving.join`, where six temporary float arrays caused the next OOM after the relief sweep guards ran.

## Version 2.0.48

- Extends the heap-pressure guard to `ReliefSweeps.between` and `bank`, whose scratch arrays run after `graded`. It also skips `blurred` allocations under pressure and reuses that method's input array as the fallback. This keeps the relief build from immediately moving the same OOM to the next allocation-heavy step.

## Version 2.0.47

- Fixes access to the heap guard's warning state from Viewpoint's inlined advice. The state is public so the transformed `ReliefSweeps.graded` method can use it without `IllegalAccessError`.

## Version 2.0.46

- Adds a heap-pressure guard to every `ReliefSweeps.graded` overload. Advice without argument binding avoids overload ambiguity; it skips grading below 1.5 GiB of heap headroom (scaled down for smaller heaps), leaves the incoming relief field unchanged, and logs the fallback once. Other Viewpoint features remain available; distant relief may be less graded in that session.

## Version 2.0.44

- Dibuja todos los Halo Notes del parche detras de ventanas, inventarios y tooltips, con texto compacto del mismo tamano que la etiqueta de la barra de progreso.

## 🧭 En esta página

- [Cambios recientes](#version-2065)
- [Barra de progreso](#barra-de-progreso-2036)
- [Rebúsqueda, pines y neblina](#neblina-del-radio-de-rebúsqueda-integrada)
- [Protección del menú del mundo](#objetos-sin-nombre-de-sprite-en-el-menú-del-mundo)
- [Funciones del paquete](#halo-de-subida-de-habilidad-y-colores-de-rasgos)
- [Historial de versiones](#cambios-de-202025)


## Equipar desde cadáver

- Mantiene las armas tomadas de cadáveres en el inventario principal durante la transferencia para que `ISEquipWeaponAction:isValid()` las encuentre antes de equiparlas; no las desvía a la mochila seleccionada.

## Version 2.0.42

- El zoom conjunto de pin, circulo e icono es global en toda la rebusqueda, haya anclas guardadas o no. Aplicar un cambio actualiza todas las zonas en la sesion; Guardar aqui lo conserva en `Zomboid/Lua`. Las anclas solo determinan la altura por ubicacion. Los archivos antiguos sin una linea global migran el ultimo zoom guardado.

## Version 2.0.41

- La barra naranja lee la cola temporizada vanilla de B42, se coloca al 57% de la altura de pantalla y no consulta el estado de Viewpoint ni depende de ViewpointUI. Chila confirmo que queda alineada con la barra vanilla y que esta ultima se oculta.
- Cada tipo de accion visto en la cola deja una linea `[ACTIVATION]` en `DebugLog.txt`, una sola vez por sesion. La linea incluye clase, modo, si quedo cubierta por la barra custom, etiqueta usada, si la etiqueta es especifica y los flags vanilla originales; sirve para encontrar clases nuevas y completar sus textos.

## Versión 2.0.36

## Barra de progreso 2.0.36

- Elimina la dependencia de `Controller` y `Executor` de ViewpointUI para la barra de progreso.
- No consulta `Viewpoint.Loot.viewOn()` ni necesita que ViewpointUI este activo. Lee `ISTimedActionQueue` y dibuja el overlay local sin depender del estado de Workshop.
- Sigue las acciones temporizadas mediante `ISTimedActionQueue`, toma la etiqueta de sus metadatos o tipo y usa `OnPostUIDraw` si UIManager omite el render de la barra naranja. Solo oculta la barra vanilla después de dibujar la personalizada. Incluye la rebúsqueda porque vanilla desactiva su barra para `ISForageAction`.
- La barra local no modifica archivos de Workshop. Las demas compatibilidades opcionales siguen disponibles cuando sus respectivos mods estan activos.

## Barra de progreso

- 2.0.34 synchronizes the custom overlay's Lua visibility flag with its Java UI
  element. Version 2.0.33 changed only Java visibility; the overlay renderer
  still returned early because `self.visible` remained false.

## Recolección de cristales sin Isometric No More

- Keeps the Viewpoint broken-glass action labeled `Juntar cristales rotos` and
  prioritizes the functional pickup action, removing duplicate pickup entries.
- The Viewpoint core action hook works without Isometric No More. The optional
  Viewpoint UI registry hook installs only when that API is present.
- The existing glass destination hook sends picked-up glass to the selected
  inventory when the native moveable pickup callback creates it.
- Accessible Actions already handles recipe completion and queued thread batches;
  Animal Balance already routes animal products to the selected container or floor.

## Neblina del radio de rebúsqueda integrada

- Ports the Workshop search fog behavior into this patch's Java bridge. When Viewpoint's
  integrated `ViewpointForage.found` API and search mode are active, it narrows the frame's
  depth-fog start/end to the live `ISSearchManager` radius and fades the vanilla 2D overlay.
- The fog radius eases between updates; the fog color and desaturation use the active search
  overlay values. The patch has its own guarded renderer hook and does not require enabling the
  separate Viewpoint Foraging mod.
- `Options > Mods > ChilaSeda Viewpoint Fix` includes an enable toggle, `Dark`/`Mist` style,
  intensity slider from 0 to 1, and edge feather slider. These adjust native search fog without
  changing the manual pin zoom.
- The bridge and options use Viewpoint 0.1.7's native `ViewpointForage.found` API; the separate
  Viewpoint Foraging addon is not required or activated. Minecraft shader-pack radius overlays
  still need a separate depth-buffer layer; the addon source that implements it is not installed
  in this workspace.

## Recoleccion de hallazgos nativos por tecla

- `Options > Mods > ChilaSeda Viewpoint Fix` includes an assignable `Pick up aimed find` key
  (default G). During native search mode, aim the cursor at a visible, identified forage pin and
  press the key. The patch calls the vanilla `ISForageIcon` double-click path, which queues the
  normal `ISForageAction`, validates container space and walks to the find as usual.
- This binding reads only native `ISSearchManager.forageIcons`; it does not load or require
  `ViewpointForaging/VPF_Core`, nor does it change vanilla collection behavior when the key is not
  pressed. Runtime confirmation in Jill is pending.

## Calibración de la rebúsqueda integrada

- The calibration panel opens with a configurable key in `Options > Mods > ChilaSeda Viewpoint Fix`
  (F6 by default); `Ctrl+Shift+Delete` remains available as a shortcut.
- Applies saved area height offsets to the native `findPinUp` tuning and visual zoom to
  `findPinHeight`. The current native renderer uses one scale for the pin and item image, so the
  panel's pin, circle, and icon zoom values are averaged into that shared scale.
- The panel requires Viewpoint's public `Tuning` fields, but does not require the Lua
  `ViewpointForage.found` API. When that API is available, the Java projection bridge also corrects
  the arrow orientation; otherwise Viewpoint keeps drawing its native arrow while the height and
  scale controls still apply.
- Uses Viewpoint's own relief lift; it no longer requires the separate `ViewpointForaging` or
  `ViewpointRollingHills` projection hooks. The renderer orientation fix also accounts for the
  active camera shot's yaw, pitch, and roll.
- The shortcut, stored offsets, and tuning bridge are checked locally by source review only. They
  still need confirmation in Jill with the active Viewpoint release.
- Pin zoom remains the manually selected global value. The native renderer reads the shared tuning
  before drawing each frame; calibration writes only when that value changes, so routine pin draws
  do not reset the selected zoom.
- Its calibrator now has a unique Lua module name and separate config/report files from the
  Viewpoint Foraging calibrator. This prevents `require` caching and shortcut handling from
  crossing between the two patches. It does not require the `ViewpointForaging` addon ID. If the
  public `Tuning` fields are unavailable, calibration stays inactive; if only the Lua forage API is
  unavailable, height and scale calibration remain available and arrow projection stays native.

## Zoom global para pines

- Guardar aqui aplica el zoom elegido de pin, circulo e icono a todas las anclas guardadas. La altura manual se conserva por ubicacion.

## Flechas de rebusqueda 3D de Viewpoint

- Reorients the native 3D find arrow using Viewpoint's active camera yaw/pitch and the pin's raised
  position, so the arrow follows the pin's projected direction while leaving the pin coordinates
  and marker placement unchanged. If the camera or pin data is unavailable, the native calculation
  remains as fallback.
- The Java arrow projection is gated by Viewpoint 0.1.7's native `ViewpointForage.found` API. If
  that API is absent, the patch leaves Viewpoint's original `ForageFinds.arrow` implementation
  untouched. This gate is independent of the separate Viewpoint Foraging addon ID.
- Requires Viewpoint and ZombieBuddy 2.3.4. Runtime confirmation in Jill is pending.

## Objetos sin nombre de sprite en el menú del mundo

- Guards the vanilla `ISWorldObjectContextMenuLogic.fetch` call used while Viewpoint builds its
  interaction and loot menus. If the current `IsoObject` is null or has no sprite name, the patch
  skips only that object so the vanilla fetch does not throw on `spriteName.equals(...)`.
- Objects with a valid sprite continue through the original menu code. The guard logs only the first
  skipped object in a session.

## Cambios de 2.0.20

- Prevents a null sprite name on one world object from breaking Viewpoint's world interaction menu.

## Cambios de 2.0.32

- Persists the selected pin, circle, and icon zoom across all saved anchors while keeping height corrections location-specific.

## Cambios de 2.0.33

- Toggles the standalone orange progress overlay with `ISUIElement:setVisible`, updating the Java UI object that UIManager renders.

## Cambios de 2.0.36

- Adds an `OnPostUIDraw` fallback for the labeled orange overlay. Some B42/Viewpoint
  UI stacks showed the native progress bar while the registered overlay's `render`
  callback never ran; the fallback draws it once per frame and suppresses vanilla
  only after that draw. Marks foraging as a required custom-bar action because
  vanilla disables its own bar for `ISForageAction`.

## Cambios de 2.0.31

- Draws a dedicated orange progress overlay regardless of ViewpointUI HUD registration; the vanilla bar is suppressed only after the orange bar actually renders.

## Cambios de 2.0.28

- Replaces Viewpoint timed actions' native green progress bar with the labeled orange bar and
  restores each action's original progress-bar flags when Viewpoint is inactive.
- Makes the Java search-fog renderer bridge public so ZombieBuddy's `IsoCell.render` advice can
  call it without `IllegalAccessError`.

## Cambios de 2.0.19

- Ports the projected-direction correction to Viewpoint 0.1.7's native 3D foraging renderer.

## Halo de subida de habilidad y colores de rasgos

- Intercepts the native Java `HaloTextHelper` call used by `IsoGameCharacter.LevelPerk`;
  skill level-ups now appear in the fixed Viewpoint overlay instead of the vanilla halo.
- Colors the shown beneficial traits green and harmful traits pink-red, including Low Thirst,
  Slow Healer, and Prone to Illness, regardless of the direction arrow. The overlay draws direction
  arrows as graphics and applies the same semantic color to both arrow and message. Thirst, injury,
  illness, and sleep traits use their matching vanilla Moodle icons; unmatched messages do not get
  a generic decorative icon.
- Requires ZombieBuddy 2.3.4 for the narrow Java hook.
- Accessible Actions calls to `HaloTextHelper` use the same fixed notice overlay; its food-purge
  notices use the direct `showFixed` route to preserve each removed item's icon.

## Barras de progreso de transferencia

- Shows the labeled orange Viewpoint action bar in place of the native green timed-action
  bar. The original `useProgressBar` and `forceProgressBar` values are saved and restored
  when Viewpoint is inactive; the orange bar retains its Spanish action label.
- Labels Accessible Actions' timed washing and fat-combining jobs as `Lavando vendaje` and
  `Combinando grasas`; these labels are added only when those queued actions run.

## Correcciones de caracteres compatibles con Jill

- Selected-container notices use "esta" without an accent, and trait-change
  notices use `+` and `-` instead of Unicode arrows because Jill displayed those
  characters as `?`.

## Cambios de 2.0.16

- Traduce la etiqueta explícita de progreso `Remove Broken Glass` que usa el
  menú de Viewpoint UI, además del nombre de la acción vanilla.

## Cambios de 2.0.15

- Traduce la etiqueta de progreso de Viewpoint para apagar una fogata como
  "Apagando fogata,â€" whether the label comes from the action type or its text.

## Cambios de 2.0.14

- When the selected bag cannot accept all requested loot, stops routing overflow
  into other worn bags and opens a menu of destinations that can accept the
  remaining items. Choosing a destination updates the selected inventory; the
  player can then retry the transfer.
- Keeps partial take-all batches within the selected bag and leaves items that
  do not fit in their source container.

## Cambios de 2.0.13

- Resolves transfer destination container names from their owning item and
  localized item key before falling back to an internal type ID.
- Wraps multiline action labels into variable-height rows and reserves enough
  room for the footer so trailer options no longer overlap.
- Replaces corrupted up/down arrow text in Halo trait notices with readable
  arrows. Accepts vanilla inventory textures for food purge notices.

One local package contains the fixes for Viewpoint and its UI integration. Each
feature uses protected module loading and checks for the API it patches. The
package can load without any of these Workshop mods; a missing or incompatible
API skips only its related fix.

- **Selected loot destination:** routes Viewpoint pickups from floors and
  containers to the selected player container. If it is full, the transfer
  stops and offers only destinations with enough space; choosing one changes
  the selected inventory before the player retries.
- **Foraging pickup routing:** uses the selected container only while
  Viewpoint Foraging is active.
- **Corpse loot:** routes corpse transfers into the selected container when
  possible; refreshes cached loot after inventory changes and sorts weapons
  first, other items next, and clothing last.
- **Seated rotation:** restores manual rotation while seated.
- **Action progress:** uses the labeled orange progress bar for queued
  Viewpoint actions, with a slim 3-pixel minimum matching Chila's preferred
  screenshot reference, while keeping the native action and inventory bars visible.
- **Broken-glass pickup:** routes the animated Viewpoint glass-gather action to
  the selected container when it has room; if it cannot accept the glass, the
  item stays in the main inventory and a Halo notice explains the fallback.
- **Quick dismantling:** prioritizes movable furniture and invokes the selected
  dismantling action through Viewpoint UI.
- **Halo notices:** preserves inline item icons and directional arrows and
  displays local notices as fixed-screen subtitles. These are passive overlays
  and do not accept mouse input. Trait-change notices use a plain style and a
  vanilla B42 moodle icon, selected for thirst/sleep messages when recognizable.
- **Food purge notices:** accepts a vanilla inventory texture as an inline icon
  so Accessible Actions can show each deleted food type in its Halo notice.

## Cambios de 2.0.1

- Explicitly loads after the local Accessible Actions package so its action and
  transfer hooks compose in the profile's intended order.
- Reviewed the 2026-11-06 console and DebugLog: the Viewpoint package loaded its
  seven scripts without a Lua exception. Logged cursor warnings point to the
  separate Foraging calibration window and passive halo overlay; no proven
  Viewpoint exception was available to justify a speculative behavioral change.

## Cambios de 2.0.2

- Draws the action bar with a saturated orange fill at a real minimum thickness
  of 10 pixels. The prior code raised the widget height but ViewpointUI's own
  renderer still drew a 3-pixel fill.

## Cambios de 2.0.3

- Preserves the `QuickLoot.tick` argument order while checking for corpse loot
  content changes. The prior wrapper passed the timestamp as the entries table,
  causing `ipairs` to fail and Viewpoint UI to stop after five ticks.

## Cambios de 2.0.4

- Forces the orange labeled bar for dismantling, drinking, and animal butchering
  actions even if a mod disables the vanilla progress flag. Adds a Spanish label
  for dismantling and caps per-action diagnostics at three lines per action type.

## Cambios de 2.0.5

- Keeps Viewpoint UI's controller running if the QuickLoot hook receives malformed
  entries. It retries the supported `QuickLoot.wants` lookup, resets only the loot
  panel when the list is still invalid, and logs the condition once until recovery.

## Cambios de 2.0.6

- Styles Dynamic Traits arrow notices as framed cards and adds a reused vanilla
  moodle icon; thirst and sleep labels use their matching B42 icons.

## Cambios de 2.0.7

- Reduces the custom orange progress fill from 10 to 5 pixels so it remains
  legible without looking heavy, matching Chila's preferred screenshot reference.

## Cambios de 2.0.8

- Routes vanilla `ISPickupBrokenGlass` results after `ISMoveableSpriteProps` adds
  them directly to the main inventory, using the selected container when
  possible and showing a notice when it is full or the transfer cannot start.

## Cambios de 2.0.9

- Translates the vanilla `ISRemoveBrokenGlass` progress label and recipe labels
  for `MakeSalad` / `MakeFruitSalad`; composite "complete recipeâ€" labels resolve
  their recipe name too.

`Viewpoint`, `ViewpointForaging`, `ViewpointUI`, and NeatUI integrations are
optional. `loadModAfter` supplies ordering hints when those mods are present;
none is a hard requirement. The two Viewpoint corpse-transfer wrappers are
kept together and composed in load order. Their inventory page changes are
restored after the wrapped transfer returns.

Workshop files are unchanged. The unified local mod ID is
`ChilaSeda_Fix_Viewpoint_B42`.

## Cambios de 2.0.25

- Keeps the broken-glass pickup filter available with Viewpoint core alone and
  promotes the native disassemble action for moveable objects without requiring
  ViewpointUI or Isometric No More.
- Draws the labeled orange action bar for timed actions with native progress, without checking `Viewpoint.Loot.viewOn()` or depending on ViewpointUI. The vanilla bar is suppressed only after the local orange bar renders for that action.
- Routes OSRS Experience Bar (`RUNE-EXP`) fractional XP drops through the fixed
  Halo notes overlay while leaving its own XP bar and drops intact.
- Batch crafting, selected-container transfers, and butcher output routing
  already come from active local patches and do not depend on ViewpointUI.

## Cambios de 2.0.26

- Registers the standalone pure-Viewpoint progress overlay with
  `ISUIElement:addToUIManager()` so the UI manager receives its native element
  instead of the Lua wrapper table.
- Keeps the vanilla action bar visible until the orange labeled overlay has
  actually rendered for that timed action. The pure-Viewpoint overlay updates
  on `OnTick`; if the custom widget is absent or fails to draw, the native
  progress bar remains available.

## Cambios de 2.0.27

- Makes the search-fog bridge entry point public so ZombieBuddy's inlined
  `IsoCell.render` advice can call it without `IllegalAccessError` every frame.

## Cambios de 2.0.30

- Does not disable an action's native progress until the orange labeled renderer
  has actually drawn that action. This keeps a visible fallback if the custom UI
  is not initialized or fails to render.
- Drives the pure-Viewpoint overlay from `OnTick` before UI rendering and logs
  the first successful custom draw so the next Jill session can verify which
  renderer is active.


---

### 🔗 Otros enlaces de interés

- [Viewpoint UI Workshop Fixes](Documentacion/ViewpointUI_0.5.0_README.md)
- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)


## 2.0.52 - Fishing cursor retention

While the native FishingState is active, the local fix marks the active fishing interaction as a temporary Viewpoint QOL device state so its existing cursor-unlock path does not recapture the mouse. The marker clears as soon as fishing ends. The patch loads after ProjectViewpointQOL when that mod is installed.


## 2.0.53 - Fishing action labels

Adds named orange progress labels for the vanilla BBQ add-fuel and extinguish actions, fish pickup, and lure attachment actions reported by Chila.


## 2.0.54 - More BBQ and fishing labels

Adds named orange progress labels for the other native fishing net, bait, chum, rod, and BBQ propane actions found in B42 source.


## 2.0.55 - Name drainable items in consolidation progress

Consolidation progress uses the destination item name, such as Consolidando Hilo, rather than calling every drainable item a liquid.

## 2.0.56 - Keep vanilla selected-container pickup routing available

The selected-container patch no longer exits when the optional `Viewpoint_Loot` API is absent. Vanilla inventory transfers from floor items still route through the selected-container hook; Viewpoint-specific hooks remain conditional on their API.


## 2.0.57 - Name the consolidation destination

The consolidation progress label now uses intoItem:getName() first, with the consumed item name as a fallback. This identifies the object being consolidated, including thread and other non-liquid items.


## 2.0.105 - Require Ctrl for forage and animal actions

Native Viewpoint forage pickup now requires Ctrl plus its configured key (G by default). Animal butchering, bone extraction, and corpse or skeleton pickup also require Ctrl plus their configured keys. The on-screen prompts and Mod Options help identify the modifier; existing key choices remain configurable.


## 2.0.107 - Use Ctrl gestures before the attack click

Hold Ctrl while moving the camera to draw a gesture, then click to attack (the click can happen before releasing Ctrl). The gesture must finish in under one second; its matching vanilla-supported melee variant is consumed by that attack only. A right-to-left stroke requests a swing, a downward stroke an overhead attack, an ascending diagonal an uppercut or swing, and a curved ascending C requests a floor attack when allowed by the held weapon. The trace and label are drawn on screen; without a compatible gesture, vanilla combat remains in control.


## 2.0.106 - Add camera gesture melee prototype

Initial prototype, superseded by 2.0.107: the detector required holding right mouse while drawing. No runtime confirmation was recorded for that input scheme.


## 2.0.108 - Avoid the vanilla H panel shortcut for animal bones

The first local workaround moved the bone key to F8 because base H shortcuts still fired with Ctrl held. Version 2.0.110 restores H and corrects the shared input dispatch so modifiers form strict chords.


## 2.0.109 - Configure modifiers for Viewpoint action shortcuts

Mod Options now lets the player choose Ctrl, Alt, Shift, or combinations of these modifiers for native forage pickup and animal corpse actions. Each action keeps its own configurable base key, and the on-screen prompts show the selected chord. The default remains Ctrl.


## 2.0.110 - Treat modifier shortcuts as strict chords

The game now suppresses an unmodified key binding whenever its base key is pressed with Ctrl, Alt, or Shift. The custom chord action runs on key-down and consumes the matching key-up event, so `Ctrl+H` can collect bones without opening the Health panel or Hunter Expansion info. The default bone key is H again.
