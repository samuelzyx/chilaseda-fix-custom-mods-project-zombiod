<div align="center">

<img src="../../docs/branding/chilaseda-atom-bio-header.jpg" width="108" alt="Avatar de ChilaSeda">

# 🧟 Kit Zombicidio Jill

**Una guía para montar una partida parecida · Project Zomboid Vanilla B42.22.2**

<a href="https://steamcommunity.com/sharedfiles/filedetails/?id=3812814868">🧰 Colección de Steam</a> ·
<a href="https://github.com/samuelzyx/chilaseda-fix-custom-mods-project-zombiod/releases">🚀 Releases</a> ·
<a href="https://www.atom.bio/chilaseda">📺 Canales de ChilaSeda</a>

</div>

---

> ⚠️ El kit comparte listas y ajustes; no redistribuye los mods de terceros. Haz una copia del
> guardado antes de reemplazar archivos.

### Accesos rápidos del catálogo

- [🌱 Mods recomendados para evaluar](mods_en_pausa.md#recomendados-para-evaluar)
- [🧪 Candidatos a ports locales Build 42](mods_en_pausa.md#candidatos-a-ports-locales-build-42)
- [⏸️ Mods en pausa y sus fichas de Steam](mods_en_pausa.md#mods-en-pausa)

## ⬇️ Descarga el kit

Clona el repositorio con Git:

```powershell
git clone https://github.com/samuelzyx/chilaseda-fix-custom-mods-project-zombiod.git
```

O abre el repo en GitHub, pulsa **Code → Download ZIP** y extrae el archivo. Continúa en
`kits/Zombicidio_Jill_B42/`. La [descripción de la colección](Descripcion_Coleccion_Zombicidio.txt)
resume estos pasos para compartirlos en Steam.

---

## 🧩 Prepara los mods

1. Suscribete a los mods de terceros de la [coleccion Zombicidio](https://steamcommunity.com/sharedfiles/filedetails/?id=3812814868) y espera a que Workshop termine de descargarlos.
2. Instala [ZombieBuddy](https://steamcommunity.com/sharedfiles/filedetails/?id=3619862853), requisito de Project Viewpoint.
3. Suscribete a [Project Viewpoint](https://steamcommunity.com/sharedfiles/filedetails/?id=3809306528) y a
   [Isometric No More](https://steamcommunity.com/sharedfiles/filedetails/?id=3819166046). El kit
   agrega la version 0.1.23 para Viewpoint 0.1.6.2. El addon integra las acciones 3D del menu y
   cursores nativos para colocar objetos. Revisa Opciones > Mods > Isometric No More y asigna
   confirmar/cancelar. Viewpoint 0.1.7+ integra estas funciones; al actualizar desde Workshop,
   desactiva el addon independiente.
4. Copia las **38 carpetas locales ChilaSeda** de este repositorio como carpetas hijas de
   `%USERPROFILE%\Zomboid\mods\`. Conserva cada carpeta completa y sus subcarpetas `42`; no las
   copies a la carpeta de Workshop.

<details>
<summary>📂 Ver las 38 carpetas locales del perfil</summary>

```text
ChilaSeda_AccessibleActions_B42
ChilaSeda_AlbumDelSuperviviente_B42
ChilaSeda_AnimalBalance_B42
ChilaSeda_AnomalousStorm_B42
ChilaSeda_AuditSuite_B42
ChilaSeda_AutoCook_B42
ChilaSeda_Fix_Authentic_Z_InstantCraft_B42_2335368829
ChilaSeda_Fix_BetterFlashlights_Lighting_B42
ChilaSeda_Fix_Check_Around_VoiceLineLists_B42_3300688173
ChilaSeda_Fix_CustomIntros_B42
ChilaSeda_Fix_Doggy_Library_RayBeam_B42_3428272880
ChilaSeda_Fix_EquippedFuel_B42
ChilaSeda_Fix_Hunter_Expansion_Filth_B42_3786994541
ChilaSeda_Fix_MiniCompass_Position_B42
ChilaSeda_Fix_NeatUI_Core_Format_B42_3818729237
ChilaSeda_Fix_Project_Zomboid_AutoTools_B42_Vanilla
ChilaSeda_Fix_Project_Zomboid_ForestMelee_B42_Vanilla
ChilaSeda_Fix_Project_Zomboid_PoisonKnowledgeIcon_B42_Vanilla
ChilaSeda_Fix_Project_Zomboid_TimedActionSpeed_B42_Vanilla
ChilaSeda_Fix_ProjectZomboid_FloorTileCapacity_B42_Vanilla
ChilaSeda_Fix_ProperRagdolls_Death_Sounds_B42_3821280085
ChilaSeda_Fix_Reactive_Sound_Events_Viewpoint_B42_3656190498
ChilaSeda_Fix_Sandbox_Options_ContextMenu_B42_3386906181
ChilaSeda_Fix_SecondaryBackpackDrop_B42
ChilaSeda_Fix_True_Weight_VanillaWeights_B42_3768669395
ChilaSeda_Fix_Viewpoint_B42
ChilaSeda_Fix_ViewpointForaging_B42_3814994364
ChilaSeda_Fix_VisualSounds_UndeadWildlife_Colors_B42
ChilaSeda_Fix_Water_Pipes_ModData_B42_3546314080
ChilaSeda_IngameLuaReload_B42
ChilaSeda_InventoryTetrisSizeCap_B42
ChilaSeda_LugliAchievements_Recent_B42
ChilaSeda_RecentMapSymbols_B42
ChilaSeda_RetroDashboardChargeIndicator_B42
ChilaSeda_Scamp13RVWindows_B42
ChilaSeda_SmartRadialNativeOptions_B42
ChilaSeda_TIYLReadOpensJournal_B42
ChilaSeda_Translations_ES_B42
```

</details>

### 🗂️ Archivos de partida incluidos

| Archivo | Dónde se usa |
| --- | --- |
| [`mods.txt`](mods.txt) | Orden de carga de referencia para Jill. |
| [`map_ver.bin`](map_ver.bin) | Acompaña a `mods.txt` en el guardado. |
| [`Sandbox Presets/Zombicidio.cfg`](Sandbox%20Presets/Zombicidio.cfg) | Preset para crear el mundo Sandbox. |
| [`configs/`](configs/README.md) | Teclas, opciones de mods y ajustes de Viewpoint de Jill. |

### 🛠️ Ajustes manuales de compatibilidad en `mod.info`

Durante la preparación de Jill se hicieron estos ajustes locales de metadatos para B42.22.2:

- [Viewpoint Foraging](https://steamcommunity.com/sharedfiles/filedetails/?id=3814994364) (`ViewpointForaging`): se ajustó el metadato de versión para incluir B42.22.2; la instalación actual declara `versionMin=42.21` y `versionMax=42.22.2`.
- [6282 3D models for Viewpoint](https://steamcommunity.com/sharedfiles/filedetails/?id=3810302175) (`PZVoxelStudioViewpoint`): se corrigió `mod.info` en la copia local para B42.22.2. El Workshop actual también declara `versionMin=42.21.0` y `versionMax=42.22.2`.
- [Grassier Grass (Viewpoint)](https://steamcommunity.com/sharedfiles/filedetails/?id=3818853354) (`GrassierGrassViewpoint`): se movió `mod.info` a la carpeta `42` y se ajustó a `versionMin=42.22` y `versionMax=42.22.2`, pero **el mod siguió sin funcionar en Jill**. No se presenta como compatibilidad resuelta.

Los cambios de `mod.info` son metadatos locales y no garantizan que el código del mod funcione.
Una actualización de Workshop puede reemplazarlos; revisa las notas del autor y vuelve a comprobar
la compatibilidad antes de repetir un ajuste.

La referencia usa **Project Zomboid Vanilla B42.22.2**. Las versiones instaladas de los mods de
Workshop pueden cambiar; comprueba sus notas en Steam y revisa el registro de
[`mods_en_pausa.md`](mods_en_pausa.md) antes de limpiar suscripciones.

---

## 🎮 Crea una partida parecida a Jill

1. Copia `Sandbox Presets/Zombicidio.cfg` en `%USERPROFILE%\Zomboid\Sandbox Presets\`.
2. Crea un mundo nuevo en Sandbox, selecciona el preset `Zombicidio` y activa los mods de la colección y las carpetas locales.
3. Para la apariencia de Jill, instala `[COS] RE:3 Remake Jill` desde Workshop y selecciona `RE3_Jill`.
4. Para recrear su personaje, elige la ocupación **Pescador** y los rasgos **Insensible, Manitas, Poca sed, Insomne, Propenso a enfermar, Sanador lento, Robusto, Bajo peso** y **Metabolismo lento**.

## ⚙️ Carga las configuraciones de Jill

La [guía de destinos de configuración](configs/README.md) muestra la ruta de cada archivo. En
resumen: el contenido de `configs/Lua/` va dentro de `%USERPROFILE%\Zomboid\Lua\`; los archivos
`.properties` van directamente en `%USERPROFILE%\Zomboid\`. No pongas la carpeta `configs` ni estos
archivos dentro de `Zomboid\mods` o Workshop. Respalda primero los archivos que ya tengas, porque
las teclas y opciones se reemplazarán. Copia [`Sandbox Presets/Zombicidio.cfg`](Sandbox%20Presets/Zombicidio.cfg)
a `%USERPROFILE%\Zomboid\Sandbox Presets\` antes de crear el mundo.

## 📋 Coloca `mods.txt` y `map_ver.bin`

Después de crear y guardar el mundo:

1. Cierra el juego y haz una copia de los archivos generados.
2. Reemplaza `mods.txt` y `map_ver.bin` dentro de `%USERPROFILE%\Zomboid\Saves\Sandbox\<nombre_de_tu_partida>\` con los archivos de este kit.
3. Déjalos juntos en la carpeta del guardado; **no** los pongas dentro de `mods`.
4. Inicia de nuevo y comprueba que el mundo cargue.

---

## 🔄 Cambios y comunidad

El [changelog](../../docs/releases/CHANGELOG.md) resume las versiones y cambios recientes. Los
ZIP individuales aparecerán en [GitHub Releases](https://github.com/samuelzyx/chilaseda-fix-custom-mods-project-zombiod/releases)
cuando cada versión esté validada y publicada. También puedes seguir los directos y redes en
[atom.bio/chilaseda](https://www.atom.bio/chilaseda).


---

### 🔗 Otros enlaces de interés

- [⚙️ Configuraciones del kit](configs/README.md)
- [🌱 Recomendaciones y 🧪 ports locales](mods_en_pausa.md#recomendados-para-evaluar)
- [⏸️ Mods en pausa](mods_en_pausa.md)
- [🏠 Inicio del repositorio](../../README.md)
- [🤝 Cómo contribuir](../../CONTRIBUTING.md)
- [🚀 Releases de mods](../../docs/releases/README.md)
