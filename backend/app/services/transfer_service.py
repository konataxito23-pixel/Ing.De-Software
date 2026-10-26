from __future__ import annotations

from datetime import datetime


def generate_comprobante() -> str:
    ts = datetime.utcnow().strftime("%Y%m%d%H%M%S")
    return f"NEX-TRX-{ts}"


def validar_transferencia(origen_saldo: float, destino_valido: bool, monto: float) -> tuple[bool, str]:
    if monto <= 0:
        return False, "El monto debe ser mayor que cero"
    if not destino_valido:
        return False, "Cuenta destino inválida"
    if origen_saldo < monto:
        return False, "Saldo insuficiente"
    return True, "OK"
