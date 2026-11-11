# ChilaSeda Fix · formato de NeatUI Core

## Qué corrige

Evita el cierre del menú de opciones de NeatUI Core causado por los signos de porcentaje sin escapar en las etiquetas `ICON_SCALE` y `OPACITY`. El parche escapa esos signos justo antes de que Project Zomboid construya el panel; las etiquetas visibles no cambian.

## Dependencias y alcance

Requiere [NeatUI - Grid Inventory](https://steamcommunity.com/sharedfiles/filedetails/?id=3818729237) y se carga después de su página de opciones y de los hooks de opciones de Viewpoint. No modifica el mod de Workshop ni los datos del mundo.

---

### 🔗 Otros enlaces de interés

- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
