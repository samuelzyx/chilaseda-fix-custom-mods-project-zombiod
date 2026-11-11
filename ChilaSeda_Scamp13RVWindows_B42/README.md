# Scamp 13 · ventanas interiores del RV (prototipo)

> Addon local para un jugador para `Base.Trailer87Scamp13` de KI5. Usa la API `RVHooks` de PROJECT RV Interior y no reemplaza archivos de Workshop ni binarios del mapa.

## Cambios en el vehículo

Al entrar, reemplaza cuatro segmentos exteriores de pared por ventanas fijas con marco cromado: tres laterales y una trasera. Retira los `IsoZombie` exteriores del espacio reservado de 60 baldosas al entrar y cada 30 ticks de juego; deja intactos los zombis y animales dentro de la habitación asignada.

Al salir del RV normalmente, restaura los objetos de pared reemplazados. Los cambios de objetos requieren que el chunk del cuadrado esté cargado; la limpieza omite cuadrados que ya comenzaron a descargarse, evitando llamadas `AddTileObject` y de pathfinding sobre datos obsoletos.

No rompas las ventanas de prueba ni intentes trepar por ellas; sal mediante la opción contextual del RV.

## Revisión visual pendiente

La primera revisión dentro del juego aún debe confirmar la selección de paredes, la disposición de los modelos, la luz diurna y la orientación de las ventanas.

---

### 🔗 Otros enlaces de interés

- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
