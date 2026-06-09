---
phase: 1
title: "Prerequisites & Credential Setup"
status: pending
priority: P1
effort: "30min"
dependencies: []
---

# Phase 1: Prerequisites & Credential Setup

## Overview

Verify all required accounts, credentials, and App Store Connect configuration before creating the Xcode Cloud workflow.

## Requirements

- **Functional**: Apple Developer Program active, App ID registered, GitHub repo connected
- **Non-functional**: All credentials verified in under 30 minutes

## Implementation Steps

### 1. Verify Apple Developer Program Membership

```
1. Go to https://developer.apple.com/account
2. Confirm membership is Active (not expired)
3. Note your Team ID (found in Membership Details)
```

### 2. Register App ID in Apple Developer Portal

```
1. Go to Certificates, Identifiers & Profiles → Identifiers
2. Click + to register new App ID
3. Configure:
   - Description: StressMonitor
   - Bundle ID: Explicit → StressMonitor.StressMonitor
   - Capabilities: 
     ✅ HealthKit (required for stress monitoring)
     ✅ CloudKit (if using cloud sync)
4. Register
```

### 3. Create App Record in App Store Connect

```
1. Go to https://appstoreconnect.apple.com
2. My Apps → + → New App
3. Fill in:
   - Platforms: iOS
   - Name: StressMonitor (or your display name)
   - Primary Language: English
   - Bundle ID: StressMonitor.StressMonitor
   - SKU: stressmonitor-001
   - Full Access: Yes
4. Create
```

### 4. Connect GitHub Repo to Xcode Cloud

```
1. Open Xcode on your Mac
2. Go to Settings (⌘,) → Accounts
3. Ensure your Apple ID is added with Developer role
4. In your project:
   - Product → Xcode Cloud → Create Workflow
   - Xcode will prompt to connect to GitHub
   - Authorize access to NextGen-Limited/ios-stress-app
5. Verify repo connection is active
```

### 5. Verify Xcode Project Settings

```
1. In Xcode, select StressMonitor target
2. Signing & Capabilities tab:
   - ✅ Automatically manage signing
   - Team: Select your team
   - Bundle Identifier: StressMonitor.StressMonitor
3. Verify HealthKit capability is added
4. Repeat for watchOS target (StressMonitorWatch)
```

## Related Code Files

- Verify: `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` (signing settings)
- Verify: `StressMonitor/Info.plist` (HealthKit usage descriptions)

## Success Criteria

- [ ] Apple Developer Program membership is active
- [ ] App ID `StressMonitor.StressMonitor` registered with HealthKit capability
- [ ] App record exists in App Store Connect
- [ ] GitHub repo connected to Xcode Cloud
- [ ] Auto-signing works locally (build succeeds in Xcode with signing ON)

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| HealthKit capability missing from App ID | Medium | Build fails | Double-check in Step 2 |
| Team provisioning profile issues | Low | Build fails | Use auto-managed signing |
| GitHub org admin approval needed | Medium | Can't connect repo | Ask org admin to approve |
