# Releases de mods ChilaSeda

Este registro permite que quien descarga el proyecto sin clonar Git también encuentre las
actualizaciones de cada mod. Cada publicación corresponde a **un mod** y tiene su propio tag,
notas y ZIP instalable.

Las versiones de publicación usan `MAJOR.MINOR.PATCH` y viven en el tag de GitHub; ese tag y
`CHANGELOG.md` son la fuente de verdad. No supongas que `mod.info` lleva un campo de versión ni
agregues uno sin necesidad del mod.

## Para jugadores

- Revisa la página de [Releases](https://github.com/samuelzyx/chilaseda-fix-custom-mods-project-zombiod/releases).
- Abre la versión del mod que necesitas y descarga el archivo ZIP adjunto con su nombre y versión.
- Extrae la carpeta del mod en `Zomboid/mods/`, reemplazando la versión anterior con el juego cerrado.
- También puedes suscribirte al [RSS de Releases](https://github.com/samuelzyx/chilaseda-fix-custom-mods-project-zombiod/releases.atom).
- En GitHub, elige **Watch → Custom → Releases** para recibir avisos de nuevas versiones.

El ZIP de una Release contiene solo la carpeta instalable de ese mod. El ZIP automático del
código fuente de GitHub contiene el repositorio completo y no es el paquete recomendado para
instalar una actualización individual.

## Flujo de publicación

1. Al cambiar un mod, incrementa su versión de publicación (`PATCH` para correcciones,
   `MINOR` para funciones compatibles y `MAJOR` para cambios incompatibles), conserva su
   `mod.info` y actualiza su documentación habitual.
2. En el mismo PR, agrega al inicio de [`CHANGELOG.md`](CHANGELOG.md) una entrada con fecha,
   ID/carpeta, versión nueva, compatibilidad y cambios visibles para jugadores.
3. Tras la revisión e integración del PR, crea una Release independiente con el título
   `Nombre del mod vX.Y.Z` y el tag `mod/<ID>/vX.Y.Z`.
4. Escribe notas breves: qué cambió, compatibilidad de Project Zomboid, requisitos y cómo
   instalar/actualizar.
5. Adjunta un ZIP llamado `<ID>-vX.Y.Z.zip`. Debe tener la carpeta del mod en su raíz y no
   incluir logs, backups, saves ni otros mods.
6. Publica la Release y verifica que el enlace y el ZIP aparezcan en la página pública.
   Solo entonces la versión se considera publicada.

Si un cambio del repo actualiza varios mods, publica una Release por cada mod y enumera los
IDs afectados en el PR. No cambies la versión de un mod por ediciones que no alteran su
contenido distribuible.

## Cómo leer el historial

`CHANGELOG.md` es el índice humano de los cambios por mod. La Release de GitHub es el anuncio
público y contiene la descarga individual. Mantén ambos registros alineados: misma versión,
fecha, resumen y enlace a la Release.
