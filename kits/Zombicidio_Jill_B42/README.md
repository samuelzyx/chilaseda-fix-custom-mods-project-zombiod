# Kit Zombicidio Jill · Project Zomboid B42

Guía para montar una partida parecida a la referencia de Jill. El kit comparte listas y ajustes,
no copias de mods de Workshop.

## Descarga del repositorio

Puedes clonar el repo con Git:

```powershell
git clone https://github.com/samuelzyx/chilaseda-fix-custom-mods-project-zombiod.git
```

O abre el repo en GitHub, pulsa **Code → Download ZIP** y extrae el archivo. Lee también
[`Descripcion_Coleccion_Zombicidio.txt`](Descripcion_Coleccion_Zombicidio.txt).

## Mods que necesitas

1. Suscríbete a los mods de terceros de la [colección Zombicidio](https://steamcommunity.com/sharedfiles/filedetails/?id=3812814868) y espera a que Workshop termine de descargarlos.
2. Instala **ZombieBuddy** desde [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3619862853); es requisito de Project Viewpoint.
3. Instala la versión de **Project Viewpoint** compartida en el enlace de Discord que acompaña la colección. Extrae el contenido y confirma que quede `Zomboid/mods/Viewpoint/42/mod.info`.
4. Copia las 38 carpetas locales ChilaSeda que aparecen abajo desde este repositorio a `%USERPROFILE%\Zomboid\mods\`. Mantén cada carpeta con su nombre y estructura.

### Carpetas locales ChilaSeda

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

## Crear la partida y aplicar los archivos

1. Copia `Sandbox Presets/Zombicidio.cfg` a `%USERPROFILE%\Zomboid\Sandbox Presets\`.
2. Crea un mundo nuevo en Sandbox y selecciona el preset `Zombicidio`. Activa los mods de la colección y los mods locales. Para la apariencia, instala `[COS] RE:3 Remake Jill` desde Workshop y selecciona `RE3_Jill`.
3. Para recrear a Jill, elige la ocupación Pescador y los rasgos Insensible, Manitas, Poca sed, Insomne, Propenso a enfermar, Sanador lento, Robusto, Bajo peso y Metabolismo lento.
4. Guarda la partida y cierra el juego. Haz una copia de seguridad de los archivos del mundo.
5. Reemplaza `mods.txt` y `map_ver.bin` en `%USERPROFILE%\Zomboid\Saves\Sandbox\<nombre_de_tu_partida>\` con los archivos de esta carpeta. No los pongas dentro de `mods`.
6. Abre el juego y carga el mundo. Comprueba compatibilidad después de cada actualización de Project Zomboid o de un mod.

El perfil de Jill es una referencia, no una partida completa. Las releases individuales de mods
ChilaSeda están en la [página Releases](https://github.com/samuelzyx/chilaseda-fix-custom-mods-project-zombiod/releases).
Sigue los directos y redes en [atom.bio/chilaseda](https://www.atom.bio/chilaseda).
