# ChilaSeda - Smart Radial Native Options (B42)

Parche local para Smart Radial Menu. Conserva las opciones nativas de inventario y
los iconos de Drink Smart.

## Version 1.1.12

- Las acciones de beber vuelven a ejecutar directamente el callback original de
  Smart Radial Menu. Se retiro la reconstruccion temporal del menu contextual y
  la invocacion manual de sus callbacks, que podia dejar una accion a medias.
- Antes de ejecutar cada opcion radial, revisa las listas de objetos de Smart
  Radial. Si una lista llega como coleccion Java en vez de tabla Lua, la convierte
  conservando sus elementos. Esto evita que el ordenamiento por cubetas aplique
  `#` a una coleccion no compatible.
- Los iconos de Drink Smart en el menu contextual se mantienen.

## Revision en Jill

Abre una bebida y una comida desde Smart Radial; confirma que la accion concluya,
que el item o el liquido cambie como corresponde y que no quede una accion activa
atascada. Abre tambien la categoria de especias. Revisa `DebugLog.txt` por el
marcador `native Smart Radial actions preserved` y confirma que no reaparezca
`bucketSort` / `__len not defined`.
