# Backup, instalacion y reversion de parches externos

Esta guia del repositorio explica como respaldar, instalar y revertir cambios
que afecten archivos fuera de la carpeta de un mod.

## Regla para archivos fuera de `mods`

Antes de cambiar, reemplazar o mover cualquier archivo fuera de `mods` o del
sandbox escribible:

1. Cierra el juego o la aplicacion que pueda tener el archivo abierto.
2. Identifica cada archivo afectado. No copies carpetas completas de partidas.
3. Copia cada archivo a `mods/backups/<timestamp>/`, conservando su ruta
   relativa y nombre. No sobrescribas ni borres backups anteriores.
4. Registra ruta original, ruta del backup, version/fuente y SHA-256 antes del
   cambio.
5. Documenta el cambio, el metodo para instalarlo y el procedimiento de
   rollback en `.ai-memory/MEMORY.md` y en esta Wiki.
6. Tras el cambio, registra la nueva version/hash y comprueba que el archivo
   original sigue recuperable.

Modificar una partida, un perfil o sus opciones requiere autorizacion explicita.

## Preferir un parche distribuible

Project Zomboid y los archivos originales de Workshop deben permanecer intactos.
Implementa una correccion como un mod local dentro de `mods`, con un ID, version,
dependencias, orden de carga e instrucciones en `mod.info` y `README.md`. No
copies una correccion a un JAR del juego como cambio exclusivo de la computadora:
Steam puede restaurar el JAR al verificar integridad y los demas usuarios no
recibiran esa correccion.

Cuando una correccion realmente necesite un archivo externo, manten el respaldo
individual anterior y documenta en esta pagina el destino exacto, el archivo de
origen versionado, la version/hash esperado, los pasos de instalacion y rollback.
No declares la correccion distribuida hasta que el artefacto versionado incluya
los archivos necesarios.

## Distribucion y validacion

Una correccion local no equivale a una version publicada. Primero completa las
comprobaciones locales; despues, Chila valida el mod dentro de Jill. Solo tras esa
confirmacion se agrega una entrada fechada al changelog y se prepara un Release
separado que contenga un ZIP con la carpeta del mod.

## Incidente de Viewpoint del 25 de noviembre de 2026

La caida al construir la escena durante rebusqueda se debio a que Viewpoint llamo
`ForagingArrowCameraProjection.traceFallback`, declarado privado en el JAR local
2.0.147. El arreglo local 2.0.148 lo hace publico y no cambia el JAR del juego ni
los originales de Workshop. La validacion runtime en Jill sigue pendiente.

## Prueba aislada de Inventory Tetris en Jill - 2026-11-26

Se retiro temporalmente solo el ID local ChilaSeda_InventoryTetrisSizeCap_B42
del mods.txt del save activo para comparar transferencias con los originales
de Workshop. INVENTORY_TETRIS y EQUIPMENT_UI_B42 siguen activos. El parche
local proviene de ChilaSeda_InventoryTetrisSizeCap_B42 version 1.4.6.

- Destino: C:\Users\zyxsa\Zomboid\Saves\Sandbox\Jill_Valantine_25_11_2026_4PM\mods.txt
- Backup previo: C:\Users\zyxsa\Zomboid\mods\backups\2026-11-26_11-33-26-0600\Saves\Sandbox\Jill_Valantine_25_11_2026_4PM\mods.txt
- SHA-256 previo y del backup: BC2553B9B522A79A36A24E8792E3B2BB7806BA28D620DFE27DD3F59DF94BEA56
- SHA-256 resultante: C05CEA62179F357DCED5699037AB714200F12E0EA2C8EEBC6D003A18D1D1E918

Para aplicar la prueba, iniciar Jill con el archivo resultante y guardar los
registros de la sesion. Para revertirla, cerrar el juego y copiar el backup exacto
al destino. Verificar que VERSION = 1, sean los primeros bytes, que no exista
BOM UTF-8, que INVENTORY_TETRIS y EQUIPMENT_UI_B42 sigan presentes y que
ZeroWeightKeys_B42 permanezca al final.

## Configuracion de Equipment UI y restauracion de Inventory Tetris - 2026-11-26

Se actualizaron la plantilla Jill y el mods.txt del save activo con la variante
EQUIPMENT_UI del Workshop 3682936016, que corresponde a Inventory Tetris. Se
retiro EQUIPMENT_UI_B42; no activar ambas variantes. El Workshop original de
Notloc 2950902979 no aparece en la instalacion/manifest local consultados. Se
restaura ChilaSeda_InventoryTetrisSizeCap_B42 y su organizador de comida local
1.4.7; ORGANIZER_ENABLED=true ofrece de nuevo orden por frescura y calorias.
Contratos locales: 17/17. La sesion de Jill aun debe validar el resultado.

- Plantilla: C:\Users\zyxsa\Zomboid\mods\kits\Zombicidio_Jill_B42\mods.txt
  - Backup: C:\Users\zyxsa\Zomboid\mods\backups\2026-11-26_11-53-34-0600\kits\Zombicidio_Jill_B42\mods.txt
  - SHA-256 previo/backup: D4CDDE2C845F0D24C132478F294A873956B1553511E93E67D5EE6BF3F748A805
  - SHA-256 resultante: 4A96ABDE46F68F34EBF63550F235A41A1171DFA8209DCD65C3A4DCA665ABCF7B
- Save: C:\Users\zyxsa\Zomboid\Saves\Sandbox\Jill_Valantine_25_11_2026_4PM\mods.txt
  - Backup: C:\Users\zyxsa\Zomboid\mods\backups\2026-11-26_11-53-34-0600\Saves\Sandbox\Jill_Valantine_25_11_2026_4PM\mods.txt
  - SHA-256 previo/backup: C05CEA62179F357DCED5699037AB714200F12E0EA2C8EEBC6D003A18D1D1E918
  - SHA-256 resultante: F63941F87050D21536FF09AC0A34AA5D908D89172D30A68A9DA347033AD816AB

Para revertir, cierra Jill y copia el backup de cada archivo sobre su destino.
Comprueba que VERSION = 1, sean los primeros bytes, que no haya BOM UTF-8 y
que INVENTORY_TETRIS, EQUIPMENT_UI, ChilaSeda_InventoryTetrisSizeCap_B42
y ZeroWeightKeys_B42 permanezcan en el orden esperado. El ID local
ChilaSeda_InventoryTetrisSizeCap_B42 debe quedar tras Inventory Tetris y
Equipment UI.
## Prueba temporal sin Inventory Tetris en Jill - 2026-11-26

Para aislar los drops al equipar bolsas, con Project Zomboid cerrado se retiraron
solo INVENTORY_TETRIS (Workshop 3775513231) y su parche requerido
ChilaSeda_InventoryTetrisSizeCap_B42 (version 1.4.8) del mods.txt del save activo.
No se modifico la plantilla del kit ni las suscripciones de Workshop.

- Destino: C:\Users\zyxsa\Zomboid\Saves\Sandbox\Jill_Valantine_25_11_2026_4PM\mods.txt
- Backup: C:\Users\zyxsa\Zomboid\mods\backups\2026-11-26_13-50-19--0600\Saves\Sandbox\Jill_Valantine_25_11_2026_4PM\mods.txt
- SHA-256 previo y backup: 284040C4C94240A14BBC68CBF98846398B76AF1EE729D6FD1C7303C1ED7E882D
- SHA-256 resultante: BB3242D2A1A1426CDF439BF3608AE1C6CC952641F12D4EAB4E56D9B9F81EFC66

Para probar, inicia Jill con el mods.txt resultante y verifica si una cartera o
cangurera se puede equipar y llenar sin caer al piso. Para revertir, cierra el
juego y copia el backup exacto al destino. Verifica SHA-256
284040C4C94240A14BBC68CBF98846398B76AF1EE729D6FD1C7303C1ED7E882D,
VERSION = 1, al inicio, UTF-8 sin BOM, INVENTORY_TETRIS y
ChilaSeda_InventoryTetrisSizeCap_B42 restaurados, y ZeroWeightKeys_B42 al final.
La prueba runtime sigue pendiente.

## Mods de Workshop agregados a la partida Jill - 2026-11-26

A solicitud de Chila se modifico solo el `mods.txt` del save activo
`Jill_Valantine_26_11_2026_2PM`; la plantilla del kit no se cambio. Los cinco
mods ya estaban descargados. Sunshi's Cooler System contiene dos IDs, y para
Project Zomboid 42.22.2 se activo solo `LVGGSunshiCS` (versionMin 42.22), no el
ID legado `SunshiCS` (versionMin 42.20). Tambien se activaron
`JullesPortableLadders`, `GetInTheDamnCar`, `TerziMasasi` y `GrapplingRope`.
Los mods se colocaron antes del bloque local; esto deja GetInTheDamnCar antes
del parche Viewpoint que consulta sus modulos. Sus `mod.info` no declaran
dependencias `require` ni restricciones `loadModAfter`.

- Workshop: 3682702613, 3836958908, 3802614552, 3841859057 y 3842199842.
- Destino: `C:\Users\zyxsa\Zomboid\Saves\Sandbox\Jill_Valantine_26_11_2026_2PM\mods.txt`.
- Backup: `C:\Users\zyxsa\Zomboid\mods\backups\2026-11-26_15-40-23-0600\Saves\Sandbox\Jill_Valantine_26_11_2026_2PM\mods.txt`.
- SHA-256 original y backup: `BB3242D2A1A1426CDF439BF3608AE1C6CC952641F12D4EAB4E56D9B9F81EFC66`.
- SHA-256 resultante: `5CBA7D811ABB40AD6D8A7C29F1C30DB247BEBA2EEFE1145CFC4DC42A324027A5`.

El archivo resultante conserva `VERSION = 1,` al inicio, UTF-8 sin BOM y
`ZeroWeightKeys_B42` como ultima entrada. Para revertir, cierra Project Zomboid,
copia el backup sobre el destino y verifica el SHA-256 original, el encabezado,
la ausencia de BOM y que `ZeroWeightKeys_B42` vuelva a quedar al final. La nueva
carga y el comportamiento de los mods aun requieren validacion en Jill.

## Inventory Tetris pausado en Jill por auto-drop al vestir mochilas - 2026-11-26

La traza `Logs/2026-11-26_13-27_DebugLog.txt` registra que
`Base.Bag_Satchel` y `KnoxPacks.KP_Bag_FieldRuck` completan Vestir con
`result=true`, pero `GridAutoDropSystem` las manda al suelo con
`unpositioned-no-grid-fit`; despues `item:isEquipped` aparece como false. Chila
confirmo que, al desactivar Inventory Tetris, pudo equipar todos los objetos.
La causa confirmada es el auto-drop por falta de espacio en las rejillas de
Inventory Tetris, no una restriccion de peso.

El workaround actual deja `INVENTORY_TETRIS` y
`ChilaSeda_InventoryTetrisSizeCap_B42` apagados en el save activo
`Jill_Valantine_26_11_2026_2PM`; ambos siguen en la plantilla del kit. El parche
local Size Cap 1.4.9 protege la ropa equipada antes de llamar al drop original,
consultando `IsoGameCharacter.isEquippedClothing` y `WornItems.contains`; sus
contratos y suite local pasan 19/19, pero aun falta validarlo en Jill. Mantener
el workaround durante la carga actual de prueba. Cuando esa sesion termine, se
puede hacer una carga aislada con Inventory Tetris y Size Cap 1.4.9 activados,
con un respaldo nuevo del save antes de editar su `mods.txt`.

## AnimalRemasterApproved opcional con AnimalBalance activo en Jill - 2026-11-27

A solicitud de Chila se retiro solo el mod Workshop `AnimalRemasterApproved`
(item 3819478254, version instalada 1.0.11) del `mods.txt` del save activo
`Jill_Valantine_26_11_2026_2PM`. `ChilaSeda_AnimalBalance_B42` 2.3.8 permanece
activo y ya no declara RRAR en `require`; RRAR sigue en `loadModAfter` como orden
opcional. No se cambio la plantilla, las suscripciones de Workshop ni otros IDs.

- Destino: `C:\Users\zyxsa\Zomboid\Saves\Sandbox\Jill_Valantine_26_11_2026_2PM\mods.txt`.
- Backup: `C:\Users\zyxsa\Zomboid\mods\backups\2026-11-27_10-38-23-0600\Saves\Sandbox\Jill_Valantine_26_11_2026_2PM\mods.txt`.
- SHA-256 original/backup: `5785AA91E955F59664F57D2533B73C3180044FEC5A05AAC5C98DD166A435EFDC`.
- SHA-256 resultante: `5448AFA8FC8FF03CD3083B6F67F5542E6E2DB30CFD94251F5A6575928DFF77CD`.

La comprobacion por bytes confirma que el resultado es el backup menos la unica
linea `mod = AnimalRemasterApproved,`. Conserva `VERSION = 1,` como primeros
bytes, UTF-8 sin BOM, una entrada `ChilaSeda_AnimalBalance_B42` y
`ZeroWeightKeys_B42` al final. Los contratos locales de AnimalBalance pasan
14/14. Para instalar otra vez esta configuracion, con Jill cerrada, conserva el
mod local 2.3.8 activo y deja ausente solo el ID `AnimalRemasterApproved`. Para
revertir, cierra Project Zomboid, copia el backup sobre el destino y verifica
que su SHA-256 vuelva a ser
`5785AA91E955F59664F57D2533B73C3180044FEC5A05AAC5C98DD166A435EFDC`, el
encabezado y la ausencia de BOM. La retirada evita cargar el modelo de ganso de
RRAR; no repara ese modelo.

## Parche de nivel de zanjas Moats en Jill - 2026-11-27

Se agrego solo el ID local `ChilaSeda_MoatsFillLevel_B42` 0.1.1 al save activo `Jill_Valantine_26_11_2026_2PM`. El parche se inserto despues de `ChilaSeda_Fix_Viewpoint_B42`; sus dependencias MoatsB42, Viewpoint y el fix estaban activos. Viewpoint Workshop 3809306528 declara 0.1.7 y Moats Workshop 3550032314 declara 1.7. No se cambio la plantilla ni archivos de Workshop.

- Destino: `C:\Users\zyxsa\Zomboid\Saves\Sandbox\Jill_Valantine_26_11_2026_2PM\mods.txt`.
- Backup: `C:\Users\zyxsa\Zomboid\mods\backups\2026-11-27_10-58-26-0600\Saves\Sandbox\Jill_Valantine_26_11_2026_2PM\mods.txt`.
- SHA-256 original/backup: `5448AFA8FC8FF03CD3083B6F67F5542E6E2DB30CFD94251F5A6575928DFF77CD`.
- SHA-256 resultante: `3452DEB7360E65845B4DB414E6204D4B71232FC893EA59F7D449224F099D81C8`.

El unico cambio en el perfil fue insertar el ID del parche despues de Viewpoint Fix. Se comprobo el encabezado `VERSION = 1,`, UTF-8 sin BOM, dependencias antes del parche y `ZeroWeightKeys_B42` como ultimo mod. Para revertir, con Project Zomboid cerrado, copia el backup sobre el destino y confirma que el SHA-256 regrese al valor original. El contrato local pasa 1/1; el valor visible y su tooltip siguen pendientes de validacion en Jill.