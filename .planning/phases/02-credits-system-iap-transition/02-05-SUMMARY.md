---
phase: 02-credits-system-iap-transition
plan: 05
subsystem: storekit-credits
tags: [storekit, iap, build-config, info-plist, gap-closure, CR-04]
requires:
  - 02-03 (StoreKitProductCatalog pack keys + .storekit consumable entries)
provides:
  - Pack product-ID resolution in real builds (both DEC-2 SKUs resolve from Bundle.main)
  - Enabled hosted StoreKitProductCatalogLiveTests suite as standing regression guard
affects:
  - StoreKitService.purchase(pack:) — no longer throws missingProductConfiguration when IDs resolve
  - StoreKitProductCatalog.live — tier-1 Bundle.main resolution now yields pack IDs
tech-stack:
  added: []
  patterns:
    - "Dual delivery: pbxproj INFOPLIST_KEY_* as configuration record + literal keys in the INFOPLIST_FILE plist that Xcode actually merges into Bundle.main"
key-files:
  created: []
  modified:
    - StressMonitor/StressMonitor.xcodeproj/project.pbxproj
    - StressMonitor/StressMonitor/Info.plist
    - StressMonitor/StressMonitorTests/StoreKitProductCatalogLiveTests.swift
decisions:
  - "Premium STOREKIT_* keys ride along in the Info.plist delivery tier — their delivery was equally unproven (02-VERIFICATION gap 1 reason); same mechanism, zero extra surface"
  - "Existing three live tests kept byte-identical per plan; only the disabled annotation/header were removed"
metrics:
  duration: 15m
  completed: 2026-08-17T07:11:57Z
  commits: 2
status: complete
estimate:
  tokens: 16000
  raw_tokens: 8000
actuals:
  tokens: 1410
  tasks: 2
  commits: 2
---

# Phase 02 Plan 05: Pack Product-ID Resolution Gap Closure Summary

**One-liner:** Credit-pack product IDs now resolve in real builds — build settings in both app-target configurations, literal STOREKIT_* keys in the merged Info.plist file, and the re-enabled hosted live-catalog suite green 6/6 as the empirical Bundle.main delivery proof.

## What Was Built

### Task 1: Build settings + Info.plist delivery tier (commit 2a58b6c)

- `project.pbxproj`: `INFOPLIST_KEY_STOREKIT_CREDITS_LARGE_PRODUCT_ID = "com.stressmonitor.app.credits.large"` and `INFOPLIST_KEY_STOREKIT_CREDITS_SMALL_PRODUCT_ID = "com.stressmonitor.app.credits.small"` added to BOTH app-target XCBuildConfiguration blocks (the two owning `PRODUCT_BUNDLE_IDENTIFIER = stress.ai.com;`), alphabetically before the premium keys. Watch/widget/test-target blocks untouched.
- `StressMonitor/Info.plist`: six top-level literal keys added (tab-indented, CFBundleURLTypes untouched) — `STOREKIT_CREDITS_{LARGE,SMALL}_PRODUCT_ID`, `STOREKIT_PREMIUM_{ANNUAL,MONTHLY,WEEKLY}_PRODUCT_ID`, `STOREKIT_PREMIUM_SUBSCRIPTION_GROUP_ID`. This file is wired as `INFOPLIST_FILE` with `GENERATE_INFOPLIST_FILE = YES`, so Xcode merges these keys into the built product's Info.plist — the delivery tier custom `INFOPLIST_KEY_*` settings provably lack.
- No Swift production code touched; `StoreKitProductCatalog` already resolves these exact keys at tier 1 of its 3-tier resolve.

### Task 2: Re-enabled live suite with pack assertions (commit 297b0d4)

- `@Suite(.disabled(...))` annotation and the 9-line DISABLED header removed; `StoreKitProductCatalogLiveTests` is a normal enabled suite again.
- Three existing tests kept unchanged; added `liveCatalogResolvesSmallPack`, `liveCatalogResolvesLargePack`, and `liveSmallPackIDRoundTrips` (pack(for:) on the resolved small ID returns `.small`), each with a failure message naming the Info.plist key that must be present.

## Verification Results

| Check | Command | Result |
| ----- | ------- | ------ |
| pbxproj pack keys | `grep -c "STOREKIT_CREDITS" project.pbxproj` | 4 (2 keys x Debug+Release, lines 850-851/907-908 inside the two stress.ai.com blocks) |
| Info.plist delivery tier | `grep -c "STOREKIT_" Info.plist` + `plutil -lint` | 6 keys, OK |
| Disabled marker gone | `grep -c "disabled"` on LiveTests | 0; 6 `@Test` functions |
| Hosted suite green | `xcodebuild test -only-testing:StressMonitorTests/StoreKitProductCatalogLiveTests -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO` | TEST SUCCEEDED — 6/6, including both pack-ID assertions against the hosted app's Bundle.main (the empirical delivery proof gap 1 demanded) |
| Release build (BUILD-05) | `xcodebuild build -configuration Release -destination 'platform=iOS Simulator,name=iPhone 17'` | BUILD SUCCEEDED, exit 0 |

## Gap Closure Assessment

Closes verification Gap 1 (CR-04 / 02-VERIFICATION truth 13, requirement IAP-01 ID-resolution half):

- "Add pack product-ID build settings in both app-target configurations" — done (Task 1).
- "Verify the chosen delivery mechanism actually lands in Bundle.main" — done: the hosted suite's pack assertions read `StoreKitProductCatalog.live` (Bundle.main tier) inside the running app and passed 6/6.
- "Re-enable StoreKitProductCatalogLiveTests with pack assertions" — done (Task 2).

Not this plan (unchanged, tracked in 02-VERIFICATION human_verification): ASC filing of the two consumables and the live sandbox money-path smoke against the deployed backend.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Missing gitignored GoogleService-Info.plist crashed the test host at launch**
- **Found during:** Task 2 verify (first suite run)
- **Issue:** Hosted test app terminated with SIGABRT before bootstrapping — `FirebaseApp.configure()` could not find `GoogleService-Info.plist`. The file is gitignored (`.gitignore:176`) and exists only in the main checkout, so the fresh worktree lacked it.
- **Fix:** Copied the gitignored file from the main checkout into the worktree (`StressMonitor/StressMonitor/Info.plist` sibling). It remains untracked/ignored — never committed, no history impact. Suite then passed 6/6.
- **Note for sibling worktree agents:** any executor running hosted StressMonitorTests in a fresh worktree needs this same local file copy.
- **Files modified:** none in git (ignored file copy only)

Otherwise the plan executed exactly as written.

## Known Stubs

None. No placeholder values, no unwired components, no skipped verifies.

## Threat Surface Scan

No new security-relevant surface beyond the plan's threat model. T-2-501 (tampering/drift of product-ID keys) and T-2-502 (pack-purchase DoS) mitigations landed as planned: the enabled live suite now fails the build-test gate if any STOREKIT_* key drifts or vanishes from the delivered Info.plist.

## Self-Check: PASSED

All 4 claimed files exist on disk (pbxproj, Info.plist, LiveTests, SUMMARY). Both task commits present in git log (2a58b6c, 297b0d4). Working tree clean apart from this SUMMARY.
