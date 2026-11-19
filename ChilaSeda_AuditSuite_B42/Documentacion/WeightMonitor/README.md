# Weight Monitor · Audit Suite 2.1.5


<div align="center">

[<- Audit Suite](../../README.md) · [Error Logs](../ErrorSessionLogs/README.md) · [Memoria](../ModMemory/README.md) · [Rendimiento](../Performance/README.md) · [Pesos](../WeightMonitor/README.md)

</div>

## Estado y metas

Weight Monitor se trasladó a `ChilaSeda_AuditSuite_B42` junto con las demás herramientas de auditoría. Sus metas, etiquetas y formato de registro no cambiaron. Las correcciones de pesos siguen en `ChilaSeda_Fix_True_Weight_VanillaWeights_B42_3768669395`.

`Base.Magazine_Rich` (`Alto Volador`) tiene una meta de 0.10 kg sincronizada con VanillaWeightFix. La lectura de Jill de 0.100 kg en la sesión del 08/11 quedó `REVISAR` porque entonces aún no existía una meta; es anterior al cambio y no cuenta como validación `OK`. La evidencia está en `docs/Manual_Pesos_B42_y_Monitor.md`.

`Base.Ginseng` ahora tiene meta de 0.02 kg por raiz fresca, sincronizada con Weight Fixes 2.1.3. El log Weight Monitor 1.9.8 de Jill del 18/11 23:39:45 -06:00 registro 26 unidades a 0.10 kg (2.60 kg total) con `target=sin_meta`; esa lectura es anterior a la meta nueva y no sirve como validacion. La estimacion de 20 g y sus fuentes estan en `docs/Manual_Pesos_B42_y_Monitor.md`.

## Rangos de peso variable

`DeadRatSkinned`, `Salad` y `PotOfStew` admiten rangos por objeto y quedan `OK` cuando cada lectura está dentro de sus límites. El log conserva `target=sin_meta` por compatibilidad y añade `targetRange=min..max`. Las metas propuestas y sus fuentes también están en `docs/Manual_Pesos_B42_y_Monitor.md`.

## Puente Java

El monitor solo inicia la sesión, el panel y los escaneos si está disponible el puente Java de ZombieBuddy. Sin ese puente, no abre un panel vacío ni inicia un escaneo.

---

### 🔗 Otros enlaces de interés

- [⬅️ Inicio del mod](../../README.md)
- [Error Magnifier Session Logs (Audit Suite)](../ErrorSessionLogs/README.md)
- [Wilderness QoL dentro de Traducciones ES](../WildernessQoL/README.md)
- [🏠 Inicio del repositorio](../../../README.md)
- [🤝 Cómo contribuir](../../../CONTRIBUTING.md)
- [🚀 Releases de mods](../../../docs/releases/README.md)
