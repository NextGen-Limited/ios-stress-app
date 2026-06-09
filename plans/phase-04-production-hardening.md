---
phase: 4
title: "Production Hardening"
status: pending
priority: P2
effort: "2h"
dependencies: [phase-03-testflight-distribution-testing]
---

# Phase 4: Production Hardening

## Overview

Optimize build pipeline, add notifications, monitor usage, and prepare for App Store submission.

## Implementation Steps

### 1. Monitor Xcode Cloud Usage

```
1. App Store Connect → Xcode Cloud → Usage
2. Track:
   - Compute hours used / remaining
   - Average build duration
   - Builds per week
3. Set usage alert at 20 hours (80% of 25h free tier)
```

### 2. Optimize Build Times

```
Tips to reduce build time:
- ✅ Commit Package.resolved to lock SPM dependencies
- ✅ Minimize test targets in CD workflow (keep UI tests separate)
- ✅ Use clean build only for distribution builds
- ✅ Skip watchOS build if unchanged (conditional trigger)
- Target: <15 min per build
```

### 3. Add Notifications

**Email notifications** (built-in):
```
App Store Connect → Xcode Cloud → Workflow → Notifications
- ✅ Notify on build success
- ✅ Notify on build failure
- Recipients: All team members
```

**Slack/Discord webhook** (optional):
```
1. App Store Connect → Xcode Cloud → Webhooks
2. Add webhook URL
3. Events: build.completed, test.completed
4. Payload includes: build status, commit info, TestFlight link
```

**Xcode Cloud webhook payload example:**
```json
{
  "action": "build.completed",
  "build": {
    "status": "success",
    "finishDate": "2026-06-09T12:00:00Z"
  },
  "source": {
    "commit": "abc123",
    "branch": "main",
    "message": "feat: add stress history chart"
  }
}
```

### 4. Configure External Testing (Optional)

```
When ready to expand beyond internal team:
1. App Store Connect → TestFlight → Groups → + 
2. Create "External Beta" group
3. Add testers by email or public link
4. Note: External builds require Beta App Review (usually <24h)
5. Required before external testing:
   - ✅ Privacy Policy URL
   - ✅ Beta App Description
   - ✅ Test Information (What to Test)
   - ✅ App Review Information (contact info)
```

### 5. Prepare for App Store Submission

```
Checklist for eventual App Store release:
- [ ] App icon (1024x1024, no alpha)
- [ ] Screenshots (6.5" + 5.5" required)
- [ ] App description + keywords
- [ ] Privacy Policy URL (required)
- [ ] Support URL
- [ ] Age rating completed
- [ ] App Review Information filled
- [ ] Pricing (Free tier)
- [ ] HealthKit capability justification for App Review
```

### 6. Document the Pipeline

```
Create/update docs:
- Add CD section to README.md
- Document workflow configuration
- List testers and groups
- Document rollback procedure:
  1. Revert commit on main
  2. Or: Expire build in TestFlight
  3. Or: Disable Xcode Cloud workflow temporarily
```

## Related Code Files

- Update: `README.md` (add CD documentation)
- Update: `docs/` (pipeline documentation)
- Reference: `.github/workflows/ci.yml` (CI stays separate from CD)

## Success Criteria

- [ ] Xcode Cloud usage monitored, alert set at 80% threshold
- [ ] Build notifications working (email and/or webhook)
- [ ] External testing group configured (if needed)
- [ ] Average build time < 15 minutes
- [ ] Pipeline documented in project README
- [ ] Rollback procedure documented and tested

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Free tier exhausted mid-month | Medium | Pipeline stops | Monitor usage, optimize builds |
| App Store rejects HealthKit usage | Low | Can't ship | Ensure clear usage descriptions |
| Build time increases with codebase | Medium | Uses more hours | Regular optimization review |
