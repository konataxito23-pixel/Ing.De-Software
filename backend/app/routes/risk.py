from __future__ import annotations

from fastapi import APIRouter

from app.schemas import RiskRequest, RiskResponse
from app.services.risk_service import evaluate_risk

router = APIRouter(prefix="/risk", tags=["Risk"])


@router.post("/transferencia", response_model=RiskResponse)
def risk_transferencia(payload: RiskRequest):
    result = evaluate_risk(
        cuenta_origen=payload.cuentaOrigen,
        cuenta_destino=payload.cuentaDestino,
        monto=payload.monto,
        tipo_transaccion=payload.tipoTransaccion,
    )
    return RiskResponse(
        aprobado=result["aprobado"],
        score=result["score"],
        nivel=result["nivel"],
        motivo=result["motivo"],
    )
