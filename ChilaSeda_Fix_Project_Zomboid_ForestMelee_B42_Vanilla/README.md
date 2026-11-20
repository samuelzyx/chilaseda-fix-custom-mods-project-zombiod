# Forest Melee Through Vegetation · B42

## Qué corrige

Parche local del combate vanilla, independiente de Viewpoint. Durante la comprobación de un ataque cuerpo a cuerpo del jugador contra un zombi vivo, solo elimina el bloqueo de la línea de ataque si el obstáculo es vegetación del bosque y la trayectoria no cruza una barrera sólida como una pared, reja, puerta, ventana u objeto sólido. Si el caso no es claro, conserva el resultado vanilla.

## Dependencias y validación

Requiere ZombieBuddy. No modifica los originales de Workshop. La validación dentro de Jill sigue pendiente.

---

### 🔗 Otros enlaces de interés

- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)

## 1.0.1 - Fix ZombieBuddy package discovery

Repackages the existing five compiled classes with standard forward-slash Java package paths and a manifest. The previous Windows-created JAR stored backslashes in its ZIP entry names, so ZombieBuddy could not match the `chilaseda.viewpointfixes` package declared in `mod.info`. All five class SHA-256 hashes remain unchanged. In-game validation is still pending.

## 1.0.2 - Fix inlined advice access

Makes `MeleeTargetContext` and the members used by the inlined `CombatManager` advice public. ZombieBuddy applies the advice inside `zombie.CombatManager`; package-private helper access caused a fatal `IllegalAccessError` during target validation. The source is included under `Source/`. The existing targeting logic and the other patch classes are unchanged. In-game validation is pending.
