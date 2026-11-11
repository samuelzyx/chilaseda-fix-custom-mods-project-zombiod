ChilaSeda Audit Suite (B42) 2.1.1

ID: ChilaSeda_AuditSuite_B42

Incluye Error Session Logs, Mod Memory Audit, Performance Black Box y Weight
Monitor bajo un solo ID. Los archivos Lua y sus documentos quedan separados
por función. Los tres puentes Java se agruparon en
42/media/java/client/ChilaSedaAuditSuite.jar.

Error Magnifier es opcional: si falta o no expone la API esperada, el registro
de errores se omite sin impedir que carguen las otras auditorías. ZombieBuddy
es opcional: si falta su puente Java, Error Session Logs, Performance Black Box
y Weight Monitor no inician sus funciones Java; Mod Memory Audit conserva sus
registros Lua y anota que las ventanas de heap no están disponibles. No se
declara `require` para esos mods. El `loadModAfter` solo sugiere el orden cuando
están instalados.

Activa únicamente este ID en la lista de mods de la partida. Consulta
Documentacion/ para los detalles y las validaciones pendientes de cada módulo.
La suite no cambia gameplay ni peso de objetos.
