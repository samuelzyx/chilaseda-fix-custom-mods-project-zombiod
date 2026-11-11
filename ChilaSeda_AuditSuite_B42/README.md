# ChilaSeda Audit Suite (B42) 2.1.3

One local ID bundles four independent tools: Error Magnifier session logs,
Mod Memory Audit, Performance Black Box, and Weight Monitor 1.9.8. Their Lua files
and feature documentation remain separate. The Java bridges are packaged into
one `ChilaSedaAuditSuite.jar`. Each exposed bridge class is in the exact
`chilaseda` package required by ZombieBuddy; helper classes remain grouped by
function.

All integrations are optional. Error Session Logs skips if Error Magnifier is
missing or its expected API is unavailable. Java-backed logging, performance
capture, and weight monitoring require ZombieBuddy's exposed bridge classes.
Mod Memory Audit continues writing its Lua session data and marks Java heap
windows unavailable when the bridge is absent. None of these tools changes
gameplay or item weights.

See `LEEME.txt` for installation and `Documentacion/` for each tool's details.


---

### 🔗 Otros enlaces de interés

- [Error Magnifier Session Logs (Audit Suite)](Documentacion/ErrorSessionLogs/README.md)
- [⚖️ Weight Monitor](Documentacion/WeightMonitor/README.md)
- [Wilderness QoL dentro de Traducciones ES](Documentacion/WildernessQoL/README.md)
- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
