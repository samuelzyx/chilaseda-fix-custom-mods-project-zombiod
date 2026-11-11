# 🤝 Contribuye al taller de mods

¡Gracias por ayudar a mejorar estos mods y sus guías! Para que cada cambio se pueda revisar,
probar y atribuir correctamente, sigue este flujo.

> 🚦 **Las contribuciones de la comunidad se envían en una rama propia y mediante un Pull
> Request a `main`.** No hagas push directo a `main`; Chila revisa y autoriza cada PR antes de
> integrarlo.

---

## 🧭 Flujo rápido

1. **Prepara tu rama** desde `main`. Usa un nombre claro, por ejemplo `fix/acciones-accesibles`,
   `feature/opcion-nueva` o `docs/instalacion`.
2. **Haz un cambio enfocado.** Conserva intactos los mods originales de Workshop. Los fixes de
   este proyecto van dentro de la carpeta local `ChilaSeda_*` correspondiente.
3. **Revisa y documenta.** Indica qué cambió y qué comprobaste; no declares como probado algo que
   no ejecutaste en el juego.
4. **Abre el Pull Request** hacia `main`. Describe el problema, solución, dependencias y
   evidencia. Espera la revisión y autorización de Chila antes de integrar.

---

## 🧩 Si cambias un mod

Incluye en el PR:

- 🏷️ Nombre y `id` del mod afectado.
- 🛠️ Resumen del arreglo o función y cualquier dependencia.
- 📚 Orden de carga requerido; documenta `loadModAfter` cuando aplique.
- 🎮 Versión o Build de Project Zomboid y versiones de los mods relacionados.
- 🔍 Cómo revisaste el cambio: pasos, resultado observado y evidencia disponible.

Agrupa en una carpeta los fixes dirigidos al mismo mod de Workshop. Si un arreglo cruza varios
mods, explica cuál tiene el defecto principal y declara el resto como dependencia.

### 🚀 Cuando cambia la versión distribuible

Si el PR actualiza la versión de un mod, agrega una entrada al inicio de
[`docs/releases/CHANGELOG.md`](docs/releases/CHANGELOG.md) con su ID/carpeta, versión, fecha,
compatibilidad y resumen para jugadores. Chila publica después una Release individual con sus
notas y el ZIP instalable de ese mod. Sigue el formato de
[`docs/releases/README.md`](docs/releases/README.md); no publiques tags o releases por tu cuenta.

---

## 📝 Reporta un incidente

Para proponer una nota o mejora, usa
[`docs/incidentes/PLANTILLA_NOTA.md`](docs/incidentes/PLANTILLA_NOTA.md) y envíala en tu rama
mediante un PR. Incluye pasos para reproducir, resultado esperado y observado, Build del juego,
mods y versiones involucradas. Adjunta capturas al PR o en
[`docs/incidentes/evidencias/`](docs/incidentes/evidencias/).

Antes de compartir evidencia, oculta nombres de usuario, rutas personales, identificadores y
datos del guardado que no sean necesarios para entender el problema.

---

## 🔒 Cuida el repositorio

No subas partidas guardadas, logs personales, backups, credenciales, cachés, datos privados ni
compilados temporales. Conserva únicamente los binarios necesarios para distribuir el mod, como
un JAR incluido por un parche.

Las skills y hooks portables viven en `.agents/` y `.codex/`. Usa rutas relativas al repositorio
en las integraciones compartidas y deja fuera configuraciones locales o datos de cuenta.

---

## 📬 Antes de solicitar revisión

- [ ] Mi rama parte de `main` y el PR apunta a `main`.
- [ ] El cambio respeta los originales de Workshop.
- [ ] Documenté versiones, dependencias y orden de carga.
- [ ] Incluí evidencia o expliqué qué validación falta.
- [ ] Si actualicé una versión, agregué su entrada al changelog.
- [ ] Revisé que el PR no incluya saves, logs privados, backups ni credenciales.
