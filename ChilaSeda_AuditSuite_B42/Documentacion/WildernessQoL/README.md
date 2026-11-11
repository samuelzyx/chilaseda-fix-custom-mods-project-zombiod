# Wilderness QoL dentro de Traducciones ES

La traducción española ya estaba parcialmente en el catálogo central. Se
añadieron las 83 claves que faltaban de Sandbox, Tooltip y UI; las 42 claves
de ContextMenu e IG_UI ya presentes conservan los textos revisados del catálogo
central, que difieren de las traducciones archivadas en algunos casos.

La guardia de identificación ahora carga desde
`ChilaSeda_Translations_ES_B42/42/media/lua/client/ChilaSeda_WFIIdentificationFix.lua`.
Solo reemplaza `WFI.isIdentified` cuando Wilderness QoL está cargado y la API
existe. El catálogo de traducciones funciona aunque el mod original falte.

Los archivos del paquete separado y el parche anterior se conservaron como
referencia en esta carpeta; sus IDs ya no se activan por separado.
