# ChilaSeda - Reemplazo rapido de armas rotas (Build 42) 1.0.0

Cuando un arma melee o cuchillo se rompe al golpear, aparece un aviso Halo con dos atajos:

- `Ctrl+A`: equipa la siguiente arma del mismo tipo que encuentre.
- `Ctrl+S`: equipa un arma melee de otra clase.

La busqueda recorre el inventario principal, las mochilas contenidas y las mochilas equipadas. El juego conserva su accion vanilla de transferencia y equipamiento. Si no encuentra un reemplazo, muestra un aviso y deja las manos como las haya dejado el juego.

En las opciones de mods se pueden cambiar las teclas que acompanan a Ctrl. El modificador Ctrl se conserva. Las teclas usadas por el mod se consumen durante el atajo para que no ejecuten su accion base.

Las trazas `[ChilaSeda_AutoEquipBrokenWeapon]` informan la carga, las teclas cargadas, la deteccion de rotura, el resultado del recorrido de inventario, el reemplazo y los fallbacks de APIs/eventos.

## Compatibilidad y dependencias

- Project Zomboid Build 42.22 o posterior.
- No requiere otros mods.
- Usa `OnWeaponHitXp` y `OnWeaponHitTree`, las acciones vanilla `ISInventoryPaneContextMenu.equipWeapon` e `ISEquipWeaponAction`, `PZAPI.ModOptions` y `HaloTextHelper`.

## Validacion en Jill

Pendiente de validar en juego tras activar el mod local. Confirmar una rotura de arma melee y de cuchillo, el aviso Halo, Ctrl+A, Ctrl+S, una mochila equipada, una mochila dentro del inventario, la configuracion de teclas y que los controles base A/S no se ejecuten al usar el atajo.
