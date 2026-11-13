ChilaSeda_Translations_ES_B42 â€” Traducciones al espaÃ±ol para mods Build 42 1.0.8

<div align="center">

[🏠 Repo](../README.md) · [🤝 Contribuir](../CONTRIBUTING.md) · [🚀 Releases](../docs/releases/README.md)

</div>

---

## Cambios en 1.4.56

- Agrega etiquetas en espanol para las acciones de menu de Viewpoint de agregar combustible, apagar fuego, recoger peces, colocar carnada, entrar a vehiculos y controles de colocar/confirmar/girar/cancelar.
- Completa los textos de las opciones locales de neblina de rebusqueda y limite de FPS del menu.
- No reemplaza traducciones de AutoTailoring pendientes de autorizacion del autor.


INSTALACION
1. Cierra Project Zomboid.
2. Copia la carpeta ChilaSeda_CheckAround_ES_B42 a:
   <ZOMBOID_ROOT>\mods\
3. Manten instalado y activo Check Around (Workshop 3300688173), junto con
   sus dependencias habituales. Activa tambien este complemento en la partida.
4. Selecciona EspaÃ±ol en el idioma del juego y vuelve a iniciarlo.

El ID real del original es CheckAround. El complemento declara require=\CheckAround
 y loadModAfter=CheckAround. Debe figurar despues del original en el orden de carga.
No necesita ZombieBuddy. No copies estos archivos dentro del Workshop.

CONTENIDO
Comparado contra Check Around 1.4.0 del RAR proporcionado, carpeta 42:
- ContextMenu: 3 claves (faltaban las 3).
- IG_UI: 137 claves (faltaban 111).
- Sandbox: 9 claves (existian 9, con errores de redaccion/sintaxis).
- Tooltip: 6 claves (faltaban las 6).
- UI: 1 clave.
TOTAL: 156 claves traducidas; 120 ausentes en el espaÃ±ol anterior.

Incluye todas las variantes de frases sobre puertas, ventanas, pisos superiores
 e inferiores y zonas de esporas, ademas de controles y opciones.
Se conserva el nombre de cada clave, incluso loreNamePlurial, tal como lo define
el autor. Se conserva el orden y numero de %s y %d. No habia concatenaciones,
%1/%2 ni otras variables en estos cinco archivos de ingles.
RT/LT/RB/LB conservan sus etiquetas fisicas, no son frases sin traducir.

FORMATOS Y ACENTOS
Incluye los cinco archivos *_ES.txt pedidos, con tablas IGUI_ES, UI_ES, etc.
Los TXT estan codificados en Windows-1252 para el formato espaÃ±ol heredado;
no son UTF-8 daÃ±ado. No convertirlos indiscriminadamente desde un editor.
Incluye tambien ContextMenu.json, IG_UI.json, Sandbox.json, Tooltip.json y
UI.json en UTF-8, con exactamente las mismas claves y textos: el Translator
inspeccionado de B42.21 utiliza esos nombres JSON. Asi el complemento aporta
las traducciones tambien en esa version sin ejecutar scripts de conversion.
No aÃ±ade ni reemplaza language.txt ni cambia la codificacion del idioma global.
Los nombres visibles de los dos cinturones Desert de Authentic Z se escriben
sin tilde en "Cinturon" porque Jill mostraba esa vocal como "?" en el inventario.

VALIDACION
156/156 claves EN tienen equivalente ES. 0 claves extra. Los TXT se evaluaron
como tablas Lua validas; los JSON se parsearon y compararon con esas tablas.
Se comprobaron los tokens de formato en orden y se probaron las cadenas
parametrizadas mediante string.format. Resultado en VALIDACION.txt.
No contiene codigo Lua ejecutable, JAR ni archivos de gameplay.
No se ha ejecutado dentro del juego en este entorno: la comprobacion final
visual consiste en revisar una puerta, una ventana y escaleras en espaÃ±ol.

LIMITE HEREDADO DEL ORIGINAL
En CheckAround_module.lua el original usa zombieName (singular) tambien para
inicializar defaultZombiesName. Si aparece "3 zombi", es ese comportamiento,
no una clave que falte. Este complemento no modifica logica. Si tu configuracion
lo permite, puedes escribir "zombis" en el nombre plural de las opciones sandbox.

DESINSTALAR
Desactiva este complemento y retira unicamente su carpeta. El mod original
queda intacto. Aunque el original soporte B41, este complemento se entrega
con estructura de Build 42 y no se anuncia como probado para B41.

FUENTES DE TRADUCCION â€” LOTE 1 (mod 1.0.8)
Los catalogos JSON no admiten comentarios. Este registro relaciona cada grupo
de claves con su archivo ingles de Workshop; los originales permanecen intactos.

MODS Y VERSIONES INSTALADAS
- KillCount (Workshop 2553809727): carpeta 42.0; mod.info no declara modversion.
- WinterFX (Workshop 3819972196): 0.1.5.
- Brief Sprinters (Workshop 3821554678): 1.1.3.
- Auto Move To (Workshop 3389328028): 1.3.
- Split Items (Workshop 3147428398): 0.0.9.

RUTAS DE LOS ARCHIVOS FUENTE
KillCount â€” 18 claves:
  Sandbox_KillCount_*:
  J:\SteamLibrary\steamapps\workshop\content\108600\2553809727\mods\KillCount\42.0\media\lua\shared\Translate\EN\Sandbox.json
  UI_KillCount_*, UI_Kills*, UI_KC*:
  J:\SteamLibrary\steamapps\workshop\content\108600\2553809727\mods\KillCount\42.0\media\lua\shared\Translate\EN\UI.json

WinterFX â€” 19 claves:
  Sandbox_WinterFX_*:
  J:\SteamLibrary\steamapps\workshop\content\108600\3819972196\mods\WinterFX\42\media\lua\shared\Translate\EN\Sandbox.json
  UI_WinterFX_*:
  J:\SteamLibrary\steamapps\workshop\content\108600\3819972196\mods\WinterFX\42\media\lua\shared\Translate\EN\UI.json

Brief Sprinters â€” 29 claves:
  Sandbox_BriefSprinters_*:
  J:\SteamLibrary\steamapps\workshop\content\108600\3821554678\mods\BriefSprinters\42\media\lua\shared\Translate\EN\Sandbox.json

Auto Move To â€” 26 claves:
  Sandbox_AutoMoveTo_*:
  J:\SteamLibrary\steamapps\workshop\content\108600\3389328028\mods\AutoMoveTo\common\media\lua\shared\Translate\EN\Sandbox.json
  UI_AutoMoveTo_*, UI_options_AutoMoveTo_*, UI_optionscreen_binding_Move_To:
  J:\SteamLibrary\steamapps\workshop\content\108600\3389328028\mods\AutoMoveTo\common\media\lua\shared\Translate\EN\UI.json

Split Items â€” 18 claves:
  ContextMenu_SplitItems:
  J:\SteamLibrary\steamapps\workshop\content\108600\3147428398\mods\SplitItems\common\media\lua\shared\Translate\EN\ContextMenu.json
  UI_SplitItems_*, UI_options_SplitItems_*:
  J:\SteamLibrary\steamapps\workshop\content\108600\3147428398\mods\SplitItems\common\media\lua\shared\Translate\EN\UI.json

FUENTES DE TRADUCCION â€” LOTE 2 (mod 1.0.9)
Se aÃ±adieron 57 claves de interfaz/opciones de tres mods activos. Las paginas
consultadas no mostraban una prohibicion expresa de parches de traduccion
separados. Se conservan intactos los originales de Workshop.

MODS Y VERSIONES INSTALADAS
- Project Viewpoint: True Weathers - Gameplay (Workshop 3813908957): 3.3.3.
- NeatUI - Survival Guide (Workshop 3818729237): 0.2.0.
- Project Viewpoint: TREE in 3D (Workshop 3813172420): 0.3.15.

RUTAS DE LOS ARCHIVOS FUENTE
True Weathers - Gameplay â€” 34 claves:
  Sandbox_TWGameplay_*:
  J:\SteamLibrary\steamapps\workshop\content\108600\3813908957\mods\ViewpointTrueWeathersGameplay\42\media\lua\shared\Translate\EN\Sandbox.json
  Base.TWG_Meteorite:
  J:\SteamLibrary\steamapps\workshop\content\108600\3813908957\mods\ViewpointTrueWeathersGameplay\42\media\lua\shared\Translate\EN\ItemName.json

NeatUI - Survival Guide â€” 7 claves:
  UI_NSG_*:
  J:\SteamLibrary\steamapps\workshop\content\108600\3818729237\mods\NeatUI_SurvivalGuide\42\media\lua\shared\Translate\EN\UI.json

Project Viewpoint: TREE in 3D â€” 16 claves:
  UI_PVNV_*:
  J:\SteamLibrary\steamapps\workshop\content\108600\3813172420\mods\ProjectViewpointNearVegetation\42\media\lua\shared\Translate\EN\UI.json

FUENTES DE TRADUCCION â€” LOTE 3 (mod 1.0.9)
Viewpoint True Ballistics â€” 31 claves:
  Sandbox_VTB*:
  J:\SteamLibrary\steamapps\workshop\content\108600\3812864848\mods\ViewpointTrueBallistics\42\media\lua\shared\Translate\EN\Sandbox.json
  Version instalada: 1.4.6. La pagina indica compatibilidad/conflictos de
  gameplay, sin prohibir parches de traduccion separados.

FUENTES DE TRADUCCION â€” LOTE 4 (mod 1.1.0)
Se aÃ±adieron 61 claves de interfaz/opciones de un mod activo. La pagina de
Workshop consultada no expresa una prohibicion de parches de traduccion
separados. El original de Workshop permanece intacto.

MOD Y VERSION INSTALADA
- OldPoint (Workshop 3815999052): 0.6.153; Project Zomboid 42.21.

RUTA DEL ARCHIVO FUENTE
OldPoint â€” 61 claves:
  UI_OldPoint_*:
  J:\SteamLibrary\steamapps\workshop\content\108600\3815999052\mods\OldPoint\42\media\lua\shared\Translate\EN\UI.json
  No se encontro un catalogo ES instalado para este mod. Su carpeta de
  traducciones contiene CN y EN. La pagina de Workshop consultada no indicaba
  una prohibicion expresa de parches de traduccion separados.

FUENTES DE TRADUCCION â€” LOTE 5 (mod 1.2.0)
Viewpoint - Advanced Throwables â€” 56 claves Sandbox:
  Sandbox_ViewpointThrowables_*:
  J:\SteamLibrary\steamapps\workshop\content\108600\3813194971\mods\ViewpointAdvancedThrowables\42\media\lua\shared\Translate\EN\Sandbox.json
  Version instalada: 1.4.1. La pagina de Workshop consultada no indica una
  prohibicion de parches de traduccion separados.

TRADUCCION MANUAL INTEGRADA
ReactiveSE / Knox Relay â€” 927 claves de IG_UI:
  J:\SteamLibrary\steamapps\workshop\content\108600\3656190498\mods\ReactiveSE\42.21\media\lua\shared\Translate\EN\IG_UI.json
  Traduccion proporcionada por Chila en:
  TraduccionesManuales\ReactiveSE\IG_UI_ES.json
  Las 927 claves coinciden con el catalogo ingles y conservan sus marcadores y
  etiquetas. Se integraron 921 claves nuevas; seis ya existian, y para cinco de
  ellas se aplico el texto del archivo manual de Chila. El original de Workshop
  permanece intacto.

FUENTES DE TRADUCCION â€” LOTE 6 (mod 1.2.1)
3D Helicopter Event - Project Viewpoint â€” 1 clave:
  IGUI_VehicleNameHeliEvent_Huey:
  J:\SteamLibrary\steamapps\workshop\content\108600\3818359767\mods\HeliEvent\42\media\lua\shared\Translate\EN\IG_UI.json
  No se encontro modversion en el mod.info instalado; la pagina de Workshop
  consultada no indica una prohibicion expresa de parches de traduccion separados.

FUENTES DE TRADUCCION â€” LOTE 7 (mod 1.3.0)
Se aÃ±adieron 19 claves de interfaz/opciones de cinco mods activos:
- Map Symbol Size Slider (Workshop 2734705913): 1 clave IG_UI. mod.info no
  declara version; la pagina indica 1.3.5.
- Arithmechick's Thermal HUD (Workshop 3819978362): 4 claves UI, version 0.1.0.
- Buttstroke (Workshop 3394044313): 4 claves Sandbox; mod.info y pagina sin
  version declarada.
- Compass Direction Indicator (Workshop 3787835610): 3 claves Sandbox y 2 UI,
  version 0.1.4.
- Mini Health Panel (Workshop 2866258937): 5 claves IG_UI, version 1.6.1.42.
Las paginas consultadas no expresan una prohibicion de parches de traduccion
separados. Las rutas fuente son:
  Map Symbol Size Slider:
  J:\SteamLibrary\steamapps\workshop\content\108600\2734705913\mods\Map Symbol Size Slider\42\media\lua\shared\Translate\EN\IG_UI.json
  Thermal HUD:
  J:\SteamLibrary\steamapps\workshop\content\108600\3819978362\mods\TSW_ThermalHUD\42\media\lua\shared\Translate\EN\UI.json
  Buttstroke:
  J:\SteamLibrary\steamapps\workshop\content\108600\3394044313\mods\Buttstroke\42\media\lua\shared\Translate\EN\Sandbox.json
  Compass Direction Indicator:
  J:\SteamLibrary\steamapps\workshop\content\108600\3787835610\mods\Compass_Direction_Indicator\42\media\lua\shared\Translate\EN\Sandbox.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3787835610\mods\Compass_Direction_Indicator\42\media\lua\shared\Translate\EN\UI.json
  Mini Health Panel:
  J:\SteamLibrary\steamapps\workshop\content\108600\2866258937\mods\MiniHealthPanel\42\media\lua\shared\Translate\EN\IG_UI.json

FUENTES DE TRADUCCION â€” LOTE 8 (mod 1.3.1)
Trees Have Loot [B42] (Workshop 2951270166) â€” 5 claves UI, version 2.0.5:
  UI_THL_ModOptions_*:
  J:\SteamLibrary\steamapps\workshop\content\108600\2951270166\mods\TreesHaveLoot\42.15\media\lua\shared\Translate\EN\UI.json
El mod ya proporciona las dos claves de ContextMenu en su catalogo ES; no las
duplique en el parche. La pagina limita la publicacion del mod en Steam a las
cuentas autorizadas, pero no expresa una prohibicion de un parche local
separado; los originales de Workshop permanecen intactos.

FUENTES DE TRADUCCION â€” LOTE 9 (mod 1.3.2)
Dale's Chieftain RV (Legacy) (Workshop 3820158673) â€” 1 clave IG_UI:
  IGUI_VehicleNameDaleChieftainRV:
  J:\SteamLibrary\steamapps\workshop\content\108600\3820158673\mods\DaleChieftainRV\42\media\lua\shared\Translate\EN\IG_UI.json
  Version instalada: 0.1.16. La pagina describe esta variante Legacy como
  congelada para partidas antiguas; no indica una prohibicion de traducciones
  locales separadas.

FUENTES DE TRADUCCION â€” LOTE 10 (mod 1.3.3)
Add More Map Symbols (AMMS) â€” version B42 1.0.5, 3 claves IG_UI:
  IGUI_Map_TabAmmSSign, IGUI_Map_TabAmmSToolGuns y
  IGUI_Map_TabAmmSFurniture:
  J:\SteamLibrary\steamapps\workshop\content\108600\3020323164\mods\AddMoreMapSymbols\42\media\lua\shared\Translate\EN\IG_UI.json
La pagina de Workshop consultada no indica una prohibicion de parches de
traduccion separados. El original permanece intacto.

FUENTES DE TRADUCCION â€” LOTE 11 (mod 1.3.4)
Se aÃ±adieron 19 claves que no estaban cubiertas por el espaÃ±ol de Workshop ni
por otro parche local activo. Los catalogos ES existentes de Water Pipes,
Alice's Weapon Sling, Gyde's Trait Magazines y Useful Barrels se conservaron;
solo se agregaron las claves ausentes. Real Vehicle VFX no tenia traduccion ES
para estas opciones. Los originales de Workshop permanecen intactos.

MODS Y VERSIONES INSTALADAS
- Water Pipes (Workshop 3546314080): carpeta 42.20; sin modversion en mod.info.
- Alice's Weapon Sling - Radial Menu [ADDON] (Workshop 3775549570): 1.1.
- Gyde's Trait Magazines (Workshop 3342191739): v2.2.
- Real Vehicle VFX (Workshop 3788393574): 2.7.29.
- Useful Barrels (Workshop 3436537035): 4.0.10.

RUTAS DE LOS ARCHIVOS FUENTE
Water Pipes â€” 1 clave:
  IGUI_CraftingCategories_Plumbing:
  J:\SteamLibrary\steamapps\workshop\content\108600\3546314080\mods\WaterPipes\42.20\media\lua\shared\Translate\EN\IG_UI.json

Alice's Weapon Sling - Radial Menu [ADDON] â€” 4 claves:
  UI_AliceWeaponSling_Equip, UI_AliceWeaponSling_Unequip,
  UI_AliceWeaponSling_MoveTo y UI_AliceWeaponSling_DefaultSlot:
  J:\SteamLibrary\steamapps\workshop\content\108600\3775549570\mods\alicesWeaponSlingRadialMenu\42\media\lua\shared\Translate\EN\UI.json

Gyde's Trait Magazines â€” 4 claves:
  Sandbox_GydeTraitMags_ReadRemove, Sandbox_GydeTraitMags_ReadRemove_tooltip,
  Sandbox_GydeTraitMags_ReadDelete y Sandbox_GydeTraitMags_ReadDelete_tooltip:
  J:\SteamLibrary\steamapps\workshop\content\108600\3342191739\mods\GydeTraitMagazines\42.15\media\lua\shared\Translate\EN\Sandbox.json

Real Vehicle VFX â€” 5 claves:
  Sandbox_RVVFX y Sandbox_RVVFX_TireMarkPersistence_*:
  J:\SteamLibrary\steamapps\workshop\content\108600\3788393574\mods\RealVehicleVFX\42\media\lua\shared\Translate\EN\Sandbox.json

Useful Barrels â€” 4 claves Sandbox y 1 Tooltip:
  Sandbox_UsefulBarrelsDebugMode, Sandbox_UsefulBarrelsDebugMode_tooltip,
  Sandbox_UsefulBarrelsEnableFillBarrelFromVehicles y
  Sandbox_UsefulBarrelsFillBarrelFromVehiclesRequiresHose:
  J:\SteamLibrary\steamapps\workshop\content\108600\3436537035\mods\UsefulBarrelsMP\42\media\lua\shared\Translate\EN\Sandbox.json
  Tooltip_UB_CantAddFluid:
  J:\SteamLibrary\steamapps\workshop\content\108600\3436537035\mods\UsefulBarrelsMP\42\media\lua\shared\Translate\EN\Tooltip.json

Las paginas consultadas no expresan una prohibicion de parches locales de
traduccion. Gyde's Trait Magazines invita a reportar traducciones y Useful
Barrels acredita una traduccion al espaÃ±ol. El lote solo aÃ±ade texto; no
reutiliza ni modifica codigo o recursos de los originales.

FUENTES DE TRADUCCION â€” LOTE 12 (mod 1.3.5)
Se aÃ±adieron 31 claves de interfaz y opciones Sandbox que no estaban cubiertas
por traducciones ES/ES_MX de Workshop ni por otros parches locales activos.
No se modificaron catalogos originales.

MODS Y VERSIONES INSTALADAS
- Moodle Framework (Workshop 3396446795): carpeta 42.0; sin modversion.
- Banger's Retro Car Dashboard (Workshop 3739256322): 0.2.3.
- Xanny Arms Core (Workshop 3820971639): 0.2.4-release-tech1.

RUTAS DE LOS ARCHIVOS FUENTE
Moodle Framework â€” 9 claves UI:
  UI_options_MFColor_*:
  J:\SteamLibrary\steamapps\workshop\content\108600\3396446795\mods\MoodleFramework\42.0\media\lua\shared\Translate\EN\UI.json

Banger's Retro Car Dashboard â€” 4 claves ContextMenu y 7 Tooltip:
  ContextMenu_RetroDash_*:
  J:\SteamLibrary\steamapps\workshop\content\108600\3739256322\mods\RetroDashboard\42\media\lua\shared\Translate\EN\ContextMenu.json
  Tooltip_RetroDash_*:
  J:\SteamLibrary\steamapps\workshop\content\108600\3739256322\mods\RetroDashboard\42\media\lua\shared\Translate\EN\Tooltip.json

Xanny Arms Core â€” 11 claves Sandbox:
  Sandbox_XannyArms_*:
  J:\SteamLibrary\steamapps\workshop\content\108600\3820971639\mods\XannyArmsCore\42\media\lua\shared\Translate\EN\Sandbox.json
La pagina de Xanny Arms indica que los nombres de armas y accesorios se
mantienen en ingles; este lote solo traduce sus opciones Sandbox. Las paginas
consultadas no expresan una prohibicion de parches locales de traduccion.

FUENTES DE TRADUCCION â€” LOTE 13 (mod 1.3.7)
Se aÃ±adieron 161 claves nuevas: 77 opciones de Project Viewpoint - Isometric
No More, 27 opciones Sandbox y 57 textos UI de Viewpoint Tactical. Los
originales de Workshop permanecen intactos.

COBERTURA Y LIMITES
- Isometric No More: 77 claves UI que faltaban. Las 57 claves IG_UI ya estan
  cubiertas por el parche local activo ChilaSeda_Fix_Viewpoint_IsometricNoMore_Menu_B42;
  otras 15 claves UI de ese mod tambien estan en ese parche y no se duplicaron.
- Viewpoint Tactical: se traducen las 27 opciones Sandbox y sus 57 claves UI.
  VPTText usa el catalogo estandar del juego cuando VPTLanguage no esta
  definido; queda pendiente confirmar en partida que la interfaz use el
  catalogo ES y no el sistema de idioma interno.
- Viewpoint Binoculars no necesito parche: sus 2 claves ItemName, 10 Sandbox
  y 9 UI estan completas en los catalogos ES y ES_MX de Workshop.
- Project Viewpoint: Recoil & ADS queda excluido por la restriccion expresa
  de no reutilizar datos sin permiso. Se preparo una solicitud escrita en
  SOLICITAR_PERMISOS.txt; no se aÃ±adieron sus nueve etiquetas de controles.

MODS Y VERSIONES INSTALADAS
- Project Viewpoint - Isometric No More (Workshop 3819166046): el mod.info
  instalado no declara modversion.
- Viewpoint Tactical (Workshop 3819385365): 0.4.16-rc.1.
- Viewpoint Binoculars (Workshop 3818585720): 1.0.5; cobertura ES/ES_MX
  existente, sin claves nuevas en este parche.

RUTAS DE LOS ARCHIVOS FUENTE
Project Viewpoint - Isometric No More â€” 77 claves UI:
  J:\SteamLibrary\steamapps\workshop\content\108600\3819166046\mods\isometricnomore\42\media\lua\shared\Translate\EN\UI.json
Viewpoint Tactical â€” 27 claves Sandbox:
  J:\SteamLibrary\steamapps\workshop\content\108600\3819385365\mods\ViewpointTactical\42\media\lua\shared\Translate\EN\Sandbox.json
Viewpoint Tactical â€” 57 claves UI aÃ±adidas desde:
  J:\SteamLibrary\steamapps\workshop\content\108600\3819385365\mods\ViewpointTactical\42\media\lua\shared\Translate\EN\UI.json
Project Viewpoint: Recoil & ADS â€” 9 etiquetas UI pendientes de permiso:
  J:\SteamLibrary\steamapps\workshop\content\108600\3812612054\mods\ProjectViewpointADS\42\media\lua\shared\Translate\EN\UI.json
Viewpoint Binoculars â€” catalogos ES/ES_MX completos, sin incorporacion:
  J:\SteamLibrary\steamapps\workshop\content\108600\3818585720\mods\ViewpointBinoculars\42\media\lua\shared\Translate\EN\ItemName.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3818585720\mods\ViewpointBinoculars\42\media\lua\shared\Translate\EN\Sandbox.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3818585720\mods\ViewpointBinoculars\42\media\lua\shared\Translate\EN\UI.json

FUENTES DE TRADUCCION â€” LOTE 14 (mod 1.3.8)
Se aÃ±adieron 26 claves de AutoMechanics y 58 claves vanilla ausentes de los
catalogos ES/ES_MX: ContextMenu (1), IG_UI (9), Moveables (1), UI (5) y
Recipes (42). Las claves de prueba de Recipes se conservaron traducidas por si
se muestran en el juego. No se modificaron los archivos originales.

MOD Y VERSION INSTALADA
- AutoMechanics (Workshop 3387539308): catalogos de la carpeta 42.21; sin
  modversion disponible en mod.info.

RUTAS DE LOS ARCHIVOS FUENTE
AutoMechanics â€” 26 claves:
  J:\SteamLibrary\steamapps\workshop\content\108600\3387539308\mods\AutoMechanics\42.21\media\lua\shared\Translate\EN\ContextMenu.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3387539308\mods\AutoMechanics\42.21\media\lua\shared\Translate\EN\Sandbox.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3387539308\mods\AutoMechanics\42.21\media\lua\shared\Translate\EN\UI.json

TEXTOS VANILLA AÃ‘ADIDOS
  J:\SteamLibrary\steamapps\common\ProjectZomboid\media\lua\shared\Translate\EN\ContextMenu.json
  J:\SteamLibrary\steamapps\common\ProjectZomboid\media\lua\shared\Translate\EN\IG_UI.json
  J:\SteamLibrary\steamapps\common\ProjectZomboid\media\lua\shared\Translate\EN\Moveables.json
  J:\SteamLibrary\steamapps\common\ProjectZomboid\media\lua\shared\Translate\EN\UI.json
  J:\SteamLibrary\steamapps\common\ProjectZomboid\media\lua\shared\Translate\EN\Recipes.json

Se mantuvieron fuera los catalogos narrativos extensos de Print_Media y
Recorded_Media para tratarlos por separado; el parche no reemplaza los
catalogos de idioma del juego.

FUENTES DE TRADUCCION â€” LOTE 15 (mod 1.3.9)
Se aÃ±adieron cuatro mensajes de interfaz de Animated Vehicle Parts Fix para su
aviso de error. Se conservaron exactamente las etiquetas de formato RGB y los
marcadores <LINE>. No se modifico el original.

MOD Y VERSION INSTALADA
- Animated Vehicle Parts Fix (Workshop 3802266453): modversion 1.2.2.

RUTAS DE LOS ARCHIVOS FUENTE
  Mod.description:
  J:\SteamLibrary\steamapps\workshop\content\108600\3802266453\mods\AnimatedVehiclePartsFix\42\media\lua\shared\Translate\EN\Mod.json
  UI_AVPF_*:
  J:\SteamLibrary\steamapps\workshop\content\108600\3802266453\mods\AnimatedVehiclePartsFix\42\media\lua\shared\Translate\EN\UI.json

FUENTES DE TRADUCCION â€” LOTE 16 (mod 1.4.0)
Se aÃ±adieron cinco claves de interfaz de Starlit Library: dos de IG_UI y
tres de UI. Se conservaron los marcadores %1, %2+, <br> y el nombre propio
Starlit Library. La fuente inglesa esta en la carpeta comun usada por Build 42;
el mod activo declara version 2.1.5 para 42.15. No se modifico el original.

RUTAS DE LOS ARCHIVOS FUENTE
  IGUI_StarlitLibrary_*:
  J:\SteamLibrary\steamapps\workshop\content\108600\3378285185\mods\StarlitLibrary\common\media\lua\shared\Translate\EN\IG_UI.json
  UI_StarlitLibrary*:
  J:\SteamLibrary\steamapps\workshop\content\108600\3378285185\mods\StarlitLibrary\common\media\lua\shared\Translate\EN\UI.json

FUENTES DE TRADUCCION â€” LOTE 17 (mod 1.4.1)
Se aÃ±adieron las 20 opciones de UI que faltaban en espaÃ±ol para P4HasBeenRead
3.8.1. Se conservaron los marcadores <br> de los catalogos y los textos
espaÃ±oles que ya proporcionaba el mod; solo se aÃ±adieron claves ausentes.

RUTA DEL ARCHIVO FUENTE
  UI_P4HasBeenRead_Options_*:
  J:\SteamLibrary\steamapps\workshop\content\108600\2544353492\mods\P4HasBeenRead\42.15\media\lua\shared\Translate\EN\UI.json

FUENTES DE TRADUCCION â€” LOTE 18 (mod 1.4.2)
Se aÃ±adieron nueve mensajes de interfaz de ZombieBuddy. Se conservaron los
marcadores de formato (<H1>, <H2>, <TEXT>, <LINE>, <INDENT>, <BR>,
<IMAGECENTRE>) y los parametros %1-%4. El mod incluye licencia MIT, que
permite modificar y reutilizar el software bajo sus condiciones; esta entrada
es una traduccion separada y no modifica los archivos originales.

MOD Y RUTA DEL ARCHIVO FUENTE
- ZombieBuddy (Workshop 3619862853; carpeta 42, sin modversion en mod.info):
  J:\SteamLibrary\steamapps\workshop\content\108600\3619862853\mods\ZombieBuddy\common\media\lua\shared\Translate\EN\UI.json

FUENTES DE TRADUCCION â€” LOTE 19 (mod 1.4.3)
Se aÃ±adieron las 22 opciones UI de Jumbo Tree Indoor Fix 1.6.5. Se conservaron
los saltos de linea de las descripciones y el nombre propio del mod. La fuente
comun no contiene catalogos ES/ES_MX para esas claves. El original permanece
intacto.

RUTA DEL ARCHIVO FUENTE
  UI_JTIF_*:
  J:\SteamLibrary\steamapps\workshop\content\108600\3774826484\mods\JumboTreeIndoorFix\42\media\lua\shared\Translate\EN\UI.json

FUENTES DE TRADUCCION â€” LOTE 20 (mod 1.4.4)
Se aÃ±adieron 24 claves de XGlueTapeCrafting: cuatro nombres de recetas
evolutivas, diez nombres de objetos, cinco recetas y cinco tooltips. Se
conservaron las claves que se repiten en ItemName y EvolvedRecipeName, cada
una en su catalogo correspondiente. El original permanece intacto.

Estas traducciones ya forman parte de este catalogo; no se necesita un parche
separado. `XGlueTapeCrafting` es opcional: `loadModAfter` solo establece el orden
cuando el Workshop esta activo y no declara `require`. Si el mod no esta
instalado, las claves de sus objetos y recetas no se utilizan.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- XGlueTapeCrafting (Workshop 3767335348); la carpeta 42 no declara
  modversion en mod.info:
  J:\SteamLibrary\steamapps\workshop\content\108600\3767335348\mods\XGlueTapeCrafting\42\media\lua\shared\Translate\EN\EvolvedRecipeName.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3767335348\mods\XGlueTapeCrafting\42\media\lua\shared\Translate\EN\ItemName.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3767335348\mods\XGlueTapeCrafting\42\media\lua\shared\Translate\EN\Recipes.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3767335348\mods\XGlueTapeCrafting\42\media\lua\shared\Translate\EN\Tooltip.json

FUENTES DE TRADUCCION â€” LOTE 21 (mod 1.4.5)
Se aÃ±adieron 14 claves de Cobb Motor Company M540: siete nombres de interfaz
para el vehiculo y sus partes y siete nombres de recetas. Se conserva el nombre
de marca. El original de Workshop permanece intacto.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- Cobb Motor Company M540 (Workshop 3722240318; carpeta common):
  J:\SteamLibrary\steamapps\workshop\content\108600\3722240318\mods\cobbM540\common\media\lua\shared\Translate\EN\IG_UI.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3722240318\mods\cobbM540\common\media\lua\shared\Translate\EN\Recipes.json

FUENTES DE TRADUCCION â€” LOTE 22 (mod 1.4.6)
Se aÃ±adieron 24 etiquetas funcionales de isoContainers: nombres de contenedores,
compartimentos, piezas, recetas y la opcion Sandbox. Se excluyeron dos claves
HEADER_* que identifican los catalogos y no son texto visible del juego. El
original de Workshop permanece intacto.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- isoContainers (Workshop 2625625421; depende de damnlib):
  J:\SteamLibrary\steamapps\workshop\content\108600\2625625421\mods\isoContainers\common\media\lua\shared\Translate\EN\IG_UI.json
  J:\SteamLibrary\steamapps\workshop\content\108600\2625625421\mods\isoContainers\common\media\lua\shared\Translate\EN\Recipes.json
  J:\SteamLibrary\steamapps\workshop\content\108600\2625625421\mods\isoContainers\common\media\lua\shared\Translate\EN\Sandbox.json

FUENTES DE TRADUCCION â€” LOTE 23 (mod 1.4.7)
Se aÃ±adieron 24 claves de interfaz y recetas del Nissan Skyline GT-R (R32)
de 1992. Se conservaron las referencias al modelo y las variantes importada
y convertida. El original de Workshop permanece intacto.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- 92 Nissan Skyline GT-R (Workshop 2846036306; carpeta common):
  J:\SteamLibrary\steamapps\workshop\content\108600\2846036306\mods\92nissanGTR\common\media\lua\shared\Translate\EN\IG_UI.json
  J:\SteamLibrary\steamapps\workshop\content\108600\2846036306\mods\92nissanGTR\common\media\lua\shared\Translate\EN\Recipes.json

FUENTES DE TRADUCCION â€” LOTE 24 (mod 1.4.8)
Se aÃ±adieron 29 claves de interfaz, recetas y opciones Sandbox del DeLorean
DMC-12 de 1981. La opcion comun de apariciones garantizadas de DAMN se traduce
una sola vez para los mods que comparten esa clave. El original permanece
intacto.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- 81 DeLorean DMC-12 (Workshop 3253385114; carpeta common):
  J:\SteamLibrary\steamapps\workshop\content\108600\3253385114\mods\81deloreanDMC12\common\media\lua\shared\Translate\EN\IG_UI.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3253385114\mods\81deloreanDMC12\common\media\lua\shared\Translate\EN\Recipes.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3253385114\mods\81deloreanDMC12\common\media\lua\shared\Translate\EN\Sandbox.json

FUENTES DE TRADUCCION â€” LOTE 25 (mod 1.4.9)
Se aÃ±adieron 42 etiquetas de interfaz y recetas del camion de bomberos Pierce
Arrow de 1990: nombres del vehiculo, compartimentos, mangueras, escaleras,
tanque de agua y piezas. El original de Workshop permanece intacto.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- 90 Pierce Arrow (Workshop 2942793445; carpeta common):
  J:\SteamLibrary\steamapps\workshop\content\108600\2942793445\mods\90pierceArrow\common\media\lua\shared\Translate\EN\IG_UI.json
  J:\SteamLibrary\steamapps\workshop\content\108600\2942793445\mods\90pierceArrow\common\media\lua\shared\Translate\EN\Recipes.json

FUENTES DE TRADUCCION â€” LOTE 26 (mod 1.4.10)
Se aÃ±adieron 35 claves de interfaz y recetas del Volkswagen Escarabajo Tipo 1
de 1963, incluido el buggy de dunas y las variantes de neumaticos y parachoques.
El original de Workshop permanece intacto.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- 63 Volkswagen Beetle (Workshop 3005903549; carpeta common):
  J:\SteamLibrary\steamapps\workshop\content\108600\3005903549\mods\63beetle\common\media\lua\shared\Translate\EN\IG_UI.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3005903549\mods\63beetle\common\media\lua\shared\Translate\EN\Recipes.json

FUENTES DE TRADUCCION â€” LOTE 27 (mod 1.4.11)
Se aÃ±adieron 36 claves de interfaz y recetas del AM General M998 HMMWV de
1992 y del remolque M101A3. El original de Workshop permanece intacto.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- 92 AM General M998 (Workshop 2642541073; carpeta common):
  J:\SteamLibrary\steamapps\workshop\content\108600\2642541073\mods\92amgeneralM998\common\media\lua\shared\Translate\EN\IG_UI.json
  J:\SteamLibrary\steamapps\workshop\content\108600\2642541073\mods\92amgeneralM998\common\media\lua\shared\Translate\EN\Recipes.json

FUENTES DE TRADUCCION â€” LOTE 28 (mod 1.4.12)
Se aÃ±adieron 42 claves de interfaz, recetas y opciones Sandbox del Cadillac
Gage LAV-300 de 1984. La clave comun de apariciones garantizadas de DAMN se
tradujo en el lote del DeLorean. El original permanece intacto.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- 84 Cadillac Gage LAV-300 (Workshop 3171184800; carpeta common):
  J:\SteamLibrary\steamapps\workshop\content\108600\3171184800\mods\84gageV300\common\media\lua\shared\Translate\EN\IG_UI.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3171184800\mods\84gageV300\common\media\lua\shared\Translate\EN\Recipes.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3171184800\mods\84gageV300\common\media\lua\shared\Translate\EN\Sandbox.json

FUENTES DE TRADUCCION â€” LOTE 29 (mod 1.4.13)
Se aÃ±adieron 44 claves de interfaz y recetas del Jeep Wrangler YJ de 1992.
El original de Workshop permanece intacto.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- 92 Jeep Wrangler YJ (Workshop 3287727378; carpeta common):
  J:\SteamLibrary\steamapps\workshop\content\108600\3287727378\mods\92jeepYJ\common\media\lua\shared\Translate\EN\IG_UI.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3287727378\mods\92jeepYJ\common\media\lua\shared\Translate\EN\Recipes.json

FUENTES DE TRADUCCION â€” LOTE 30 (mod 1.4.14)
Se aÃ±adieron 49 claves de interfaz y recetas de la furgoneta Volkswagen
Tipo 2 de 1963, incluidas las variantes militar, hippie y del apocalipsis.
El original de Workshop permanece intacto.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- 63 Volkswagen Type 2 Van (Workshop 3041122351; carpeta common):
  J:\SteamLibrary\steamapps\workshop\content\108600\3041122351\mods\63Type2Van\common\media\lua\shared\Translate\EN\IG_UI.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3041122351\mods\63Type2Van\common\media\lua\shared\Translate\EN\Recipes.json

FUENTES DE TRADUCCION â€” LOTE 31 (mod 1.4.15)
Se aÃ±adieron 63 claves de interfaz y recetas de KI5 Campers: seis remolques,
asientos/camas, almacenamiento, gabinetes, herramientas y recetas para Scamp,
Airstream y Shasta. El original de Workshop permanece intacto.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- KI5 Campers (Workshop 3670064951; carpeta common):
  J:\SteamLibrary\steamapps\workshop\content\108600\3670064951\mods\KI5campers\common\media\lua\shared\Translate\EN\IG_UI.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3670064951\mods\KI5campers\common\media\lua\shared\Translate\EN\Recipes.json

FUENTES DE TRADUCCION â€” LOTE 32 (mod 1.4.16)
Se aÃ±adieron 69 claves de interfaz, nombres de objetos, opciones Sandbox,
tooltips, menu contextual y rasgos de Hunter Expansion. Se conservaron los
marcadores <br> de las descripciones. El original de Workshop permanece intacto.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- Hunter Expansion (Workshop 3786994541; carpeta common):
  J:\SteamLibrary\steamapps\workshop\content\108600\3786994541\mods\HunterExpansion\common\media\lua\shared\Translate\EN\ContextMenu.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3786994541\mods\HunterExpansion\common\media\lua\shared\Translate\EN\IG_UI.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3786994541\mods\HunterExpansion\common\media\lua\shared\Translate\EN\ItemName.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3786994541\mods\HunterExpansion\common\media\lua\shared\Translate\EN\Sandbox.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3786994541\mods\HunterExpansion\common\media\lua\shared\Translate\EN\Tooltip.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3786994541\mods\HunterExpansion\common\media\lua\shared\Translate\EN\UI.json

FUENTES DE TRADUCCION â€” LOTE 33 (mod 1.4.17)
Se aÃ±adieron 77 claves de GridRV: interfaz del vehiculo, objetos de blindaje,
recetas, opciones Sandbox y avisos para respaldar partidas/servidores antes
de una actualizacion. Se conservaron las etiquetas de formato y los marcadores
de color. El original de Workshop permanece intacto.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- GridRV (Workshop 3820158673; carpeta 42):
  J:\SteamLibrary\steamapps\workshop\content\108600\3820158673\mods\GridRV\42\media\lua\shared\Translate\EN\IG_UI.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3820158673\mods\GridRV\42\media\lua\shared\Translate\EN\ItemName.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3820158673\mods\GridRV\42\media\lua\shared\Translate\EN\Recipes.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3820158673\mods\GridRV\42\media\lua\shared\Translate\EN\Sandbox.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3820158673\mods\GridRV\42\media\lua\shared\Translate\EN\Tooltip.json

FUENTES DE TRADUCCION â€” LOTE 34 (mod 1.4.18)
Se aÃ±adieron 85 claves de interfaz, recetas y opciones de los autobuses Ford
B700 y camiones F700 de 1987. El original de Workshop permanece intacto.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- 87 Ford B700 (Workshop 3110911330; carpeta common):
  J:\SteamLibrary\steamapps\workshop\content\108600\3110911330\mods\87fordB700\common\media\lua\shared\Translate\EN\IG_UI.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3110911330\mods\87fordB700\common\media\lua\shared\Translate\EN\Recipes.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3110911330\mods\87fordB700\common\media\lua\shared\Translate\EN\Sandbox.json

FUENTES DE TRADUCCION â€” LOTE 35 (mod 1.4.19)
Se aÃ±adieron 39 opciones Sandbox de Undead Wildlife, incluidos controles de
encuentros, zombis, daÃ±o, reanimacion y depuracion. Se conservaron los
marcadores `%%` para mostrar porcentajes en el juego. El original permanece
intacto.

MOD Y RUTA DEL ARCHIVO FUENTE
- Undead Wildlife (Workshop 3781571720; carpeta 42):
  J:\SteamLibrary\steamapps\workshop\content\108600\3781571720\mods\UndeadWildlife\42\media\lua\shared\Translate\EN\Sandbox.json

FUENTES DE TRADUCCION â€” LOTE 36 (mod 1.4.20)
Se aÃ±adieron 53 textos de HomemadeThings: categoria de fabricacion, fluido,
objetos y recetas. Se omitio language.json porque solo contiene metadatos de
idioma y version. El original de Workshop permanece intacto.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- HomemadeThings (Workshop 3391325510; carpeta 42):
  J:\SteamLibrary\steamapps\workshop\content\108600\3391325510\mods\HomemadeThings\42\media\lua\shared\Translate\EN\Fluids.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3391325510\mods\HomemadeThings\42\media\lua\shared\Translate\EN\IG_UI.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3391325510\mods\HomemadeThings\42\media\lua\shared\Translate\EN\ItemName.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3391325510\mods\HomemadeThings\42\media\lua\shared\Translate\EN\Recipes.json

FUENTES DE TRADUCCION â€” LOTE 37 (mod 1.4.21)
Se aÃ±adieron 55 opciones Sandbox de MaD's Awesome Zombie Loot. Se conservaron
los marcadores %% y la sintaxis de las reglas de botin configurables. El
original de Workshop permanece intacto.

MOD Y RUTA DEL ARCHIVO FUENTE
- MaD's Awesome Zombie Loot B42 (Workshop 3789934624; carpeta common):
  J:\SteamLibrary\steamapps\workshop\content\108600\3789934624\mods\MaDZombieLootB42\common\media\lua\shared\Translate\EN\Sandbox.json

FUENTES DE TRADUCCION â€” LOTE 38 (mod 1.4.22)
Se aÃ±adieron 60 textos de True Cargo: interfaz, opciones Sandbox y controles
de carga visible en remolques. Se omitieron las dos claves genericas name y
description de Mod.json para evitar colisiones en el catalogo compartido. El
original de Workshop permanece intacto.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- True Cargo (Workshop 3806955469; carpeta common):
  J:\SteamLibrary\steamapps\workshop\content\108600\3806955469\mods\PFHDTrueCargo\common\media\lua\shared\Translate\EN\Sandbox.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3806955469\mods\PFHDTrueCargo\common\media\lua\shared\Translate\EN\UI.json

FUENTES DE TRADUCCION â€” LOTE 39 (mod 1.4.23)
Se aÃ±adieron cuatro claves de Authentic Z - Current: el menu para lanzar una
barra luminosa y los nombres de tres recipientes de fluidos. Este lote cubre
solo ContextMenu y Fluids; los demas catalogos de Authentic Z se revisaran por
separado. El original de Workshop permanece intacto.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- Authentic Z - Current (Workshop 2335368829; carpeta 42):
  J:\SteamLibrary\steamapps\workshop\content\108600\2335368829\mods\Authentic Z - Current\42\media\lua\shared\Translate\EN\ContextMenu.json
  J:\SteamLibrary\steamapps\workshop\content\108600\2335368829\mods\Authentic Z - Current\42\media\lua\shared\Translate\EN\Fluids.json

FUENTES DE TRADUCCION â€” LOTE 40 (mod 1.4.24)
Se aÃ±adieron 78 claves de Xanny Arms Gun Pack: diez acciones de menu para
pruebas/diagnostico y 68 recetas para abrir o empaquetar municion. Se conservo
el marcador %1 y la notacion de cada calibre. El original permanece intacto.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- Xanny Arms Gun Pack (Workshop 3820971639; carpeta 42):
  J:\SteamLibrary\steamapps\workshop\content\108600\3820971639\mods\XannyArmsGunPack\42\media\lua\shared\Translate\EN\ContextMenu.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3820971639\mods\XannyArmsGunPack\42\media\lua\shared\Translate\EN\Recipes.json

FUENTES DE TRADUCCION â€” LOTE 41 (mod 1.4.25)
Se aÃ±adieron 141 claves de Wound Expansion: 37 de menu contextual, 103 de
interfaz y una receta. Se conservaron los marcadores de formato; los archivos
originales de Workshop permanecen intactos.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- Wound Expansion (Workshop 3819438691; carpeta 42):
  J:\SteamLibrary\steamapps\workshop\content\108600\3819438691\mods\WoundExpansion\42\media\lua\shared\Translate\EN\ContextMenu.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3819438691\mods\WoundExpansion\42\media\lua\shared\Translate\EN\IG_UI.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3819438691\mods\WoundExpansion\42\media\lua\shared\Translate\EN\Recipes.json

FUENTES DE TRADUCCION â€” LOTE 42 (mod 1.4.26)
Se aÃ±adieron 38 descripciones de objetos y procedimientos de Wound Expansion.
Se conservaron los marcadores de formato; el original de Workshop permanece
intacto. Sandbox e ItemName quedan pendientes; no se modificaron porque Chila
los esta editando manualmente.

MOD Y RUTA DEL ARCHIVO FUENTE
- Wound Expansion (Workshop 3819438691; carpeta 42):
  J:\SteamLibrary\steamapps\workshop\content\108600\3819438691\mods\WoundExpansion\42\media\lua\shared\Translate\EN\Tooltip.json

FUENTES DE TRADUCCION â€” LOTE 43 (mod 1.4.27)
Se aÃ±adieron dos nombres de contenedores de fluidos de damnlib y dos opciones
de menu de Dismantle All at Once. Los originales de Workshop permanecen intactos.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- damnlib (Workshop 3171167894; carpeta common):
  J:\SteamLibrary\steamapps\workshop\content\108600\3171167894\mods\damnlib\common\media\lua\shared\Translate\EN\Fluids.json
- Dismantle All at Once (Workshop 3761218629; carpeta 42):
  J:\SteamLibrary\steamapps\workshop\content\108600\3761218629\mods\DismantleAllAtOnce\42\media\lua\shared\Translate\EN\ContextMenu.json

FUENTES DE TRADUCCION â€” LOTE 44 (mod 1.4.28)
Se aÃ±adieron 29 textos de Skateboards: acciones, controles y opciones de sonido
y velocidad. No se modificaron sus catalogos de objetos, tooltips ni Sandbox.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- Skateboards! (Workshop 3456675747; carpeta 42.13):
  J:\SteamLibrary\steamapps\workshop\content\108600\3456675747\mods\SkateBoard\42.13\media\lua\shared\Translate\EN\ContextMenu.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3456675747\mods\SkateBoard\42.13\media\lua\shared\Translate\EN\IG_UI.json

FUENTES DE TRADUCCION â€” LOTE 45 (mod 1.4.29)
Se aÃ±adieron 20 textos de Animal Remaster: una etiqueta de leche de cabra y
recetas para procesar pieles, trofeos y patos. No se modificaron ItemName ni
Sandbox, que Chila esta editando manualmente.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- Animal Remaster (Workshop 3819478254; carpeta 42):
  J:\SteamLibrary\steamapps\workshop\content\108600\3819478254\mods\RRAR\42\media\lua\shared\Translate\EN\Fluids.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3819478254\mods\RRAR\42\media\lua\shared\Translate\EN\Recipes.json

FUENTES DE TRADUCCION â€” LOTE 46 (mod 1.4.30)
Se tradujo un primer bloque de razas, patrones de pelaje y tipos de animales de
Animal Remaster. El catalogo IG_UI del mod es extenso y este bloque no lo cubre
completo; ItemName y Sandbox siguen sin modificarse por las ediciones manuales.

MOD Y RUTA DEL ARCHIVO FUENTE
- Animal Remaster (Workshop 3819478254; carpeta 42):
  J:\SteamLibrary\steamapps\workshop\content\108600\3819478254\mods\RRAR\42\media\lua\shared\Translate\EN\IG_UI.json

FUENTES DE TRADUCCION â€” LOTE 47 (mod 1.4.31)
Se aÃ±adieron nombres de vacas, terneros, toros, ciervos, cerdos, ovejas y
carneros de Animal Remaster.

MOD Y RUTA DEL ARCHIVO FUENTE
- Animal Remaster (Workshop 3819478254; carpeta 42):
  J:\SteamLibrary\steamapps\workshop\content\108600\3819478254\mods\RRAR\42\media\lua\shared\Translate\EN\IG_UI.json

FUENTES DE TRADUCCION â€” LOTE 48 (mod 1.4.32)
Se aÃ±adieron nombres y variedades de patos, ocas, pavos reales y cabras de
Animal Remaster.

MOD Y RUTA DEL ARCHIVO FUENTE
- Animal Remaster (Workshop 3819478254; carpeta 42):
  J:\SteamLibrary\steamapps\workshop\content\108600\3819478254\mods\RRAR\42\media\lua\shared\Translate\EN\IG_UI.json

FUENTES DE TRADUCCION â€” LOTE 49 (mod 1.4.33)
Se completaron las 362 claves de IG_UI de Animal Remaster, incluyendo ganado,
aves, cabras y tipos de animales. ItemName y Sandbox siguen sin cambios porque
Chila los esta editando manualmente.

MOD Y RUTA DEL ARCHIVO FUENTE
- Animal Remaster (Workshop 3819478254; carpeta 42):
  J:\SteamLibrary\steamapps\workshop\content\108600\3819478254\mods\RRAR\42\media\lua\shared\Translate\EN\IG_UI.json

FUENTES DE TRADUCCION â€” LOTE 50 (mod 1.4.34)
Se aÃ±adieron seis categorias de armas de Xanny Arms Gun Pack. Los catalogos
ItemName y Tooltip de ese mod no se modificaron porque Chila los edita manualmente.

MOD Y RUTA DEL ARCHIVO FUENTE
- Xanny Arms Gun Pack (Workshop 3820971639; carpeta 42):
  J:\SteamLibrary\steamapps\workshop\content\108600\3820971639\mods\XannyArmsGunPack\42\media\lua\shared\Translate\EN\IGUI.json

FUENTES DE TRADUCCION â€” LOTE 51 (mod 1.4.35)
Se aÃ±adieron seis etiquetas de interfaz y una receta faltantes de Authentic Z -
Current. Sus catalogos ItemName, Tooltip y UI conservan pendientes que no se
modificaron en este lote.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- Authentic Z - Current (Workshop 2335368829; carpeta 42):
  J:\SteamLibrary\steamapps\workshop\content\108600\2335368829\mods\Authentic Z - Current\42\media\lua\shared\Translate\EN\IG_UI.json
  J:\SteamLibrary\steamapps\workshop\content\108600\2335368829\mods\Authentic Z - Current\42\media\lua\shared\Translate\EN\Recipes.json

FUENTES DE TRADUCCION â€” LOTE 52 (mod 1.4.36)
Se aÃ±adieron 42 textos de Wilderness QoL para identificar alimentos, recolectar,
gestionar rutas automaticas y configurar sus opciones.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- Wilderness QoL (Workshop 3779759338; carpeta 42.20):
  J:\SteamLibrary\steamapps\workshop\content\108600\3779759338\mods\ForageIdentification\42.20\media\lua\shared\Translate\EN\ContextMenu.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3779759338\mods\ForageIdentification\42.20\media\lua\shared\Translate\EN\IG_UI.json

FUENTES DE TRADUCCION â€” LOTE 53 (mod 1.4.37)
Se aÃ±adieron 335 textos de interfaz: 280 de Mirage Wardrobe, 30 de Tryhonesty's
Tiles y 25 de Community Tile Pack. Se conservaron las claves y los marcadores
de formato del catalogo de Mirage Wardrobe. Solo se modifico IG_UI.json; no se
tocaron Sandbox.json, ItemName.json, Tooltip.json ni UI.json.

MODS Y RUTAS DE LOS ARCHIVOS FUENTE
- Mirage Wardrobe (Workshop 3770186452; carpeta 42.0):
  J:\SteamLibrary\steamapps\workshop\content\108600\3770186452\mods\MirageWardrobe\42.0\media\lua\shared\Translate\EN\IG_UI.json
- Tryhonesty's Tiles (Workshop 2844685624; carpeta common):
  J:\SteamLibrary\steamapps\workshop\content\108600\2844685624\mods\Tryhonesty's Tiles\common\media\lua\shared\Translate\EN\IG_UI.json
- Community Tile Pack (Workshop 3628736763; carpeta common):
  J:\SteamLibrary\steamapps\workshop\content\108600\3628736763\mods\CommunityTilePack\common\media\lua\shared\Translate\EN\IG_UI.json

FUENTES DE TRADUCCION â€” LOTE 54 (mod 1.4.38)
Se aÃ±adieron 89 etiquetas de interfaz de damnlib para partes y asientos de
vehiculos, avisos de instalacion y controles de toldo/techo corredizo. Las
claves de grupos activos de vehiculos se amplian en los lotes 56â€“57; no se
modificaron Sandbox.json ni Tooltip.json.

MOD Y RUTA DEL ARCHIVO FUENTE
- damnlib (Workshop 3171167894; carpeta common):
  J:\SteamLibrary\steamapps\workshop\content\108600\3171167894\mods\damnlib\common\media\lua\shared\Translate\EN\IG_UI.json

FUENTES DE TRADUCCION â€” LOTE 55 (mod 1.4.39)
Se aÃ±adieron 40 recetas generales de damnlib para asientos militares, cajas,
mirillas y piezas de neumaticos. En el lote 58 se amplia la cobertura con las
94 recetas genericas restantes de damnCraft.

MOD Y RUTA DEL ARCHIVO FUENTE
- damnlib (Workshop 3171167894; carpeta common):
  J:\SteamLibrary\steamapps\workshop\content\108600\3171167894\mods\damnlib\common\media\lua\shared\Translate\EN\Recipes.json

FUENTES DE TRADUCCION â€” LOTE 60 (mod 1.4.44)
Se aÃ±adieron 209 textos de The Only Cure+ (Workshop 3818733381): 142 de IG_UI,
39 de ContextMenu, 26 de Recipes y 2 de Moveables. El complemento declara
que carga despues del original. El mod usa GPL-3.0; se conservaron los archivos
originales y sus rutas.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- The Only Cure+ (carpeta 42):
  J:\SteamLibrary\steamapps\workshop\content\108600\3818733381\mods\TheOnlyCurePlus\42\media\lua\shared\Translate\EN\IG_UI.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3818733381\mods\TheOnlyCurePlus\42\media\lua\shared\Translate\EN\ContextMenu.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3818733381\mods\TheOnlyCurePlus\42\media\lua\shared\Translate\EN\Recipes.json
  J:\SteamLibrary\steamapps\workshop\content\108600\3818733381\mods\TheOnlyCurePlus\42\media\lua\shared\Translate\EN\Moveables.json

FUENTES DE TRADUCCION â€” LOTE 62 (mod 1.4.46)
Se aÃ±adieron 190 nombres y descripciones de Moodle Descriptions Expanded
(Workshop 3389003300). Se conservaron todos los modificadores porcentuales
del catalogo. El archivo Moodles.json quedo sin claves duplicadas.

MOD Y RUTA DEL ARCHIVO FUENTE
- Moodle Descriptions Expanded (carpeta 42):
  J:\SteamLibrary\steamapps\workshop\content\108600\3389003300\mods\[B42] Moodle Descriptions Expanded\42\media\lua\shared\Translate\EN\Moodles.json

FUENTES DE TRADUCCION â€” LOTE 63 (mod 1.4.47)
Se aÃ±adieron 48 opciones y acciones de Minimal Display Bars + Nutritions +
Discomfort (Workshop 3388844542) en ContextMenu.json. La interfaz de opciones
UI.json sigue pendiente y no se modifico por las ediciones manuales de Chila.

MOD Y RUTA DEL ARCHIVO FUENTE
- Minimal Display Bars + Nutritions + Discomfort (carpeta 42.20):
  J:\SteamLibrary\steamapps\workshop\content\108600\3388844542\mods\Minimal Display Bars Nutritions B42\42.20\media\lua\shared\Translate\EN\ContextMenu.json

FUENTES DE TRADUCCION â€” LOTE 64 (mod 1.4.48)
Se aÃ±adieron las cuatro recetas inglesas de Liel's Brazilian Chips (Workshop
3269291624). Los catalogos ItemName y Sandbox no se modificaron porque Chila
los esta editando manualmente.

MOD Y RUTA DEL ARCHIVO FUENTE
- Liel's Brazilian Chips (carpeta 42.16):
  J:\SteamLibrary\steamapps\workshop\content\108600\3269291624\mods\Liel's Brazilian Chips\42.16\media\lua\shared\Translate\EN\Recipes.json

FUENTES DE TRADUCCION â€” LOTE 61 (mod 1.4.45)
Se aÃ±adieron 65 textos de Dynamic Traits and Expanded Moodles (Workshop
2459400130): 26 estados de animo, 20 recetas, 15 textos IG_UI y 4 acciones
de menu contextual. No se modificaron Sandbox.json, ItemName.json, Tooltip.json
ni UI.json.

MOD Y RUTAS DE LOS ARCHIVOS FUENTE
- Dynamic Traits and Expanded Moodles (carpeta 42.15):
  J:\SteamLibrary\steamapps\workshop\content\108600\2459400130\mods\DynamicTraits\42.15\media\lua\shared\Translate\EN\Moodles.json
  J:\SteamLibrary\steamapps\workshop\content\108600\2459400130\mods\DynamicTraits\42.15\media\lua\shared\Translate\EN\Recipes.json
  J:\SteamLibrary\steamapps\workshop\content\108600\2459400130\mods\DynamicTraits\42.15\media\lua\shared\Translate\EN\IG_UI.json
  J:\SteamLibrary\steamapps\workshop\content\108600\2459400130\mods\DynamicTraits\42.15\media\lua\shared\Translate\EN\ContextMenu.json

FUENTES DE TRADUCCION â€” LOTE 56 (mod 1.4.40)
Se aÃ±adieron 49 recetas de damnlib correspondientes a remolques KI5, Shelby
GT500 y Oshkosh P19A/M1082 activos en el perfil.

MOD Y RUTA DEL ARCHIVO FUENTE
- damnlib (Workshop 3171167894; carpeta common):
  J:\SteamLibrary\steamapps\workshop\content\108600\3171167894\mods\damnlib\common\media\lua\shared\Translate\EN\Recipes.json

FUENTES DE TRADUCCION â€” LOTE 57 (mod 1.4.41)
Se aÃ±adieron 51 textos IG_UI de esos mismos grupos activos: nombres de
vehiculos/remolques y etiquetas de partes y compartimentos.

MOD Y RUTA DEL ARCHIVO FUENTE
- damnlib (Workshop 3171167894; carpeta common):
  J:\SteamLibrary\steamapps\workshop\content\108600\3171167894\mods\damnlib\common\media\lua\shared\Translate\EN\IG_UI.json

FUENTES DE TRADUCCION â€” LOTE 58 (mod 1.4.42)
Se aÃ±adieron las 94 recetas genericas restantes de damnCraft: neumaticos,
reparaciones, desmontaje y fabricacion de piezas, moldes y seÃ±ales. Con esto
quedan cubiertas las 101 claves damnCraft de la fuente comun de damnlib.

MOD Y RUTA DEL ARCHIVO FUENTE
- damnlib (Workshop 3171167894; carpeta common):
  J:\SteamLibrary\steamapps\workshop\content\108600\3171167894\mods\damnlib\common\media\lua\shared\Translate\EN\Recipes.json

FUENTES DE TRADUCCION â€” LOTE 59 (mod 1.4.43)
Se aÃ±adieron 84 recetas adicionales del bloque comun de damnlib para piezas
de GM B/C-body, Ford CVPI, cajas utilitarias, Chevrolet C/K y CUCV, Ford F-Series
y camionetas de los aÃ±os 80. Son claves incluidas por damnlib; la presencia de
cada vehiculo en el perfil activo debe confirmarse antes de considerarlo cubierto.

MOD Y RUTA DEL ARCHIVO FUENTE
- damnlib (Workshop 3171167894; carpeta common):
  J:\SteamLibrary\steamapps\workshop\content\108600\3171167894\mods\damnlib\common\media\lua\shared\Translate\EN\Recipes.json


WILDERNESS QOL Y PARCHE DE IDENTIFICACION
La cobertura de Wilderness QoL 0.8.11 estÃ¡ integrada en este catÃ¡logo (125 claves). Las claves que ya existÃ­an conservan el texto central revisado; se aÃ±adieron las faltantes de Sandbox, Tooltip y UI. La guardia de identificaciÃ³n tambiÃ©n vive aquÃ­ y solo se aplica si Wilderness QoL expone WFI/WFI_Core. Si el original estÃ¡ ausente, la traducciÃ³n no causa errores y la guardia se omite. El antiguo ID ChilaSeda_WildernessQoL_ES_B42 y el ID del parche separado dejan de activarse. Referencia y validaciÃ³n anteriores: ChilaSeda_AuditSuite_B42/Documentacion/WildernessQoL/.

FUENTES DE TRADUCCION â€” RECETAS VANILLA B42 (mod 1.4.51)
Se aÃ±adieron las claves oficiales `MakeSalad` y `MakeFruitSalad` de
`media/lua/shared/Translate/EN/Recipes.json`, con los nombres Â«Preparar ensaladaÂ»
y Â«Preparar ensalada de frutasÂ».

CORRECCION DE NOMBRES CONTEXTUALES DE ENSALADAS (2026-11-08)
Se aÃ±adieron tambiÃ©n las claves literales `Make Salad` y `Make Fruit Salad`, que
el menÃº contextual y sus tooltips consultan con espacio. Estas claves apuntan a
los mismos nombres espaÃ±oles que `MakeSalad` y `MakeFruitSalad`.

CAMBIOS EN 1.4.53
- AÃ±ade las claves IGUI_VPF_Forage, IGUI_VPF_Examine e IGUI_VPF_Tracks para el HUD de Viewpoint Foraging.
- AÃ±ade etiquetas, valores y ayudas en espaÃ±ol para su pÃ¡gina PZAPI de opciones; ChilaSeda Fix - Viewpoint Foraging Fixes 1.3.11 aplica esas traducciones a los textos literales del Workshop.

CAMBIOS EN 1.4.54
- AÃ±ade espaÃ±ol para etiquetas, valores y ayudas PZAPI literales de Project Viewpoint QOL Legacy,
  Way More Cars, Mini Compass, Visual Sounds KA y Heli Event; el localizador solo cambia texto
  visible y conserva valores funcionales y ajustes.
- Traduce el tÃ­tulo PZAPI de Has Been Read y la etiqueta Current/Total HP de CombatText.

