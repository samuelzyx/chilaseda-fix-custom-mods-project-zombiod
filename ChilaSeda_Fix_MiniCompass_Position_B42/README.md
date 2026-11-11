# Mini Compass: posicion persistente (Build 42)

<div align="center">

[Repo](../README.md) | [Contribuir](../CONTRIBUTING.md) | [Releases](../docs/releases/README.md)

</div>

---


Este parche local acompana a [Mini Compass en Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3772670381), un HUD arrastrable que muestra el rumbo de Jill.

## Problema que corrige

Mini Compass guarda la ubicacion al soltar el HUD y la conserva en `Zomboid/Lua`. La API original podia usar el nombre de la cuenta de Steam para escribir, pero la identidad del personaje para la partida es distinta. El archivo del jugador Jill es `MiniCompass_Position_user_JillValentine.txt`; si se guardaba bajo otra clave, el siguiente inicio no recuperaba el ultimo arrastre.

La version local 0.1.2 fuerza una clave estable tomada de `player:getUsername()` tanto al leer como al escribir. Esto mantiene la posicion por personaje aunque se carguen copias de la partida con nombres distintos. La posicion se guarda al soltar el compas mediante el flujo original de Workshop y se restaura despues de crear el jugador.

## Instalacion

Activa `MiniCompass` y `ChilaSeda_Fix_MiniCompass_Position_B42`. El parche declara `require=MiniCompass` y `loadModAfter=MiniCompass`; no reemplaces ni edites el original de Workshop.

Para validar, mueve el compas, sal de la partida y carga una copia con otro nombre. La posicion debe coincidir con el ultimo arrastre. Esa comprobacion en Jill sigue pendiente; no se anuncia como validada.

## Navegacion

- [Inicio del repositorio](../README.md)
- [Como contribuir](../CONTRIBUTING.md)
- [Historial y Releases](../docs/releases/README.md)
