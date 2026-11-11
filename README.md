<div align="center">

# 🧟 ChilaSeda · Mods para Project Zomboid

**Mods propios, parches locales y guías para Build 42**

![Project Zomboid Build 42](https://img.shields.io/badge/PROJECT_ZOMBOID-Build_42-52796F?style=for-the-badge)
![ChilaSeda Mods](https://img.shields.io/badge/CHILASEDA-Mods_y_parches-E76F51?style=for-the-badge)
![Contribuciones](https://img.shields.io/badge/COMUNIDAD-Ramas_%2B_PRs-3A86FF?style=for-the-badge)

[📦 Mods](#-contenido-del-repositorio) · [🧰 Kit Jill](#-kit-zombicidio-jill) · [🤝 Colaborar](#-colaborar) · [📝 Incidentes](#-notas-de-la-comunidad) · [🎨 Autoría](#-creación-propia-y-auditoría)

</div>

---

Este repositorio reúne mods y parches locales de ChilaSeda, junto con herramientas y guías para revisarlos. Las carpetas de mods originales de Workshop se conservan intactas; los arreglos propios viven en sus carpetas `ChilaSeda_*`.

---

## 📦 Contenido del repositorio

| 🗂️ Ruta | ✨ Qué encontrarás |
| --- | --- |
| `ChilaSeda_*` | Mods propios y parches locales para Build 42. |
| `kits/Zombicidio_Jill_B42/` | Paquete local, preset y archivos de referencia para montar una partida parecida a Jill. |
| `docs/incidentes/` | Guía y plantilla para proponer notas comunitarias con evidencia. |
| `tools/` · `tests/` | Herramientas de mantenimiento y pruebas que acompañan a los mods. |
| `.agents/` · `.codex/` · `.claude/` · `.codemie/` | Instrucciones, skills y espacios portables para colaborar con herramientas de IA. |

---

## 🧰 Kit Zombicidio Jill

La carpeta [`kits/Zombicidio_Jill_B42/`](kits/Zombicidio_Jill_B42/README.md) explica los archivos y el orden para preparar una partida nueva. Incluye:

- 📦 [RAR con los mods locales ChilaSeda](kits/Zombicidio_Jill_B42/Kit_Zombicidio_Jill_B42.rar) y el preset `Zombicidio`.
- 📋 [`mods.txt`](kits/Zombicidio_Jill_B42/mods.txt) y 🗺️ [`map_ver.bin`](kits/Zombicidio_Jill_B42/map_ver.bin), para colocar en el guardado después de crear el mundo y cerrar el juego.
- ⚙️ [Preset de Sandbox](kits/Zombicidio_Jill_B42/Sandbox%20Presets/Zombicidio.cfg) y 📖 [guía de instalación y colección](kits/Zombicidio_Jill_B42/Descripcion_Coleccion_Zombicidio.txt).

> 🧟 Es una referencia para crear una partida parecida. Los mods de terceros, como Project Viewpoint y la apariencia RE:3 Jill, se descargan desde sus páginas de Workshop; no se redistribuyen aquí. Revisa la guía y conserva una copia de los archivos del mundo antes de reemplazarlos.

---

## 🤝 Colaborar

**Toda contribución requiere una rama propia y un Pull Request hacia `main`.** No se autorizan cambios directos a `main`; Chila revisa y autoriza cada PR antes de integrarlo.

1. 🌱 Crea una rama `fix/...`, `feature/...` o `docs/...`.
2. 📝 Describe el cambio, los mods afectados, dependencias, orden de carga y versión del juego.
3. 🚀 Abre el PR hacia `main` y espera la revisión.

Consulta [`CONTRIBUTING.md`](CONTRIBUTING.md) para las reglas completas. No subas partidas guardadas, logs personales, backups, credenciales, cachés ni datos identificables.

---

## 📝 Notas de la comunidad

¿Encontraste un error o tienes una mejora? Puedes enviar una nota con pasos para reproducirla y capturas:

- 🧾 Usa [`docs/incidentes/PLANTILLA_NOTA.md`](docs/incidentes/PLANTILLA_NOTA.md).
- 🌱 Envíala en tu rama mediante un Pull Request.
- 📷 Adjunta evidencia al PR o guárdala en `docs/incidentes/evidencias/`.
- 🔎 Revisaremos versiones, pasos y capturas antes de incorporarla.

Oculta nombres de usuario, rutas personales y datos del guardado que no sean necesarios.

---

## 🤖 Herramientas de IA

`.agents/` y `.codex/` contienen skills y hooks compartidos. `.claude/` y `.codemie/` reservan espacio para guía portable. Las configuraciones locales, datos de cuenta y cachés no se publican.

---

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
