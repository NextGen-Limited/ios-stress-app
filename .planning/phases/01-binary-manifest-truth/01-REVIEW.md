---
phase: 01-binary-manifest-truth
reviewed: 2026-09-03T12:26:18Z
depth: standard
iteration: 4 (final — re-review closed after CI-parity build, full test suite, and harness verification)
files_reviewed: 20
files_reviewed_list:
  - .gitignore
  - CLAUDE.md
  - docs-site/legal/privacy.md
  - docs-site/vi/legal/privacy.md
  - scripts/verify-archive-tests.sh
  - scripts/verify-archive.sh
  - StressMonitor/spm-cache/packages/proxy/.proxies/Firebase_proxy/Package.swift
  - StressMonitor/spm-cache/packages/proxy/.proxies/Firebase_proxy/Sources/Firebase_FirebaseAuth_shim/Firebase_FirebaseAuth_shim.swift
  - StressMonitor/spm-cache/packages/proxy/.proxies/Firebase_proxy/Sources/Firebase_FirebaseCore_shim/Firebase_FirebaseCore_shim.swift
  - StressMonitor/spm-cache/packages/proxy/.proxies/GoogleSignIn-iOS_proxy/Package.swift
  - StressMonitor/spm-cache/packages/proxy/.proxies/GoogleSignIn-iOS_proxy/Sources/GoogleSignIn-iOS_GoogleSignIn_shim/GoogleSignIn-iOS_GoogleSignIn_shim.swift
  - StressMonitor/spm-cache/packages/proxy/.proxies/GoogleSignIn-iOS_proxy/Sources/GoogleSignIn-iOS_GoogleSignInSwift_shim/GoogleSignIn-iOS_GoogleSignInSwift_shim.swift
  - StressMonitor/spm-cache/packages/proxy/Package.resolved
  - StressMonitor/spm-cache/packages/proxy/Package.swift
  - StressMonitor/spm-cache/packages/proxy/src/root/spm_cache_root.swift
  - StressMonitor/StressMonitor.xcodeproj/project.pbxproj
  - StressMonitor/StressMonitor.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - StressMonitor/StressMonitorTests/FirebaseBootstrapTests.swift
  - "StressMonitor/StressMonitorWatch Watch App/PrivacyInfo.xcprivacy"
  - StressMonitor/StressMonitorWidget/README.md
findings:
  critical: 0
  warning: 0
  info: 7
  total: 7
status: findings
---

# Phase 1: Code Review Report — Binary & Manifest Truth (Final Re-Review)

**Reviewed:** 2026-09-03
**Depth:** standard
**Files Reviewed:** 20 (original phase scope; fix-pass delta `c9cf40a..HEAD`)
**Status:** findings — all 5 in-scope findings (1 Critical, 4 Warnings) verified **FIXED** with empirical evidence; no new Critical/Warning findings; no regressions. The 7 documented Info findings from the initial review remain open (out of fix scope per `--fix` default) and are carried below.

## Summary

Final re-review after the fix pass (commits `3ba30d2`, `34dfc27`, `dbba5a0`, `a90d55b`, `93e044e`, in order at HEAD). Each fix was verified adversarially — exercised in both red and green directions, probed with edge cases beyond the fixer's own tests — and the previously pending CI-parity verification has now completed green. Prior verified positives were re-confirmed: exact-revision proxy pins (`firebase-ios-sdk@fdc352f…`, `GoogleSignIn-iOS@08d8dce…`), identical pin sets in both `Package.resolved` files, pure `@_exported import` shims, the `.gitignore` exception chain tracking exactly the 9 proxy source files, intact watch privacy manifest, and `GoogleService-Info.plist` ignored at exactly `StressMonitor/StressMonitor/`.

## Fix Verification — 5/5 FIXED

| Prior finding | Fix commit | Verdict | Evidence |
|---|---|---|---|
| CR-01 vacuous CFBundleURLSchemes check | `3ba30d2` | **Fixed** | awk state-machine edge-case matrix (populated/self-closed-empty/open-empty/key-absent/empty-string/multi-URL-type/plutil-failure — all correct); harness tests 4–5 red+green incl. absence-assertion that catches the vacuous form; full golden gate run all-green |
| WR-01 golden-archive hard dependency, no guard, false CI claim | `34dfc27` | **Fixed** | Golden-absent simulation in temp root → single clean `SKIP:` line, exit 0, no cascade; golden-present → 5/5 PASS; header now states the truth (`.github/` has zero `verify-archive` references) |
| WR-02 9 orphaned PBXBuildFile entries | `dbba5a0` | **Fixed** | Diff = exactly 18 deletions, 0 additions; removed IDs grep to 0; no-ref scan negative; `plutil -lint` OK; `xcodebuild -list` resolves; **CI-parity BUILD SUCCEEDED** proves `packageProductDependencies` is sufficient linkage |
| WR-03 dead `provision_firebase_config.sh` pointer | `a90d55b` | **Fixed** | `git check-ignore` on the documented recovery path; quick-task record `260829-kby` exists; source-wide grep → zero remaining references to the nonexistent script; test/runtime wording in sync |
| WR-04 privacy policies missing 4 collection types | `93e044e` | **Fixed** | All 5 manifest types (HealthAndFitness, PhotoVideo, OtherUserContent, DeviceID, ProductInteraction) cross-checked against both locales, purpose-by-purpose — app-functionality only, never tracking, matching `NSPrivacyTracking=false` |

**Final verification (this session, CI parity):**

- CI-parity build (`generic/platform=iOS Simulator`, signing off): **BUILD SUCCEEDED** (exit 0) — confirms WR-02's orphan removal does not break linking.
- Full test suite (`TEST_RUNNER_GSD_CI=1`, `-parallel-testing-enabled NO`, iPhone 16 / OS=latest): **TEST SUCCEEDED** (exit 0).
- `scripts/verify-archive-tests.sh`: **5/5 PASS, 0 failures** — including the new red/green anti-vacuous CFBundleURLSchemes tests (red asserts FAIL present **and** PASS absent).

Known residual boundary of the rewritten CR-01 check, documented and accepted (no action required): a hand-malformed type shape (bare `<string>` where an `<array>` belongs) would still count as an entry — unreachable via Xcode/PlistBuddy/`plutil` serialization, and the check only reads `plutil` output. If the gate is ever hardened, require the `<array>` opener between key and first `<string>`.

**Regression check:** `git diff c9cf40a..HEAD` touches exactly the 7 files belonging to the 5 fix commits — `scripts/verify-archive.sh`, `scripts/verify-archive-tests.sh`, `project.pbxproj`, `FirebaseBootstrapTests.swift`, `StressMonitor/StressMonitor/Services/Firebase/FirebaseBootstrap.swift` (WR-03's mirrored runtime log — read during fix verification; the one fix file outside the original 20-file scope), `docs-site/legal/privacy.md`, `docs-site/vi/legal/privacy.md` — and nothing else; every other in-scope file is byte-identical.

## Carried Info (known, documented — out of fix scope per `--fix` default)

- **IN-01** `scripts/verify-archive.sh:29` — credential-scan pattern set misses AWS (`AKIA…`), GitHub (`gh…_`/`github_pat_`), and Slack (`xox…-`) token shapes.
- **IN-02** `scripts/verify-archive.sh:35-43` — allowlist still masks `supabase*` literals that no longer exist in source, so their reintroduction would scan green.
- **IN-03** `scripts/verify-archive.sh:15-16` — stale comment still describes the removed `INFOPLIST_KEY_STOREKIT_*` merge mechanism.
- **IN-04** `StressMonitor/StressMonitorWidget/README.md:5,79-83,114-137` — remaining truth gaps: target/binary name (`StressMonitorWidget` vs `StressMonitorWidgetExtension`), "iOS 17" vs actual 18.6, and an unimplemented `handleDeepLink(_:)` snippet.
- **IN-05** `CLAUDE.md:207,480` — "Dependencies: None" contradicts the SPM proxy migration; "iOS 17+" vs actual 18.6; root `AGENTS.md` still claims `GoogleService-Info.plist` is committed.
- **IN-06** `project.pbxproj:652-1001` + `proxy/src/root/spm_cache_root.swift` — non-canonical pbxproj formatting invites wholesale Xcode rewrite churn; the tracked proxy root file is 0 bytes with no placeholder comment.
- **IN-07** `proxy/Package.resolved:74-82` — only the 2 direct dependencies are revision-pinned; 15 transitive pins float on re-resolution (GoogleUtilities already drifted 8.1.2→8.1.3 in-phase).

All seven confirmed untouched by the fix pass (`git diff c9cf40a..HEAD`); triage stays with the orchestrator/developer.

---

_Reviewed: 2026-09-03_
_Reviewer: the agent (gsd-code-reviewer) — final re-review, iteration 4_
_Depth: standard_
