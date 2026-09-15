# Ing.De-Software

# API Bancaria Simulada — NEXORA (TAR-02 y TAR-03)

## Cómo correrla
1. Activar entorno virtual: `source venv/bin/activate` (o `venv\Scripts\Activate.ps1` en Windows)
2. Instalar dependencias: `pip install -r requirements.txt`
3. Correr: `python app.py`
4. Servidor disponible en http://127.0.0.1:5000

## Endpoints

### GET /cuentas/<usuario_id>
Devuelve las cuentas del usuario indicado.
**Requiere** el header `X-User-Id` con el mismo id del usuario consultado, o responde 403.

### POST /transferencia
Simula una transferencia entre dos cuentas.

## Usuarios y cuentas de prueba
| Usuario   | ID | Cuentas          | Saldo               |
|-----------|----|------------------|---------------------|
| Ana       | 1  | 0001             | 500.000             |
| Luis      | 2  | 0002             | 150.000             |
| Marta     | 3  | 0003             | 0                   |
| Carlos    | 4  | 0004, 0005       | 2.350.000 / 890.000 |
| Valentina | 5  | 0006 (bloqueada) | 45.000              |
| Andrés    | 6  | 0007             | 75.000              |

## Escenarios cubiertos en /transferencia
- Transferencia exitosa
- Saldo insuficiente (usar cuenta origen 0003)
- Destino inválido (usar una cuenta destino inexistente, ej: 9999)
- Transferencia duplicada (reenviar el mismo operacion_id)

## Seguridad (TAR-03)

### Autorización
El endpoint `/cuentas/<usuario_id>` exige un header `X-User-Id` que debe coincidir
con el usuario consultado. Si no coincide, responde 403 - No autorizado.

Ejemplo en Postman: Headers → Key: `X-User-Id`, Value: `1`

### Auditoría
Cada consulta de cuentas y cada transferencia queda registrada en `auditoria.log`,
sin contraseñas ni datos sensibles. Incluye también los intentos de acceso denegado.

### Pendiente (a cargo de Julián / trabajo en pareja)
- HTTPS/TLS (TAR-03.1)
- Rate limiting (TAR-03.3)