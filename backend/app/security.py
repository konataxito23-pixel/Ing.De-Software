from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class UserCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=120)
    email: str = Field(..., min_length=3, max_length=255)
    password: str = Field(..., min_length=6)


class UserLogin(BaseModel):
    email: str
    password: str


class TokenResponse(BaseModel):
    token: str
    user: dict


class AccountOut(BaseModel):
    id: int
    numero_cuenta: str
    tipo_cuenta: str
    saldo: float
    estado: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class TransferRequest(BaseModel):
    cuentaOrigen: str
    cuentaDestino: str
    monto: float = Field(..., gt=0)


class TransferResponse(BaseModel):
    estado: str
    mensaje: str
    comprobante: Optional[str] = None
    saldoActual: Optional[float] = None


class RiskRequest(BaseModel):
    cuentaOrigen: str
    cuentaDestino: str
    monto: float = Field(..., gt=0)
    hora: Optional[str] = None
    tipoTransaccion: str = "transferencia"


class RiskResponse(BaseModel):
    aprobado: bool
    score: float
    nivel: str
    motivo: str
