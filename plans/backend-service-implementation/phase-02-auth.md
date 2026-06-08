# Phase 2: Authentication

**Priority:** Critical
**Status:** Pending
**Depends On:** Phase 1
**File Ownership:** `backend/app/routes/auth.py`, `backend/app/services/auth_service.py`, `backend/app/middleware/auth.py`

## Overview

Implement JWT-based authentication with register, login, and token refresh.

## Files to Create/Modify

- `backend/app/services/auth_service.py`
- `backend/app/routes/auth.py`
- `backend/app/middleware/__init__.py`
- `backend/app/middleware/auth.py`

## Implementation Steps

1. Create `auth_service.py`:
   - Password hashing with bcrypt (passlib)
   - JWT token creation (access + refresh)
   - Token validation and decoding
2. Create `routes/auth.py`:
   - `POST /auth/register` - validate email, hash password, create user
   - `POST /auth/login` - verify credentials, return tokens
   - `POST /auth/refresh` - validate refresh token, return new access token
3. Create `middleware/auth.py`:
   - JWT Bearer dependency for protected routes
   - Extract user from token

## Success Criteria

- [ ] Register creates user with hashed password
- [ ] Login returns valid JWT access + refresh tokens
- [ ] Protected routes reject invalid/missing tokens
- [ ] Refresh endpoint issues new access token
