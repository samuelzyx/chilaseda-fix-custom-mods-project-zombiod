# ChilaSeda Weight Monitor — Audit Suite 2.1.2

Weight Monitor se trasladó a `ChilaSeda_AuditSuite_B42` junto con las otras
auditorías. Sus metas, etiquetas y formato de registro no cambiaron. Los arreglos
de peso siguen en `ChilaSeda_Fix_True_Weight_VanillaWeights_B42_3768669395`.

`Base.Magazine_Rich` (`“Alto Volador”`) tiene una meta de 0.10 kg, sincronizada
con VanillaWeightFix. La lectura Jill de 0.100 kg de la sesión 08/11 quedó
`REVISAR` porque todavía no existía meta; es anterior a este cambio y no cuenta
como validación `OK`. La evidencia está en `docs/Manual_Pesos_B42_y_Monitor.md`.

El monitor acepta rangos por objeto para pesos variables: `DeadRatSkinned`,
`Salad` y `PotOfStew` muestran sus límites y quedan `OK` cuando todas las
lecturas individuales entran en el rango. El log conserva `target=sin_meta`
para compatibilidad y agrega `targetRange=min..max`. Las metas propuestas y
su evidencia están en `docs/Manual_Pesos_B42_y_Monitor.md`.

El monitor solo inicia sesión, panel y escaneos si está disponible el puente
Java de ZombieBuddy. Sin ese puente, no abre un panel vacío ni comienza un
escaneo. Conserva las mismas metas documentadas en
`docs/Manual_Pesos_B42_y_Monitor.md`.
