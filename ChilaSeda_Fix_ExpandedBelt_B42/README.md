# ChilaSeda Fix - Expanded Belt (B42) 1.0.0

## Objetivo

Este addon local adapta [B42] Expanded Belt (Workshop 3783401258, mod ID `Expanded_Belt_B42`) a Build 42.22+. Mantiene intacto el original de Workshop y carga despues de el.

El `Base.Belt2` actual conserva las etiquetas `base:hasmetal`, `base:buckle` y `base:scrapasbelt`, y expone la investigacion de `Forge_Buckle`. El objeto `ExpandedBelt.ExpandedBelt` del Workshop no las declara; por eso las recetas que buscan un cinturon para desarmar no lo reconocen y el objeto no anuncia esa receta investigable. El parche agrega solo esos campos al item existente.

## Dependencia y orden

- Requiere `Expanded_Belt_B42`.
- `loadModAfter=Expanded_Belt_B42` aplica la extension despues de la definicion del Workshop.
- `versionMin=42.22` limita el parche a Build 42.22 o posterior.

## Verificacion

Al iniciar el mundo, el registro `[ChilaSeda_ExpandedBeltCompat_B42]` confirma los tres tags y `Forge_Buckle`. Si falta el item, el API o un campo, una linea acotada registra `result=fallback` y el motivo.

En Jill, verificar el log de compatibilidad, que la receta de desarmar cinturon acepte Expanded Belt, que la receta de expandir siga funcionando y que al restaurar el cinturon los items de los dos slots extra vuelvan al inventario.
