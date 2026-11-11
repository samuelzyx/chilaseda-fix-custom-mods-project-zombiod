# Error Magnifier Session Logs · Audit Suite

## Qué registra

Este componente guarda una vez por sesión los errores que Error Magnifier ya procesó. No declara una dependencia obligatoria. Si falta Error Magnifier o no puede cargar la API esperada, registra un único mensaje de omisión y termina. Si no está disponible el puente Java de ZombieBuddy, no escribe archivos de sesión; los demás componentes de Audit Suite siguen funcionando.

## Archivos y alcance

Los reportes se guardan bajo `mods/ErrorLogs` en la carpeta de caché activa de Project Zomboid. Conserva los reportes existentes: el exportador no reemplaza Error Magnifier ni escribe en `Errors.txt`.

El código fuente y los archivos de prueba se conservan en `source/errorlogs/` y `tests/errorlogs/`.

---

### 🔗 Otros enlaces de interés

- [⬅️ Inicio del mod](../../README.md)
- [⚖️ Weight Monitor](../WeightMonitor/README.md)
- [Wilderness QoL dentro de Traducciones ES](../WildernessQoL/README.md)
- [🏠 Inicio del repositorio](../../../README.md)
- [🤝 Cómo contribuir](../../../CONTRIBUTING.md)
- [🚀 Releases de mods](../../../docs/releases/README.md)
