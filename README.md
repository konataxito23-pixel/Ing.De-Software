# NEXORA — Frontend Flutter (HU-03 Realizar transferencia)

![CI](https://github.com/konataxito23-pixel/Ing.De-Software/actions/workflows/ci.yml/badge.svg)

App del MVP académico NEXORA (Ingeniería de Software · UPB · 2026-2). Flujo
**Login → Dashboard → Nueva transferencia → Comprobante / error** de la historia **HU-03**.

## Requisitos
Flutter estable (Dart >= 3.3). Para probar en navegador basta `flutter doctor` con Flutter y Chrome en ✓.

## Ejecución
```bash
flutter pub get
flutter run -d web-server --web-port 8080      # abrir http://localhost:8080 (backend simulado)
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://10.0.2.2:8080   # backend real
```
`10.0.2.2` es el localhost del emulador Android. No se suben contraseñas ni `.env`.

## Funcionalidades
- **Sesión (NEXO-77):** el login valida correo y contraseña (mín. 4 caracteres); es simulado, sin backend de autenticación. Sin sesión solo se ve el login; el ícono de salida cierra sesión; una respuesta 401 devuelve al login.
- **Códigos de error (NEXO-78):** 400 (motivo del servidor), 401, 403 (Shield, con reglas), 404, 409, 503 y 5xx se muestran con un mensaje claro y el código.
- **Validación en cliente:** monto mayor que cero (NS-01).

## Backend simulado
Cuenta origen `100001` (saldo 500.000); destinos válidos `100002`, `200001`, `200002`.
Simulaciones: destino `300001` → 403 (Shield, NS-04); `300002` → 503 (Shield no disponible).

## Pruebas
```bash
flutter test
```
| Archivo | Cubre |
|---|---|
| `transferencia_test.dart` | TEST-01..03: CA-01, CA-02, CA-03 |
| `http_api_test.dart` | NEXO-79: cliente HTTP (200, 400, 401, 403, 404, 409, 503, 500, sin red, cuerpo no JSON) |
| `flujo_test.dart` | NEXO-121: flujo completo; NEXO-77/122: login y sesión expirada; NEXO-78: 403 y 503 en pantalla |

## CI y release (NEXO-123)
- `ci.yml`: en cada push y PR a `main` ejecuta `flutter analyze`, `flutter test` y `flutter build web`.
- `release.yml`: al publicar un tag `v*` genera el build web y lo adjunta a un GitHub Release.
```bash
git checkout main && git pull
git tag v1.0.0 && git push origin v1.0.0
```
Build local: `flutter build web --release` (salida en `build/web`) o `flutter build apk --release` (requiere Android SDK).

## Integración pendiente
El cliente HTTP sigue el contrato `POST /api/transferencias`. El backend implementado expone `POST /transferencia`
(`operacion_id`, `origen`, `destino`, `importe`); falta adaptar el cliente cuando haya acceso al backend.

## Nota de uso de IA
Se usó Claude (Anthropic) como apoyo para el código base, las pruebas y este README. El equipo revisó, ejecutó y es responsable del resultado. *(Ajustar al formato del curso.)*
