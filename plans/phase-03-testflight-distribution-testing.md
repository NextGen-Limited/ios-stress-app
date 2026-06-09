---
phase: 3
title: "TestFlight Distribution & Testing"
status: pending
priority: P1
effort: "1h"
dependencies: [phase-02-configure-xcode-cloud-workflow]
---

# Phase 3: TestFlight Distribution & Testing

## Overview

Configure TestFlight groups, invite testers, and verify the full distribution flow from Xcode Cloud build → tester device.

## Architecture

```
TestFlight Distribution Flow:
┌─────────────────────┐
│ Xcode Cloud Build    │
│ → Archive uploaded   │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ App Store Connect    │
│ → TestFlight tab     │
│ → Processing (~5min) │
└──────────┬──────────┘
           ↓
┌─────────────────────────────────────┐
│ Internal Testing Group              │
│ → Auto-notify on new build          │
│ → Up to 100 testers (App Team)      │
│ → No beta review required           │
└──────────┬──────────────────────────┘
           ↓ (optional, Phase 4)
┌─────────────────────────────────────┐
│ External Testing Group              │
│ → Up to 10,000 testers              │
│ → Requires brief beta review        │
└─────────────────────────────────────┘
```

## Implementation Steps

### 1. Configure Internal Testing Group

```
1. App Store Connect → My Apps → StressMonitor → TestFlight
2. Go to "Groups" in left sidebar
3. Click + to create group:
   - Name: "Internal Team"
   - Enable: ✅ Automatic distribution
   - Build: Latest build from Xcode Cloud
4. Add testers:
   - Add by Apple ID email
   - Or add all App Store Connect users (Admin, Dev, App Manager)
```

### 2. Set Up TestFlight App

On each tester's iPhone:
```
1. Download TestFlight from App Store (if not installed)
2. Open invitation email → Accept invite
3. Install StressMonitor beta
4. App appears on home screen with orange dot (beta indicator)
```

### 3. Configure Build Settings

```
In App Store Connect → TestFlight → Builds:
1. Select latest build
2. Test Information:
   - What to Test: "Merge to main auto-build. Test stress monitoring, dashboard, trends."
   - Description: Auto-populated from release notes
3. Privacy Policy URL: (required for external testing)
4. Review Notes: "Internal testing build. HealthKit access required."
```

### 4. Test the Full Pipeline

```
1. Make a small change on a feature branch
2. Create PR → merge to main
3. Verify:
   ✅ Xcode Cloud triggers automatically
   ✅ Build completes (~15 min)
   ✅ Build appears in TestFlight (processing ~5 min)
   ✅ Testers receive push notification
   ✅ App installs and runs correctly
   ✅ HealthKit permissions work
   ✅ Stress monitoring data displays
```

### 5. Configure TestFlight Beta Feedback

```
1. Testers can submit feedback via:
   - Screenshot → Share → TestFlight Beta Feedback
   - In-app shake gesture → Beta Feedback
2. Feedback appears in:
   - App Store Connect → TestFlight → Feedback
   - Xcode → Organizer → Crashes & Feedback
```

## Related Code Files

- No code changes needed — this is all App Store Connect configuration
- Verify: HealthKit Info.plist keys are correct:
  - `NSHealthShareUsageDescription`
  - `NSHealthUpdateUsageDescription`

## Success Criteria

- [ ] Internal testing group created with auto-distribution
- [ ] At least 1 tester can install the app via TestFlight
- [ ] Merge to `main` → auto-build → auto-distribute flow works end-to-end
- [ ] TestFlight push notification received by testers
- [ ] App launches and HealthKit permissions work correctly
- [ ] Beta feedback can be submitted and viewed in App Store Connect

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| TestFlight processing takes long (>30min) | Low | Delay | Apple processes most builds in 5-15min |
| HealthKit permissions rejected in beta | Medium | App unusable | Verify Info.plist descriptions are clear |
| Build rejected (missing privacy policy) | Medium | External testing blocked | Add privacy policy URL (not needed for internal) |
| TestFlight invitation expired | Low | Tester can't install | Resend invitation, 30-day expiry |
