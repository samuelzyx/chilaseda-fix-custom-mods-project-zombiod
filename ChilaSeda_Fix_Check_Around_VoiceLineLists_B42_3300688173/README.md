# Check Around · reparación de listas de voces

> Parche local para Check Around 1.4.0 en Project Zomboid B42.21.

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
