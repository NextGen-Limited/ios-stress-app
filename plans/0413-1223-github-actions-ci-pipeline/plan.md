---
name: GitHub Actions CI Pipeline
description: Build + unit test CI pipeline with merge protection on main
status: in-progress
created: 2026-04-13
author: phuongddx
blocks: [0413-2113-ci-test-reporting-xcresulttool]
---

# GitHub Actions CI Pipeline

## Overview

Add GitHub Actions CI that builds the StressMonitor scheme and runs `StressMonitorTests` on every PR to `main`. Tests must pass before merge is allowed.

## Context

| Item | Value |
|------|-------|
| Xcode project | `StressMonitor/StressMonitor.xcodeproj` |
| Scheme | `StressMonitor` |
| Unit test target | `StressMonitorTests` |
| SPM dependencies | SwiftUICharts 2.10.4, AnimatedTabBar 1.0.0 |
| iOS deployment target | 18.6 / 26.1 |
| Swift version | 5.0 |
| Repo | `NextGen-Limited/ios-stress-app` |

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Runner | `macos-15` | Xcode 26.x support for iOS 26.1 target |
| Test destination | `iPhone 16, iOS 18.6` | Matches lowest deployment target; stable on CI |
| Xcode version | latest-stable | Auto-selects; Xcode 26.x on macos-15 |
| UI tests | Skip on CI | Flaky on GitHub runners, slow, need simulator boot |
| Cache strategy | SPM via `actions/cache` on `.build/checkouts` + `DerivedData` | Cuts 2-3 min off resolve + build |
| Build approach | Single `xcodebuild test` step | Simpler than split build-for-testing / test-without-building for this project size |

## Phase 1: CI Workflow File

Create `.github/workflows/ci.yml` with:
- **Trigger**: `pull_request` to `main`, `push` to `main`
- **Steps**: checkout → cache SPM → resolve deps → xcodebuild test → upload test results on failure
- **Timeout**: 20 min

## Phase 2: Branch Protection

Requires GitHub admin to configure (can't be done via workflow):
1. Settings → Branches → Branch protection rules → `main`
2. Enable "Require status checks to pass before merging"
3. Select `build-and-test` status check
4. Enable "Require branches to be up to date before merging"

## Files to Create

| File | Purpose |
|------|---------|
| `.github/workflows/ci.yml` | CI pipeline definition |

## Files to Modify

None.

## Success Criteria

- [ ] CI workflow runs on every PR to `main`
- [ ] Unit tests pass on CI
- [ ] Branch protection blocks merge on failing tests
- [ ] Build completes under 15 min
- [ ] Cache hits reduce subsequent runs by ~3 min

## Risks

| Risk | Mitigation |
|------|------------|
| Xcode version mismatch with iOS 26.1 target | Use `maxim-lobanov/setup-xcode` to pin version if `latest-stable` fails |
| SPM resolve timeouts | Cache `.build/checkouts` + `Package.resolved` |
| Simulator boot failures | Use `platform=iOS Simulator,name=iPhone 16,OS=latest` (auto-resolves available runtime) |
| Flaky tests | Add `retry_count: 2` via `xcodebuild test-without-building` retry wrapper if needed |

## Unresolved Questions

1. Does the repo org (`NextGen-Limited`) have GitHub Actions enabled? (Assumed yes)
2. Does the user have admin access to configure branch protection? (Will need to verify)
