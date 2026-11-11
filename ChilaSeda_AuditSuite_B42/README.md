# ChilaSeda Audit Suite | Build 42

<div align="center">

[🏠 Repo](../README.md) · [🤝 Contribuir](../CONTRIBUTING.md) · [🚀 Releases](../docs/releases/README.md)

</div>

---


[![Project Zomboid](https://img.shields.io/badge/Project%20Zomboid-Build%2042-52796F?style=for-the-badge)](https://store.steampowered.com/app/108600/Project_Zomboid/)
[![Local mod](https://img.shields.io/badge/ID-ChilaSeda_AuditSuite_B42-2D6A4F?style=for-the-badge)](42/mod.info)

> Herramientas locales para entender errores, uso de memoria, rendimiento y peso de objetos en una partida de Project Zomboid.

[Herramientas](#herramientas) | [Instalacion](#instalacion) | [Documentacion](#documentacion) | [Limites](#limites)

---

## Herramientas

| Modulo | Para que sirve | Cuando abrir sus datos |
| --- | --- | --- |
| **Error Session Logs** | Exporta a un archivo por sesion los errores que Error Magnifier ya detecto. | Al revisar un error Lua o comparar una sesion con `DebugLog.txt`. |
| **Mod Memory Audit** | Registra uso y cambios de memoria de los mods, con limites claros sobre lo que Lua puede observar. | Al buscar crecimiento sostenido de memoria; distingue medicion disponible de datos no observables. |
| **Performance Black Box** | Conserva una ventana antes y despues de un pico de rendimiento, con marcas de contexto. | Tras una pausa o tiron para correlacionar ticks, zeds cercanos y eventos registrados. |
| **Weight Monitor** | Registra pesos observados de objetos y compara objetivos por ID tecnico. | Al revisar masas incoherentes o preparar una meta razonada en el manual. |

Los cuatro modulos son independientes y no cambian gameplay, inventarios, XP ni el peso de los objetos. Los datos son evidencia para investigar; una correlacion temporal no demuestra por si sola la causa.

## Instalacion

Activa solo `ChilaSeda_AuditSuite_B42` en el perfil Jill. Los puentes Java estan agrupados en `ChilaSedaAuditSuite.jar` y requieren ZombieBuddy. Error Session Logs necesita ademas Error Magnifier. Si falta una API opcional, el modulo afectado registra que no esta disponible y los otros siguen funcionando.

## Documentacion

- [Error Session Logs](Documentacion/ErrorSessionLogs/README.md)
- [Mod Memory Audit](Documentacion/ModMemory/README.md)
- [Performance Black Box](Documentacion/Performance/README.md)
- [Weight Monitor](Documentacion/WeightMonitor/README.md)
- [Instalacion detallada](INSTALACION.md)
- [Historial de versiones](../docs/releases/CHANGELOG.md)

## Limites

La suite conserva archivos locales de diagnostico; no los subas con reportes publicos si contienen rutas o datos de tu equipo. Black Box no mide frame presentado, GPU, duracion exacta de cargas de chunk ni todas las pausas internas de Java. Las paginas de cada modulo explican campos ausentes y como leer los registros.

---

### Otros enlaces

[Inicio del repositorio](../README.md) · [Como contribuir](../CONTRIBUTING.md) · [Releases](../docs/releases/README.md)
