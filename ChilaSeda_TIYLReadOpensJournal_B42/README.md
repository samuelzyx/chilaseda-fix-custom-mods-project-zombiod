# ChilaSeda - Abrir Survivor Journal (B42)

<div align="center">

[🏠 Repo](../README.md) · [🤝 Contribuir](../CONTRIBUTING.md) · [🚀 Releases](../docs/releases/README.md)

</div>

---


La opción **Abrir diario** usa el icono de libro vanilla de B42 y queda detrás
de equipar/recetas en vez de ocupar la primera posición del menú.

Parche local para `ThisIsYourLife`. Al hacer clic derecho en la libreta propia, **Abrir diario** aparece al principio del menú. Se quitan **Leer** y **Volver a leer** para evitar que se inicie la lectura temporizada. El panel abre directamente desde inventario principal, mochilas anidadas, contenedores cercanos y cajuelas abiertas. La tecla K queda desactivada por defecto.

El parche deja **Open Survivor Journal** sin tecla predeterminada. Si el atajo guardado todavía es K, lo desactiva al iniciar la partida; se puede asignar otra tecla desde Controles.

El parche reconoce la libreta propia aunque el evento de inventario entregue varios objetos seleccionados o los agrupe dentro de una entrada de contenedor. Los diarios preservados de otros sobrevivientes mantienen su acción original.

El mod requiere `ThisIsYourLife` y debe cargarse después de él. La partida de Jill lo lleva al final de `mods.txt`.

La versión 0.3.0 quedó confirmada en partida por Chila. La versión 0.4.0 solo cambia la posición de **Abrir diario** en el menú; queda pendiente confirmar que aparezca entre las primeras opciones durante la siguiente sesión.


---

### 🔗 Otros enlaces de interés

- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
