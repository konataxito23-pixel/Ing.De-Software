from flask import Flask, jsonify, request
import json
import logging
import os
import urllib.request
import urllib.error

app = Flask(__name__)

logging.basicConfig(
    filename="auditoria.log",
    level=logging.INFO,
    format="%(asctime)s - %(message)s"
)

# Cargar los datos ficticios desde el archivo JSON
with open("datos.json", "r", encoding="utf-8") as f:
    datos = json.load(f)

# Lista en memoria para detectar transferencias duplicadas
operaciones_realizadas = []

# NEXORA Shield (carpeta shield-ml). Si SHIELD_URL no está definida, la integración queda desactivada
# y el servicio funciona como antes. Ejemplo: http://127.0.0.1:5001
SHIELD_URL = os.environ.get("SHIELD_URL")


def consultar_shield(payload):
    """Consulta a shield-ml. Devuelve su respuesta (dict), None si está desactivado,
    o lanza RuntimeError si no responde (en ese caso la transferencia NO se ejecuta)."""
    if not SHIELD_URL:
        return None
    req = urllib.request.Request(
        SHIELD_URL.rstrip("/") + "/shield/evaluar",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=2) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except (urllib.error.URLError, TimeoutError, ValueError) as e:
        raise RuntimeError(f"Shield no disponible: {e}")


@app.route("/")
def home():
    return "Hola NEXORA - el servidor está funcionando"


# Endpoint 1: consultar las cuentas de un usuario (con autorización)
@app.route("/cuentas/<int:usuario_id>")
def consultar_cuentas(usuario_id):
    usuario_autenticado = request.headers.get("X-User-Id", type=int)

    if usuario_autenticado != usuario_id:
        logging.info(f"Acceso denegado: usuario {usuario_autenticado} intentó ver cuentas de {usuario_id}")
        return jsonify({"error": "No autorizado para consultar estas cuentas"}), 403

    cuentas_usuario = [c for c in datos["cuentas"] if c["usuario_id"] == usuario_id]
    if not cuentas_usuario:
        return jsonify({"error": "Usuario sin cuentas registradas"}), 404

    logging.info(f"Usuario {usuario_id} consultó sus cuentas")
    return jsonify(cuentas_usuario)


# Endpoint 2: simular una transferencia
@app.route("/transferencia", methods=["POST"])
def transferencia():
    body = request.get_json(silent=True)
    if not isinstance(body, dict):
        return jsonify({"error": "Cuerpo JSON requerido"}), 400

    operacion_id = body.get("operacion_id")
    origen = body.get("origen")
    destino = body.get("destino")
    importe = body.get("importe")

    # NS-01: el importe debe ser numérico y mayor que cero
    if isinstance(importe, bool) or not isinstance(importe, (int, float)) or importe <= 0:
        return jsonify({"error": "El importe debe ser un número mayor que cero"}), 400

    if operacion_id in operaciones_realizadas:
        return jsonify({"error": "Transferencia duplicada"}), 409

    cuenta_origen = next((c for c in datos["cuentas"] if c["numero"] == origen), None)
    if cuenta_origen is None:
        return jsonify({"error": "Cuenta origen no encontrada"}), 404

    cuenta_destino = next((c for c in datos["cuentas"] if c["numero"] == destino), None)
    if cuenta_destino is None:
        return jsonify({"error": "Cuenta destino inválida"}), 400

    if cuenta_origen["saldo"] < importe:
        return jsonify({"error": "Saldo insuficiente"}), 400

    # NEXORA Shield decide ANTES de mover dinero
    try:
        shield = consultar_shield({
            "operacion_id": operacion_id,
            "origen": origen,
            "destino": destino,
            "importe": importe,
            "saldo_origen": cuenta_origen["saldo"],
            "destino_valido": True,
        })
    except RuntimeError as e:
        logging.info(f"Transferencia {operacion_id} bloqueada: {e}")
        return jsonify({"error": "Servicio de validación preventiva no disponible"}), 503

    if shield and shield.get("decision") == "RECHAZAR":
        logging.info(f"Transferencia {operacion_id} rechazada por Shield: {shield.get('reglas_activadas')}")
        return jsonify({"error": "Operación rechazada por NEXORA Shield",
                        "reglas": shield.get("reglas_activadas", [])}), 403

    cuenta_origen["saldo"] -= importe
    cuenta_destino["saldo"] += importe
    operaciones_realizadas.append(operacion_id)
    comprobante = f"NEX-TRX-{len(operaciones_realizadas):06d}"
    logging.info(f"Transferencia {operacion_id} ({comprobante}): {origen} -> {destino} por {importe}")

    respuesta = {
        "mensaje": "Transferencia exitosa",
        "comprobante": comprobante,
        "origen": cuenta_origen,
        "destino": cuenta_destino
    }
    if shield and shield.get("decision") == "ADVERTENCIA":
        respuesta["advertencias"] = shield.get("reglas_activadas", [])
    return jsonify(respuesta)


if __name__ == "__main__":
    app.run(debug=True, port=5000)
