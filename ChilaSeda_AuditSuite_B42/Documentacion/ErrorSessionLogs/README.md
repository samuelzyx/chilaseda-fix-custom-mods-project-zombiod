# Error Magnifier Session Logs · Audit Suite

## Qué registra

Este componente guarda una vez por sesion los errores que Error Magnifier ya proceso. Si su API aun no esta lista cuando se evalua el archivo, la busca de nuevo cada segundo en el menu y durante la partida; un fallo inicial ya no cancela el exportador. Si la API o el puente Java de ZombieBuddy nunca estan disponibles durante la partida, no se crea un reporte. Los demas componentes de Audit Suite siguen funcionando.

Desde Error Session Logs 1.0.1, `[ChilaSeda Error Logs] Loaded` confirma que el recolector inicio un reporte para esa sesion. Si no hay reporte, no concluyas que no hubo errores: revisa primero el marcador en DebugLog/console.

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
