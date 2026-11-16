# Check Around · reparación de listas de voces

## Version 0.1.2

- Corrige el error al iniciar Check Around desde una puerta en Build 42.22. `rollCreek` llamaba la API retirada `HasTrait("nombre")`; el parche usa `hasTrait(CharacterTrait)` y conserva compatibilidad con la API anterior. La barra puede completar el inicio de la accion y su vector de barrido queda inicializado.

> Parche local para [Check Around 1.4.0](https://steamcommunity.com/sharedfiles/filedetails/?id=3300688173), hoy marcado como deprecated en Workshop, en Project Zomboid Build 42.22.2.

## Qué hace

Comprueba las dos listas de voces que `ISCheckBehindObject` selecciona para puertas y ventanas. Si
reconoce el objetivo pero falta una lista, recupera la correspondiente de Check Around y registra en
`DebugLog` la clase del objeto y la forma de las listas. Si la lista sigue siendo inválida, omite solo
esa línea de voz para permitir que termine la acción temporizada.

## Alcance y diagnóstico

El parche responde al fallo observado en `ApplyVoiceline`, `CheckAround.lua:86`. Mantiene disponibles
las trazas de diagnóstico para identificar la causa en tiempo de ejecución y no modifica los archivos
de Workshop de Check Around ni de Doggy's Library.

---

### 🔗 Otros enlaces de interés

- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
