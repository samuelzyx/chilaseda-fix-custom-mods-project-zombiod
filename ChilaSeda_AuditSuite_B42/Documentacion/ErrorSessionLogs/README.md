# Error Magnifier Session Logs (Audit Suite)

This component records Error Magnifier's parsed errors once per session. It
requires no mod by declaration. If Error Magnifier is absent or its expected
API cannot be loaded, the component prints one skip message and returns. If the
ZombieBuddy Java bridge is unavailable, it does not write session files; the
other audit components continue independently.

Reports are written under `mods/ErrorLogs` in the active PZ cache directory.
Existing reports are preserved. The exporter does not replace Error Magnifier
or write to its `Errors.txt` file.

Source and harness files are preserved under `source/errorlogs/` and
`tests/errorlogs/`.

---

### 🔗 Otros enlaces de interés

- [⬅️ Inicio del mod](../../README.md)
- [⚖️ Weight Monitor](../WeightMonitor/README.md)
- [Wilderness QoL dentro de Traducciones ES](../WildernessQoL/README.md)
- [🏠 Inicio del repositorio](../../../README.md)
- [🤝 Cómo contribuir](../../../CONTRIBUTING.md)
- [🚀 Releases de mods](../../../docs/releases/README.md)
