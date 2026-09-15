from flask import Flask, jsonify, request
import json
import logging

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
    body = request.get_json()

    operacion_id = body.get("operacion_id")
    origen = body.get("origen")
    destino = body.get("destino")
    importe = body.get("importe")

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

    cuenta_origen["saldo"] -= importe
    cuenta_destino["saldo"] += importe
    logging.info(f"Transferencia {operacion_id}: {origen} -> {destino} por {importe}")
    operaciones_realizadas.append(operacion_id)

    return jsonify({
        "mensaje": "Transferencia exitosa",
        "origen": cuenta_origen,
        "destino": cuenta_destino
    })


if __name__ == "__main__":
    app.run(debug=True, port=5000)