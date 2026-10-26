from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user
from app.models import Account, Movement, RiskEvent, Transfer, User
from app.schemas import TransferRequest, TransferResponse
from app.services.risk_service import evaluate_risk
from app.services.transfer_service import generate_comprobante, validar_transferencia

router = APIRouter(prefix="/transferencias", tags=["Transfers"])


@router.get("")
def list_transfers(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    accounts = [a.id for a in current_user.accounts]
    transfers = (
        db.query(Transfer)
        .filter((Transfer.cuenta_origen_id.in_(accounts)) | (Transfer.cuenta_destino_id.in_(accounts)))
        .order_by(Transfer.created_at.desc())
        .all()
    )

    result = []
    for transfer in transfers:
        result.append(
            {
                "id": transfer.id,
                "cuentaOrigen": transfer.cuenta_origen.numero_cuenta,
                "cuentaDestino": transfer.cuenta_destino.numero_cuenta,
                "monto": transfer.monto,
                "estado": transfer.estado,
                "mensaje": transfer.mensaje,
                "comprobante": transfer.comprobante,
                "created_at": transfer.created_at.isoformat(),
            }
        )
    return result


@router.post("", response_model=TransferResponse)
def create_transfer(
    payload: TransferRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    origen = (
        db.query(Account)
        .filter(Account.numero_cuenta == payload.cuentaOrigen, Account.user_id == current_user.id)
        .first()
    )
    destino = db.query(Account).filter(Account.numero_cuenta == payload.cuentaDestino).first()

    if not origen:
        raise HTTPException(status_code=404, detail="Cuenta origen no encontrada")
    if not destino:
        raise HTTPException(status_code=404, detail="Cuenta destino no encontrada")
    if payload.cuentaOrigen == payload.cuentaDestino:
        raise HTTPException(status_code=400, detail="La cuenta origen y destino no pueden ser iguales")

    ok, message = validar_transferencia(origen.saldo, True, payload.monto)
    if not ok:
        raise HTTPException(status_code=400, detail=message)

    risk_result = evaluate_risk(
        cuenta_origen=payload.cuentaOrigen,
        cuenta_destino=payload.cuentaDestino,
        monto=payload.monto,
        tipo_transaccion="transferencia",
    )

    if not risk_result["aprobado"]:
        return TransferResponse(
            estado="RECHAZADA",
            mensaje=risk_result["motivo"],
            comprobante=None,
            saldoActual=origen.saldo,
        )

    comprobante = generate_comprobante()

    transfer = Transfer(
        cuenta_origen_id=origen.id,
        cuenta_destino_id=destino.id,
        monto=payload.monto,
        estado="EXITOSA",
        mensaje="Transferencia realizada correctamente",
        comprobante=comprobante,
    )
    db.add(transfer)
    db.flush()

    risk_event = RiskEvent(
        transfer_id=transfer.id,
        score=risk_result["score"],
        nivel=risk_result["nivel"],
        aprobado=risk_result["aprobado"],
    )
    db.add(risk_event)

    origen.saldo -= payload.monto
    destino.saldo += payload.monto

    movement_origen = Movement(
        cuenta_id=origen.id,
        transfer_id=transfer.id,
        tipo="DEBITO",
        monto=payload.monto,
        descripcion=f"Transferencia enviada a {destino.numero_cuenta}",
    )
    movement_destino = Movement(
        cuenta_id=destino.id,
        transfer_id=transfer.id,
        tipo="CREDITO",
        monto=payload.monto,
        descripcion=f"Transferencia recibida desde {origen.numero_cuenta}",
    )

    db.add_all([movement_origen, movement_destino])
    db.commit()
    db.refresh(transfer)

    return TransferResponse(
        estado="EXITOSA",
        mensaje="Transferencia realizada correctamente",
        comprobante=transfer.comprobante,
        saldoActual=origen.saldo,
    )
