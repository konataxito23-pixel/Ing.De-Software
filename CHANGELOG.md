# Changelog

## v1.0.0
- HU-03: flujo Login → Dashboard → Nueva transferencia → Comprobante / error.
- NEXO-77: sesión en memoria; sin sesión solo se muestra el login; "Cerrar sesión"; un 401 devuelve al login.
- NEXO-78: códigos de error 400, 401, 403, 404, 409, 503 y 5xx traducidos a mensajes claros (con el código en pantalla).
- NEXO-79 / NEXO-121: pruebas del cliente HTTP y del flujo completo (flutter test).
- CI: analyze, test y build web; workflow de release al publicar un tag `v*`.
