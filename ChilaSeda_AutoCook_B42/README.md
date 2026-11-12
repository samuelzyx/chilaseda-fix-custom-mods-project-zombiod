# ChilaSeda AutoCook Fixes · B42 2.0.11

<div align="center">

[🏠 Repo](../README.md) · [🤝 Contribuir](../CONTRIBUTING.md) · [🚀 Releases](../docs/releases/README.md)

</div>

---


> Paquete local con movilidad y reanudación de AutoCook, finalización segura de comidas y reparación de ingredientes envenenados. Cada función conserva su propio script Lua.

## Funciones

- **Moverse y reanudar:** permite caminar y apuntar durante acciones de AutoCook, reanuda después de otras acciones en cola y admite cancelación explícita.
- **Limpiar ingredientes:** retira los ingredientes agotados después de que AutoCook los usa.
- **Finalizar comidas de forma segura:** permite terminar una comida preparada con ingredientes seguros y conserva el filtro original de AutoCook para preparar comidas nuevas.
- **Retirar ingredientes venenosos:** registra cada ingrediente que aporta veneno y los cambios que causa en la comida. Al hacer clic derecho en una ensalada ya mezclada, la opción muestra los nombres y cantidades registrados antes de retirarlos, para identificar el origen sin adivinar por el icono. Al confirmar, elimina esos ingredientes y revierte sus valores nutricionales y su contribución venenosa. Las comidas preparadas antes de activar este registro no contienen historial por ingrediente y no pueden repararse de forma fiable.
- **Devolver recipientes:** recuerda la mochila de origen cuando AutoCook toma un tazón u olla, devuelve allí el recipiente de la comida terminada y avisa el destino con Halo. Si la mochila no tiene espacio, deja el objeto en el piso e indica ese destino.
- **Compatibilidad B42:** evita usar la global `next`, que no está disponible, al retirar veneno.
- **Tooltip nutricional:** muestra calorías, carbohidratos, proteínas y grasas para todos los personajes con las etiquetas y valores traducidos del juego. El panel dibuja primero el fondo y despues el texto nativo y el bloque de macros; las etiquetas y valores custom usan blanco solido. Nutritionist conserva el tooltip nativo. Normaliza alturas antes de operar con campos Java de B42, usa el origen fijo vanilla porque `ISToolTipInv` no expone `padLeft`, y calcula el bloque de macros una sola vez debajo de las filas nativas.
- **Solo alimentos con nutrición:** omite objetos `Food` no comestibles sin valores nutritivos, incluidas las plumas de pollo y pavo.

La opción de inventario **Reanudar AutoCook** usa el icono vanilla B42 de olla y queda después de recetas y acciones de equipar nativas cuando están presentes. **Retirar ingredientes venenosos** usa el icono vanilla de veneno para ratas; no requiere textura propia.

## Dependencias y archivos

AutoCook es opcional. Cada script lo carga con `pcall`, verifica las funciones que modifica y omite su integración con un mensaje breve si AutoCook falta o cambió su API. `loadModAfter=AutoCook` solo afecta el orden cuando está instalado.

Los archivos de Workshop permanecen intactos. El ID local consolidado es `ChilaSeda_AutoCook_B42`. Las notas históricas de Safe Meal Completion están en `Documentacion/AutoCookSafeCompletion_1.1.0.md` y `README.md`.

---

### 🔗 Otros enlaces de interés

- [ChilaSeda - AutoCook Safe Meal Completion (B42)](Documentacion/AutoCookSafeCompletion_1.1.0.md)
- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
