# ChilaSeda Fix - VisualSounds and Living World Proximity Colors (B42) 0.8.2
<div align="center">

[🏠 Repo](../README.md) · [🤝 Contribuir](../CONTRIBUTING.md) · [🚀 Releases](../docs/releases/README.md)

</div>

---


## Resumen

Version 0.8.2 leaves cue rotation to VisualSoundsKAViewpoint through `SDI.viewAngle`; this patch handles proximity and color only. Human zombie cues are red, Living World team members green, other Living World NPCs yellow, normal wildlife blue, and zombie wildlife fuchsia/purple.

Integra VisualSounds KA con los zombis cercanos y los 16 tipos de animales hostiles de Undead Wildlife. El mod de Workshop no expone una tabla Lua `VisualSoundsKA`; el parche anterior apuntaba a esa API inexistente y registraba que se omitía.

Cada 250 ms, el parche revisa los objetos vivos dentro de 15 baldosas y entrega al indicador `SDI` señales de proximidad para los zombis aunque no hayan emitido sonido. Esto solo crea señales visuales: no genera un `WorldSound` ni atrae zombis. Las señales se actualizan con la posicion actual y vencen al alejarse o morir la fuente. Se conservan los filtros de escucha, modo de busqueda y sigilo configurados en VisualSounds.

El parche pasa los sonidos de animales hostiles al canal de señales de zombis, para que sigan visibles aunque se ignoren sonidos genéricos `LAMBDA`. Muestrea objetos `IsoAnimal` cercanos cada 250 ms dentro del radio de 15 baldosas del detector de Workshop y actualiza las señales antes de que expire su duración predeterminada de un segundo. Así evita que el retorno temprano por fuente duplicada de Workshop haga parpadear los avisos de proximidad.

Los animales normales conservan los filtros de visibilidad y busqueda `LAMBDA` y usan una escala azul: azul intenso cerca y celeste mas claro lejos. Los animales zombi usan una escala fucsia a morado, de color intenso cerca a lavanda clara lejos. Los tipos `infected*` y `undead*` de Undead Wildlife conservan su identificacion por tipo. Los archivos originales de Workshop permanecen intactos.

## Dependencias y carga

- VisualSounds KA (`VisualSoundsKA`)
- Visual Sounds KA Viewpoint (`VisualSoundsKAViewpoint`)
- Undead Wildlife (`UndeadWildlife`)
- Living World is optional; it is used only to identify its NPC marks.

`mod.info` requiere los tres y carga este parche después de ellos. El ID local es `ChilaSeda_Fix_VisualSounds_UndeadWildlife_Colors_B42`.

## Tipos de animales

Reconoce estos tipos hostiles: `infectedraccoon`, `infectedcockerel`, `infectedchicken`, `infectedturkey`, `infectedrabbit`, `infectedpiglet`, `infectedfarmpig`, `infecteddeerdoe`, `infecteddeerstag`, `infectedcow`, `infectedcowcalf`, `infectedbull`, `infectedewe`, `infectedram`, `infectedlamb` e `infectedrat`. También reconoce otros tipos de Undead Wildlife que empiezan con `infected` o `undead`, incluidas variantes esqueléticas.

## Cambios

### 0.8.2

- Removes the local camera-yaw angle override. Cue placement and rotation now use the original VisualSounds render path and the Viewpoint compatibility addon's `SDI.viewAngle` implementation.
- Keeps the local color palettes and Living World proximity cues.

### 0.8.0

- Detects Living World NPCs through their `LivingWorldNPC` animation variable. Team members use a green distance gradient; other NPCs use orange/amber, separate from zombie wildlife's fuchsia palette.
- Routes NPC proximity cues through VisualSounds' `PLAYERS` category and respects its ignore-players, search-mode, crouch, and hearing-range settings. It does not emit game `WorldSound` events.

### 0.8.1

- Colors human zombie cues red, Living World allies green, and other Living World NPCs yellow.
- Keeps normal wildlife blue and zombie wildlife fuchsia/purple.

### 0.7.1

- Calculates the angle of synthetic zombie and animal proximity cues from Viewpoint's live camera yaw. When Viewpoint is inactive or the camera API is unavailable, it retains the VisualSounds default angle calculation. Cue colors and proximity behavior are unchanged.

### 0.7.0

- Detecta zombis vivos dentro de 15 baldosas aunque no produzcan sonidos, actualizando sus señales cada 250 ms.
- Refresca la duracion y posicion de cada señal y conserva los filtros de VisualSounds.
- No emite sonidos de mundo; solo alimenta el indicador visual.

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
