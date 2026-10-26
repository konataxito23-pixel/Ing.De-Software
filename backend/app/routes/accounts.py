from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user
from app.models import Account, User
from app.schemas import AccountOut

router = APIRouter(prefix="/accounts", tags=["Accounts"])


@router.get("/me", response_model=list[AccountOut])
def list_my_accounts(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return db.query(Account).filter(Account.user_id == current_user.id).all()


@router.get("/{numero_cuenta}/saldo")
def get_saldo(
    numero_cuenta: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    account = (
        db.query(Account)
        .filter(Account.numero_cuenta == numero_cuenta, Account.user_id == current_user.id)
        .first()
    )
    if not account:
        raise HTTPException(status_code=404, detail="Cuenta no encontrada")

    return {"cuenta": account.numero_cuenta, "saldo": account.saldo}
