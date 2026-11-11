# Contribuir

Las contribuciones se revisan mediante Pull Requests. No está autorizado trabajar directamente en `main` ni subir commits a esa rama.

1. Crea una rama para tu cambio, por ejemplo `fix/nombre-del-arreglo`, `feature/nombre` o `docs/tema`.
2. Haz commits en esa rama y súbela a GitHub.
3. Abre un Pull Request dirigido a `main` y describe el problema, los cambios, dependencias y cómo los revisaste.
4. Espera la revisión y autorización de Chila antes de integrar el cambio.

Para cambios en mods, mantén intactas las copias de mods originales e implementa los arreglos dentro del mod local correspondiente. Documenta el arreglo, dependencias y orden de carga en el README o LEEME del mod. Indica la versión de Project Zomboid y los mods relacionados que usaste para revisar el cambio.

No agregues partidas guardadas, registros de usuario, backups, credenciales, cachés, datos personales ni compilados temporales. Conserva únicamente los binarios que formen parte de la distribución del mod (por ejemplo, JARs incluidos por un parche).

Las skills y hooks compartidos de Codex viven en `.agents/` y `.codex/`. Ajusta cualquier integración de usuario para que use rutas relativas del repositorio.
