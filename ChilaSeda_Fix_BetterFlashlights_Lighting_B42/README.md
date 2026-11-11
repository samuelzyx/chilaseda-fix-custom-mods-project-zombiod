# ChilaSeda Fix · Better Flashlights + Project Viewpoint (B42)

> Parche local de iluminación para usar Better Flashlights con Project Viewpoint.
> Conserva intactos los dos mods de Workshop.

## Qué corrige

## Cambios

- Mantiene la luz de la linterna equipada mientras el personaje sigue en la misma baldosa y mira
  en la misma dirección; evita recrearla cada tres ticks.
- Usa el vector frontal del personaje sin invertirlo, como hace la proyección de Better Flashlights.
  Invertirlo dirige el haz detrás de Jill. En las capturas del 6 de noviembre, Jill miraba al oeste
  (270°), pero el haz se desplazaba hacia arriba; el halo y el radio del haz se mantienen compactos.
- Evita el parpadeo que causaba la recreación repetida de fuentes de luz en el render asíncrono de
  Project Viewpoint.
- Reduce de 6 a 3 baldosas el radio fijo de la antorcha de Better Flashlights cuando cae al suelo.

Las acciones de linterna conservan los iconos vanilla B42 de antorcha y batería. Los interruptores
de luces en el piso siguen las opciones nativas de recoger y tomar.

## Dependencias y carga

Requiere Better Flashlights 2.4.16 (`BetterFlashlightsFixed`, Workshop 3420478458) y Project
Viewpoint (`ProjectViewpointQOLLegacy0.1.6`). `mod.info` carga este parche después de ambos y solo
sobrescribe las dos rutas Lua correspondientes. Si Workshop modifica esos archivos, compara la nueva
versión con el parche antes de actualizarlo.

## Estado de validación

Falta confirmar en Jill la dirección del haz, el parpadeo y el radio de la linterna caída.


---

### 🔗 Otros enlaces de interés

- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
