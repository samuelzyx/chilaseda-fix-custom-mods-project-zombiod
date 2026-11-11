<div align="center">

<img src="docs/branding/chilaseda-atom-bio-header.jpg" width="132" alt="Avatar de ChilaSeda">

# 🧟 ChilaSeda · Mods para Project Zomboid

**Mods propios, parches locales y guías · Base: Project Zomboid Vanilla B42.22.2**

<a href="#kit-zombicidio-jill"><img alt="Project Zomboid · Build 42" src="https://img.shields.io/badge/PROJECT_ZOMBOID-Build_42-52796F?style=for-the-badge"></a>
<a href="#redes-y-streaming"><img alt="ChilaSeda · Canales" src="https://img.shields.io/badge/CHILASEDA-STREAMS_Y_REDES-E76F51?style=for-the-badge"></a>
<a href="#colaborar"><img alt="Colaborar" src="https://img.shields.io/badge/COMUNIDAD-RAMAS_%2B_PRS-3A86FF?style=for-the-badge"></a>

[📦 Mods](#contenido-del-repositorio) · [🧰 Kit Jill](#kit-zombicidio-jill) · [🤝 Colaborar](#colaborar) · [📝 Incidentes](#notas-de-la-comunidad) · [🚀 Releases](#releases) · [📺 Canales](#redes-y-streaming) · [🎨 Autoría](#creacion-propia-y-auditoria)

</div>

---

Este repositorio reúne mods y parches locales de ChilaSeda, junto con herramientas y guías para revisarlos. Las carpetas de mods originales de Workshop se conservan intactas; los arreglos propios viven en sus carpetas `ChilaSeda_*`.

---

<a id="contenido-del-repositorio"></a>
## 📦 Contenido del repositorio

| 🗂️ Ruta | ✨ Qué encontrarás |
| --- | --- |
| `ChilaSeda_*` | Mods propios y parches locales para Build 42. |
| `kits/Zombicidio_Jill_B42/` | Guía, lista de suscripciones en pausa, `mods.txt`, `map_ver.bin` y preset de Jill. |
| `docs/incidentes/` | Guía y plantilla para proponer notas comunitarias con evidencia. |
| `docs/releases/` | Historial de versiones de mods y guía para descargar actualizaciones. |
| `docs/Manual_Pesos_B42_y_Monitor.md` | Manual de objetivos de peso y del monitor. |
| `tools/` · `tests/` | Herramientas de mantenimiento y pruebas que acompañan a los mods. |
| `.agents/` · `.codex/` · `.claude/` · `.codemie/` | Instrucciones, skills y espacios portables para colaborar con herramientas de IA. |

---

<a id="kit-zombicidio-jill"></a>
## 🧰 Kit Zombicidio Jill

La guía [`kits/Zombicidio_Jill_B42/README.md`](kits/Zombicidio_Jill_B42/README.md) incluye las instrucciones para clonar o descargar el repo como ZIP y enumera las **38 carpetas locales ChilaSeda** activas en el perfil Jill.

- 🎮 Partida de referencia: **Project Zomboid Vanilla B42.22.2**.
- 🧺 [Colección ChilaSeda en Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3812814868).
- 📋 [`mods.txt`](kits/Zombicidio_Jill_B42/mods.txt) y 🗺️ [`map_ver.bin`](kits/Zombicidio_Jill_B42/map_ver.bin), para colocar en el guardado después de crear el mundo y cerrar el juego.
- ⏸️ [`mods_en_pausa.md`](kits/Zombicidio_Jill_B42/mods_en_pausa.md) registra elementos de Workshop que no están activos en la lista de Jill y candidatos para desuscripción temporal.
- ⚙️ [Preset de Sandbox](kits/Zombicidio_Jill_B42/Sandbox%20Presets/Zombicidio.cfg) y 📖 [descripción de la colección e instalación](kits/Zombicidio_Jill_B42/Descripcion_Coleccion_Zombicidio.txt).
- 🧟 Los mods de terceros se descargan desde Workshop; el repo no redistribuye sus archivos.

> ⚠️ Conserva una copia de los archivos del mundo antes de reemplazar `mods.txt` y `map_ver.bin`.

---

<a id="colaborar"></a>
## 🤝 Colaborar

**Toda contribución requiere una rama propia y un Pull Request hacia `main`.** No se autorizan cambios directos a `main`; Chila revisa y autoriza cada PR antes de integrarlo.

1. 🌱 Crea una rama `fix/...`, `feature/...` o `docs/...`.
2. 📝 Describe el cambio, los mods afectados, dependencias, orden de carga y versión del juego.
3. 🚀 Abre el PR hacia `main` y espera la revisión.

Consulta [`CONTRIBUTING.md`](CONTRIBUTING.md). No subas partidas guardadas, logs personales, backups, credenciales, cachés ni datos identificables.

---

<a id="notas-de-la-comunidad"></a>
## 📝 Notas de la comunidad

¿Encontraste un error o tienes una mejora? Envía una nota con pasos para reproducirla y capturas:

- 🧾 Usa [`docs/incidentes/PLANTILLA_NOTA.md`](docs/incidentes/PLANTILLA_NOTA.md).
- 🌱 Envíala en una rama mediante un Pull Request.
- 📷 Adjunta evidencia al PR o guárdala en `docs/incidentes/evidencias/`.
- 🔎 Revisaremos versiones, pasos y capturas antes de incorporarla.

Oculta nombres de usuario, rutas personales y datos del guardado que no sean necesarios.

---

<a id="redes-y-streaming"></a>
## 📺 Síguenos y apoya el proyecto

🎥 **¿Te laten las partidas y los mods de Project Zomboid?** Sigue los directos, videos y redes de ChilaSeda desde [atom.bio/chilaseda](https://www.atom.bio/chilaseda). Ahí están reunidos todos los canales oficiales.

---

<a id="releases"></a>
## 🚀 Actualizaciones y descargas

El [changelog](docs/releases/CHANGELOG.md) ya muestra los cambios recientes del repositorio. Cuando publiquemos paquetes individuales, estarán en [GitHub Releases](https://github.com/samuelzyx/chilaseda-fix-custom-mods-project-zombiod/releases). También puedes suscribirte al [feed Atom/XML](https://github.com/samuelzyx/chilaseda-fix-custom-mods-project-zombiod/releases.atom) o, en GitHub, elegir **Watch → Custom → Releases** para recibir avisos de Releases publicadas.

El historial y el procedimiento para publicar versiones están en [`docs/releases/`](docs/releases/README.md).

---

## 🤖 Herramientas de IA

`.agents/` y `.codex/` contienen skills y hooks compartidos. `.claude/` y `.codemie/` reservan espacio para guía portable. Las configuraciones locales, datos de cuenta y cachés no se publican.

---

<a id="creacion-propia-y-auditoria"></a>
## 🎨 Creación propia y auditoría

El **Álbum del Superviviente** es una creación de ChilaSeda, desarrollada a partir de nuestra auditoría del contenido y de la experiencia de juego. No plagies ni redistribuyas sus diseños, textos o recursos propios como si fueran tuyos. Para proponer mejoras, conserva la atribución y usa el flujo de ramas y PRs.

<table>
  <tr>
    <td align="center"><img src="ChilaSeda_AlbumDelSuperviviente_B42/42/media/textures/ChilaSeda_Album_FrontCover.png" width="220" alt="Portada del Álbum del Superviviente"></td>
    <td align="center"><img src="ChilaSeda_AlbumDelSuperviviente_B42/42/media/textures/ChilaSeda_Album_BackCover.png" width="220" alt="Contraportada del Álbum del Superviviente"></td>
  </tr>
  <tr>
    <td align="center"><strong>📕 Portada</strong></td>
    <td align="center"><strong>📘 Contraportada</strong></td>
  </tr>
</table>
