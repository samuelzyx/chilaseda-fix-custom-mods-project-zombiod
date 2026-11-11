# Kit Zombicidio Jill — Project Zomboid Build 42

Carpeta para montar una partida nueva parecida al perfil de Jill. Revisa primero `Descripcion_Coleccion_Zombicidio.txt`; los mods de terceros se descargan desde Workshop y no se redistribuyen en este kit.

## Archivos

- [`Kit_Zombicidio_Jill_B42.rar`](Kit_Zombicidio_Jill_B42.rar): paquete de mods locales ChilaSeda y recursos; incluye `Sandbox Presets/Zombicidio.cfg`.
- [`Sandbox Presets/Zombicidio.cfg`](Sandbox%20Presets/Zombicidio.cfg): preset de sandbox listo para copiar.
- [`mods.txt`](mods.txt): orden de mods del perfil Jill de referencia.
- [`map_ver.bin`](map_ver.bin): archivo de referencia para colocar junto a `mods.txt`.
- [`Descripcion_Coleccion_Zombicidio.txt`](Descripcion_Coleccion_Zombicidio.txt): pasos para instalar la colección, ZombieBuddy, el preset y recrear a Jill.

## Montaje

1. Suscríbete a los mods de terceros de la [colección Zombicidio](https://steamcommunity.com/sharedfiles/filedetails/?id=3812814868) y deja que Workshop termine las descargas.
2. Extrae el RAR y copia sus carpetas `mods` dentro de `%USERPROFILE%\Zomboid\`. Copia `Sandbox Presets/Zombicidio.cfg` a `%USERPROFILE%\Zomboid\Sandbox Presets\`.
3. Crea una partida nueva en Sandbox, selecciona el preset `Zombicidio` y activa los mods requeridos. Para la apariencia de Jill, instala `[COS] RE:3 Remake Jill` desde Workshop y selecciona el conjunto `RE3_Jill`.
4. Para acercarte al perfil de referencia, usa la ocupación Pescador y los rasgos listados en la descripción: Insensible, Manitas, Poca sed, Insomne, Propenso a enfermar, Sanador lento, Robusto, Bajo peso y Metabolismo lento.
5. Guarda la partida y cierra el juego. Conserva una copia de los archivos creados. Reemplaza `mods.txt` y `map_ver.bin` dentro de `%USERPROFILE%\Zomboid\Saves\Sandbox\<nombre_de_tu_partida>\` con los dos archivos de esta carpeta.
6. Inicia de nuevo y revisa que la partida cargue con las versiones actuales de los mods.

El perfil Jill es una referencia para reconstruir una partida similar; la compatibilidad puede cambiar cuando los mods o Project Zomboid se actualizan.
