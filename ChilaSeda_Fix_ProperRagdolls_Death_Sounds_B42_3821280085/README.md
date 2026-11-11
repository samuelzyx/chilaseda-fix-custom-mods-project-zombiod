# ChilaSeda Fix · sonidos de muerte de Proper Ragdolls (B42)

<div align="center">

[🏠 Repo](../README.md) · [🤝 Contribuir](../CONTRIBUTING.md) · [🚀 Releases](../docs/releases/README.md)

</div>

---


> Parche local para [Proper Ragdolls](https://steamcommunity.com/sharedfiles/filedetails/?id=3821280085). Se carga después del mod original.

## Qué cambia

- Conserva intactos los XML de animación de muerte y los eventos `PlayDeathSound` de Proper Ragdolls.
- Detiene los alias de voz `MaleZombieDeath` y `FemaleZombieDeath` cuando empieza la animación de muerte personalizada.
- Conserva el impacto `BodyHitGround`, además de la velocidad y duración originales de la animación.
- Cuando termina la voz, permite hacer clic derecho en el zombi que aún cae y elegir **Loot dead zombie / Saquear zombi muerto**. El panel vanilla abre el inventario del zombi y la opción permanece disponible durante toda la animación.
- Cuando aparece el cadáver, cambia el panel abierto a su contenedor si el juego creó uno separado; espera a que el contenedor esté disponible para hacer el traspaso.

El icono de la opción de botín temprano usa la mochila vanilla B42 y queda después de la primera opción nativa de botín.

## Comportamiento que conserva

Proper Ragdolls activa `prdDone=true` al 90 % de sus clips de muerte personalizados y después habilita `ragdollFall`. Este addon no cambia el clip ni el momento en que el cuerpo se convierte en cadáver.

## Versión 1.3.0

Elimina el temporizador fijo de dos segundos. Limpia un marcador `prdDeath` obsoleto en `OnZombieDead` y observa el evento XML `SetVariable prdDeath=PRDeath_*`, que ocurre al inicio del clip personalizado. El parche corta la voz y habilita el botín temprano al detectar ese marcador, sin alterar el clip, el sonido de impacto ni el momento de conversión del cadáver.

Los archivos de Workshop permanecen intactos.

---

### 🔗 Otros enlaces de interés

- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](../docs/releases/README.md)
