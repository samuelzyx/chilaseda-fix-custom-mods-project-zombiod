# Configuración de referencia de Jill

Estos archivos son una captura de la configuración local de Jill para **Project Zomboid Vanilla
B42.22.2**. Conservan opciones de mods, teclas, ajustes de Viewpoint y posiciones de interfaz.
No incluyen archivos de guardado, registros ni opciones gráficas generales del equipo.

## Archivos

| Archivo del kit | Destino dentro de `%USERPROFILE%\Zomboid\` | Contenido |
|---|---|---|
| `Lua/ModOptions.ini` | `Lua/ModOptions.ini` | Opciones y teclas de mods guardadas por Mod Options. |
| `Lua/keysB42.ini` | `Lua/keysB42.ini` | Asignaciones de teclas de Project Zomboid. |
| `Lua/MiniCompass_Position_user_JillValentine.txt` | `Lua/MiniCompass_Position_user_JillValentine.txt` | Posición del MiniCompass para Jill. |
| `Lua/ViewpointRebusquedaHills_manual_offsets.txt` | `Lua/ViewpointRebusquedaHills_manual_offsets.txt` | Posición de la ventana y ajustes manuales de pines de rebusca. |
| `viewpoint-live.properties` | `viewpoint-live.properties` | Ajustes vivos de cámara, controles, render y mundo de Viewpoint. |
| `grassiergrass.properties` | `grassiergrass.properties` | Preferencias guardadas de Grassier Grass; incluirlas no corrige el fallo de carga/render que tuvo Jill. |
| `../Sandbox Presets/Zombicidio.cfg` | `Sandbox Presets/Zombicidio.cfg` | Preset Sandbox, ya incluido fuera de esta carpeta. |

## Instalar la configuración

1. Cierra Project Zomboid.
2. Haz una copia de los archivos existentes en los destinos de la tabla, porque al reemplazarlos
   también cambiarán tus preferencias y teclas personales.
3. Copia el contenido de `configs/` a `%USERPROFILE%\Zomboid\`, conservando las carpetas y
   permitiendo reemplazar los archivos indicados.
4. Copia `Sandbox Presets/Zombicidio.cfg` a `%USERPROFILE%\Zomboid\Sandbox Presets\` al crear
   el mundo.
5. Inicia el juego y comprueba la configuración antes de entrar a la partida.

`ModOptions.ini` reúne preferencias de los mods guardadas en el cliente. Los mods deben estar
instalados y activos para que sus opciones tengan efecto. La lista de mods del guardado (`mods.txt`)
y el estado de mapas (`map_ver.bin`) se aplican después de crear y guardar el mundo siguiendo el
README del kit.
