# Phase 4: User Preferences

**Priority:** High
**Status:** Pending
**Depends On:** Phase 1, Phase 2
**File Ownership:** `backend/app/routes/preferences.py`, `backend/app/services/preferences_service.py`

## Overview

Implement CRUD endpoints for user preferences.

## Files to Create/Modify

- `backend/app/services/preferences_service.py`
- `backend/app/routes/preferences.py`

## Implementation Steps

1. Create `preferences_service.py`:
   - Get preferences (with defaults if none exist)
   - Update preferences (partial update supported)
2. Create `routes/preferences.py`:
   - `GET /preferences` - Get current user's preferences
   - `PUT /preferences` - Update preferences

## Preferences Schema

```json
{
  "notifications": {
    "stress_alerts": true,
    "daily_summary": true,
    "breathing_reminders": false
  },
  "stress_thresholds": {
    "moderate_alert": 50,
    "high_alert": 75
  },
  "breathing": {
    "default_technique": "box",
    "duration_minutes": 5
  },
  "chat": {
    "personality": "supportive",
    "detail_level": "concise"
  }
}
```

## Success Criteria

- [ ] GET returns preferences with defaults for new users
- [ ] PUT updates only provided fields (partial update)
- [ ] Preferences are user-scoped (authenticated)
- [ ] Invalid preferences rejected with 422
