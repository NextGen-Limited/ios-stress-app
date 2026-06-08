# Phase 6: Testing & Documentation

**Priority:** Medium
**Status:** Pending
**Depends On:** All previous phases
**File Ownership:** `backend/tests/*`, `backend/README.md`, `backend/Dockerfile`

## Overview

Write tests, create Docker config, and document the API.

## Files to Create

- `backend/tests/__init__.py`
- `backend/tests/conftest.py`
- `backend/tests/test_auth.py`
- `backend/tests/test_chat.py`
- `backend/tests/test_preferences.py`
- `backend/Dockerfile`
- `backend/docker-compose.yml`
- `backend/alembic.ini`
- `backend/alembic/env.py`
- `backend/README.md`

## Implementation Steps

1. Create test fixtures (test database, test client, test user)
2. Write auth tests (register, login, refresh, invalid credentials)
3. Write chat tests (streaming response, error handling)
4. Write preferences tests (CRUD, partial update)
5. Create Dockerfile with multi-stage build
6. Create docker-compose.yml with app + postgres
7. Create Alembic config and initial migration
8. Write README with setup instructions

## Success Criteria

- [ ] All tests pass
- [ ] Docker container builds and runs
- [ ] API documentation auto-generated
- [ ] README covers setup, config, deployment
