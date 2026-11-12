# ChilaSeda Fix · colores de VisualSounds para Undead Wildlife (B42) 0.6.0

<div align="center">

[🏠 Repo](../README.md) · [🤝 Contribuir](../CONTRIBUTING.md) · [🚀 Releases](../docs/releases/README.md)

</div>

---


## Resumen

Integra los 16 tipos de animales hostiles de Undead Wildlife con el indicador de dirección de sonido `SDI` de VisualSounds KA. El mod de Workshop no expone una tabla Lua `VisualSoundsKA`; el parche anterior apuntaba a esa API inexistente y registraba que se omitía.

El parche pasa los sonidos de animales hostiles al canal de señales de zombis, para que sigan visibles aunque se ignoren sonidos genéricos `LAMBDA`. Muestrea objetos `IsoAnimal` cercanos cada 250 ms dentro del radio de 15 baldosas del detector de Workshop y actualiza las señales antes de que expire su duración predeterminada de un segundo. Así evita que el retorno temprano por fuente duplicada de Workshop haga parpadear los avisos de proximidad.

Los animales normales conservan los filtros de visibilidad y busqueda `LAMBDA` y usan una escala azul: azul intenso cerca y celeste mas claro lejos. Los animales zombi usan una escala fucsia a morado, de color intenso cerca a lavanda clara lejos. Los tipos `infected*` y `undead*` de Undead Wildlife conservan su identificacion por tipo. Los archivos originales de Workshop permanecen intactos.

## Dependencias y carga

- VisualSounds KA (`VisualSoundsKA`)
- Visual Sounds KA Viewpoint (`VisualSoundsKAViewpoint`)
- Undead Wildlife (`UndeadWildlife`)

`mod.info` requiere los tres y carga este parche después de ellos. El ID local es `ChilaSeda_Fix_VisualSounds_UndeadWildlife_Colors_B42`.

## Tipos de animales

Reconoce estos tipos hostiles: `infectedraccoon`, `infectedcockerel`, `infectedchicken`, `infectedturkey`, `infectedrabbit`, `infectedpiglet`, `infectedfarmpig`, `infecteddeerdoe`, `infecteddeerstag`, `infectedcow`, `infectedcowcalf`, `infectedbull`, `infectedewe`, `infectedram`, `infectedlamb` e `infectedrat`. También reconoce otros tipos de Undead Wildlife que empiezan con `infected` o `undead`, incluidas variantes esqueléticas.

## Cambios

### 0.4.0

- Sustituye los hooks de métodos de color inexistentes en `VisualSoundsKA` por hooks sobre `SDI`.
- Actualiza las señales de animales zombis con su posición en vivo y usa texturas cian/magenta.
- Corrige la dependencia de carga para requerir VisualSounds KA.

### 0.5.0

- Detecta animales normales y zombificados cercanos aunque no produzcan sonido en el mundo, siguiendo el rango y el muestreo de distancia de los zombis en VisualSoundsKA.
- Actualiza en vivo la posición de las señales de animales normales y hostiles.

### 0.6.0

- Reconoce definiciones `infected*` y `undead*` como señales hostiles.
- Mantiene actualizadas las señales mientras los animales sigan cerca, evitando el retorno temprano por fuente duplicada y el vencimiento predeterminado de un segundo.
- Asigna a la fauna normal una paleta turquesa a ámbar y reserva cian a magenta para la fauna hostil.

---

### 🔗 Otros enlaces de interés

- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
