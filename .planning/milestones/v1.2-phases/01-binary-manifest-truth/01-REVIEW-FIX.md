---
phase: 01-binary-manifest-truth
fixed_at: 2026-09-03T19:30:00+07:00
review_path: .planning/phases/01-binary-manifest-truth/01-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-03T19:30:00+07:00
**Source review:** .planning/phases/01-binary-manifest-truth/01-REVIEW.md
**Iteration:** 1
**Branch:** gsd/v1.2-submission-readiness (commits made directly in the main checkout — `workflow.use_worktrees: false`)

**Summary:**
- Findings in scope (critical + warning): 5
- Fixed: 5
- Skipped: 0
- Info findings (7): out of scope for this run (fix_scope: critical_warning) — untouched, documented in the review

## Fixed Issues

### CR-01: CFBundleURLSchemes "has at least one entry" check is vacuous — passes on an empty array

**Files modified:** `scripts/verify-archive.sh`, `scripts/verify-archive-tests.sh`
**Commit:** `3ba30d2`
**Applied fix:** The merged-plists check no longer greps the `plutil -p` dump (whose key line always satisfies a quote grep). It converts the app Info.plist to its canonical XML serialization with `plutil -convert xml1` and an awk state machine requires at least one `<string>` entry inside the array following `<key>CFBundleURLSchemes</key>` — handling self-closed empty `<array/>` forms. Harness gains a red test (planted plist with an empty `CFBundleURLSchemes` array must report FAIL **and must not emit the PASS line**, which is exactly the vacuous form under the old code) plus a green test (one scheme entry reports PASS). Both new tests run on a planted temp archive built with PlistBuddy, so they exercise the check without the golden.

### WR-01: Test harness hard-depends on a gitignored golden archive; "Works in CI" claim unwired

**Files modified:** `scripts/verify-archive-tests.sh`
**Commit:** `34dfc27`
**Applied fix:** Added a `GOLDEN_PRESENT` existence guard: when `.asc/artifacts/StressMonitor.xcarchive` is absent, tests 1-3 skip with a clear `SKIP:` message (no cascading cp/stat/dd/"integer expression expected" noise) and exit stays clean, while the planted-plist tests 4-5 — which need no golden — still run. The header claim "Works locally and in CI" is corrected to state the actual dependency: golden is gitignored, machine-local, and no CI workflow provisions it.

### WR-02: pbxproj migration orphans 9 no-op PBXBuildFile entries

**Files modified:** `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`
**Commit:** `dbba5a0`
**Applied fix:** Removed all 9 orphaned `PBXBuildFile` definitions (`F227C3DF…`, `F227C3E0…`, `F227C739…`, `F227C73A…`, `F2696881…`, `F2FCD7AF…`, `FB1A…04/05/07`) and their 9 references in the app target's Frameworks `files` list (now empty, matching the project's existing empty-phase formatting). `packageProductDependencies` (FirebaseAuth/FirebaseCore/GoogleSignIn proxied) is the single source of linkage truth. Verified before commit: every removed ID had exactly 2 occurrences (definition + list ref, nothing else); `plutil -lint` OK; `xcodebuild -list` parses with full package-graph resolution; CI-parity build (`generic/platform=iOS Simulator`, signing off) **BUILD SUCCEEDED**.

### WR-03: Failure messages point at nonexistent `ci_scripts/provision_firebase_config.sh`

**Files modified:** `StressMonitor/StressMonitorTests/FirebaseBootstrapTests.swift`, `StressMonitor/StressMonitor/Services/Firebase/FirebaseBootstrap.swift`
**Commit:** `a90d55b`
**Applied fix:** Confirmed the script was planned but never committed (`ci_scripts/` holds only `ci_post_clone.sh` / `ci_post_xcodebuild.sh`); CI provisioning is deferred under quick-task 260829-kby (plan: decode `GOOGLE_SERVICE_INFO_PLIST_BASE64` secret into `StressMonitor/StressMonitor/GoogleService-Info.plist`). Both `#expect` messages and the runtime `.fault` log now name the real recovery: copy the per-app `GoogleService-Info.plist` into `StressMonitor/StressMonitor/` (gitignored by design), state CI provisioning is deferred, and reference `.planning/quick/260829-kby-provision-googleservice-info-plist-in-ci`. Suite doc comment and test/runtime wording kept in sync.

### WR-04: EN/VI privacy policies omit 4 declared collection types

**Files modified:** `docs-site/legal/privacy.md`, `docs-site/vi/legal/privacy.md`
**Commit:** `93e044e`
**Applied fix:** The manifest is the truth source (`PrivacyInfo.xcprivacy` declares HealthAndFitness, PhotoVideo, ProductInteraction, DeviceID, OtherUserContent — all AppFunctionality, none tracking). Both locales' "Data We Access" sections now list: photos/videos you choose to share in AI Coaching Chat; chat message content (backend chat-history retention); device & app identifiers transmitted to Google (Firebase Auth / Google Sign-In) strictly for authentication and app functionality; product-interaction data via Google Firebase — each stated "never used for tracking or advertising". The blanket "no third-party analytics or advertising trackers" bullet is qualified (Google/Firebase is sign-in only), the AI Coaching Chat sections note attached photos/videos follow the same retention policy, and both "last updated" dates moved to 2026-09-03. All five manifest types are now covered in both locales with purposes matching `NSPrivacyCollectedDataTypePurposes` and `NSPrivacyTracking=false`.

## Skipped Issues

None — all 5 in-scope findings were fixed.

## Out-of-Scope Info Findings (documented, not fixed)

`fix_scope: critical_warning` — IN-01 (credential-scan pattern gaps: AWS/GitHub/Slack token shapes), IN-02 (stale `supabase*` allowlist entries), IN-03 (stale STOREKIT merge-mechanism comment), IN-04 (widget README truth gaps), IN-05 (CLAUDE.md contradictions + root AGENTS.md "plist is committed" claim), IN-06 (pbxproj re-serialization churn / empty proxy root file), IN-07 (transitive pin drift undetected) remain open for the orchestrator/developer to triage.

## Verification Summary

All verification ran in the **main checkout** on `gsd/v1.2-submission-readiness` (workflow.use_worktrees=false — no isolated worktree, so the numbers are reproducible from this tree directly).

- `bash -n` on both shell scripts — pass.
- `bash scripts/verify-archive-tests.sh` (golden present) — **5/5 PASS**, 0 failures, exit 0.
- Golden-absent simulation (scripts copied to a temp root so `$GOLDEN` resolves nowhere) — clean `SKIP:` message, planted-plist tests still pass, exit 0 (no cascade).
- `bash scripts/verify-archive.sh .asc/artifacts/StressMonitor.xcarchive` — all checks pass including the rewritten URL-schemes check.
- `plutil -lint project.pbxproj` — OK; removed IDs grep to 0 occurrences.
- `xcodebuild -list` — project parses, package graph resolves.
- `xcodebuild build … -destination 'generic/platform=iOS Simulator'` (CI parity, signing off) — **BUILD SUCCEEDED**.
- `TEST_RUNNER_GSD_CI=1 xcodebuild test … -only-testing:StressMonitorTests/FirebaseBootstrapTests` (iPhone 16, OS=latest, parallel off, signing off) — 3/3 tests pass, **TEST SUCCEEDED** (compiles both changed Swift files).

Logic-classification note: CR-01 is a logic fix (condition correctness) — beyond syntax checks it carries the red/green harness pair proving the empty-array case now fails and the populated case passes, including absence-assertions that would catch a vacuous regression.

---

_Fixed: 2026-09-03T19:30:00+07:00_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
