# ChilaSeda Audit Suite · B42 2.1.3

## Herramientas incluidas

Un único ID local reúne cuatro herramientas independientes: registros de sesión de Error Magnifier, Mod Memory Audit, Performance Black Box y Weight Monitor 1.9.8. Sus archivos Lua y documentación se mantienen separados. Los puentes Java se empaquetan en `ChilaSedaAuditSuite.jar`; cada clase pública usa el paquete `chilaseda` que requiere ZombieBuddy y las clases auxiliares siguen agrupadas por función.

## Integraciones y dependencias

Todas las integraciones son opcionales. Los registros de Error Magnifier se omiten si falta el mod o su API esperada. El registro Java, la captura de rendimiento y el monitoreo de pesos requieren los puentes expuestos por ZombieBuddy. Mod Memory Audit continúa guardando sus datos de sesión Lua y marca como no disponibles las lecturas de heap Java si falta ese puente.

Audit Suite no cambia la jugabilidad ni los pesos de objetos. La instalación está en `LEEME.txt`; los detalles de cada herramienta, en `Documentacion/`.

---

### 🔗 Otros enlaces de interés

- [Error Magnifier Session Logs (Audit Suite)](Documentacion/ErrorSessionLogs/README.md)
- [⚖️ Weight Monitor](Documentacion/WeightMonitor/README.md)
- [Wilderness QoL dentro de Traducciones ES](Documentacion/WildernessQoL/README.md)
- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
