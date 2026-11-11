<div align="center">

# 🚀 Releases de mods ChilaSeda

**Actualizaciones individuales para Project Zomboid · Build 42**

Consulta el [historial del proyecto](CHANGELOG.md) · Descarga en
[GitHub Releases](https://github.com/samuelzyx/chilaseda-fix-custom-mods-project-zombiod/releases)

</div>

---

## 📡 ¿Cómo me entero de una actualización?

| Opción | Para qué sirve |
| --- | --- |
| **GitHub Releases** | Ver las notas y descargar el ZIP de un mod específico. |
| **Watch → Custom → Releases** | Recibir notificaciones de GitHub sobre nuevas Releases. |
| **Feed Atom/XML** | Suscribirte desde un lector de feeds, sin clonar el repo. |

🔔 [Abrir la página de Releases](https://github.com/samuelzyx/chilaseda-fix-custom-mods-project-zombiod/releases) ·
📰 [Suscribirse al feed Atom](https://github.com/samuelzyx/chilaseda-fix-custom-mods-project-zombiod/releases.atom)

> El feed `releases.atom` es un documento XML generado por GitHub. Solo anuncia Releases
> publicadas; el historial de `CHANGELOG.md` no se replica allí automáticamente. Por eso el feed
> puede estar vacío hasta que publiquemos la primera versión.

---

## 🎮 Descargar e instalar

1. Abre una Release y localiza el ZIP que tenga el ID y la versión del mod, por ejemplo
   `<ID>-vX.Y.Z.zip`.
2. Cierra Project Zomboid y reemplaza la carpeta del mod anterior en
   `%USERPROFILE%\Zomboid\mods\` por la del ZIP.
3. Inicia el juego y comprueba la compatibilidad indicada en las notas de esa Release.

Cada ZIP adjunto contiene **un solo mod**, con su carpeta en la raíz del archivo. El ZIP
automático que ofrece GitHub contiene el repositorio entero; no lo uses para instalar una versión
individual.

---

## Historial del proyecto

CHANGELOG.md registra solo cambios de mods que Chila confirmo dentro de Jill.

- **Cambios confirmados por Chila:** resultado final que ya verifico en el juego.
- **GitHub Releases publicadas:** versiones validadas con enlace al paquete individual.

El trabajo activo y lo que Chila aun no valida se siguen en TODO.md.
Esos cambios no se presentan como finales en el changelog.

---

## 🛠️ Flujo para preparar una versión

1. Incrementa el número de publicación `MAJOR.MINOR.PATCH`: `PATCH` para correcciones,
   `MINOR` para funciones compatibles y `MAJOR` para cambios incompatibles. El tag de GitHub y
   el changelog son la fuente de esa versión; no agregues `version=` a `mod.info` sin que el mod
   lo necesite.
2. Despues de que Chila confirme el resultado dentro de Jill, agrega a CHANGELOG.md el ID, carpeta,
   version, fecha de confirmacion, compatibilidad y resumen para jugadores. Mientras siga sin
   confirmar, deja el trabajo en TODO.md.
3. Cuando el cambio esté revisado y su validación requerida esté confirmada, crea una Release
   independiente titulada `Nombre del mod vX.Y.Z` y con tag `mod/<ID>/vX.Y.Z`.
4. Resume el cambio, compatibilidad de Project Zomboid, requisitos e instrucciones de instalación.
5. Adjunta `<ID>-vX.Y.Z.zip` con solo la carpeta instalable de ese mod. Excluye logs, backups,
   partidas guardadas y otros mods.
6. Publica y revisa que la página, las notas y el ZIP sean visibles. Añade el enlace y la fecha
   a la sección de Releases publicadas de `CHANGELOG.md`.

Si una actualización afecta varios mods, publica una Release por cada uno. La plantilla de notas
está en [`.github/release_template.md`](../../.github/release_template.md).

---

## 📣 Canales de ChilaSeda

Los directos y redes están reunidos en [atom.bio/chilaseda](https://www.atom.bio/chilaseda).


---

### 🔗 Otros enlaces de interés

- [🧾 Changelog](CHANGELOG.md)
- [🏠 Inicio del repositorio](../../README.md)
- [🤝 Cómo contribuir](../../CONTRIBUTING.md)
