# ChilaSeda - Animal Balance and Handling (B42)

Paquete local para rendimiento, productos y manipulacion de animales. ID:
`ChilaSeda_AnimalBalance_B42`. Reune Animal Yield, Heavy Animal Pickup y las reparaciones
locales de Undead Wildlife. Version 2.3.0. No modifica archivos de Workshop.

La opción de carnicería desde contenedor usa el icono vanilla B42 de cuchilla y
queda tras las opciones nativas de equipar/recetas.

## Defensa de fauna

Todas las especies registradas activan `attackBack` para responder cuando reciben daño. Se conservan distancia y daño vanilla cuando existen; en las demás se asigna una represalia de alcance y daño bajos según el peso máximo de la especie. No se activa `attackIfStressed`, así que este ajuste no ordena a los animales iniciar ataques por estrés.

Con Undead Wildlife, las especies hostiles registradas se agregan a `LivingToUndead` con su propio tipo. Esto permite que el sistema existente de predación zombi las considere objetivos y conserve su flujo de infección y reanimación. Los originales de Workshop permanecen intactos.

## Rendimientos y destino de productos

- Limita la cantidad total de huesos por carcasa segun la masa media de la especie y el nivel
  de Carniceria. El objetivo se conserva entre acciones de despiezado y extraccion de huesos;
  craneo, huesos grandes/pequenos y fragmentos comparten el mismo presupuesto, con maximo 24.
- Ajusta la cantidad de carne por masa y habilidad y aplica multiplicadores de especies hostiles
  de Undead Wildlife solo si el mod registra sus tipos. El limite contabiliza unidades de pila,
  incluso cuando el inventario fusiona carne nueva con una pila que ya existia.
- Identifica productos oseos por su tipo (`Bone`, `Fragment` o `Skull`), no mediante una lista
  cerrada de especies.
- Al terminar, guarda los productos en el contenedor seleccionado del inventario del personaje
  si los admite y caben. Sin seleccion, sin espacio o ante un fallo de traslado, los deja en el
  piso junto al personaje. No usa el inventario principal como destino alternativo. Un Halo note
  indica mochila seleccionada/piso; DebugLog registra rendimiento, tope y destino.

## Manipulacion de animales pesados

Bloquea recoger animales vivos y cadaveres animales que superen 50 kg. Protege tanto la opcion
del menu como la validacion y finalizacion de las acciones temporizadas; el aviso Halo informa
masa medida y limite. No altera la carniceria ni reconstruye objetos ya perdidos.

## Undead Wildlife opcional

`UndeadWildlife` aparece solo en `loadModAfter`, nunca en `require`. Si no esta instalado, los
scripts especificos salen sin modificar el juego y siguen disponibles el balance general y el
limite de carga. Si esta instalado, el paquete:

- Detecta los tipos hostiles/esqueleticos para ajustar rendimientos y huesos.
- Clasifica correctamente los cuerpos infectados durante la carniceria vanilla en el suelo,
  usando temporalmente la definicion de avatar equivalente y restaurandola despues.
- Permite despiezar un cuerpo desde un contenedor accesible del personaje, con cuchillo accesible,
  sin moverlo manualmente al inventario principal.
- Interrumpe el ataque anunciado por Undead Wildlife si el personaje esta dentro de un vehiculo
  con puertas cerradas y ventanas cerradas e intactas verificables por Lua. Si falta informacion,
  permite el ataque.
- Muestra Halo notes de ataque, herida y victoria.

La proteccion del vehiculo depende del evento temprano `AnimalAttackStart` y de que el mod acepte
`AnimalAttackInterrupt`; su eficacia contra el impacto real debe confirmarse en partida.

## Dependencias y validacion

Requiere `AnimalRemasterApproved`, `ChilaSeda_Fix_True_Weight_VanillaWeights_B42_3768669395` y
`ChilaSeda_AuditSuite_B42`. Carga despues de esos mods y de Undead Wildlife si esta activo.

La revision estatica enlaza las rutas vanilla de carniceria de suelo, extraccion de huesos,
despiece en gancho y recogida pesada. Falta validar en Jill el tope acumulado, destino, avisos Halo,
bloqueo sobre 50 kg, acceso a cuerpos desde contenedores y proteccion/avisos de Undead Wildlife.
