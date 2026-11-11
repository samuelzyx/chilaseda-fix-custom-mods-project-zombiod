# Seguimiento de versiones de Workshop y fixes locales

Este registro sigue los mods de Workshop que sirven de objetivo a los fixes locales. El ID de
Workshop y `time_updated` identifican la publicaciÃƒÂ³n; `modversion` se registra cuando el contenido
instalado la declara. Una fecha nueva es una seÃƒÂ±al para revisar, no prueba de que el fix ya no haga
falta.

## LÃƒÂ­mite histÃƒÂ³rico

Los `mod.info` de los fixes no guardaban la versiÃƒÂ³n del mod original en la que se aplicÃƒÂ³ cada
correcciÃƒÂ³n. No se puede reconstruir ese dato con certeza desde el workspace. La primera consulta del
comprobador establece una lÃƒÂ­nea base fechada. Desde entonces, las diferencias quedan registradas y
se comparan con la sesiÃƒÂ³n de Jill. No se debe presentar esa primera observaciÃƒÂ³n como la versiÃƒÂ³n
histÃƒÂ³rica de aplicaciÃƒÂ³n.

## Revisiones actuales

El comprobador actualiza la tabla marcada abajo y guarda el estado previo en
`Workshop_Fix_Tracking_State.json`.

Primera consulta a Steam: **2026-10-30 10:27:06 -06:00**. Validacion de versiones instaladas: **10:30:44 -06:00**.
La primera lectura habia seleccionado por error la variante B42.13 de Reactive Sound Events (1.0.0).
El selector ahora prefiere B42.21 (1.3.0); el `time_updated` de Steam no cambio. Esta correccion
de lectura no se cuenta como una actualizacion del Workshop. Las fechas anteriores a la primera
consulta ya estaban publicadas; no hay dato local de cuando llegaron al equipo ni de la version
fuente exacta con la que se creo historicamente cada fix.

Authentic Z se agregÃ³ al seguimiento al crear `ChilaSeda_Fix_Authentic_Z_InstantCraft_B42_2335368829`.
La consulta del 2026-10-30 10:47:37 -06:00 registrÃ³ `time_updated=2026-09-13 23:01:38 UTC`.
El `mod.info` solo declara `version=42` (rama/build compatible), no `modversion`; el comprobador
omite esa etiqueta para no confundirla con una versiÃ³n del contenido.

<!-- CURRENT_STATE_START -->
| Mod original de Workshop | Workshop ID | Mod ID fuente | Fix local | Version del fix | Version fuente aplicada | Workshop actualizado | Version fuente instalada | Estado |
|---|---:|---|---|---:|---|---|---|---|
| [Glue & Duct Tape Crafting](https://steamcommunity.com/sharedfiles/filedetails/?id=3767335348) | 3767335348 | XGlueTapeCrafting | ChilaSeda_Fix_XGlueTapeCrafting_Translation_B42_3767335348 | sin etiqueta | Sin registro histórico | 2026-08-30 09:23:32 UTC | mod.info sin modversion | En seguimiento |
| [[DEPRECATED] Check Around](https://steamcommunity.com/sharedfiles/filedetails/?id=3300688173) | 3300688173 | CheckAround | ChilaSeda_Fix_Check_Around_VoiceLineLists_B42_3300688173 | 0.1.1 | Sin registro histórico | 2025-12-13 21:23:16 UTC | 1.4.0 | En seguimiento |
| [Authentic Z](https://steamcommunity.com/sharedfiles/filedetails/?id=2335368829) | 2335368829 | Authentic Z - Current | ChilaSeda_Fix_Authentic_Z_InstantCraft_B42_2335368829 | 0.1.0 | Sin registro histórico | 2026-10-31 01:17:39 UTC | mod.info sin modversion | En seguimiento |
| [Any Wall Flags 3D - Project Viewpoint [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3818605688) | 3818605688 | DGVFlags | ChilaSeda_Fix_Any_Wall_Flags_3D_Weight_B42_3818605688 | sin etiqueta | Sin registro histórico | 2026-10-25 14:52:17 UTC | no disponible en disco | En seguimiento |
| [Dismantle All at Once](https://steamcommunity.com/sharedfiles/filedetails/?id=3761218629) | 3761218629 | DismantleAllAtOnce | ChilaSeda_Fix_Dismantle_All_at_Once_MenuOrder_B42_3761218629 | sin etiqueta | Sin registro histórico | 2026-08-08 21:55:02 UTC | no disponible en disco | En seguimiento |
| [Doggy's Library](https://steamcommunity.com/sharedfiles/filedetails/?id=3428272880) | 3428272880 | DoggyLibrary | ChilaSeda_Fix_Doggy_Library_RayBeam_B42_3428272880 | 1.0.0 | Sin registro histórico | 2025-06-29 23:04:40 UTC | no disponible en disco | En seguimiento |
| [Hunter Expansion](https://steamcommunity.com/sharedfiles/filedetails/?id=3786994541) | 3786994541 | HunterExpansion | ChilaSeda_Fix_Hunter_Expansion_Filth_B42_3786994541 | 1.1.1 | Sin registro histórico | 2026-09-01 17:52:57 UTC | 0.6.3 | En seguimiento |
| [NeatUI - Grid Inventory](https://steamcommunity.com/sharedfiles/filedetails/?id=3818729237) | 3818729237 | NeatUI_Core | ChilaSeda_Fix_NeatUI_Core_Format_B42_3818729237 | 0.1.0 | Sin registro histórico | 2026-10-21 19:51:52 UTC | 0.2.3 | En seguimiento |
| [Any Wall Posters 3D - Project Viewpoint [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3818605173) | 3818605173 | DGVPosters | ChilaSeda_Fix_Any_Wall_Posters_3D_Weight_B42_3818605173 | sin etiqueta | Sin registro histórico | 2026-10-25 14:51:56 UTC | no disponible en disco | En seguimiento |
| [Reactive Sound Events](https://steamcommunity.com/sharedfiles/filedetails/?id=3656190498) | 3656190498 | ReactiveSE | ChilaSeda_Fix_Reactive_Sound_Events_Viewpoint_B42_3656190498 | 1.1.2 | Sin registro histórico | 2026-10-24 18:30:23 UTC | 1.3.0 | En seguimiento |
| [[B42+] Sandbox Options](https://steamcommunity.com/sharedfiles/filedetails/?id=3386906181) | 3386906181 | SandboxSettings | ChilaSeda_Fix_Sandbox_Options_ContextMenu_B42_3386906181 | 1.0.0 | Sin registro histórico | 2026-10-03 13:19:51 UTC | no disponible en disco | En seguimiento |
| [Undead Wildlife [B42 Stable]](https://steamcommunity.com/sharedfiles/filedetails/?id=3781571720) | 3781571720 | UndeadWildlife | ChilaSeda_AnimalBalance_B42 | 2.3.0 | Sin registro histórico | 2026-08-16 00:03:32 UTC | 1.1.0 | En seguimiento |
| [True Weight](https://steamcommunity.com/sharedfiles/filedetails/?id=3768669395) | 3768669395 | TrueWeight | ChilaSeda_Fix_True_Weight_VanillaWeights_B42_3768669395 | 2.1.1 | Sin registro histórico | 2026-08-01 23:04:10 UTC | 1.10 | En seguimiento |
| [Viewpoint - Interface](https://steamcommunity.com/sharedfiles/filedetails/?id=3812616893) | 3812616893 | ViewpointUI | ChilaSeda_Fix_Viewpoint_Interface_ActionProgress_B42_3812616893 | sin etiqueta | Sin registro histórico | 2026-10-25 15:03:41 UTC | 0.14.0 | En seguimiento |
| [Viewpoint Foraging](https://steamcommunity.com/sharedfiles/filedetails/?id=3814994364) | 3814994364 | ViewpointForaging | ChilaSeda_Fix_ViewpointForaging_B42_3814994364 | 1.3.15 | Sin registro histórico | 2026-10-14 20:24:31 UTC | 0.3.0 | En seguimiento |
| [[B42] Water Pipes](https://steamcommunity.com/sharedfiles/filedetails/?id=3546314080) | 3546314080 | Waterpipes | ChilaSeda_Fix_Water_Pipes_ModData_B42_3546314080 | 1.0.0 | Sin registro histórico | 2026-08-22 20:05:37 UTC | no disponible en disco | En seguimiento |
| [Wilderness QoL [B42.21]](https://steamcommunity.com/sharedfiles/filedetails/?id=3779759338) | 3779759338 | Wilderness QoL | ChilaSeda_Fix_Wilderness_QoL_Identification_B42_3779759338 | sin etiqueta | Sin registro histórico | 2026-09-28 21:36:06 UTC | 0.8.11 | En seguimiento |
| Project Zomboid (juego base) | - | - | ChilaSeda_Fix_Project_Zomboid_AutoTools_B42_Vanilla | 1.0.1 | No aplica | No aplica | No aplica | Sin Workshop original |
<!-- CURRENT_STATE_END -->

## Historial de cambios detectados

El comprobador agrega aquÃƒÂ­ solo cambios posteriores a la primera lÃƒÂ­nea base. Cada cambio se revisa
contra el contenido instalado y la parte concreta que corrige el fix antes de recomendar conservar,
adaptar o retirar el parche.

<!-- CHANGE_LOG_START -->
| Detectado | Mod | Workshop ID | `time_updated` anterior Ã¢â€ â€™ nuevo | VersiÃƒÂ³n instalada anterior Ã¢â€ â€™ nueva | RevisiÃƒÂ³n del fix |
|---|---|---:|---|---|---|
| 2026-10-31T01:40:21.8580859Z | Authentic Z | 2335368829 | 2026-09-13 23:01:38 UTC -> 2026-10-31 01:17:39 UTC | sin dato -> sin dato | Pendiente de revision |
<!-- CHANGE_LOG_END -->

## Revision de actualizaciones recientes en la primera linea base

Estas publicaciones ya tenian fechas recientes el 30 de octubre. No se pueden atribuir a una
actualizacion recibida hoy o durante una sesion anterior porque no habia una linea base previa.

- **Any Wall Flags 3D**, actualizado el 25 de octubre: el Workshop instalado conserva el modulo
  `DGVFlags`; el fix recorre los items y reajusta banderas y estandartes de ese modulo. No hay evidencia
  de que el cambio lo vuelva innecesario. La fuente no declara `modversion`.
- **Any Wall Posters 3D**, actualizado el 25 de octubre: conserva `DGVPosters`; el fix identifica
  items por prefijo de tipo y ajusta tambien instancias accesibles. No hay evidencia de obsolescencia.
  La fuente no declara `modversion`.
- **Viewpoint - Interface 0.14.0**, actualizado el 25 de octubre: la API instalada aun expone
  `VPProgressBar`, que usa el parche para mostrar el progreso de acciones en cola. No se encontro
  evidencia de que el Workshop haya aÃ±adido esa integracion.
- **Reactive Sound Events 1.3.0**, actualizado el 24 de octubre: `setAngleFromPoint()` todavia
  calcula la direccion con proyeccion isometrica, sin aplicar el yaw de Viewpoint. El fix local
  adapta ese metodo para la camara; la actualizacion no parece resolver ese caso.
- **NeatUI - Grid Inventory 0.2.3**, actualizado el 21 de octubre: los nombres instalados siguen
  incluyendo `Icon size (%)` y `Window body opacity (%)`. El fix escapa esos signos antes del
  formato de texto; la causa sigue presente.
- **Viewpoint Foraging 0.3.0**, actualizado el 14 de octubre: siguen presentes `VPF.project()` y
  `VPF.placePin()`, que son los puntos que ajusta el fix para la altura de pines. No se encontro
  evidencia de que la actualizacion elimine la necesidad del parche.
- **Project Viewpoint**, revisado el 10 de noviembre: Steam muestra una actualizacion del 9 de
  noviembre, sin descripcion en su entrada de cambios. El JAR instalado conserva Viewpoint 0.1.6.2
  y no contiene `viewpoint.interact.ForageFinds`; los Lua instalados tampoco exponen
  `ViewpointForage.found`. El fix de neblina/calibracion integrado sigue dependiendo de esa API;
  la actualizacion no permite retirar ni adaptar ese flujo todavía.

Estas revisiones son comprobaciones estaticas de la fuente instalada, no validaciones dentro de Jill.

## Uso

Ejecutar desde la raÃƒÂ­z `mods` con:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Check-WorkshopFixUpdates.ps1
```

La tarea de Windows ejecuta el comprobador cada hora mientras la cuenta estÃ© iniciada y muestra una
notificaciÃ³n visible si detecta una publicaciÃ³n o `modversion` instalada distinta. El detalle se
conserva en `Workshop_Fix_Checker.log` y en los cambios agregados arriba. Antes/despuÃ©s de Jill y
cuando se investigue un crash, comparar tambiÃ©n las horas registradas en esos archivos. Si no se
puede consultar Steam o el contenido instalado, se conserva el Ãºltimo dato vÃ¡lido y se registra el
fallo; no se marca una versiÃ³n como actual sin evidencia.
