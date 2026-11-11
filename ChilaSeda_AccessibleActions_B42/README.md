# ChilaSeda - Acciones Accesibles (Build 42) 1.0.20

## Cambios de 1.0.20

- Incluye los contenedores de los objetos seleccionados al revisar recetas del men� contextual y al ejecutar Dismantle All at Once. Ahora puede desmantelar relojes desde un cad�ver sin moverlos primero a la mochila; los resultados vuelven al contenedor del objeto seleccionado.

# ChilaSeda - Acciones Accesibles (Build 42) 1.0.19

## Cambios de 1.0.19

- Permite eliminar objetos y purgar comida seleccionada directamente desde el panel Suelo. La limpieza de piso incluye comida podrida, rancia y fresca; opera solo sobre los objetos seleccionados y los retira del mundo y de su contenedor.
# ChilaSeda - Acciones Accesibles (Build 42) 1.0.17

## Cambios de 1.0.17

- Anade al menu del piso la eliminacion confirmada de objetos seleccionados y opciones para purgar comida podrida, rancia o fresca. Solo procesa los objetos seleccionados en el piso.


## Cambios de 1.0.16

- Al terminar de consumir completamente comida en taz�n u olla, busca el recipiente vac�o creado por `ReplaceOnUse` y lo devuelve a la mochila donde estaba la comida. Si esa mochila ya no sigue dentro del inventario del personaje, el recipiente se queda en el inventario principal.


- «Cortar cabeza» y «Acoplar a cinturón» quedan inmediatamente después de las
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
  colocar, soltar/eliminar y opciones secundarias. «Más acciones» queda al final.
- Normaliza acentos al clasificar etiquetas y traduce el rótulo técnico de Xanny
  como «Diagnósticos de armas».

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
  para reducir todas las grasas disponibles. Estas dos funciones solo se
  instalan cuando `LongTermPreservationExtended` esta activo.
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
- Coloca «Eliminar objetos» después de equipar o recetas, con icono de bolsa de
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

## Validacion pendiente

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
  «Comer», antes de las opciones de equipar, conservando el orden de inserción.
- Da a «Eliminar objetos» un icono directo de basura de la interfaz vanilla B42,
  con respaldo en la textura del objeto bolsa de basura.

## Cambios de 1.0.10

- El submenú «Encolar fabricaciones posibles» ahora incluye únicamente recetas cuyo
  resultado de hilo/cordel/cuerda se pudo resolver. Antes, cualquier receta compatible
  con el ingrediente podía crear un submenú padre y luego omitirse al construir sus filas,
  dejando la opción con flecha vacía.


---

### 🔗 Otros enlaces de interés

- [Acciones Accesibles 1.0.18](Cambios_1.0.18.md)
- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
