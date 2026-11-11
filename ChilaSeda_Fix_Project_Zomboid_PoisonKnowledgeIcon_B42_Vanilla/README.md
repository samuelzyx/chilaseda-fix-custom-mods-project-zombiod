# ChilaSeda Fix · conocimiento de veneno (B42 vanilla) 0.2.0

<div align="center">

[🏠 Repo](../README.md) · [🤝 Contribuir](../CONTRIBUTING.md) · [🚀 Releases](../docs/releases/README.md)

</div>

---


## Problema

Vanilla usa dos comprobaciones distintas para el veneno. El inventario cambia el nombre de una baya o hongo cuando el personaje conoce la receta `Herbalist` y el alimento tiene potencia de veneno positiva; en cambio, las calaveras del inventario y de los pines de rebusca solo consultan `player:isKnownPoison(item)`. Por eso Jill podía reconocer el ingrediente por Herbalist sin ver la misma señal en el tooltip o el pin.

## Qué cambia en 0.2.0

- Aplica la misma regla de Herbalist y potencia positiva al tooltip de comida y a las etiquetas de objetos encontrados. Mientras la interfaz los dibuja, usa el nombre traducido vanilla para la baya o el hongo venenoso y después restaura el nombre anterior del objeto.
- Añade calaveras a los iconos del inventario, pines generales de rebusca y pines de objetos del mundo cuando vanilla no las haya añadido mediante `isKnownPoison`.

## Límites y carga

El parche no revela el veneno a quien no conoce Herbalist, no añade excepciones por ID de objeto y no modifica archivos vanilla. Se carga después de AutoCook para combinar el wrapper del nombre venenoso con su tooltip nutricional.

---

### 🔗 Otros enlaces de interés

- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
