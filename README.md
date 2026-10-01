# NEXORA — Frontend Flutter (HU-03 Realizar transferencia)

![CI](https://github.com/konataxito23-pixel/Ing.De-Software/actions/workflows/ci.yml/badge.svg)

App móvil del MVP académico NEXORA (Ingeniería de Software · UPB · 2026-2). Implementa el flujo
**Login → Dashboard → Nueva transferencia → Comprobante / Error** de la historia **HU-03**.

## Requisitos
- Flutter estable (Dart >= 3.3) — `flutter --version`
- Android Studio/emulador o Chrome

## Instalación y ejecución
```bash
flutter pub get
flutter run                      # backend simulado (por defecto)
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://10.0.2.2:8080   # backend real
```
`10.0.2.2` es el localhost del emulador Android. No hay contraseñas ni `.env` en el repo.

## Pruebas
```bash
flutter test
```
| ID | Criterio | Verifica |
|----|----------|----------|
| TEST-01 | CA-01 | Transferencia exitosa: comprobante y saldo descontado |
| TEST-02 | CA-02 | Saldo insuficiente: rechaza y conserva saldo |
| TEST-03 | CA-03 | Cuenta destino inválida: rechaza y conserva saldo |

## Backend simulado
Datos de prueba: cuenta origen `100001` (saldo 500.000), destinos válidos `100002`, `200001`, `200002`.
Reglas NEXORA Shield: NS-01 monto ≤ 0, NS-02 saldo insuficiente, NS-03 destino inválido.

## Contrato con el backend
`POST /api/transferencias` con `{"cuentaOrigen","cuentaDestino","monto"}`.
Éxito: `{"estado":"EXITOSA","mensaje":"...","comprobante":"NEX-TRX-000001"}`.
Rechazo (supuesto, a confirmar con el equipo de backend): HTTP 4xx con `{"estado":"RECHAZADA","mensaje":"..."}`.

## CI
GitHub Actions (`.github/workflows/ci.yml`) ejecuta `flutter analyze` y `flutter test` en cada push y PR a `main`.

## Nota de uso de IA
Se usó Claude (Anthropic) como apoyo para migrar el frontend de React a Flutter y generar el código base,
las pruebas y este README. El equipo revisó, ejecutó y es responsable del resultado. *(Ajustar al formato exigido por el curso.)*
