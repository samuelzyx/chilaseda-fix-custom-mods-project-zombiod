# ChilaSeda Fix · PZ Custom Intros (B42)

> Addon local para PZ Custom Intros en Project Zomboid B42.22.2.

## Problema y solución

La intro de carga del mod de Workshop accedía a `Core.gameMode` como `String`, pero B42.22.2 declara
ese campo como `GameMode`; la diferencia de descriptor producía `NoSuchFieldError`. El addon
reemplaza únicamente `Boot.beginLoading()` y usa `Core.getInstance().getGameMode()` para comprobar el
modo Tutorial. Conserva la selección, la historia, el canvas, el control de carga, la música y el
fallback vanilla originales.

## Dependencias y alcance

Requiere `PZCustomIntros` y `ZombieBuddy`. No modifica los archivos de Workshop.

## Cambios en 1.0.1

- Dirige el advice integrado de ZombieBuddy a través de una entrada puente pública. Evita
  `IllegalAccessError` cuando se ejecuta dentro de `Boot` y llama a los helpers del addon local.


---

### 🔗 Otros enlaces de interés

- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
