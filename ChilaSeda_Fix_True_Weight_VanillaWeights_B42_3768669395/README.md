# ChilaSeda Fix · pesos vanilla y overrides (B42) 2.1.3

## Contenido del paquete

Incluye VanillaWeightFix y los overrides de peso para Any Wall Flags y Posters. Weight Monitor ahora forma parte de `ChilaSeda_AuditSuite_B42`.

## Reajuste de instancias

El reajuste de objetos accesibles corre una sola vez por episodio de sueno y solo si la salud esta completa (100). Si no esta al maximo, se omite hasta el siguiente sueno. No hay sondeo periodico mientras el personaje juega.

## Metas de peso documentadas

- `Base.Magazine_Rich` (`Alto Volador`): 0.10 kg. Es una estimación razonada a partir de revistas impresas comparables. La meta equivalente y su evidencia están en `docs/Manual_Pesos_B42_y_Monitor.md`.
- `Base.Ginseng`: meta de 0.02 kg para una raiz fresca, en lugar de los 0.10 kg vanilla; Weight Monitor 1.9.9 comprueba la misma meta.
- `Base.Machete` y `Base.Machete_Crude`: 0.71 kg; `Base.MacheteBlade_NoTang`, sin terminar: 0.48 kg. Las estimaciones usan la referencia de fabricación de UNIDO para un machete completo de 0.71 kg y un cuerpo de 0.48 kg. Weight Monitor 1.9.9 usa las mismas metas, incluida la nueva meta de ginseng.

## Dependencias opcionales

`TrueWeight`, `ThisIsYourLife`, `ExtendedVanillaWeapons`, `AnimalRemasterApproved`, `DGVFlags` y `DGVPosters` son opcionales. Las correcciones recorren las definiciones de objetos cargadas e ignoran los objetivos de mods ausentes; no hay requisitos estrictos.

Consulta `docs/Manual_Pesos_B42_y_Monitor.md` para ver las metas y su evidencia.

---

### 🔗 Otros enlaces de interés

- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
