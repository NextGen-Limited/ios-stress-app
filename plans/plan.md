---
title: "Xcode Cloud CD Pipeline: Merge to Main → Auto TestFlight"
description: "Set up Xcode Cloud CI/CD pipeline that auto-builds and deploys StressMonitor to TestFlight on every merge to main branch."
status: pending
priority: P1
branch: "main"
tags: [xcode-cloud, testflight, ci-cd, ios]
blockedBy: []
blocks: []
created: "2026-06-09T05:39:47.193Z"
createdBy: "ck:plan"
source: skill
---

# Xcode Cloud CD Pipeline: Merge to Main → Auto TestFlight

## Overview

Set up automated CD pipeline using **Xcode Cloud** that triggers on every merge to `main`, builds the StressMonitor iOS + watchOS app, runs tests, and auto-distributes to **TestFlight** for internal/external testers.

## Context

| Item | Value |
|------|-------|
| Xcode project | `StressMonitor/StressMonitor.xcodeproj` |
| Scheme (iOS) | `StressMonitor` |
| Scheme (watchOS) | `StressMonitorWatch` |
| Bundle ID (iOS) | `StressMonitor.StressMonitor` |
| Bundle ID (watchOS) | `StressMonitor.StressMonitor.watchkitapp` |
| Repo | `NextGen-Limited/ios-stress-app` (GitHub, SSH) |
| Branch | `main` |
| iOS deployment target | 18.6 / 26.1 |
| Xcode Cloud free tier | 25 compute hours/month |
| Existing CI | GitHub Actions (build-only, no signing) |

## Why Xcode Cloud over GitHub Actions

- **Auto signing**: Apple manages certificates & provisioning — no manual cert management
- **TestFlight built-in**: One-click distribution, no fastlane needed
- **25h free/month**: ~50-100 builds, sufficient for this project
- **Native integration**: Status in Xcode + App Store Connect

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| CI platform | Xcode Cloud | Free 25h/mo, auto signing, native TestFlight |
| Trigger | Push to main | CD on merge, not on PR (PR builds stay on GitHub Actions) |
| Signing | Auto (Xcode Cloud managed) | No cert hassle |
| Distribution | TestFlight Internal + External | Start with internal, expand later |
| watchOS | Included in same workflow | Build both iOS + watchOS |

## Credentials Needed (Phase 1)

| Credential | Where to get | Where to store |
|------------|-------------|----------------|
| Apple Developer Program membership ($99/yr) | developer.apple.com | Active membership required |
| App Store Connect — App record | App Store Connect → Apps → + | Auto-created on first build |
| GitHub repo access for Xcode Cloud | Xcode → Settings → Xcode Cloud | OAuth connection |
| App Store Connect API Key (optional, for scripts) | App Store Connect → Integrations → App Store Connect API | Not needed for basic setup |

## Phases

| Phase | Name | Status | Effort |
|-------|------|--------|--------|
| 1 | [Prerequisites & Credential Setup](phase-01-prerequisites-credential-setup.md) | pending | 30min |
| 2 | [Configure Xcode Cloud Workflow](phase-02-configure-xcode-cloud-workflow.md) | pending | 1h |
| 3 | [TestFlight Distribution & Testing](phase-03-testflight-distribution-testing.md) | pending | 1h |
| 4 | [Production Hardening](phase-04-production-hardening.md) | pending | 2h |

## Pipeline Flow

```
[PR merged to main]
       ↓
[Xcode Cloud auto-trigger]
       ↓
[Build iOS (StressMonitor scheme)]
       ↓
[Build watchOS (StressMonitorWatch scheme)] ← parallel or sequential
       ↓
[Run Unit Tests (StressMonitorTests)]
       ↓
[Archive & Auto-sign]
       ↓
[Upload to TestFlight]
       ↓
[Internal testers get notification]
       ↓
[TestFlight beta feedback → Xcode]
```

## Risks

| Risk | Mitigation |
|------|-----------|
| 25h free tier exhausted | Monitor usage in App Store Connect; optimize build times |
| Bundle ID `StressMonitor.StressMonitor` needs explicit App ID | Create in Apple Developer Portal before first build |
| Xcode 26.3 not available on Xcode Cloud | Use latest stable Xcode version available; pin in workflow settings |
| watchOS build fails | Separate workflow for watchOS with different trigger |

## Success Criteria

- [ ] Xcode Cloud workflow triggers on merge to `main`
- [ ] Build succeeds with auto-signing
- [ ] App appears in TestFlight within 10 minutes of merge
- [ ] Internal testers can install and run the app
- [ ] Build status visible in Xcode + App Store Connect
