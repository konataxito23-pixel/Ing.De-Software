from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from app.database import Base, SessionLocal, engine
from app.models import Account, User
from app.routes.accounts import router as accounts_router
from app.routes.auth import router as auth_router
from app.routes.risk import router as risk_router
from app.routes.transfers import router as transfers_router
from app.security import hash_password

Base.metadata.create_all(bind=engine)

app = FastAPI(title="NEXORA API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/api")
app.include_router(accounts_router, prefix="/api")
app.include_router(transfers_router, prefix="/api")
app.include_router(risk_router, prefix="/api")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.on_event("startup")
def seed_data():
    db: Session = SessionLocal()
    try:
        if db.query(User).count() == 0:
            user = User(
                name="Ana Gómez",
                email="ana@nexora.com",
                password_hash=hash_password("123456"),
            )
            db.add(user)
            db.flush()

            cuentas = [
                Account(user_id=user.id, numero_cuenta="100001", tipo_cuenta="ahorros", saldo=500000.0),
                Account(user_id=user.id, numero_cuenta="100002", tipo_cuenta="ahorros", saldo=120000.0),
                Account(user_id=user.id, numero_cuenta="200001", tipo_cuenta="ahorros", saldo=250000.0),
                Account(user_id=user.id, numero_cuenta="200002", tipo_cuenta="ahorros", saldo=300000.0),
            ]
            db.add_all(cuentas)
            db.commit()
    finally:
        db.close()
