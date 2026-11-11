# ChilaSeda — Álbum del Superviviente (Build 42)

<div align="center">

[🏠 Repo](../README.md) · [🤝 Contribuir](../CONTRIBUTING.md) · [🚀 Releases](../docs/releases/README.md)

</div>

---


Álbum personal para documentos y medios impresos de Project Zomboid.

La opción para abrir el álbum reutiliza el icono de libro vanilla de B42.

## Alcance actual

- Conserva el álbum de doble página y la apertura Kentucky Herald July 16 existente.
- P-002.5 agrega el folleto vanilla FashionaBelle como segunda apertura: recurso original a la izquierda, texto traducido a la derecha, zoom/arrastre independientes, scroll y acceso al visor vanilla para su acción de mapa.
- `Documentacion/P-002.5_Report.md` explica recursos, comparación e instrucciones de revisión.
- `Documentacion/P-002.5A_InventoryReport.md` y los CSV anexos contienen el inventario preliminar estático de medios/coleccionables Build 42.
- Al cargar un personaje, comprueba que la revista exista en el inventario o en una mochila anidada; si falta, restaura el acceso al álbum sin reiniciar los registros persistentes del personaje.

## Identidad del objeto

El mod ID es `ChilaSeda_AlbumDelSuperviviente_B42`. El FullType del objeto físico sigue siendo `ChilaSeda_PersonalReadingArchive.PersonalReadingArchive` para conservar compatibilidad con el objeto ya existente.

## Cambios de 0.4.3

El álbum agrega páginas para los medios impresos encontrados en el inventario y sus mochilas
anidadas, aunque todavía no se hayan leído. Cada página usa la composición original traducida
cuando está disponible; si falta, muestra el icono vanilla del tipo de objeto. El texto del medio
aparece en la página derecha y admite scroll. Kentucky Herald y FashionaBelle conservan sus páginas
dedicadas. Las páginas nuevas se enumeran alfabéticamente después de ellas y antes de la contraportada.
El doble clic de un medio impreso sigue abriendo el visor nativo de B42; la página del álbum se abre
con la opción propia del álbum.

## Recuperación del acceso al álbum

El historial y los registros del álbum se guardan en `player:getModData()` con la clave `ChilaSedaPersonalReadingArchive`. La revista física es el acceso al visor. Si falta del inventario y de las mochilas llevadas, la versión 0.4.2 restaura una revista con el mismo `FullType`; conserva los datos existentes del personaje y evita duplicarla cuando aparece en una mochila anidada.

## Límites de esta iteración

No se modifican portada/contraportada ni icono. Los medios nuevos aparecen cuando se encuentran en el inventario llevado o en una mochila anidada; no se genera un catálogo de ejemplares que el personaje nunca haya tenido. No se implementan P-002.6/P-002.7, el catálogo funcional ni un sistema general de mapas. El inventario técnico no se ha validado dentro del juego.

## Revisión runtime

Con el mod activo, abre el álbum y sigue `Documentacion/P-002.5_Report.md`. Comprueba layout, idioma, zoom, arrastre, scroll, acción de mapa y errores Lua. La prueba de Jill queda pendiente.


---

### 🔗 Otros enlaces de interés

- [P-002.5A — Inventario preliminar vanilla de medios impresos y coleccionables](Documentacion/P-002.5A_InventoryReport.md)
- [Informe P-002.5 — Segunda apertura vanilla](Documentacion/P-002.5_Report.md)
- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
