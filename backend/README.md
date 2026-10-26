# Nexora Backend

This folder contains the real FastAPI backend for the Nexora project.

## Stack

- FastAPI
- SQLAlchemy
- SQLite for local development
- JWT authentication
- Pydantic validation

## Run locally

```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Environment

Copy `.env.example` to `.env` and adjust values if needed.

## Default demo user

A demo user is created automatically when the app starts:

- email: ana@nexora.com
- password: 123456

## Main endpoints

- `POST /api/auth/login`
- `POST /api/auth/register`
- `GET /api/accounts/me`
- `GET /api/accounts/{numero_cuenta}/saldo`
- `POST /api/transferencias`
- `GET /api/transferencias`
- `POST /api/risk/transferencia`

## Notes

This backend is designed to mirror the logic already defined in the Flutter mock backend, but with real persistence and authentication.
