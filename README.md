# NEXORA — Frontend Flutter + MVP de transferencia

![CI](https://github.com/konataxito23-pixel/Ing.De-Software/actions/workflows/ci.yml/badge.svg)

Aplicación móvil del MVP académico NEXORA (Ingeniería de Software · UPB · 2026-2). El proyecto implementa el flujo de negocio de la historia **HU-03** para realizar transferencias bancarias desde la app móvil.

## Estado actual

El repositorio se encuentra en una etapa de **MVP funcional de demostración**:

- Frontend Flutter completo para login, dashboard y flujo de transferencia.
- Capa de integración API con backend mock en memoria.
- Reglas de negocio validadas por pruebas automatizadas.
- Módulo de IA/ML `shield-ml` para análisis de anomalías (basado en un dataset sintético).

La solución está lista para demostración y validación académica, pero aún requiere backend real, autenticación real y cierre de integración con servicios productivos para pasar de MVP a sistema completo.

## Arquitectura del proyecto

La estructura actual del repositorio es la siguiente:

- `lib/main.dart`: UI principal de Flutter y pantallas.
- `lib/api.dart`: contrato de transferencia y backend mock.
- `test/transferencia_test.dart`: pruebas del flujo principal.
- `shield-ml/`: dataset sintético y notebook del modelo NEXORA Shield.
- `.github/workflows/ci.yml`: pipeline de validación automática.

### Arquitectura funcional

- Frontend Flutter
  - Login
  - Dashboard
  - Nueva transferencia
  - Resultado de operación

- API abstraction layer
  - `TransferenciaApi`
  - `MockTransferenciaApi`
  - `HttpTransferenciaApi`

- Reglas NEXORA Shield (actualmente simuladas)
  - NS-01: monto <= 0
  - NS-02: saldo insuficiente
  - NS-03: cuenta destino inválida

- Módulo ML
  - Dataset sintético de 5.000 transacciones
  - Modelo baseline con Isolation Forest

## Requisitos

- Flutter estable (Dart >= 3.3) — `flutter --version`
- Android Studio/emulador o Chrome
- Python 3.x para el módulo `shield-ml` (si se desea ejecutar el notebook)

## Instalación y ejecución

```bash
flutter pub get
flutter run
```

Por defecto la aplicación usa el backend mock y no requiere servicios externos.

Para conectarse a un backend real:

```bash
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

`10.0.2.2` corresponde al localhost del emulador Android. No se usan contraseñas ni `.env` en este repositorio.

## Flujo funcional actual

1. Usuario ingresa correo y contraseña en la pantalla de login.
2. Si la validación local pasa, se navega al dashboard.
3. El dashboard muestra la cuenta origen `100001` y su saldo.
4. El usuario crea una nueva transferencia.
5. La app valida:
   - monto positivo
   - cuenta destino no vacía
   - saldo suficiente
   - cuenta destino válida
6. Se intenta la transferencia mediante la API.
7. El sistema muestra:
   - comprobante generado: `NEX-TRX-000001`
   - mensaje de éxito o rechazo

## Reglas de negocio

### Reglas implementadas

- `monto > 0`
- `destino != origen`
- `destino` debe estar en `{'100002', '200001', '200002'}`
- `saldo(origen) >= monto`

### Datos de prueba

- Cuenta origen: `100001`
- Saldo inicial: `500.000 COP`
- Destinos válidos: `100002`, `200001`, `200002`

## Contrato con el backend

El backend real debe implementar el siguiente contrato, compatible con la lógica de la app:

### Endpoint de transferencia

`POST /api/transferencias`

Request:

```json
{
  "cuentaOrigen": "100001",
  "cuentaDestino": "200001",
  "monto": 150000
}
```

Respuesta exitosa:

```json
{
  "estado": "EXITOSA",
  "mensaje": "Transferencia realizada correctamente",
  "comprobante": "NEX-TRX-000001"
}
```

Respuesta rechazada:

```json
{
  "estado": "RECHAZADA",
  "mensaje": "Saldo insuficiente"
}
```

### Criterios del cliente

El cliente considera una transferencia exitosa si:

- HTTP status está en 200-299
- `estado == "EXITOSA"`

En la capa actual, la app acepta mensajes de respuesta textuales de la API. El backend real debería mantener la misma semántica para que la UI no cambie.

## Backlog para dejarlo completo

Lo siguiente es necesario para que el sistema deje de ser solo un MVP y pase a ser una solución integral:

### 1. Backend real

- API REST funcional con endpoints reales para:
  - auth/login
  - consultar saldo
  - transferir
  - consultar historial
- Persistencia de datos (base de datos relacional o NoSQL)
- Manejo de errores y validación centralizada

### 2. Autenticación real

- Login con usuario autenticado
- Token o sesión segura
- Roles y permisos mínimos
- Mecanismo para mantener la sesión en la app

### 3. Estado de cuenta real

- El dashboard debe consultar saldo real por usuario/cuenta
- Debe soportar múltiples cuentas por cliente
- Historial de movimientos

### 4. Integración con NEXORA Shield

- Endpoint del modelo o servicio de scoring para detectar anomalías
- Decisión de aprobación/rechazo basada en riesgo
- Alertas o feedback visual para el usuario

### 5. Observabilidad

- Logs
- Métricas
- Trazabilidad de movimientos
- Manejo de fallos de red

## Pruebas

```bash
flutter test
```

Las pruebas actuales validan los tres casos críticos:

| ID | Criterio | Verifica |
|----|----------|----------|
| TEST-01 | CA-01 | Transferencia exitosa: comprobante y saldo descontado |
| TEST-02 | CA-02 | Saldo insuficiente: rechaza y conserva saldo |
| TEST-03 | CA-03 | Cuenta destino inválida: rechaza y conserva saldo |

## CI

GitHub Actions ejecuta automáticamente:

- `flutter analyze`
- `flutter test`

Archivo: `.github/workflows/ci.yml`

## Módulo NEXORA Shield

El repositorio incluye una carpeta `shield-ml` con un dataset sintético y un notebook de prueba del modelo. El modelo implementado usa `Isolation Forest` y evidencia que:

- distingue bien transacciones normales
- identifica solo una fracción de anomalías en su baseline
- es útil como demostración académica, no como sistema de decisión financiera real

Documentación específica del módulo:

- `shield-ml/README.md`
- `shield-ml/Nexora_Shield_Test.ipynb`

## Documentación adicional

- `docs/arquitectura.md`: resumen de la arquitectura moderna del proyecto
- `docs/contrato-backend.md`: especificación de contratos del backend y reglas del API

## Conclusión

Este proyecto cumple con la intención de un MVP académico funcional para la historia **HU-03**. La pieza más sólida es el frontend y la lógica de validación, mientras que la parte faltante para una solución real es la integración con backend autenticado, saldo real y modelo de riesgo operativo.

Si se desea avanzar a una entrega formal, el siguiente paso recomendado es:

1. definir el backend real
2. definir autenticación
3. cerrar el contrato de saldo y transferencia
4. integrar NEXORA Shield con la decisión final

---

Nota de uso de IA: se usó Claude (Anthropic) como apoyo para migrar el frontend de React a Flutter, para las pruebas y para la documentación del repositorio.

