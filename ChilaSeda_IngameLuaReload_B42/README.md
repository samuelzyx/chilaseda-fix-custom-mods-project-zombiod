ChilaSeda - Recargar Lua dentro de partida (B42)

<div align="center">

[🏠 Repo](../README.md) · [🤝 Contribuir](../CONTRIBUTING.md) · [🚀 Releases](../docs/releases/README.md)

</div>

---


Version 0.1.3
  En el modal Si/No, las etiquetas Si [E] y No [Esc] aparecen arriba de sus botones; E confirma y Escape cancela.
  El modal queda excluido del hook global para evitar registrar dos veces los mismos atajos.

Uso:
  En una partida individual, pulsa Ctrl+Shift+F10 para abrir el modal.

El juego reinicia el entorno Lua y vuelve a cargar el guardado actual. Guarda primero:
el mod no guarda automaticamente el mundo y los avances posteriores al ultimo guardado
podrian perderse.

No funciona en multijugador. Requiere Build 42.21.
