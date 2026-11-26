# ChilaSeda Options Search (B42)

Agrega un filtro de busqueda a cada pestana de la ventana Opciones. Busca por texto visible en los controles de Project Zomboid y de los mods, incluidas etiquetas, descripciones, categorias, tooltips y opciones. El filtro se actualiza al confirmar cada cambio de texto y compara sin distinguir mayusculas, minusculas ni tildes. Mientras filtras, las coincidencias se compactan para evitar huecos; al limpiar, cada control recupera su posicion original. Los controles de busqueda permanecen fijos fuera del desplazamiento de opciones.

La categoria de cada mod conserva el orden original de la lista de opciones. El filtro de texto encuentra tanto la categoria como sus ajustes. Si el resultado pertenece a una sola categoria, `Ver otras opciones de esta categoria` cambia la busqueda al nombre de la categoria y muestra todos sus ajustes; tambien limpia un filtro de tecla activo. Los resultados filtrados empiezan en la parte superior del area desplazable, aunque la lista original tenga filas fuera del viewport.

En `Teclas`, el filtro de texto busca la accion y la tecla mostrada. El control `Filtrar al presionar una tecla` captura la siguiente tecla pulsada y muestra solo las acciones asignadas a ella, comparando sus palabras en orden con el boton de asignacion (incluye nombres como `Left Shift`). `Esc` tambien se puede seleccionar como filtro. Usa `Limpiar tecla`, junto al selector, para quitarlo sin cerrar Opciones. El mismo filtro por tecla esta disponible en `Mods` para las opciones que usan asignaciones de teclas; cada pestana conserva su propio estado. La `X` junto al campo borra el texto sin borrar el filtro de tecla. Las filas se descubren desde los hijos reales del panel, se compactan al filtrar y se restauran al limpiar. El buscador conserva el orden nativo de los mods y no modifica sus datos compartidos.

La normalizacion ignora tildes al comparar los textos.

## Historial

- 1.0.10: evita recortar la primera coincidencia si el panel tenia filas por encima del viewport; agrega un boton para cambiar de una opcion a todas las opciones de su categoria.
- 1.0.9: separa los filtros en un bloque fijo titulado `Filtros`, con fondo y divisor, del panel desplazable de opciones. El aviso `Sin coincidencias` aparece dentro del viewport de resultados, que conserva su propio desplazamiento.
- 1.0.8: en `Teclas`, asocia cada atajo con la categoria nativa de `MainOptions.keyText`; al filtrar conserva el titulo y divisor originales solo para categorias con resultados, y los restaura al limpiar. Registra una traza compacta con la cantidad de encabezados y atajos asociados.
- 1.0.7: mantiene el aviso "Sin coincidencias" alineado a la izquierda debajo del campo de busqueda. `ISLabel:new` por defecto resta el ancho del texto a la coordenada X; el argumento `bLeft=true` evita que el aviso se dibuje fuera del panel.
- 1.0.6: mueve los controles de busqueda a un encabezado fijo fuera del panel desplazable, reserva el espacio de contenido y calcula el area scrollable con las filas reales. Conecta el filtro de texto al callback del campo y aplica el texto confirmado en el siguiente tick para responder a cada letra; conserva el filtro por tecla.
- 1.0.5: llama a `getText()` solo para claves conocidas de traduccion, no para el texto arbitrario de las opciones; evita `UnknownFormatConversionException` con textos que contienen `%`. Calcula el area desplazable desde la fila mas baja para conservar la lista completa de Mod Options.
- 1.0.4: recorre los controles vanilla por sus IDs reales, activa el filtrado, conserva espacio para los controles y agrega X para vaciar el texto.
- 1.0.3: permite filtrar por Esc y agrega el boton Limpiar tecla junto al control de captura.
- 1.0.2: compacta las coincidencias, restaura el diseno al limpiar, conserva el centrado nativo de cada pestana, adapta los controles a paneles angostos y separa el estado del filtro por tecla entre Teclas y Mods.
- 1.0.1: inicializa el control Java del campo antes de leer su texto; sin `instantiate()`, `getText()` fallaba y la pestana podia abortar antes de instalar el filtro.

## Uso

Abre `Opciones`. Cada pestana tiene un campo en la parte superior. Escribe para filtrar y borra el campo para recuperar todos los controles. En `Teclas` o `Mods`, pulsa el boton de filtro por tecla y luego la tecla que quieres buscar.
