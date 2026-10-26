from __future__ import annotations


def evaluate_risk(cuenta_origen: str, cuenta_destino: str, monto: float, tipo_transaccion: str = "transferencia") -> dict:
    score = 0.15

    if monto >= 500000:
        score += 0.35
    if monto >= 1000000:
        score += 0.2
    if cuenta_origen == cuenta_destino:
        score += 0.25
    if tipo_transaccion == "transferencia":
        score += 0.15

    if score >= 0.8:
        return {
            "aprobado": False,
            "score": round(score, 2),
            "nivel": "ALTO",
            "motivo": "La transferencia excede el umbral de riesgo",
        }

    if score >= 0.5:
        return {
            "aprobado": False,
            "score": round(score, 2),
            "nivel": "MEDIO",
            "motivo": "Se requiere revisión del riesgo antes de aprobar",
        }

    return {
        "aprobado": True,
        "score": round(score, 2),
        "nivel": "BAJO",
        "motivo": "Sin anomalías detectadas",
    }
