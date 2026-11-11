# ChilaSeda Fix - Viewpoint Workshop Fixes (B42) 2.0.37

> **Resumen:** paquete local de compatibilidad para Viewpoint y sus integraciones. Cada ajuste comprueba si existe la API correspondiente; las funciones que dependen de una API aún no publicada permanecen inactivas.

## 🧭 En esta página

- [Cambios recientes](#equipar-desde-cadáver)
- [Barra de progreso](#barra-de-progreso-2036)
- [Rebúsqueda, pines y neblina](#neblina-del-radio-de-rebúsqueda-integrada)
- [Protección del menú del mundo](#objetos-sin-nombre-de-sprite-en-el-menú-del-mundo)
- [Funciones del paquete](#halo-de-subida-de-habilidad-y-colores-de-rasgos)
- [Historial de versiones](#cambios-de-202025)


## Equipar desde cadáver

- Mantiene las armas tomadas de cadáveres en el inventario principal durante la transferencia para que `ISEquipWeaponAction:isValid()` las encuentre antes de equiparlas; no las desvía a la mochila seleccionada.

## Versión 2.0.36

## Barra de progreso 2.0.36

- Elimina la dependencia de `Controller` y `Executor` de ViewpointUI para la barra de progreso.
- Detecta si la vista de Viewpoint está activa mediante `Viewpoint.Loot.viewOn()`. La tabla global `ViewpointLoot` solo es un espacio de nombres, no una señal de actividad.
- Sigue las acciones temporizadas mediante `ISTimedActionQueue`, toma la etiqueta de sus metadatos o tipo y usa `OnPostUIDraw` si UIManager omite el render de la barra naranja. Solo oculta la barra vanilla después de dibujar la personalizada. Incluye la rebúsqueda porque vanilla desactiva su barra para `ISForageAction`.
- Conserva intactos los archivos de ViewpointUI en Workshop. Las demás compatibilidades opcionales del parche siguen disponibles cuando ese mod está activo.

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
- The official installed Viewpoint 0.1.6.2 does not yet expose the integrated forage API, so the
  new path stays inactive until that API appears in an official release. Minecraft shader-pack
  radius overlays still need a separate depth-buffer layer.

## Calibración de la rebúsqueda integrada

- Ports the existing calibration window into this active Viewpoint fix package. It opens with
  `Ctrl+Shift+Delete` when Viewpoint exposes its native `ViewpointForage.found` API.
- Applies saved area height offsets to the native `findPinUp` tuning and visual zoom to
  `findPinHeight`. The current native renderer uses one scale for the pin and item image, so the
  panel's pin, circle, and icon zoom values are averaged into that shared scale.
- Uses Viewpoint's own relief lift; it no longer requires the separate `ViewpointForaging` or
  `ViewpointRollingHills` projection hooks. The renderer orientation fix also accounts for the
  active camera shot's yaw, pitch, and roll.
- The shortcut, stored offsets, and tuning bridge are checked locally by source review only. They
  still need confirmation in Jill with the official integrated Viewpoint release.
- Its calibrator now has a unique Lua module name and separate config/report files from the
  Viewpoint Foraging calibrator. This prevents `require` caching and shortcut handling from
  crossing between the two active patches. When the installed Viewpoint lacks the integrated
  forage API, its calibrator shortcut stays inactive and leaves the Foraging calibrator available.

## Zoom global para pines

- Guardar aqui aplica el zoom elegido de pin, circulo e icono a todas las anclas guardadas. La altura manual se conserva por ubicacion.

## Flechas de rebusqueda 3D de Viewpoint

- Reorients the native 3D find arrow using Viewpoint's active camera yaw/pitch and the pin's raised
  position, so the arrow follows the pin's projected direction while leaving the pin coordinates
  and marker placement unchanged. If the camera or pin data is unavailable, the native calculation
  remains as fallback.
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
- Colors the shown beneficial traits green and harmful traits red, including Low Thirst,
  Slow Healer, and Prone to Illness, regardless of the direction arrow.
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
- Draws the labeled orange action bar through a standalone UI overlay when
  ViewpointUI is absent. The native timed-action bar stays visible as a fallback
  until the orange bar actually renders for that action; then it is suppressed.
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
