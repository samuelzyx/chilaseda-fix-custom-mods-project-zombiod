# ChilaSeda Fix - Reactive Sound Events + Viewpoint (B42) 1.1.3

Parches locales para orientar las senales de Reactive Sound Events con la camara Viewpoint.
No modifica archivos de Workshop.

## Version 1.1.3

- Lee el angulo publicado del frame de camara de Viewpoint mediante el puente Java de VisualSounds.
- Evita llamar `VisualSoundsViewpoint.active()` o `yaw()` desde `update()` y `render()` de Reactive Sound Events, donde pueden ejecutarse fuera del hilo principal.
- Conserva el calculo de direccion y la correccion de 180 grados del indicador.

Con VisualSounds/Viewpoint activo, el parche depende del puente expuesto por
`ChilaSeda_Fix_VisualSounds_UndeadWildlife_Colors_B42`. `Ctrl+Shift+F6` sigue ciclando
las direcciones de prueba; la quinta pulsacion oculta el indicador.
