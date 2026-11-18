# Viewpoint: equilibrio de calidad y FPS en Jill

## Estado actual

Chila reporta **56 FPS estables, con picos ocasionales de 60**, y decidio mantener este perfil por ahora. El archivo vivo se leyo antes de cerrar PZ; despues solo se agrego la activacion del pack 6282, sin cambiar ajustes graficos.

- Shaderpack: `default`; el archivo guarda `graphics.preset=Custom` y `packPreset.default=Custom`.
- DLSS: `renderScale=59`; Reflections: `high` (Ultra en el menu).
- Far world shadows Off; Depth of field Off; Volumetric light Off.
- Godrays On y Sun shafts On. Chila prefiere dejarlos On; la prueba de Godrays Off coincidio con avanzar y caer a 34 FPS, asi que no fue una A/B aislada.
- Clouds in reflections Off; Moving waves On; Puddles On; Rain density 100.
- Sombras: resolucion 2048, 3 cascades y 4 samples.
- Oclusion: On, calidad High, metodo `groundTruth`, radio 1 y fuerza 1.
- Pack `PZVoxelStudioViewpoint` activado en `viewpoint-live.properties`; su prueba en mundo queda para la siguiente carga.

El respaldo **Config 59 FPS** es una referencia de ajustes guardada antes de la tanda Ultra, no una promesa de que las mismas opciones produzcan 59 FPS en cualquier zona, clima o movimiento. La referencia esta en `backups/20261117_230624/Config_59FPS/viewpoint-live.properties`.

## Diferencias frente a Config 59 FPS

| Ajuste | Actual | Config 59 | Prueba sugerida | Efecto visual probable |
|---|---:|---:|---|---|
| Oclusion | On / High | On / Medium | **Primero: High -> Medium** | Menos sombreado fino en rincones y contactos; conserva el efecto de profundidad. |
| Shadow cascades | 3 | 2 | Despues, si hace falta: 3 -> 2 | Menos detalle de sombras a distancia y posible cambio visible en transiciones. |
| Shadow samples | 4 | 4 | Ya coincide; no tocar por ahora | Los bordes ya estan en el valor de referencia. |
| Cloud steps / resolution | 60 / 75 | 30 / 50 | Probar solo Cloud steps: 60 -> 40 | Menos detalle fino en las nubes; no cambiar ambos a la vez. |
| Moving waves (`fftWaves`) | On | Off | Dejar para despues | Reduce el movimiento de las olas; no equivale al splash de lluvia en charcos. |
| Lamp shadows / resolution | 6 / 512 | 2 / 256 | Probar de noche: 6 -> 4 | Menos luces proyectan sombras o menor detalle cerca de faroles/vehiculos. |
| Headlight shadows | 2 | 1 | Probar de noche, por separado | Menos detalle de sombras de faros. |
| Snow | High | Medium | Solo probar durante nieve | Menos detalle de nieve. |
| Water reach | `all` | `shells` | No tocar hasta revisar el efecto en pantalla | Cambia el alcance del efecto de agua; no hay A/B reciente. |
| Volumetric light | Off | On | Mantener Off | Ya esta reducido frente a Config 59; volverlo a On tuvo un costo de FPS en pruebas anteriores. `volumetricSteps=32` no es prioridad mientras el toggle siga Off. |

Coinciden con Config 59: DLSS 59, Reflections `high`, Far world shadows Off, DoF Off, Godrays On, Sun shafts On, Clouds in reflections Off, lluvia 100 y shadow resolution 2048. No hace falta tocarlos para buscar la referencia.

## Orden recomendado para la proxima sesion

1. Mantener la configuracion actual como punto de partida. Anotar zona, clima y si Jill camina o rebusca.
2. Cambiar solo **Occlusion quality: High -> Medium** en el menu. Mantener `occlusion` On, metodo `groundTruth`, radio 1 y fuerza 1.
3. Caminar el mismo tramo con clima parecido. Anotar FPS minimo y maximo y revisar si la escena pierde sombreado de contacto.
4. Si el cambio se ve bien pero no sostiene 59, conservarlo y probar despues **Shadow cascades: 3 -> 2**, sin mover nada mas.
5. Parar y restaurar el ultimo valor si el minimo baja de 30 FPS o si la perdida visual no compensa. El objetivo es mejorar sobre los 56 estables sin desarmar este equilibrio.

## Rebusqueda nativa y diferencias con Viewpoint Foraging

Chila prefiere la rebusqueda nativa y dice que la de Viewpoint se siente rara. `ViewpointForaging` permanece fuera del save; no reactivarlo durante estas pruebas graficas. La recuperacion del pack 3D y del fix local de Sound Events es independiente de esta preferencia.

La auditoria de fuentes de Viewpoint 0.1.7 y del addon confirma estas diferencias:

| Funcion | Viewpoint nativo 0.1.7 | Fix local | Solo addon ViewpointForaging |
|---|---|---|---|
| Pines 3D de hallazgos de rebusca | Si | Calibracion de altura por zona, zoom global y proyeccion del pin nativo para apuntarlo con G | Escala de pin ligada a profundidad |
| Flechas de hallazgos | Si | Corrige la orientacion segun la camara | Tamano/borde configurables y asistencia de borde |
| Radio de busqueda | Si, la API nativa expone hallazgos y radio | El puente de niebla consulta el radio nativo | Modos de burbuja y ajustes de alcance propios |
| Niebla de busqueda | Viewpoint nativo expone la niebla de escena, pero no una burbuja circular configurable para shader packs | El fix local 2.0.80 porta la capa de profundidad circular del addon, con opcion propia; los controles nativos Dark/Mist, intensidad y suavizado siguen disponibles | Falta confirmar en Jill con shader pack que la burbuja siga el radio y se desvanezca al salir del modo de busqueda |
| Recoleccion con tecla apuntando al pin | Tiene API y acciones normales de cosecha/menu | G selecciona el pin nativo visible mas cercano al centro de pantalla, dentro de 110 px y 12 tiles, y llama su accion normal | Aro/objetivo visual, asistencia por alcance y pickup por pin proyectado |
| Marcadores 3D | Pines de hallazgos de rebusca | Ajustes de altura/zoom para esos pines | Marcadores de objetos del mundo, escondites y huellas; trazos/seguimiento |

Por tanto, el zoom del panel, la calibracion de altura y la niebla circular pueden funcionar con las API nativas de Viewpoint sin activar el addon. La recoleccion con tecla requiere validacion runtime. El addon tambien recorria categorias de iconos que no aparecen en la lista nativa de hallazgos, asi que no se debe asumir que el nativo da marcadores 3D para objetos, escondites o huellas.
