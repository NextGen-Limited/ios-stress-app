---
phase: 2
title: "Configure Xcode Cloud Workflow"
status: pending
priority: P1
effort: "1h"
dependencies: [phase-01-prerequisites-credential-setup]
---

# Phase 2: Configure Xcode Cloud Workflow

## Overview

Create and configure the Xcode Cloud workflow that triggers on merge to `main`, builds both iOS and watchOS targets, and auto-archives for TestFlight distribution.

## Architecture

```
Xcode Cloud Workflow: "Deploy to TestFlight"
├── Trigger: Push to main branch
├── Environment: Clean build (no cache for distribution)
├── Actions:
│   ├── 1. Build + Test (iOS - StressMonitor scheme)
│   ├── 2. Build (watchOS - StressMonitorWatch scheme)
│   └── 3. Archive (iOS for distribution)
├── Post-build:
│   └── Auto-upload to TestFlight
└── Notifications: Email + optional Slack webhook
```

## Implementation Steps

### 1. Create Workflow in Xcode

```
1. Open StressMonitor.xcodeproj in Xcode
2. Product → Xcode Cloud → Create Workflow
3. Select product: StressMonitor
4. Xcode auto-detects settings → Review & Create
```

### 2. Configure Workflow Settings

**General tab:**
- Workflow name: `Deploy to TestFlight`
- Branch: `main`
- Trigger: `Every push to main` (NOT on PRs — PRs use GitHub Actions CI)

**Environment tab:**
- Clean build: ✅ Enabled (fresh build for distribution)
- Xcode version: Latest stable (or match local Xcode 26.x)
- macOS version: Latest

**Actions tab:**

**Action 1 — Build & Test (iOS):**
- Scheme: `StressMonitor`
- Destination: `Any iOS Device` (for archive)
- Run tests: ✅ Enable
- Test destination: `iPhone 16` (latest simulator)

**Action 2 — Build (watchOS) — Optional:**
- Scheme: `StressMonitorWatch`
- Destination: `Any watchOS Device`

### 3. Configure Archive & Distribution

```
1. In the workflow editor, scroll to "Archive" section
2. Enable: ✅ Archive the app
3. Distribution method: TestFlight
4. Xcode Cloud will auto-manage:
   - Certificates (Distribution certificate)
   - Provisioning profiles
   - App Store Connect upload
```

### 4. Configure Post-Actions

```
1. After Archive:
   - ✅ Upload to App Store Connect
   - ✅ Make available for TestFlight
2. TestFlight settings:
   - Enable automatic distribution to internal testers
   - Build notes: Auto-include commit message
```

### 5. Optional: Custom Build Script (ci_scripts/ci_post_clone.sh)

If you need custom logic (version bumping, etc.):

```bash
#!/bin/sh
# ci_scripts/ci_post_clone.sh
# Runs after Xcode Cloud clones the repo

set -e

# Auto-increment build number
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Get latest TestFlight build number
LATEST_BUILD=$(xcrun altool --list-apps \
  --apiKey "$APP_STORE_CONNECT_API_KEY_ID" \
  --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID" 2>/dev/null | \
  grep -A1 "StressMonitor" | grep "BuildVersion" | awk '{print $2}' || echo "0")

NEW_BUILD=$((LATEST_BUILD + 1))

# Update build number in Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD" \
  StressMonitor/Info.plist

echo "Build number set to $NEW_BUILD"
```

### 6. Save & Trigger First Build

```
1. Save workflow
2. Trigger manual build: Product → Xcode Cloud → Start Build
3. Monitor in Xcode → Report Navigator → Cloud tab
4. Wait for build to complete (~15-20 min first build)
```

## Related Code Files

- Create: `ci_scripts/ci_post_clone.sh` (optional, for build number bump)
- Modify: `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` (auto-managed by Xcode Cloud)
- Reference: `.github/workflows/ci.yml` (keep for PR builds)

## Success Criteria

- [ ] Workflow triggers on push to `main`
- [ ] iOS build succeeds with auto-signing
- [ ] watchOS build succeeds (if configured)
- [ ] Unit tests pass
- [ ] Archive is created and uploaded to App Store Connect
- [ ] Build appears in TestFlight section of App Store Connect

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| First build slow (cache miss) | High | Wait ~20min | Normal, subsequent builds faster |
| Xcode version mismatch | Medium | Build fails | Pin Xcode version in workflow settings |
| SPM dependency resolution slow | Medium | Timeout | Ensure Package.resolved is committed |
| Signing fails (capabilities mismatch) | Low | Build fails | Verify App ID has all required capabilities |
