# NEXORA Backend — Uso y pruebas de integración

Este backend expone la API REST de NEXORA y está diseñado para sostener el flujo financiero de la app Flutter.

## Stack

- FastAPI
- SQLAlchemy
- SQLite para desarrollo local
- JWT para autenticación
- Pydantic para validación

## Requisitos

- Python 3.11+
- pip
- entorno virtual recomendado

## Instalación local

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Variables de entorno

Archivo `.env`:

```env
SECRET_KEY=change-me-super-secret-key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
DATABASE_URL=sqlite:///./nexora.db
```

## Usuario demo

Al arrancar la API por primera vez, se crea automáticamente un usuario demo:

- email: `ana@nexora.com`
- password: `123456`

## Endpoints principales

### Health check

```bash
curl http://localhost:8000/health
```

Respuesta esperada:

```json
{"status":"ok"}
```

### Login

```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ana@nexora.com","password":"123456"}'
```

Respuesta esperada:

```json
{
  "token": "<jwt>",
  "user": {
    "id": 1,
    "name": "Ana Gómez",
    "email": "ana@nexora.com"
  }
}
```

### Mis cuentas

```bash
curl -X GET http://localhost:8000/api/accounts/me \
  -H "Authorization: Bearer <jwt>"
```

### Saldo de una cuenta

```bash
curl -X GET http://localhost:8000/api/accounts/100001/saldo \
  -H "Authorization: Bearer <jwt>"
```

Respuesta esperada:

```json
{"cuenta":"100001","saldo":500000.0}
```

### Crear transferencia

```bash
curl -X POST http://localhost:8000/api/transferencias \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <jwt>" \
  -d '{"cuentaOrigen":"100001","cuentaDestino":"200001","monto":150000}'
```

Respuesta esperada:

```json
{
  "estado": "EXITOSA",
  "mensaje": "Transferencia realizada correctamente",
  "comprobante": "NEX-TRX-20261026120000",
  "saldoActual": 350000.0
}
```

### Listar transferencias

```bash
curl -X GET http://localhost:8000/api/transferencias \
  -H "Authorization: Bearer <jwt>"
```

### Evaluación de riesgo

```bash
curl -X POST http://localhost:8000/api/risk/transferencia \
  -H "Content-Type: application/json" \
  -d '{
    "cuentaOrigen":"100001",
    "cuentaDestino":"200001",
    "monto":150000,
    "tipoTransaccion":"transferencia"
  }'
```

Respuesta esperada:

```json
{
  "aprobado": true,
  "score": 0.15,
  "nivel": "BAJO",
  "motivo": "Sin anomalías detectadas"
}
```

## Flujo recomendado de uso

1. Hacer login
2. Guardar el JWT
3. Consultar `/api/accounts/me`
4. Consultar saldo real
5. Enviar una transferencia a `/api/transferencias`
6. Revisar el comprobante y el saldo nuevo

## Reglas de negocio actuales

Estas reglas están implementadas en el backend y equivalen a las del mock:

- monto mayor que 0
- cuenta origen existe y pertenece al usuario autenticado
- cuenta destino existe
- origen y destino no pueden ser iguales
- saldo suficiente
- riesgo bajo para aprobar

## Integración con Flutter

La app Flutter usa:

- `POST /api/auth/login`
- `GET /api/accounts/{cuenta}/saldo`
- `POST /api/transferencias`

El token JWT se envía con la cabecera:

```http
Authorization: Bearer <jwt>
```

## Script de prueba de integración

Se incluye un script en `backend/test_api.sh` con una secuencia de pruebas CURL que cubre:

- health check
- login
- saldo
- transferencia exitosa
- riesgo

Ejecutarlo:

```bash
cd backend
bash test_api.sh
```

## Observaciones

- La API usa SQLite en desarrollo para agilizar la puesta en marcha.
- Para entorno de producción, se recomienda PostgreSQL.
- El sistema es totalmente funcional como base real del MVP, pero aún requiere endurecimiento de seguridad y validación de producción.
