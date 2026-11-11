# Mini Compass: posicion persistente (Build 42) 0.1.3

<div align="center">

[Repo](../README.md) | [Contribuir](../CONTRIBUTING.md) | [Releases](../docs/releases/README.md)

</div>

---


Este parche local acompana a [Mini Compass en Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3772670381), un HUD arrastrable que muestra el rumbo de Jill.

## Problema que corrige

Mini Compass guarda la ubicacion al soltar el HUD y la conserva en `Zomboid/Lua`. La API original podia usar el nombre de la cuenta de Steam para escribir, pero la identidad del personaje para la partida es distinta. El archivo del jugador Jill es `MiniCompass_Position_user_JillValentine.txt`; si se guardaba bajo otra clave, el siguiente inicio no recuperaba el ultimo arrastre.

La version local 0.1.2 fuerza una clave estable tomada de `player:getUsername()` tanto al leer como al escribir. Esto mantiene la posicion por personaje aunque se carguen copias de la partida con nombres distintos. La posicion se guarda al soltar el compas mediante el flujo original de Workshop.

## Version local 0.1.3

La posicion confirmada se aplica en cuanto el HUD ya existe, aunque la partida siga pausada. `OnCreatePlayer` intenta restaurarla al crear al jugador; si Mini Compass todavia no creo su panel, `OnTickEvenPaused` reintenta sin esperar a despausar. La restauracion por `OnTick` sigue como respaldo.

## Instalacion

Activa `MiniCompass` y `ChilaSeda_Fix_MiniCompass_Position_B42`. El parche declara `require=MiniCompass` y `loadModAfter=MiniCompass`; no reemplaces ni edites el original de Workshop.

Chila confirmo que la posicion guardada se recupera. Falta validar en Jill que aparezca en su lugar mientras la partida continua pausada, sin esperar a reanudar la simulacion.

## Navegacion

- [Inicio del repositorio](../README.md)
- [Como contribuir](../CONTRIBUTING.md)
- [Historial y Releases](../docs/releases/README.md)
