# Backend Service Implementation Plan

**Project:** StressMonitor Backend API
**Created:** 2026-06-08
**Status:** In Progress

---

## Overview

Build a FastAPI backend service for the StressMonitor iOS app with:
- JWT-based authentication
- LLM chat service (OpenAI-compatible SSE streaming)
- User preferences storage

## Tech Stack

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| Framework | FastAPI 0.111+ | Async, SSE support, OpenAPI docs |
| Database | SQLite (dev) / PostgreSQL (prod) | Zero-config dev, scalable prod |
| ORM | SQLAlchemy 2.0 + Alembic | Async support, migrations |
| Auth | JWT (python-jose) + bcrypt | Stateless, iOS-friendly |
| LLM Proxy | httpx + OpenAI SDK | Async streaming |
| Validation | Pydantic v2 | FastAPI native |
| Server | uvicorn | ASGI, production-ready |

## Directory Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI app + middleware
│   ├── config.py            # Settings via pydantic-settings
│   ├── database.py          # SQLAlchemy async engine
│   ├── models/
│   │   ├── __init__.py
│   │   ├── user.py          # User model
│   │   └── preferences.py   # UserPreferences model
│   ├── schemas/
│   │   ├── __init__.py
│   │   ├── auth.py          # Login/Register schemas
│   │   ├── chat.py          # Chat request/response schemas
│   │   └── preferences.py   # Preferences schemas
│   ├── routes/
│   │   ├── __init__.py
│   │   ├── auth.py          # POST /auth/register, /auth/login, /auth/refresh
│   │   ├── chat.py          # POST /v1/chat/completions (SSE streaming)
│   │   └── preferences.py   # GET/PUT /preferences
│   ├── services/
│   │   ├── __init__.py
│   │   ├── auth_service.py  # Password hashing, JWT creation/validation
│   │   ├── llm_service.py   # LLM proxy with SSE streaming
│   │   └── preferences_service.py
│   ├── middleware/
│   │   ├── __init__.py
│   │   └── auth.py          # JWT Bearer middleware
│   └── utils/
│       ├── __init__.py
│       └── sse.py           # SSE response helpers
├── alembic/                 # Database migrations
├── tests/
│   ├── test_auth.py
│   ├── test_chat.py
│   └── test_preferences.py
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
├── .env.example
├── alembic.ini
└── README.md
```

## Dependency Graph

```
Phase 1: Foundation (config, models, database)
    ├── Phase 2: Auth (depends on Phase 1)
    ├── Phase 3: LLM Service (depends on Phase 1)
    └── Phase 4: Preferences (depends on Phase 1, 2)
         └── Phase 5: iOS Integration (depends on 2, 3, 4)
              └── Phase 6: Testing (depends on all)
```

## Parallel Execution Strategy

| Group | Phases | Can Run Concurrently |
|-------|--------|---------------------|
| A | 1 (Foundation) | No - must complete first |
| B | 2 (Auth), 3 (LLM) | Yes - independent after Phase 1 |
| C | 4 (Preferences) | After Phase 2 completes |
| D | 5 (iOS Integration) | After Phases 2, 3, 4 |
| E | 6 (Testing) | After all phases |

## API Endpoints

### Auth
- `POST /auth/register` - Create account (email, password)
- `POST /auth/login` - Login (returns access + refresh tokens)
- `POST /auth/refresh` - Refresh access token

### Chat (LLM)
- `POST /v1/chat/completions` - OpenAI-compatible streaming chat
- `GET /health` - Health check

### Preferences
- `GET /preferences` - Get user preferences
- `PUT /preferences` - Update user preferences

## Success Criteria

- [ ] Auth endpoints return valid JWT tokens
- [ ] Chat endpoint streams SSE tokens in OpenAI format
- [ ] Preferences CRUD works with authenticated requests
- [ ] All endpoints documented in OpenAPI/Swagger
- [ ] Docker container builds and runs
- [ ] iOS client can connect and authenticate
