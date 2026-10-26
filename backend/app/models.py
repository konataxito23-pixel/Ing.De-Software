from __future__ import annotations

from datetime import datetime
from typing import List, Optional

from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)

    accounts: Mapped[List["Account"]] = relationship(back_populates="user")


class Account(Base):
    __tablename__ = "accounts"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    numero_cuenta: Mapped[str] = mapped_column(String(20), unique=True, index=True, nullable=False)
    tipo_cuenta: Mapped[str] = mapped_column(String(50), default="ahorros")
    saldo: Mapped[float] = mapped_column(default=0.0)
    estado: Mapped[str] = mapped_column(String(20), default="ACTIVA")
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)

    user: Mapped[User] = relationship(back_populates="accounts")
    transferencias_origen: Mapped[List["Transfer"]] = relationship(
        foreign_keys="Transfer.cuenta_origen_id",
        back_populates="cuenta_origen",
    )
    transferencias_destino: Mapped[List["Transfer"]] = relationship(
        foreign_keys="Transfer.cuenta_destino_id",
        back_populates="cuenta_destino",
    )
    movimientos: Mapped[List["Movement"]] = relationship(back_populates="account")


class Transfer(Base):
    __tablename__ = "transfers"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    cuenta_origen_id: Mapped[int] = mapped_column(ForeignKey("accounts.id"), nullable=False)
    cuenta_destino_id: Mapped[int] = mapped_column(ForeignKey("accounts.id"), nullable=False)
    monto: Mapped[float] = mapped_column(nullable=False)
    estado: Mapped[str] = mapped_column(String(30), default="EXITOSA")
    mensaje: Mapped[str] = mapped_column(String(255), default="Transferencia realizada correctamente")
    comprobante: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)

    cuenta_origen: Mapped[Account] = relationship(
        foreign_keys=[cuenta_origen_id],
        back_populates="transferencias_origen",
    )
    cuenta_destino: Mapped[Account] = relationship(
        foreign_keys=[cuenta_destino_id],
        back_populates="transferencias_destino",
    )
    risk_events: Mapped[List["RiskEvent"]] = relationship(back_populates="transfer")
    movements: Mapped[List["Movement"]] = relationship(back_populates="transfer")


class Movement(Base):
    __tablename__ = "movements"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    cuenta_id: Mapped[int] = mapped_column(ForeignKey("accounts.id"), nullable=False)
    transfer_id: Mapped[Optional[int]] = mapped_column(ForeignKey("transfers.id"), nullable=True)
    tipo: Mapped[str] = mapped_column(String(30), nullable=False)
    monto: Mapped[float] = mapped_column(nullable=False)
    descripcion: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)

    account: Mapped[Account] = relationship(back_populates="movimientos")
    transfer: Mapped[Optional[Transfer]] = relationship(back_populates="movements")


class RiskEvent(Base):
    __tablename__ = "risk_events"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    transfer_id: Mapped[int] = mapped_column(ForeignKey("transfers.id"), nullable=False)
    score: Mapped[float] = mapped_column(nullable=False)
    nivel: Mapped[str] = mapped_column(String(20), nullable=False)
    aprobado: Mapped[bool] = mapped_column(default=True)
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)

    transfer: Mapped[Transfer] = relationship(back_populates="risk_events")
