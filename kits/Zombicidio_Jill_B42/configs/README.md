# Configuración de referencia de Jill

Estos archivos son una captura de la configuración local de Jill para **Project Zomboid Vanilla
B42.22.2**. Conservan opciones de mods, teclas, ajustes de Viewpoint y posiciones de interfaz.
No incluyen archivos de guardado, registros ni opciones gráficas generales del equipo.

## Archivos

Las rutas de destino son bajo `%USERPROFILE%\Zomboid\` (en Windows suele ser
`C:\Users\<tu_usuario>\Zomboid\`). Por ejemplo, el archivo del kit
`configs/Lua/keysB42.ini` debe terminar en `C:\Users\<tu_usuario>\Zomboid\Lua\keysB42.ini`.

| Archivo dentro del kit | Ruta de destino completa | Contenido |
|---|---|---|
| `configs/Lua/ModOptions.ini` | `%USERPROFILE%\Zomboid\Lua\ModOptions.ini` | Opciones y teclas de mods guardadas por Mod Options. |
| `configs/Lua/keysB42.ini` | `%USERPROFILE%\Zomboid\Lua\keysB42.ini` | Asignaciones de teclas de Project Zomboid. |
| `configs/Lua/MiniCompass_Position_user_JillValentine.txt` | `%USERPROFILE%\Zomboid\Lua\MiniCompass_Position_user_JillValentine.txt` | Posición del MiniCompass para Jill. |
| `configs/Lua/ViewpointRebusquedaHills_manual_offsets.txt` | `%USERPROFILE%\Zomboid\Lua\ViewpointRebusquedaHills_manual_offsets.txt` | Posición de la ventana y ajustes manuales de pines de rebusca. |
| `configs/viewpoint-live.properties` | `%USERPROFILE%\Zomboid\viewpoint-live.properties` | Ajustes vivos de cámara, controles, render y mundo de Viewpoint. |
| `configs/grassiergrass.properties` | `%USERPROFILE%\Zomboid\grassiergrass.properties` | Preferencias guardadas de Grassier Grass; incluirlas no corrige el fallo de carga/render que tuvo Jill. |
| `Sandbox Presets/Zombicidio.cfg` | `%USERPROFILE%\Zomboid\Sandbox Presets\Zombicidio.cfg` | Preset Sandbox, ya incluido fuera de `configs/`. |

La estructura final en la computadora queda así:

```text
%USERPROFILE%\Zomboid\
├── Lua\
│   ├── ModOptions.ini
│   ├── keysB42.ini
│   ├── MiniCompass_Position_user_JillValentine.txt
│   └── ViewpointRebusquedaHills_manual_offsets.txt
├── Sandbox Presets\
│   └── Zombicidio.cfg
├── grassiergrass.properties
└── viewpoint-live.properties
```

## Instalar la configuración

1. Cierra Project Zomboid.
2. Haz una copia de los archivos existentes en los destinos de la tabla, porque al reemplazarlos
   también cambiarán tus preferencias y teclas personales.
3. Abre `configs/` del kit. Copia **su contenido** directamente a `%USERPROFILE%\Zomboid\`;
   combina la carpeta `Lua` con la que ya existe y conserva las rutas de la tabla. No copies la
   carpeta `configs` como subcarpeta, y no pongas estos archivos en `Zomboid\mods` ni en Workshop.
4. Copia `Sandbox Presets/Zombicidio.cfg` a `%USERPROFILE%\Zomboid\Sandbox Presets\` al crear
   el mundo.
5. Inicia el juego y comprueba la configuración antes de entrar a la partida.

`ModOptions.ini` reúne preferencias de los mods guardadas en el cliente. Los mods deben estar
instalados y activos para que sus opciones tengan efecto. La lista de mods del guardado (`mods.txt`)
y el estado de mapas (`map_ver.bin`) se aplican después de crear y guardar el mundo siguiendo el
README del kit.
