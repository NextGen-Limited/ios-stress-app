# Phase 5: iOS Client Integration

**Priority:** High
**Status:** Pending
**Depends On:** Phase 2, 3, 4
**File Ownership:** `StressMonitor/StressMonitor/Services/LLM/*`

## Overview

Update iOS app to use authenticated backend endpoints.

## Files to Modify

- `StressMonitor/StressMonitor/Services/LLM/CloudLLMService.swift`
- `StressMonitor/StressMonitor/Services/LLM/LLMAPITarget.swift`

## Implementation Steps

1. Update `LLMAPITarget.swift`:
   - Add auth endpoints (register, login, refresh)
   - Add preferences endpoints
   - Update base URL to configurable backend
2. Update `CloudLLMService.swift`:
   - Add JWT token storage (Keychain)
   - Include Authorization header in requests
   - Handle token refresh on 401
3. Add backend URL configuration in Settings

## Success Criteria

- [ ] iOS app authenticates with backend
- [ ] Chat requests include JWT token
- [ ] Token refresh works transparently
- [ ] Preferences sync between app and backend
