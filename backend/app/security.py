from __future__ import annotations

from datetime import datetime, timedelta

import jwt
from jwt import InvalidTokenError
from passlib.context import CryptContext

from app.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(subject: str) -> str:
    expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    payload = {"sub": subject, "exp": expire}
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def decode_access_token(token: str) -> str:
    if not token or not isinstance(token, str):
        raise ValueError("Token inválido o expirado")

    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        subject = payload.get("sub")
        if not subject:
            raise ValueError("Token sin sub")
        return str(subject)
    except (InvalidTokenError, TypeError, ValueError, UnicodeDecodeError, UnicodeEncodeError) as exc:
        raise ValueError("Token inválido o expirado") from exc
