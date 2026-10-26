from __future__ import annotations

import json
import logging
import os
import secrets
import sqlite3
import time
from datetime import datetime, timedelta, timezone
from typing import Any, Optional
from urllib import error, request

from flask import Flask, g, jsonify, request
from werkzeug.security import check_password_hash, generate_password_hash

app = Flask(__name__)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "nexora.db")
SHIELD_URL = os.environ.get("SHIELD_URL")
REQUIRE_SHIELD = os.environ.get("REQUIRE_SHIELD", "false").lower() == "true"

logging.basicConfig(
    filename=os.path.join(BASE_DIR, "auditoria.log"),
    level=logging.INFO,
    format="%(asctime)s - %(message)s",
)


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def get_db() -> sqlite3.Connection:
    if "db" not in g:
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA foreign_keys = ON")
        g.db = conn
    return g.db


@app.teardown_appcontext
def close_db(_: BaseException | None) -> None:
    db = g.pop("db", None)
    if db is not None:
        db.close()


def init_db() -> None:
    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA foreign_keys = ON")

    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            usuario TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            created_at TEXT NOT NULL DEFAULT (datetime('now'))
        )
        """
    )

    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            numero TEXT NOT NULL UNIQUE,
            usuario_id INTEGER NOT NULL,
            alias TEXT NOT NULL,
            tipo TEXT NOT NULL,
            moneda TEXT NOT NULL,
            estado TEXT NOT NULL DEFAULT 'Activa',
            saldo REAL NOT NULL DEFAULT 0,
            FOREIGN KEY (usuario_id) REFERENCES users(id)
        )
        """
    )

    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            token TEXT NOT NULL UNIQUE,
            expires_at TEXT NOT NULL,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            FOREIGN KEY (user_id) REFERENCES users(id)
        )
        """
    )

    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS transfers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            operacion_id TEXT UNIQUE NOT NULL,
            usuario_id INTEGER NOT NULL,
            origen TEXT NOT NULL,
            destino TEXT NOT NULL,
            monto REAL NOT NULL,
            estado TEXT NOT NULL,
            mensaje TEXT NOT NULL,
            comprobante TEXT,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            FOREIGN KEY (usuario_id) REFERENCES users(id)
        )
        """
    )

    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS notifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            tipo TEXT NOT NULL,
            mensaje TEXT NOT NULL,
            leida INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            FOREIGN KEY (user_id) REFERENCES users(id)
        )
        """
    )

    conn.commit()
    seed_default_data(conn)
    conn.close()


def seed_default_data(conn: sqlite3.Connection) -> None:
    user_count = conn.execute("SELECT COUNT(*) FROM users").fetchone()[0]
    if user_count == 0:
        demo_users = [
            {"nombre": "Ana Torres", "usuario": "ana", "password": "1234"},
            {"nombre": "Luis Gómez", "usuario": "luis", "password": "1234"},
            {"nombre": "Marta Ríos", "usuario": "marta", "password": "1234"},
            {"nombre": "Carlos Peña", "usuario": "carlos", "password": "1234"},
            {"nombre": "Valentina Ruiz", "usuario": "valentina", "password": "1234"},
            {"nombre": "Andrés Morales", "usuario": "andres", "password": "1234"},
        ]
        for user in demo_users:
            conn.execute(
                "INSERT INTO users (nombre, usuario, password_hash) VALUES (?, ?, ?)",
                (user["nombre"], user["usuario"], generate_password_hash(user["password"])),
            )

    account_count = conn.execute("SELECT COUNT(*) FROM accounts").fetchone()[0]
    if account_count == 0:
        conn.executemany(
            """
            INSERT INTO accounts (numero, usuario_id, alias, tipo, moneda, estado, saldo)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            [
                ("100001", 1, "Ahorros principal", "Ahorros", "COP", "Activa", 500000.0),
                ("100002", 1, "Cuenta secundaria", "Ahorros", "COP", "Activa", 120000.0),
                ("200001", 2, "Cuenta nómina", "Corriente", "COP", "Activa", 250000.0),
                ("200002", 2, "Ahorro personal", "Ahorros", "COP", "Activa", 100000.0),
                ("300001", 3, "Ahorros", "Ahorros", "COP", "Activa", 0.0),
                ("300002", 4, "Cuenta corriente", "Corriente", "COP", "Activa", 2350000.0),
                ("400001", 5, "Ahorro viaje", "Ahorros", "COP", "Activa", 890000.0),
                ("500001", 6, "Cuenta nómina", "Corriente", "COP", "Activa", 75000.0),
            ],
        )

    conn.commit()


def get_bearer_token() -> str:
    auth_header = request.headers.get("Authorization", "")
    if auth_header.startswith("Bearer "):
        return auth_header.split(" ", 1)[1].strip()
    return request.headers.get("X-Session-Token", "").strip()


def get_authenticated_user() -> Optional[sqlite3.Row]:
    token = get_bearer_token()
    if not token:
        return None

    row = get_db().execute(
        """
        SELECT u.*
        FROM sessions s
        JOIN users u ON u.id = s.user_id
        WHERE s.token = ? AND s.expires_at > ?
        ORDER BY s.created_at DESC
        LIMIT 1
        """,
        (token, utcnow().isoformat()),
    ).fetchone()
    return row


def require_auth() -> tuple[Optional[sqlite3.Row], Optional[str]]:
    user = get_authenticated_user()
    if user is None:
        return None, "No autorizado"
    return user, None


def consultar_shield(payload: dict[str, Any]) -> dict[str, Any] | None:
    if not SHIELD_URL:
        return None

    req = request.Request(
        SHIELD_URL.rstrip("/") + "/shield/evaluar",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with request.urlopen(req, timeout=3) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except (error.URLError, TimeoutError, ValueError) as exc:
        raise RuntimeError(f"Shield no disponible: {exc}") from exc


@app.route("/health", methods=["GET"])
def health_check():
    return jsonify({"status": "ok"}), 200


@app.route("/", methods=["GET"])
def home():
    return "Hola NEXORA - el servidor está funcionando", 200


@app.route("/api/auth/login", methods=["POST"])
def login():
    data = request.get_json(silent=True) or {}
    usuario = str(data.get("usuario") or data.get("username") or "").strip()
    password = str(data.get("password") or "")

    if not usuario or not password:
        return jsonify({"estado": "RECHAZADA", "mensaje": "Usuario y contraseña requeridos"}), 400

    db = get_db()
    user = db.execute("SELECT * FROM users WHERE usuario = ?", (usuario,)).fetchone()
    if user is None or not check_password_hash(user["password_hash"], password):
        logging.info("Intento de login fallido: %s", usuario)
        return jsonify({"estado": "RECHAZADA", "mensaje": "Credenciales inválidas"}), 401

    token = secrets.token_urlsafe(32)
    expires_at = (utcnow() + timedelta(hours=12)).isoformat()

    db.execute(
        "INSERT INTO sessions (user_id, token, expires_at) VALUES (?, ?, ?)",
        (user["id"], token, expires_at),
    )
    db.commit()

    return jsonify(
        {
            "token": token,
            "usuario": {
                "id": user["id"],
                "nombre": user["nombre"],
                "usuario": user["usuario"],
            },
            "expires_at": expires_at,
        }
    ), 200


@app.route("/api/auth/logout", methods=["POST"])
def logout():
    user, error_message = require_auth()
    if user is None:
        return jsonify({"estado": "RECHAZADA", "mensaje": error_message}), 401

    token = get_bearer_token()
    if token:
        get_db().execute("DELETE FROM sessions WHERE token = ?", (token,))
        get_db().commit()

    return jsonify({"estado": "EXITOSA", "mensaje": "Sesión cerrada"}), 200


@app.route("/api/cuentas", methods=["GET"])
def listar_cuentas():
    user, error_message = require_auth()
    if user is None:
        return jsonify({"estado": "RECHAZADA", "mensaje": error_message}), 401

    rows = get_db().execute(
        "SELECT * FROM accounts WHERE usuario_id = ? ORDER BY numero ASC",
        (user["id"],),
    ).fetchall()

    return jsonify({
        "cuentas": [
            {
                "numero": row["numero"],
                "usuario_id": row["usuario_id"],
                "alias": row["alias"],
                "tipo": row["tipo"],
                "moneda": row["moneda"],
                "estado": row["estado"],
                "saldo": float(row["saldo"]),
            }
            for row in rows
        ]
    }), 200


@app.route("/cuentas/<int:usuario_id>")
def consultar_cuentas_legacy(usuario_id: int):
    auth_header = request.headers.get("X-User-Id")
    if auth_header is None or int(auth_header) != usuario_id:
        logging.info("Acceso denegado a cuentas de %s", usuario_id)
        return jsonify({"error": "No autorizado para consultar estas cuentas"}), 403

    rows = get_db().execute(
        "SELECT * FROM accounts WHERE usuario_id = ? ORDER BY numero ASC",
        (usuario_id,),
    ).fetchall()
    if not rows:
        return jsonify({"error": "Usuario sin cuentas registradas"}), 404

    return jsonify([
        {
            "numero": row["numero"],
            "usuario_id": row["usuario_id"],
            "alias": row["alias"],
            "tipo": row["tipo"],
            "moneda": row["moneda"],
            "estado": row["estado"],
            "saldo": float(row["saldo"]),
        }
        for row in rows
    ])


@app.route("/api/historial", methods=["GET"])
def historial():
    user, error_message = require_auth()
    if user is None:
        return jsonify({"estado": "RECHAZADA", "mensaje": error_message}), 401

    rows = get_db().execute(
        "SELECT * FROM transfers WHERE usuario_id = ? ORDER BY created_at DESC LIMIT 50",
        (user["id"],),
    ).fetchall()

    return jsonify({
        "movimientos": [
            {
                "operacion_id": row["operacion_id"],
                "origen": row["origen"],
                "destino": row["destino"],
                "monto": float(row["monto"]),
                "estado": row["estado"],
                "mensaje": row["mensaje"],
                "comprobante": row["comprobante"],
                "fecha": row["created_at"],
            }
            for row in rows
        ]
    }), 200


@app.route("/api/notificaciones", methods=["GET"])
def notificaciones():
    user, error_message = require_auth()
    if user is None:
        return jsonify({"estado": "RECHAZADA", "mensaje": error_message}), 401

    rows = get_db().execute(
        "SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 20",
        (user["id"],),
    ).fetchall()

    return jsonify({
        "notificaciones": [
            {
                "id": row["id"],
                "tipo": row["tipo"],
                "mensaje": row["mensaje"],
                "leida": bool(row["leida"]),
                "fecha": row["created_at"],
            }
            for row in rows
        ]
    }), 200


@app.route("/api/comprobantes/<string:comprobante>", methods=["GET"])
def comprobante(comprobante: str):
    user, error_message = require_auth()
    if user is None:
        return jsonify({"estado": "RECHAZADA", "mensaje": error_message}), 401

    row = get_db().execute(
        "SELECT * FROM transfers WHERE usuario_id = ? AND comprobante = ? LIMIT 1",
        (user["id"], comprobante),
    ).fetchone()

    if row is None:
        return jsonify({"estado": "RECHAZADA", "mensaje": "Comprobante no encontrado"}), 404

    return jsonify({
        "comprobante": row["comprobante"],
        "estado": row["estado"],
        "mensaje": row["mensaje"],
        "origen": row["origen"],
        "destino": row["destino"],
        "monto": float(row["monto"]),
        "fecha": row["created_at"],
    }), 200


@app.route("/transferencia", methods=["POST"])
@app.route("/api/transferencias", methods=["POST"])
def transferencias():
    user, error_message = require_auth()
    if user is None:
        return jsonify({"estado": "RECHAZADA", "mensaje": error_message}), 401

    payload = request.get_json(silent=True) or {}
    operacion_id = str(payload.get("operacion_id") or payload.get("idempotency_key") or f"op-{int(time.time()*1000)}")
    cuenta_origen = payload.get("cuentaOrigen")
    cuenta_destino = payload.get("cuentaDestino")
    monto = payload.get("monto")
    confirmar = bool(payload.get("confirmar", False))

    if isinstance(monto, bool) or not isinstance(monto, (int, float)) or float(monto) <= 0:
        return jsonify({"estado": "RECHAZADA", "mensaje": "El monto debe ser un número mayor que cero"}), 400

    monto = float(monto)
    if not cuenta_origen or not cuenta_destino:
        return jsonify({"estado": "RECHAZADA", "mensaje": "Cuenta origen y destino requeridas"}), 400

    existing = get_db().execute(
        "SELECT * FROM transfers WHERE operacion_id = ? LIMIT 1",
        (operacion_id,),
    ).fetchone()
    if existing is not None:
        return jsonify({
            "estado": existing["estado"],
            "mensaje": existing["mensaje"],
            "comprobante": existing["comprobante"],
        }), 200

    origen = get_db().execute(
        "SELECT * FROM accounts WHERE numero = ? AND usuario_id = ? LIMIT 1",
        (str(cuenta_origen), user["id"]),
    ).fetchone()
    if origen is None:
        return jsonify({"estado": "RECHAZADA", "mensaje": "Cuenta origen no encontrada o no pertenece al usuario"}), 403

    destino = get_db().execute(
        "SELECT * FROM accounts WHERE numero = ? LIMIT 1",
        (str(cuenta_destino),),
    ).fetchone()
    if destino is None:
        return jsonify({"estado": "RECHAZADA", "mensaje": "Cuenta destino inválida"}), 400

    if origen["numero"] == destino["numero"]:
        return jsonify({"estado": "RECHAZADA", "mensaje": "No es posible transferir a la misma cuenta"}), 400

    if float(origen["saldo"]) < monto:
        return jsonify({"estado": "RECHAZADA", "mensaje": "Saldo insuficiente"}), 400

    shield = None
    try:
        shield = consultar_shield({
            "operacion_id": operacion_id,
            "origen": str(cuenta_origen),
            "destino": str(cuenta_destino),
            "importe": monto,
            "saldo_origen": float(origen["saldo"]),
            "destino_valido": True,
        })
    except RuntimeError:
        if REQUIRE_SHIELD:
            logging.info("Transferencia bloqueada: Shield obligatorio y no disponible")
            return jsonify({"estado": "RECHAZADA", "mensaje": "Servicio de validación preventiva no disponible"}), 503
        shield = None

    if shield and shield.get("decision") == "RECHAZAR":
        reglas = shield.get("reglas_activadas", [])
        get_db().execute(
            "INSERT INTO transfers (operacion_id, usuario_id, origen, destino, monto, estado, mensaje, comprobante) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            (operacion_id, user["id"], str(cuenta_origen), str(cuenta_destino), monto, "RECHAZADA", "Operación rechazada por NEXORA Shield", None),
        )
        get_db().execute(
            "INSERT INTO notifications (user_id, tipo, mensaje) VALUES (?, ?, ?)",
            (user["id"], "shield", f"Transferencia rechazada por NEXORA Shield: {reglas}"),
        )
        get_db().commit()
        return jsonify({"estado": "RECHAZADA", "mensaje": "Operación rechazada por NEXORA Shield", "reglas": reglas}), 403

    if shield and shield.get("decision") == "ADVERTENCIA" and not confirmar:
        return jsonify({
            "estado": "ADVERTENCIA",
            "mensaje": "La transferencia requiere confirmación explícita antes de ejecutarse",
            "reglas": shield.get("reglas_activadas", []),
        }), 202

    db = get_db()
    try:
        db.execute("BEGIN IMMEDIATE")
        origen_actualizado = db.execute(
            "SELECT saldo FROM accounts WHERE numero = ? AND usuario_id = ? LIMIT 1",
            (str(cuenta_origen), user["id"]),
        ).fetchone()

        if origen_actualizado is None:
            raise ValueError("Cuenta origen no disponible")

        if float(origen_actualizado["saldo"]) < monto:
            raise ValueError("Saldo insuficiente")

        nuevo_saldo_origen = float(origen_actualizado["saldo"]) - monto
        db.execute(
            "UPDATE accounts SET saldo = ? WHERE numero = ? AND usuario_id = ?",
            (nuevo_saldo_origen, str(cuenta_origen), user["id"]),
        )
        db.execute(
            "UPDATE accounts SET saldo = saldo + ? WHERE numero = ?",
            (monto, str(cuenta_destino)),
        )

        comprobante = f"NEX-TRX-{int(time.time()*1000) % 10000000000:011d}"
        db.execute(
            "INSERT INTO transfers (operacion_id, usuario_id, origen, destino, monto, estado, mensaje, comprobante) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            (operacion_id, user["id"], str(cuenta_origen), str(cuenta_destino), monto, "EXITOSA", "Transferencia realizada correctamente", comprobante),
        )
        db.execute(
            "INSERT INTO notifications (user_id, tipo, mensaje) VALUES (?, ?, ?)",
            (user["id"], "transferencia", f"Transferencia exitosa: {comprobante}"),
        )
        db.commit()
    except Exception:
        db.rollback()
        logging.exception("Error procesando transferencia")
        return jsonify({"estado": "RECHAZADA", "mensaje": "No se pudo completar la transferencia"}), 400

    respuesta = {
        "estado": "EXITOSA",
        "mensaje": "Transferencia realizada correctamente",
        "comprobante": comprobante,
    }

    if shield and shield.get("decision") == "ADVERTENCIA":
        respuesta["advertencias"] = shield.get("reglas_activadas", [])

    return jsonify(respuesta), 200


init_db()

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
