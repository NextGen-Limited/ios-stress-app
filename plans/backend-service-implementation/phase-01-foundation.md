# Phase 1: Foundation

**Priority:** Critical (blocking)
**Status:** In Progress
**File Ownership:** `backend/app/config.py`, `backend/app/database.py`, `backend/app/models/*`, `backend/app/schemas/*`

## Overview

Set up project structure, configuration, database models, and schemas.

## Files to Create

- `backend/requirements.txt`
- `backend/.env.example`
- `backend/app/__init__.py`
- `backend/app/config.py`
- `backend/app/database.py`
- `backend/app/models/__init__.py`
- `backend/app/models/user.py`
- `backend/app/models/preferences.py`
- `backend/app/schemas/__init__.py`
- `backend/app/schemas/auth.py`
- `backend/app/schemas/chat.py`
- `backend/app/schemas/preferences.py`
- `backend/app/main.py`

## Implementation Steps

1. Create `requirements.txt` with all dependencies
2. Create `config.py` with pydantic-settings for env vars
3. Create `database.py` with async SQLAlchemy engine
4. Create User model (id, email, hashed_password, created_at)
5. Create UserPreferences model (user_id, notification_settings, stress_thresholds, breathing_patterns, chat_personality)
6. Create Pydantic schemas for auth, chat, preferences
7. Create `main.py` with FastAPI app initialization

## Success Criteria

- [ ] All files created with correct imports
- [ ] Models define correct relationships
- [ ] Schemas validate input correctly
- [ ] FastAPI app starts without errors
