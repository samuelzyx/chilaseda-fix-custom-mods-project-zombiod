# ChilaSeda - Acciones Accesibles (Build 42) 1.0.52

## Version 1.0.52

- Adds a bounded trace from right-click Wear through `ISWearClothing`, worn-slot changes, queued transfers, and any resulting floor drop. Caller capture prefers the verified public `LuaManager.getLuaStackTraceStrings` API and falls back to the available Lua stack APIs.

## Version 1.0.51

- Groups selected food across different item types by freshness. The confirmation deletes only the selected items, rechecks their current freshness and container, and reports the bounded menu and removal results.

## Version 1.0.50

- Logs each queued clothing inventory transfer with its source, destination, and compact Lua caller frames. The diagnostic can be disabled and emits at most 32 callsite records per session; it prefers `getLuaStackTrace()` and falls back to `debug.traceback()`.

## Version 1.0.49

- Checks that a bait parameter is a Java item and exposes `getFullType` before calling it. Skips callback/function parameters without throwing or recording caught exceptions in Error Magnifier.

## Version 1.0.47

- Adds bounded menu and action lifecycle traces for Viewpoint water filling, including source, selected container, queue, and transfer result.
- Logs the fill choices available from native Viewpoint interactions to compare them with the right-click menu.

## Version 1.0.46

- Oculta sebo, grasa animal y sal del menu de cebo de trampas; registra los tipos filtrados.

## Version 1.0.45

- Amplia las trazas para seguir la seleccion "Inspect" de literatura desde el menu contextual hasta la transferencia y el ciclo de `ISReadABook`, incluyendo tipo, contenedor, cola, inicio, finalizacion o cancelacion.
- Tras Caps Lock registra durante 3 segundos el estado de FreeCam de Viewpoint, ventanas UI que aparecen/se ocultan/cierran y cambios o cancelaciones de la cola de acciones. El sondeo queda acotado a esa ventana y limita los eventos registrados.

## Version 1.0.44

- Con Long Term Preservation Extended activo, agrega recetas para convertir el conejo entero de rebusqueda en `Base.Fat` y la chuleta de cerdo `Base.PorkChop` en `Base.Lard`. Los cortes `Base.Pork` y `Base.Beef` conservan las recetas LTP existentes para manteca y sebo. Las trazas confirman la receta, el resultado y cualquier fallback de calculo.

## Version 1.0.43

- En el menú de inventario, `Procesar en lote` queda inmediatamente después de `Fabricar` cuando ambas opciones aparecen. Las demás opciones conservan su orden y una traza acotada confirma el ajuste.

## Version 1.0.42

- El menu de Viewpoint protege el escaneo de contenedores y las consultas vanilla de agua de lavado cuando una API no esta disponible. La falta de ropa accesible ya no interrumpe la opcion de lavarse; las trazas acotadas indican APIs omitidas y el resultado del menu.

## Version 1.0.41

- El menu de Viewpoint para fuentes de agua recorre tambien los contenedores visibles del panel de inventario, admite los recipientes que acepta la accion vanilla y ofrece lavar el cuerpo o ropa sucia cuando hay agua suficiente. Un registro limitado deja el origen, tipos de recipientes y conteos de lavado para diagnostico.

<div align="center">

[🏠 Repo](../README.md) · [🤝 Contribuir](../CONTRIBUTING.md) · [🚀 Releases](../docs/releases/README.md)

</div>

---

## Version 1.0.40

- El menú nativo de Viewpoint puede abrirse sin `updateMainListbox` en el panel de inventario. La actualización opcional del panel ahora comprueba cada método disponible, registra una sola advertencia si falta o falla y continúa leyendo los recipientes directamente del inventario.

## Version 1.0.39

- Las opciones para llenar recipientes se agregan durante `OnFillWorldObjectContextMenu`, antes de que Viewpoint recolecte las acciones del menu nativo oculto. Se conserva la comprobacion posterior al menu como respaldo; la deteccion de opciones ya presentes evita duplicados.

## Version 1.0.38

- El lote de cordeles/hilos y la opcion masiva de grasa de LTP ahora transfieren los ingredientes requeridos y conectan el inicio, final o cancelacion de cada accion con `HandcraftLogic`, igual que el panel vanilla. Si no se crean todas las acciones, se registra el motivo y aparece un aviso en Halo; DAAO tambien informa si no llega a construir acciones. La traza de fabricacion cubre esos lotes.
- Se agregaron pruebas de contrato para las rutas de lote locales, DAAO y resultados del crafteo normal.

## Version 1.0.37

- Registra inicio, fin y reinicios de acciones de fabricacion que procesan carne para grasa/sebo, junto con la receta y si admite trabajo desde el piso, para diagnosticar la cancelacion de traslados observada en Jill.

## Version 1.0.36

- Los resultados de fabricar y fabricar por lotes van primero a la mochila seleccionada; si no caben, pasan al inventario principal y solo caen al piso si tampoco caben ahi. Se conservan la devolucion de recipientes y materiales, y el Halo indica los destinos.

## Version 1.0.35

- Al reanudar Secar, solo lee el avance si ya existe la accion interna; las acciones aun en cola se conservan sin provocar `getJobDelta` nulo.

## Version 1.0.34

- Si el trapo se agota o Secarse deja de ser valido, no vuelve a reencolar la accion en bucle; la accion termina sin dejar la barra naranja congelada.

## Version 1.0.33

- Secarse ya no intenta reanudarse en bucle mientras Jill sigue caminando o corriendo; espera a que se detenga y restaura el avance de la barra al reanudar. Escape sigue cancelando la accion.

## Version 1.0.32

- Secarse conserva la accion pendiente si otra tarea interrumpe la cola y la reanuda al terminar. Caminar, correr y apuntar no interrumpen el secado; la humedad ya reducida y los usos de la toalla se conservan.

## Version 1.0.31

- Evita que una entidad sin sprite interrumpa la construccion del menu contextual; la opcion de interfaz de entidad se omite y el resto del menu puede continuar.

## Version 1.0.30

- Desmontar objetos del inventario y rasgar ropa ahora conserva las acciones pendientes al caminar o combatir y las reanuda al terminar la interrupcion. El mobiliario del mundo conserva su flujo vanilla.


## Version 1.0.29

- En los 50 puntos de creacion vanilla de modales Si/No, E confirma y Escape cancela; cada tecla aparece arriba del boton correspondiente, incluidos los avisos para dormir en cama o vehiculo. Los botones conservan sus titulos Si y No.

## Version 1.0.28

- En los modales Si/No de eliminacion y veneno, E confirma y Escape cancela; los botones muestran sus teclas asignadas.

## Version 1.0.27

- Los resultados de fabricacion, fabricacion por lotes y desmantelado de objetos se sueltan directamente en el piso. Se quito la seleccion automatica de contenedor y el Halo confirma el destino; reparaciones y recipientes devueltos conservan su ruta anterior.


> **Resumen:** ajustes locales de inventario, recetas, transferencias, limpieza y desmantelado para Build 42. Las integraciones con otros mods son opcionales y solo se aplican cuando sus APIs están disponibles.

## 🧭 Contenido

- [Cambios recientes](#version-1029)
- [Funciones incluidas](#funciones-incluidas)
- [Dependencias opcionales](#dependencias-opcionales)
- [Validación pendiente](#validación-pendiente)
- [Historial](#cambios-de-101)


## Cambios de 1.0.25

- Las confirmaciones de comer veneno conocido y eliminar objetos muestran **Si [E]** y **No [Esc]** en los botones. E confirma y Escape cancela; ambos atajos ejecutan los mismos callbacks que los botones.

## Cambios de 1.0.26

- Las teclas E y Escape para los modales Si/No ahora se capturan con el evento global de teclado mientras el modal esta visible. Esto permite confirmar o cancelar aunque el modal no reciba `onKeyPress` desde el foco de la interfaz.

## Cambios de 1.0.24

- Al comer un alimento que Jill ya identifico como venenoso, aparece la confirmacion Si/No. Cancelar descarta la accion; aceptar la vuelve a encolar.

## Cambios de 1.0.23

- Conserva el orden nativo de las opciones de inventario; solo reubica las opciones locales marcadas.
- Coloca **Acoplar** inmediatamente despues de Equipar secundaria y agrupa la limpieza de alimentos despues de Comer, con **Eliminar objeto** al final.
- Agrega la eliminacion confirmada de comida quemada despues de la comida podrida, rancia y fresca.
- Usa un icono de gota para verter al suelo, la textura de la toalla para **Secarse** y un icono de nausea para quitar ingredientes venenosos.

## Cambios de 1.0.22

- Coloca las opciones Hacer cataplasma de consuelda justo despues de Equipar para que queden visibles en el menu contextual.

## Cambios de 1.0.21

- Asigna el icono vanilla de Salud a la opcion contextual **Secarse** cuando no trae uno, sin cambiar la accion ni su posicion en el menu.

## Cambios de 1.0.20

- Incluye los contenedores de los objetos seleccionados al revisar recetas del menú contextual y al ejecutar Dismantle All at Once. Ahora puede desmantelar relojes desde un cadáver sin moverlos primero a la mochila; los resultados vuelven al contenedor del objeto seleccionado.

## Versión 1.0.19

### Cambios de 1.0.19

- Permite eliminar objetos y purgar comida seleccionada directamente desde el panel Suelo. La limpieza de piso incluye comida podrida, rancia y fresca; opera solo sobre los objetos seleccionados y los retira del mundo y de su contenedor.
## Versión 1.0.17

### Cambios de 1.0.17

- Anade al menu del piso la eliminacion confirmada de objetos seleccionados y opciones para purgar comida podrida, rancia o fresca. Solo procesa los objetos seleccionados en el piso.


## Cambios de 1.0.16

- Al terminar de consumir completamente comida en tazón u olla, busca el recipiente vacío creado por `ReplaceOnUse` y lo devuelve a la mochila donde estaba la comida. Si esa mochila ya no sigue dentro del inventario del personaje, el recipiente se queda en el inventario principal.


- Â«Cortar cabezaÂ» y Â«Acoplar a cinturónÂ» quedan inmediatamente después de las
  opciones para equipar en mano. Se reconocen sus etiquetas en español e inglés.

## Cambios de 1.0.14

- Permite que la transferencia de fluidos valide recipientes dentro de mochilas
  anidadas o contenedores abiertos accesibles. No mueve los recipientes.
- Presenta cada aviso de purga de comida como Halo centrado con el icono vanilla
  del alimento eliminado. Conserva el texto, el orden secuencial y la lógica de
  eliminación; si Viewpoint no está cargado, mantiene el aviso vanilla.

Este paquete reune los parches locales de fabricacion, combinacion de objetos,
lavado, limpieza de alimentos, retorno de recipientes, saqueo y desmantelado.
Mantiene cada comportamiento en un script separado para que sus cambios se
puedan revisar y ajustar de forma independiente.

## Cambios de 1.0.12

- Reordena los menús de inventario en una secuencia funcional: equipar, armas,
  abrir/inspeccionar, consumir/usar, fabricar, procesar, transferir, dividir,
  colocar, soltar/eliminar y opciones secundarias. Â«Más accionesÂ» queda al final.
- Normaliza acentos al clasificar etiquetas y traduce el rótulo técnico de Xanny
  como Â«Diagnósticos de armasÂ».

## Cambios de 1.0.11

- Ordena las opciones de los menús de inventario por tipo de acción: equipar,
  usar/consumir, recetas, procesar, transferir/guardar, dividir, colocar,
  soltar/eliminar y opciones adicionales. Mantiene el orden original dentro de
  cada grupo.
- Reubica las acciones añadidas por los parches junto a sus acciones afines y
  después de Equipar cuando hay opciones de equipo.
- Añade iconos vanilla B42 para recetas/ensaladas, verter al suelo, dividir
  objetos y Tetris. Limpia el prefijo técnico `xxanyarms:` en las opciones de
  diagnóstico del mod.

## Funciones incluidas

- Al recoger una llave desde un contenedor externo, la enruta al primer llavero con espacio que encuentre dentro del destino elegido o de las mochilas llevadas. Las llaves que ya se transfieren entre contenedores del personaje conservan el movimiento manual vanilla. Si no hay llavero compatible o con espacio, la llave se queda en el destino elegido.

- Amplia las recetas vanilla a contenedores accesibles, incluidas mochilas
  anidadas. Las recetas de hilo, cordel y cuerda se pueden encolar desde esos
  contenedores y sus resultados siguen el destino seleccionado; si no caben,
  regresan al contenedor de los ingredientes o caen al suelo. Muestra un Halo
  Note con el destino.
- Extiende la consolidacion de objetos drenables a mochilas y contenedores
  accesibles. Tambien permite consolidar baterias y encendedores drenables que
  vanilla marca como no consolidables cuando otro objeto del mismo tipo tiene
  usos disponibles. Usa el mismo punto de insercion del menu que vanilla,
  despues de Equipar, y mantiene la accion vanilla para consumir y transferir usos.
- Agrega combinacion de grasas de Long Term Preservation Extended y la opcion
  para reducir todas las grasas disponibles. Tambien agrega recetas para el
  conejo entero de rebusqueda y `Base.PorkChop`, con salida a grasa animal o
  manteca. Estas funciones solo se instalan cuando
  `LongTermPreservationExtended` esta activo.
- Lava vendas, tiras y trapos sucios de mochilas y contenedores accesibles,
  usando agua ambiental, agua de lluvia y las recetas vanilla correspondientes.
- Agrega confirmacion antes de borrar objetos seleccionados y permite eliminar
  alimentos sueltos podridos, rancios o frescos del contenedor actual. La purga
  masiva queda limitada al tipo seleccionado, se coloca junto a Comer y emite
  avisos secuenciales por tipo eliminado. Excluye comida dentro de recipientes
  preparados y reutiliza iconos vanilla.
- Conserva los resultados del crafteo, reparacion, desmantelado y consumo en el
  destino apropiado: primero el contenedor seleccionado, despues otras mochilas
  llevadas y el contenedor de origen; el inventario principal queda antes del
  suelo, que solo se usa cuando no cabe en ningun destino compatible. Devuelve
  los recipientes comestibles vaciados al contenedor de origen despues de comer,
  incluso desde mochilas anidadas.
- Ajusta el orden de opciones y el retorno de componentes del mod opcional
  `DismantleAllAtOnce`; la funcion se omite cuando ese mod no esta activo.
- Recupera la opcion vanilla `DismantleElectronics` para un reloj digital en una
  mochila secundaria solo cuando `CraftRecipeManager` confirma que la receta
  esta disponible. Si el juego no ofrece la receta, no crea una accion nueva;
  deja una linea de diagnostico por tipo de reloj.
- Conserva el equipo y la colocacion de objetos al desmontar y colocar elementos
  movibles. La compatibilidad especifica con Viewpoint se aplica solo cuando su
  API esta cargada.
- Incluye trazas de diagnostico de transferencias desde cadaveres. La traza
  registra ruta, origen, destino y datos de capacidad; no cambia el destino de
  transferencia.

## Dependencias opcionales

El paquete no declara dependencias obligatorias de mods de Workshop. Si estan
activos, puede ordenar su carga despues de `LongTermPreservationExtended`,
`DismantleAllAtOnce`, `Viewpoint`, `ProjectViewpointQOL`, `ViewpointUI` e
`INVENTORY_TETRIS`. Las funciones propias de Long Term Preservation Extended y
Dismantle All at Once verifican el mod activo antes de instalar sus hooks. Si
faltan, se omiten sin impedir la carga de las funciones vanilla. La presencia de
los demas mods solo amplifica las rutas de compatibilidad que usan sus APIs.

`ConsolidatedAllFixB42` y `ChilaSeda_Fix_Water_Pipes_ModData_B42_3546314080`
son referencias de orden opcional, no requisitos.

## Cambios de 1.0.2

- Evita depender de las funciones globales `next` y `pairs` al construir la lista
  de tipos de comida seleccionados para la purga.
- Encola la reducción de grasas de LTP con `HandcraftLogic` e
  `ISEntityUI.HandcraftStartMultiple`, compatibles con `CraftRecipe` de B42.

## Cambios de 1.0.3

- Añade iconos de objetos vanilla B42 a las opciones propias de borrar objetos,
  combinar/reducir grasas, encolar recetas, consolidar drenables y llenar
  recipientes; lavado y purga conservan sus iconos vanilla.
- Coloca Â«Eliminar objetosÂ» después de equipar o recetas, con icono de bolsa de
  basura vanilla.

## Cambios de 1.0.4

- Oculta las opciones individuales y por lote de reducción de grasa de LTP cuando
  la carne seleccionada está podrida; conserva las demás recetas del menú.

## Cambios de 1.0.5

- Añade trazas limitadas al encolar y ejecutar combinaciones de grasa y cuando
  una transferencia se rechaza, para identificar fallos con grasas en mochilas.

## Cambios de 1.0.6

- Enruta resultados de recetas por lote, crafteo, reparacion, consumo y
  desmantelado hacia el contenedor seleccionado y otras mochilas compatibles
  antes de usar el suelo. Los resultados por lote permanecen en el inventario
  hasta decidir su destino final, evitando dejarlos en el suelo antes de revisar
  las demas mochilas.

## Cambios de 1.0.1

- Actualiza la consulta de resultados de recetas de hilo a la API `CraftRecipe`
  de B42 y mantiene seguro el menu contextual ante resultados no disponibles.
- Usa `HandcraftLogic` al comprobar la receta masiva de grasas de LTP y oculta
  la opcion si la API no permite comprobarla sin errores.
- Corrige el alcance, el orden, las protecciones de recipientes y los avisos de
  la limpieza masiva de alimentos.
- Permite que la devolucion de recipientes tambien procese alimentos que son
  `InventoryContainer` y los retorna a su bolsa de origen, incluso anidada.

## Validación pendiente

Probar en Jill la consolidacion de baterias y encendedores azules desde mochila,
las recetas desde mochila secundaria, los destinos cuando una mochila esta
llena, la limpieza por estado de comida, el lavado con agua disponible y lluvia,
el retorno de recipientes y las funciones de desmantelado. Revisar Lua logs;
este paquete aun no se considera validado dentro del juego.

## Cambios de 1.0.8

- Normaliza la selección del menú con `ISInventoryPane.getActualItems`, usado por
  Vanilla para desenvolver las pilas del menú de Inventory Tetris. La combinación
  de grasas puede aparecer al abrir el menú sobre un contenedor secundario.

## Cambios de 1.0.9

- Agrupa las opciones propias relacionadas con comida inmediatamente después de
  Â«ComerÂ», antes de las opciones de equipar, conservando el orden de inserción.
- Da a Â«Eliminar objetosÂ» un icono directo de basura de la interfaz vanilla B42,
  con respaldo en la textura del objeto bolsa de basura.

## Cambios de 1.0.10

- El submenú Â«Encolar fabricaciones posiblesÂ» ahora incluye únicamente recetas cuyo
  resultado de hilo/cordel/cuerda se pudo resolver. Antes, cualquier receta compatible
  con el ingrediente podía crear un submenú padre y luego omitirse al construir sus filas,
  dejando la opción con flecha vacía.



### 🔗 Otros enlaces de interés

- [Acciones Accesibles 1.0.18](Cambios_1.0.18.md)
- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
