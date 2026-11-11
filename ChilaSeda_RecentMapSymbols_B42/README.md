# ChilaSeda Recent Map Symbols · símbolos recientes del mapa (B42)

## Funciones

Añade las pestañas **Recientes** y **Buscar** a la paleta normal de símbolos del mapa. Recientes aparece primero y muestra hasta 20 símbolos distintos, ordenados del último colocado al más antiguo. Al colocar un símbolo, pasa al inicio de la lista.

Los IDs recientes se guardan en ModData del personaje, en ModData del mundo por jugador y en un archivo Lua individual. Así la lista sobrevive a la recarga aunque falte o se restablezca el ModData del personaje. Los IDs desconocidos se conservan si un paquete de símbolos no está disponible temporalmente; sus iconos reaparecen cuando se registran sus definiciones.

Buscar recorre las mismas definiciones que usa la paleta vanilla y acepta nombres en español o inglés, ID, nombre de textura y categoría. Los términos se separan en tokens y se ordenan por relevancia: por ejemplo, `bag de backpag` puede encontrar alias de mochilas sin coincidir con nombres ajenos como `Garbage`. Los resultados se pueden colocar en el mapa y conservan el color seleccionado.

La pestaña usa las definiciones y la acción de colocación vanilla. Funciona sin Viewpoint y no requiere Extra Map Symbols. Cuando el atajo normal abre el mapa del jugador, recentra la vista en el personaje después de que vanilla restaura la vista anterior; las llamadas con coordenadas explícitas conservan ese centro.

## Historial de cambios

- **0.2.6:** actualiza los símbolos recientes después de crear el panel del mapa y mientras la pestaña está visible si los IDs o definiciones llegan tarde; no guarda lecturas vacías. La búsqueda acepta coincidencias exactas, prefijos y subcadenas dentro de tokens, así que `flech` y `flecha` encuentran `Flechas`.
- **0.2.5:** corrige una palabra reservada de Lua en la tabla de palabras vacías, que impedía cargar todo el script de pestañas.
- **0.2.4:** agrega archivos de idioma JSON B42 para español e inglés, nombres en español para símbolos comunes y búsquedas sin distinción de acentos, con alias de mochilas y orden por relevancia. Añade persistencia por jugador en ModData del mundo además del ModData del personaje y el archivo Lua.
- **0.2.3:** guarda los IDs recientes en un archivo por jugador, conserva IDs de paquetes temporalmente ausentes y añade una pestaña de búsqueda con etiquetas localizadas.
- **0.2.2:** hace que los iconos recientes hereden el color seleccionado al crear o actualizar la pestaña; los cambios de color vanilla siguen actualizándolos en la lista compartida de botones.

---

### 🔗 Otros enlaces de interés

- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
