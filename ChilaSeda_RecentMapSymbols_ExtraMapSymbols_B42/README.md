# ChilaSeda Recent Map Symbols + Extra Map Symbols (B42)

<div align="center">

[🏠 Repo](../README.md) · [🤝 Contribuir](../CONTRIBUTING.md) · [🚀 Releases](../docs/releases/README.md)

</div>

---


## Funciones

Añade las pestañas **Recientes** y **Buscar** a la paleta normal de símbolos del mapa, y registra los símbolos adicionales de Extra Map Symbols (Workshop 2701170568). Sus iconos aparecen en la pestaña vanilla y también en Buscar; los IDs `extra:` se conservan para que los símbolos ya colocados sigan resolviendo.

Recientes aparece primero y muestra hasta 20 símbolos distintos, ordenados del último colocado al más antiguo. Al colocar un símbolo, pasa al inicio de la lista.

Los IDs recientes se guardan en ModData del personaje, en ModData del mundo por jugador y en un archivo Lua individual. Así la lista sobrevive a la recarga aunque falte o se restablezca el ModData del personaje. Los IDs desconocidos se conservan si un paquete de símbolos no está disponible temporalmente; sus iconos reaparecen cuando se registran sus definiciones.

Buscar recorre las mismas definiciones que usa la paleta vanilla y acepta nombres en español o inglés, ID, nombre de textura y conceptos relacionados para todo el catalogo (por ejemplo comida, vehiculos, medicina, animales, naturaleza y peligro). Al abrir la pestana muestra accesos sugeridos por categoria; al escribir filtra en cada tecla. La `X` junto al campo borra toda la busqueda. Cada resultado enseña su nombre en espanol junto al icono, y los botones `-`/`+` amplian o reducen los simbolos hasta el doble. La lista calcula cuantas tarjetas caben a ese zoom y muestra un aviso si hay mas resultados; ya no se dibuja por debajo de los botones del panel. El texto de ayuda queda como marcador dentro del campo y no tapa las sugerencias. Los terminos en ingles como `bag`, `backpack`, `duffel bag` y `rucksack` siguen encontrando la mochila. Los resultados se pueden colocar en el mapa conservando el color seleccionado.

Las pestañas usan las definiciones y la acción de colocación vanilla. Cuando el atajo normal abre el mapa del jugador, recentra la vista en el personaje después de que vanilla restaura la vista anterior; las llamadas con coordenadas explícitas conservan ese centro.

Este porte integra las definiciones y recursos de símbolos. No carga el antiguo reemplazo de interfaz `ExtraMapSymbolsUI`, incompatible con los controles de mapa B42; las pestañas recientes y búsqueda siguen usando el panel vanilla de B42.

## Historial de cambios

- **0.3.5:** filtra resultados desde el evento de cambio de texto y procesa el texto confirmado durante la pausa, igual que el campo del menu vanilla de construccion.
- **0.3.3:** evita leer el control de busqueda antes de instanciar su objeto UI nativo, que podia interrumpir la apertura del mapa.
- **0.3.2:** agrega sugerencias por categoria, nombres visibles en los resultados, zoom ajustable de iconos y busqueda semantica para el catalogo completo.
- **0.3.0:** integra Extra Map Symbols para B42.22, conserva los IDs `extra:` y renombra el mod unificado.
- **0.2.7:** actualiza los símbolos recientes después de crear el panel del mapa y mientras la pestaña está visible si los IDs o definiciones llegan tarde; no guarda lecturas vacías. La búsqueda acepta coincidencias exactas, prefijos y subcadenas dentro de tokens, así que `flech` y `flecha` encuentran `Flechas`.
- **0.2.5:** corrige una palabra reservada de Lua en la tabla de palabras vacías, que impedía cargar todo el script de pestañas.
- **0.2.4:** agrega archivos de idioma JSON B42 para español e inglés, nombres en español para símbolos comunes y búsquedas sin distinción de acentos, con alias de mochilas y orden por relevancia. Añade persistencia por jugador en ModData del mundo además del ModData del personaje y el archivo Lua.
- **0.2.3:** guarda los IDs recientes en un archivo por jugador, conserva IDs de paquetes temporalmente ausentes y añade una pestaña de búsqueda con etiquetas localizadas.
- **0.2.2:** hace que los iconos recientes hereden el color seleccionado al crear o actualizar la pestaña; los cambios de color vanilla siguen actualizándolos en la lista compartida de botones.

---

### 🔗 Otros enlaces de interés

- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
