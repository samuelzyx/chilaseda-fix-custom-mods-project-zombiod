ChilaSeda Audit Suite B42 - Performance Black Box component


<div align="center">

[<- Audit Suite](../../README.md) · [Error Logs](../ErrorSessionLogs/README.md) · [Memoria](../ModMemory/README.md) · [Rendimiento](../Performance/README.md) · [Pesos](../WeightMonitor/README.md)

</div>

ESTADO HONESTO
The Java capture pipeline and mocked Lua checks ran outside Project Zomboid.
In-game ZombieBuddy exposure, restart behavior, and overhead still need Jill
runtime validation. Attached logs are from JVM harnesses, not a game session.

INSTALACION
1. Close Project Zomboid completely.
2. Keep the complete ChilaSeda_AuditSuite_B42 folder in the local mods folder.
3. Activate ChilaSeda_AuditSuite_B42. ZombieBuddy is optional; without its
   Java bridge, this component records no performance session.
4. Start the game and enter the save unpaused for runtime validation.
SELFTEST AUTOMÃTICO Y MANUAL
Se solicita automÃ¡ticamente UNA vez por proceso cuando Lua consigue ejecutar
Java. No debes editar ningÃºn archivo ni provocar un congelamiento. Se llena
el buffer durante ~8 segundos, se dispara un evento artificial, y se recogen
4 segundos posteriores. En condiciones estables termina en ~12 segundos;
con spikes repetidos puede tardar mÃ¡s (~30 segundos o mÃ¡s si existe otro evento
activo). Sigue jugando sin pausa hasta ver el resultado.

En consola Lua de debug tambiÃ©n puedes ejecutar:
  ChilaPerf.selftest()
Para ver estado, muestras, cola y resultado:
  ChilaPerf.status()
Desde una consola con clases expuestas tambiÃ©n existe ChilaPerfJ.selftest().
La autoprueba manual tiene lÃ­mite de una solicitud cada 60 segundos.

Ã‰XITO: console.txt y el archivo independiente deben contener:
  [ChilaPerf][SELFTEST] PASS
El PASS se imprime DESPUÃ‰S de escribir y sincronizar el evento completo,
leer exactamente sus bytes y comprobar igualdad, ventana previa >=7.8s,
posterior >=3.9s, tiempos crecientes y medidas reales de heap positivas.
No se imprimirÃ¡ PASS por el simple registro de la clase.
Los eventos artificiales llevan synthetic=true. No se induce un sleep en el juego.

RUTA EXACTA
En tu instalaciÃ³n habitual:
  <ZOMBOID_ROOT>\ChilaPerformance.log
Se obtiene de zombie.ZomboidFileSystem.instance.getCacheDir(), de modo que si
usas -cachedir serÃ¡ ese directorio, no uno inventado. JAVA_EXECUTING y
LUA_EXECUTING imprimen la ruta efectiva. El archivo se crea al persistir el
primer evento, no al cargar la clase. Se conserva por append al reiniciar.
RotaciÃ³n: 20 MiB por archivo; conserva .1, .2 y .3. Aproximadamente 80 MiB
mÃ¡ximos mÃ¡s un evento si este excede el umbral de rotaciÃ³n. No borra otros logs.

COMPROBACIÃ“N EN TU JUEGO (PENDIENTE, NECESARIA)
A. Sin transmitir, entra a la partida, espera el PASS y comprueba que el evento
   tenga player_xyz real, CONTEXT y SAMPLE, no solo mensajes de carga.
B. Camina/corre cerca de zombis en una situaciÃ³n segura de prueba. Comprueba
   MARK AI_STATE_CHANGE y estados/flags cuando el evento quede persistido.
C. Cierra completamente el juego y vuelve a entrar. Debe aparecer otro PASS
   con session distinto, conservÃ¡ndose los anteriores (o en .1 tras rotaciÃ³n).
D. Compara la misma ruta con/sin este mod. context_collect_ms mide el sondeo Lua;
   previous_probe_java_ns mide la llamada anterior a tick (no toda la JVM).
   Sin esta comparaciÃ³n no afirmamos que no cause stutters apreciables.
E. PÃ¡same ChilaPerformance.log y console.txt de esa prueba.

Si solo aparece LUA_LOADED, espera JAVA_UNAVAILABLE. Si JAVA_EXECUTING aparece
pero no hay LUA_EXECUTING, revisa ERROR. Si no hay PASS, NO considerar validado:
status explica PENDING/FAIL. Un cierre forzado puede perder el evento en RAM;
no se promete captura de crashes. Al cerrar normalmente hay un flush de hasta
3s, y un evento incompleto queda indicado, nunca pasa el SELFTEST por eso.

QUÃ‰ OBSERVA
- System.nanoTime: timestamp monotÃ³nico de cada muestra y de cada marca.
- Intervalo OnTick (simulaciÃ³n), mÃ¡ximo intervalo OnRenderTick observado entre
  ticks y contador de callbacks de render. NO son GPU/present frame time.
- Severidad por mayor intervalo observado: >33 LOW, >50 MEDIUM, >100 HIGH,
  >250 CRITICAL. Los lÃ­mites son estrictamente mayores. Cada evento lleva
  SPIKE-0001, etc., y un UUID de sesiÃ³n para distinguir reinicios.
- CPU consumida por el hilo que ejecuta OnTick entre muestras, si ThreadMXBean
  ya la ofrece. No fuerza habilitar mediciÃ³n. Incluye otros trabajos del hilo,
  no representa duraciÃ³n aislada del update ni tiempo wall-clock.
- Heap Java usado, libre dentro del heap comprometido y mÃ¡ximo. NO RAM total
  de Windows ni memoria nativa, texturas o VRAM.
- Contadores acumulados de GC y tiempo total GC consultados cada 250 ms, con
  antigÃ¼edad. Comparar deltas antes/durante/despuÃ©s. No es una traza exacta de
  cada pausa y los recolectores concurrentes pueden solaparse.
- PosiciÃ³n, Z lÃ³gico, velocidad observada entre sondeos en tiles/s, correr/sprint.
- Zombis cargados; prÃ³ximos en radio XY de 30 tiles. Sondeo cada 250 ms, mÃ¡ximo
  128 zombis por sondeo y 24 estados listados. Si hay mÃ¡s, escaneo rotatorio y
  count_complete=false: nearby_observed es PARCIAL, no un censo completo.
- getCurrentStateName, prone, crawling, onFloor y cambios entre observaciones.
- Evento real OnAIStateChange(owner,newState,oldState) para zombis a <=30 tiles:
  MARK incluye nombres de estado (attack/lunge/get-up/crawler segÃºn el motor),
  ID y flags. No etiqueta una mordida efectiva si el motor no la declara.
- LoadChunk: contador de callbacks recibidos, NO duraciÃ³n de cargar un chunk.
- Chunk XY donde estÃ¡ el jugador (floor X/10,Y/10), NO cola de carga.
- Tiempo del sondeo Lua, tiempo del recorder Java, cola y marcadores descartados.

NO DISPONIBLE / LÃMITES EXPLÃCITOS
UNAVAILABLE marca mÃ©tricas no observables sin instrumentaciÃ³n adicional:
- frame presentado/GPU time, duraciÃ³n del render thread;
- duraciÃ³n de IsoZombie.update y costes internos de ataque/mordida/crawler;
- carga interna de assets/modelos/texturas/animaciones y sus duraciones;
- tiempo de carga de chunks y duraciÃ³n de callbacks de otros mods/Lua/Java;
- tiempo exacto e hilo causal de cada GC.
Los nombres de estado observados no demuestran causalidad. OnAIStateChange se
emite despuÃ©s del cambio; no mide cuÃ¡nto tardÃ³ ese cambio. El sondeo puede perder
estados rÃ¡pidos; las marcas del evento ayudan a compensarlo. Datos de contexto
pueden tener ~250ms o mÃ¡s de antigÃ¼edad: su timestamp lo indica. Un valor 0 de un
contador observado es vÃ¡lido; ausencia de API se marca UNAVAILABLE, no 0.
Pausas, alt-tab, carga y lÃ­mite de FPS pueden generar gaps: no toda detecciÃ³n es
un bug. OnTick no corre pausado, y el gap al reanudar puede incluir la pausa.

BUFFER / OVERHEAD / THROTTLING
- Buffer temporal: Ãºltimos 8s, lÃ­mite 4096 muestras. Por encima de ~512 muestras/s
  el lÃ­mite reduce la ventana; pre_actual_ms lo muestra y SELFTEST no da PASS si
  no alcanza la ventana exigida. No se promete una ventana inexistente.
- 4s despuÃ©s del trigger; spikes repetidos extienden hasta mÃ¡ximo 20s despuÃ©s
  del primer trigger. LÃ­mite total 8192 muestras/evento; se indica reason.
- DespuÃ©s de un evento hay cooldown de 15s: spikes de ese intervalo no generan
  otro archivo. Es una pÃ©rdida deliberada documentada para limitar overhead.
- Contexto compartido en RAM y escrito solo al cambiar, sin repetir texto por tick.
- Formateo, escritura, sync y lectura de SELFTEST en un hilo de trabajo dedicado.
- Cola de escritura mÃ¡xima 4 eventos; si se llena se descarta e informa ERROR.
- MÃ¡ximo 64 marcas entre ticks; descartes cuentan explÃ­citamente. El callback de
  AI sigue recibiÃ©ndose para todas las transiciones: su coste real con hordas
  debe medirse en juego. No se engancha a cada IsoZombie.update.
- Console solo carga/error/resumen/PASS, no una lÃ­nea por muestra.
- No se modifican archivos del juego, Workshop, saves ni otros mods.

FUENTES Y PRUEBAS
source/: Java y Lua instalable bajo 42/media/lua/client.
tests/: harness Java, pruebas Lua con mocks y resultados de ejecuciÃ³n.
evidence/ChilaPerformance_SELFTEST.log: archivo REAL producido en dos procesos
JVM consecutivos. Los campos de juego se marcan UNAVAILABLE porque no habÃ­a PZ.
VALIDACION.txt: medidas concretas y lo que queda pendiente.

