# 📜 Cambios y versiones

Este archivo separa el trabajo que ya está en `main` de los paquetes publicados como GitHub
Releases. **Estar en el repositorio no significa que ya exista un ZIP de Release.** Una
validación en Jill solo se considera confirmada cuando se comprueba dentro del juego.

## 🛠️ Cambios recientes incluidos en el repositorio

### Project Viewpoint · parches locales

- **2.0.37** — al equipar armas desde cadáveres, conserva el destino vanilla del inventario
  principal durante la transferencia. La revisión en Jill sigue pendiente.
- **2.0.36** — agrega la barra naranja delgada y etiquetada a rebusque, despiezar y beber; la
  barra nativa solo se suprime después de dibujar la personalizada. Falta validación runtime.

### Accessible Actions

- **1.0.20** — permite desmantelar un reloj desde el inventario de un cadáver sin moverlo antes
  a la mochila. Falta validación runtime.
- **1.0.19** — permite seleccionar y eliminar objetos y comida desde el panel Suelo. Falta
  validación runtime.
- **1.0.18** — filtra objetos de Viewpoint antes de consultar su item y corrige la firma del
  callback para reducir grasa desde una mochila secundaria. Falta validación runtime.

### AutoCook

- **2.0.9** — muestra macros solo cuando el alimento tiene datos nutritivos reales y respeta
  `isCantEat`. Falta validación runtime.
- **2.0.8** — corrige la retirada de ingredientes venenosos y devuelve el recipiente a su
  contenedor de origen; el Halo avisa si debe caer al piso. Falta validación runtime.

### Otros parches

- **Poison Knowledge Icon 0.2.0** — sincroniza el nombre del veneno conocido y muestra el icono
  correspondiente en tooltip, inventario, objetos del mundo y pines de rebusque. Falta
  validación runtime.
- **Recent Map Symbols 0.2.6** — carga Recientes al abrir el mapa y acepta búsquedas parciales.
  Falta validación runtime.
- **MiniCompass Position 0.1.1** — conserva la posición del compás que Jill ajustó arrastrándolo.
  Falta validación runtime.
- **Viewpoint Foraging 0.3.0 + parche local 1.3.15** — incorpora el calibrador y el ajuste de
  altura de pines; queda pendiente la revisión completa de la siguiente sesión.
- **PZ Custom Intros 1.0.1** — el parche usa el puente público compilado para Build 42.22.2.
  Falta validación runtime.

> 🧪 Estos cambios constan en las notas de trabajo del 10 de noviembre de 2026. La marca
> «falta validación runtime» significa que la revisión de Chila sigue pendiente.

## 📦 GitHub Releases publicadas

**Todavía no hay Releases individuales publicadas.** Al completar y validar una versión,
agregaremos aquí su fecha de publicación y enlace de descarga. La lista pública se consulta en
[Releases](https://github.com/samuelzyx/chilaseda-fix-custom-mods-project-zombiod/releases).

## 🗂️ Cambios del repositorio · 2026-11-11

- Se ordenaron las instrucciones del kit Jill y se retiró el RAR local de la distribución.
- Se corrigieron los enlaces de cabecera del README y se añadió promoción a los canales de
  ChilaSeda.
- Se mejoraron las guías del kit Jill y de contribución; se documentaron el changelog por mod,
  los paquetes individuales y las opciones para seguir Releases con Watch o Atom/XML.
