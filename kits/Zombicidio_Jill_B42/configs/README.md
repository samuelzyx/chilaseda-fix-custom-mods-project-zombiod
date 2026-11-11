<div align="center">

<img src="../../../docs/branding/chilaseda-atom-bio-header.jpg" width="108" alt="Avatar de ChilaSeda">

# ⚙️ Configuración de Jill

**Teclas, opciones de mods y ajustes de Viewpoint · Project Zomboid Vanilla B42.22.2**

<a href="../README.md">🧟 Kit Zombicidio</a> ·
<a href="https://steamcommunity.com/sharedfiles/filedetails/?id=3812814868">🧰 Colección de Steam</a> ·
<a href="https://github.com/samuelzyx/chilaseda-fix-custom-mods-project-zombiod">📦 Repositorio</a> ·
<a href="https://www.atom.bio/chilaseda">📺 Canales</a>

</div>

---

> 🎯 **¿Qué contiene?** Una captura de la configuración local de Jill: teclas, opciones de mods,
> ajustes de Viewpoint y posiciones de interfaz. No incluye partidas guardadas, logs ni ajustes
> gráficos generales del equipo.

## 🧭 Índice

- [📍 Destino de cada archivo](#destino-de-cada-archivo)
- [🗂️ Así queda en tu computadora](#estructura-en-tu-computadora)
- [🚀 Instala la configuración](#instalacion)
- [⚠️ Antes de reemplazar archivos](#antes-de-reemplazar-archivos)
- [🧟 Continúa con el kit](#continua-con-el-kit)

---

## 📍 Destino de cada archivo

<a id="destino-de-cada-archivo"></a>

La carpeta personal del juego es `%USERPROFILE%\Zomboid\` —por ejemplo,
`C:\Users\<tu_usuario>\Zomboid\`. Copia cada archivo a la ruta indicada:

| Archivo incluido en el kit | Debe quedar en | Para qué sirve |
|---|---|---|
| `configs/Lua/ModOptions.ini` | `%USERPROFILE%\Zomboid\Lua\ModOptions.ini` | Opciones y teclas guardadas por los mods. |
| `configs/Lua/keysB42.ini` | `%USERPROFILE%\Zomboid\Lua\keysB42.ini` | Teclas generales de Project Zomboid. |
| `configs/Lua/MiniCompass_Position_user_JillValentine.txt` | `%USERPROFILE%\Zomboid\Lua\MiniCompass_Position_user_JillValentine.txt` | Posición del MiniCompass de Jill. |
| `configs/Lua/ViewpointRebusquedaHills_manual_offsets.txt` | `%USERPROFILE%\Zomboid\Lua\ViewpointRebusquedaHills_manual_offsets.txt` | Ventana y posiciones manuales de pines de rebusca. |
| `configs/Lua/ViewpointNativeForage_manual_offsets.txt` | `%USERPROFILE%\Zomboid\Lua\ViewpointNativeForage_manual_offsets.txt` | Zoom global de pines, circulos e iconos; queda fuera de las carpetas de partidas. |
| `configs/Lua/ChilaSeda_RecentMapSymbols_0.txt` | `%USERPROFILE%\Zomboid\Lua\ChilaSeda_RecentMapSymbols_0.txt` | Simbolos recientes del jugador local (sufijo actual: `0`). |
| `configs/viewpoint-live.properties` | `%USERPROFILE%\Zomboid\viewpoint-live.properties` | Cámara, controles, render y mundo de Viewpoint. |
| `configs/grassiergrass.properties` | `%USERPROFILE%\Zomboid\grassiergrass.properties` | Preferencias de Grassier Grass. **No corrige el fallo que tuvo Jill.** |
| `Sandbox Presets/Zombicidio.cfg` | `%USERPROFILE%\Zomboid\Sandbox Presets\Zombicidio.cfg` | Preset para crear el mundo. Está fuera de `configs/`. |

---

## 🗂️ Así queda en tu computadora

<a id="estructura-en-tu-computadora"></a>

```text
%USERPROFILE%\Zomboid\
|-- Lua\
|   |-- ModOptions.ini
|   |-- keysB42.ini
|   |-- MiniCompass_Position_user_JillValentine.txt
|   |-- ViewpointRebusquedaHills_manual_offsets.txt
|   |-- ViewpointNativeForage_manual_offsets.txt
|   `-- ChilaSeda_RecentMapSymbols_0.txt
|-- Sandbox Presets\
|   `-- Zombicidio.cfg
|-- grassiergrass.properties
`-- viewpoint-live.properties
```

MiniCompass, Viewpoint Native Foraging y Recent Map Symbols guardan estas preferencias fuera de la carpeta del mundo.

Al abrir respaldos con nombres distintos, los archivos de `Zomboid/Lua` siguen disponibles.
Manten separados `ViewpointRebusquedaHills_manual_offsets.txt` (parche de Viewpoint Foraging)
y `ViewpointNativeForage_manual_offsets.txt` (parche nativo de Viewpoint).
El sufijo `0` de Recent Map Symbols es el archivo que genera esta partida local. Si Jill crea
otro sufijo en tu instalacion, conserva el nombre generado por el juego.

Los mods locales van en `%USERPROFILE%\Zomboid\mods\<carpeta_del_mod>\`, conservando cada
carpeta completa y sus subcarpetas `42`. Las configuraciones de esta página **no van dentro de
`mods` ni dentro de las carpetas de Workshop**.

---

## 🚀 Instala la configuración

<a id="instalacion"></a>

1. Cierra Project Zomboid.
2. En el kit, abre `configs/` y copia **lo que está dentro** directamente a
   `%USERPROFILE%\Zomboid\`.
3. Si Windows pregunta si quieres combinar `Lua` o reemplazar archivos, combina la carpeta y
   permite el reemplazo después de respaldar tus copias actuales.
4. Copia `Sandbox Presets/Zombicidio.cfg` a `%USERPROFILE%\Zomboid\Sandbox Presets\`.
5. Inicia el juego y revisa los controles y ajustes antes de cargar una partida.

> 💡 No copies la carpeta `configs` como una carpeta adicional. Por ejemplo,
> `configs/Lua/keysB42.ini` va en `Zomboid/Lua/keysB42.ini`, no en `Zomboid/configs/Lua/`.

### ✅ Revisa estos requisitos

- Los mods correspondientes deben estar instalados y activos para que sus opciones tengan efecto.
- `ModOptions.ini` contiene preferencias y teclas de mods; `keysB42.ini` contiene las teclas
  generales del juego.
- El preset Sandbox sirve al crear un mundo nuevo. No cambia un mundo que ya existe.
- `mods.txt` y `map_ver.bin` se copian **después de crear y guardar el mundo**, dentro de
  `%USERPROFILE%\Zomboid\Saves\Sandbox\<nombre_de_tu_partida>\`. Consulta el
  [README del kit](../README.md) para completar ese paso.

---

## ⚠️ Antes de reemplazar archivos

<a id="antes-de-reemplazar-archivos"></a>

Estos archivos reemplazan opciones y teclas personales. Haz una copia de los destinos existentes
antes de copiarlos. Las preferencias pueden variar según el teclado, la pantalla y los mods
instalados en cada equipo.

## 🧟 Continúa con el kit

<a id="continua-con-el-kit"></a>

Vuelve al [README del kit Zombicidio Jill](../README.md) para instalar mods, crear el mundo y
colocar `mods.txt` y `map_ver.bin` en el guardado.


---

### 🔗 Otros enlaces de interés

- [⬅️ Inicio del kit Jill](../README.md)
- [⏸️ Mods en pausa](../mods_en_pausa.md)
- [🏠 Inicio del repositorio](../../../README.md)
- [🤝 Cómo contribuir](../../../CONTRIBUTING.md)
- [🚀 Releases de mods](../../../docs/releases/README.md)
