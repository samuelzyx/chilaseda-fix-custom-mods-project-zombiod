# ChilaSeda - Animal Balance and Handling (B42)

<div align="center">

[🏠 Repo](../README.md) · [🤝 Contribuir](../CONTRIBUTING.md) · [🚀 Releases](../docs/releases/README.md)

</div>

---


Paquete local para rendimiento, productos y manipulacion de animales. ID:
`ChilaSeda_AnimalBalance_B42`. Reune Animal Yield, Heavy Animal Pickup y las reparaciones
locales de Undead Wildlife. Version 2.3.8. No modifica archivos de Workshop.

La opción de carnicería desde contenedor usa el icono vanilla B42 de cuchilla y
queda tras las opciones nativas de equipar/recetas.

## Defensa de fauna

Todas las especies registradas activan `attackBack` para responder cuando reciben daño. Se conservan distancia y daño vanilla cuando existen; en las demás se asigna una represalia de alcance y daño bajos según el peso máximo de la especie. No se activa `attackIfStressed`, así que este ajuste no ordena a los animales iniciar ataques por estrés.

Con [Undead Wildlife [B42 Stable]](https://steamcommunity.com/sharedfiles/filedetails/?id=3781571720), de N3WO, las especies hostiles registradas se agregan a `LivingToUndead` con su propio tipo. Esto permite que el sistema existente de predación zombi las considere objetivos y conserve su flujo de infección y reanimación. Los originales de Workshop permanecen intactos.

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
  piso junto al personaje. No usa el inventario principal como destino alternativo. Con Viewpoint
  activo, cada producto muestra en Halo su nombre y destino; DebugLog registra rendimiento, tope y
  destino.
- La seleccion se compara con el inventario raiz del personaje, no con `page.inventory`: Build 42
  actualiza `page.inventory` al mismo contenedor seleccionado. Esto mantiene la prioridad de la
  mochila elegida en despiezado y extraccion de huesos antes del fallback al piso.

## Manipulacion de animales pesados

Bloquea recoger animales vivos y cadaveres animales que superen 50 kg. Protege tanto la opcion
del menu como la validacion y finalizacion de las acciones temporizadas; el aviso Halo informa
masa medida y limite. No altera la carniceria ni reconstruye objetos ya perdidos.

## Interaccion zombies vs animales (Undead Wildlife opcional)

En `Opciones > Mods > Interaccion zombies vs animales` se ajustan el maximo de zombis por presa (1-20, predeterminado 2), los segundos sin acercarse antes de soltarla (5-300, predeterminado 20) y el tiempo para ignorar una presa inaccesible (0-600 segundos, predeterminado 60). Aplica a animales normales y a especies agregadas por Undead Wildlife. Los valores se guardan en las opciones locales de Build 42. La presa vuelve a ser elegible antes si se mueve dos casillas o cambia de nivel.

`UndeadWildlife` aparece solo en `loadModAfter`, nunca en `require`. Si no esta instalado, los
scripts especificos salen sin modificar el juego y siguen disponibles el balance general y el
limite de carga. Si esta instalado, el paquete:

- Detecta los tipos hostiles/esqueleticos para ajustar rendimientos y huesos.
- Clasifica correctamente los cuerpos infectados durante la carniceria vanilla en el suelo,
  usando temporalmente la definicion de avatar equivalente y restaurandola despues.
- Permite despiezar un cuerpo desde un contenedor accesible del personaje, con cuchillo accesible,
  sin moverlo manualmente al inventario principal.
- Interrumpe los ataques anunciados por Undead Wildlife siempre que el personaje este dentro de
  cualquier vehiculo. La proteccion ya no depende de que Lua pueda leer el estado de puertas o
  ventanas; DebugLog registra el intento de interrupcion y si aun llega un resultado de ataque.
- Reduce a la mitad los intervalos de vocalizaciones ambientales (idle, caminando/volando y
  estres) de los tipos hostiles registrados por Undead Wildlife. Conserva los mismos sonidos y no
  modifica volumen ni alcance de sonido.
- Muestra Halo notes de ataque, herida y victoria.

La proteccion usa el evento temprano `AnimalAttackStart` y el comando `AnimalAttackInterrupt` que
Undead Wildlife procesa antes del impacto. El resultado final debe confirmarse en partida.

### Presas inaccesibles y acumulacion de zombis

Undead Wildlife Workshop `3781571720` version `1.1.0` escanea animales elegibles y asigna la
presa mas cercana a cada zombi. Su script cliente renueva el objetivo incluso cuando el zombi se
mueve por la orilla sin acercarse a la presa; tampoco limita cuantos zombis pueden elegir el mismo
animal. Este paquete incluye un override local de `UndeadWildlife_PredationVisuals.lua`, cargado
despues del Workshop. El archivo original permanece intacto.

- Limita a dos los zombis que persiguen simultaneamente al mismo animal.
- Considera avance una reduccion de al menos `0.35` tiles en la distancia a la presa. Si no ocurre
  en `20` segundos, libera a todos los cazadores de esa presa y la excluye temporalmente durante
  `60` segundos.
- Si el animal se desplaza al menos `2` tiles o cambia de nivel, la caceria vuelve a estar
  disponible antes de que termine la pausa.
- Las trazas quedan bajo la opcion `PredationDebug`: `route-stalled`, `prey-temporarily-ignored`,
  `prey-unblocked` y el resumen `scan` informa el limite de cazadores y presas pausadas.

La prueba de contrato compara el override con la version instalada del Workshop. Si el original
cambia, revisar el flujo upstream antes de actualizar este archivo local.

## Dependencias y validacion

Requiere `ChilaSeda_Fix_True_Weight_VanillaWeights_B42_3768669395` y `ChilaSeda_AuditSuite_B42`.
`AnimalRemasterApproved` es opcional: el paquete no llama codigo de ese mod; su entrada en
`loadModAfter` solo conserva el orden si esta instalado, no lo activa ni lo exige. Undead Wildlife
tambien es opcional y sus integraciones se cargan despues solo cuando esta activo.

La revision estatica enlaza las rutas vanilla de carniceria de suelo, extraccion de huesos,
despiece en gancho y recogida pesada. Falta validar en Jill el tope acumulado, destino, avisos Halo,
bloqueo sobre 50 kg, acceso a cuerpos desde contenedores y proteccion/avisos de Undead Wildlife.


---

### 🔗 Otros enlaces de interés

- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
