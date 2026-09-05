---
phase: 01-binary-manifest-truth
plan: 01
subsystem: infra
tags: [swift-package-manager, xcodebuild, artifact-gate, codesign-entitlements, credential-scan, privacy-manifests, local-proxy]

# Dependency graph
requires: []
provides:
  - scripts/verify-archive.sh — reusable 5-check artifact gate (entitlements x3, merged plists, credential scan w/ AUTH-01 allowlist, AIza resource grep, SDK privacy manifests) for plans 02-05
  - scripts/verify-archive-tests.sh — bidirectional gate harness (green on build-13 golden archive, red on planted JWT)
  - Completed SPM local-proxy migration — Firebase_proxy shim package + collision-free _proxied product names; project Package.resolved regains firebase-ios-sdk 11.15.0 pin
  - Proven archive-from-tree pipeline — unsigned Release .xcarchive from the working tree passing the gate
affects: [01-binary-manifest-truth, BUILD-01, BUILD-02, BUILD-03, AUTH-01, ENV-04, 02-privacy-manifests, 03-plist-truth, 04-widget-evidence, 05-ci-upload]

# Actuals (#2632) — pairs with the plan's `estimate` (34000 tokens, 3 tasks, confidence low)
actuals:
  tokens: 12766   # chars/4 over the committed diff 3e4233b..HEAD (production commits)
  tasks: 3
  commits: 4

tech-stack:
  added: []   # no new packages — repackaged two already-pinned SPM deps through local shims
  patterns:
    - "_proxied product-name suffix for proxy shims (upstream enters the graph through the shim, so shim product names MUST differ from upstream's — PIF registers both)"
    - "bidirectional verification gate: a green run is not enough; a planted-secret red run proves the gate detects what it claims"
    - "macOS strings stops at a Mach-O's last section — bytes appended past EOF are invisible; plant test secrets by overwriting inside the file"

key-files:
  created:
    - scripts/verify-archive.sh
    - scripts/verify-archive-tests.sh
    - StressMonitor/spm-cache/packages/proxy/.proxies/Firebase_proxy/Package.swift
    - StressMonitor/spm-cache/packages/proxy/.proxies/Firebase_proxy/Sources/Firebase_FirebaseAuth_shim/Firebase_FirebaseAuth_shim.swift
    - StressMonitor/spm-cache/packages/proxy/.proxies/Firebase_proxy/Sources/Firebase_FirebaseCore_shim/Firebase_FirebaseCore_shim.swift
    - StressMonitor/build/Phase1-Verify.xcarchive (local, gitignored)
  modified:
    - StressMonitor/StressMonitor.xcodeproj/project.pbxproj
    - StressMonitor/StressMonitor.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
    - StressMonitor/spm-cache/packages/proxy/Package.swift (gitignored tree)
    - StressMonitor/spm-cache/packages/proxy/.proxies/GoogleSignIn-iOS_proxy/Package.swift (gitignored tree)
    - StressMonitor/spm-cache/packages/umbrella/Package.swift (gitignored tree)

key-decisions:
  - "Firebase shim products renamed to FirebaseAuth_proxied/FirebaseCore_proxied (plan's A4 flagged-assumption remedy) — Xcode PIF rejected duplicate product registration exactly as the GoogleSignIn case predicted"
  - "spm-cache/ package sources stay uncommitted: StressMonitor/spm-cache/ is gitignored by repo convention ('regenerated locally'); the tracked migration artifacts are pbxproj + Package.resolved, and ENV-04's bar is archive-from-working-tree, not archive-from-fresh-clone"
  - "Planted-secret test mechanism: midpoint byte-overwrite instead of append-past-EOF (macOS strings stops at Mach-O last section; appended bytes are never scanned)"

patterns-established:
  - "Artifact gate pattern: read-only inspection script, PASS/FAIL per check with one-line reason, pattern names but never matched content, benign allowlist documented as comments in-script"
  - "Proxy shim pattern: Package.swift + one @_exported import per product, revision-exact upstream pins, auto-generated header comment preserved"

requirements-completed: [ENV-04]

coverage:
  - id: D1
    description: "verify-archive.sh artifact gate — green on build-13 golden archive (all 5 checks), red on planted JWT-shaped secret, --skip-entitlements mode, triage allowlist in comments"
    requirement: ENV-04
    verification:
      - kind: other
        ref: "bash scripts/verify-archive-tests.sh (3/3 PASS: green_on_golden, red_on_planted_secret, entitlements_all_three_bundles)"
        status: pass
      - kind: other
        ref: "bash scripts/verify-archive.sh .asc/artifacts/StressMonitor.xcarchive → exit 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "SPM proxy migration completed in place — Firebase_proxy shim package created, GoogleSignIn products renamed collision-free, lockfile regains firebase-ios-sdk 11.15.0 @ fdc352fabaf5916e7faa1f96ad02b1957e93e5a5, no remote refs revert"
    requirement: ENV-04
    verification:
      - kind: other
        ref: "cd StressMonitor/spm-cache/packages/proxy && swift package resolve (exit 0) + Package.resolved firebase pin grep + pbxproj GoogleSignIn_proxied grep"
        status: pass
      - kind: other
        ref: "grep productName hygiene: GoogleSignIn_proxied/FirebaseAuth_proxied/FirebaseCore_proxied x1 each, 0 old names, 1 XCLocalSwiftPackageReference, 0 XCRemoteSwiftPackageReference"
        status: pass
    human_judgment: false
  - id: D3
    description: "Unsigned Release .xcarchive producible from the unmodified working tree, passing verify-archive.sh --skip-entitlements incl. SDK privacy-manifest bundles"
    requirement: ENV-04
    verification:
      - kind: other
        ref: "xcodebuild archive … -archivePath StressMonitor/build/Phase1-Verify.xcarchive (ARCHIVE SUCCEEDED) && bash scripts/verify-archive.sh … --skip-entitlements → exit 0"
        status: pass
      - kind: other
        ref: "find Phase1-Verify.xcarchive -name PrivacyInfo.xcprivacy -path '*Firebase_FirebaseCore.bundle*' and '*GoogleSignIn_GoogleSignIn.bundle*' → both found"
        status: pass
    human_judgment: false

duration: 40min
completed: 2026-09-03
status: complete
---

# Phase 1 Plan 01: Binary & Manifest Truth (Tracer) Summary

**Artifact-inspection gate (5 checks, proven green/red) + completed SPM local-proxy migration (Firebase shims, _proxied renames, 11.15.0 pin regained) + unsigned Release archive from the working tree — ENV-04 closed**

## Performance

- **Duration:** 40 min
- **Started:** 2026-09-03T07:08:23Z
- **Completed:** 2026-09-03T07:48:47Z
- **Tasks:** 3/3 (Task 1 TDD: RED → GREEN, no refactor needed)
- **Files modified:** 11 (5 tracked-adjacent; 6 in gitignored spm-cache/build trees)

## Accomplishments

- `scripts/verify-archive.sh` — the phase's reusable artifact gate: per-bundle entitlements (build-12 regression guard), merged-plist truth (6 STOREKIT keys + URL schemes + widget ext point), AUTH-01 credential scan with the documented benign allowlist as comments, AIza resource grep, third-party SDK privacy-manifest presence. Green on the build-13 golden archive; **red** on a planted JWT-shaped secret (scan mode exits non-zero).
- ENV-04 migration completed **in place, no revert**: `.proxies/Firebase_proxy/` shim package created (revision-exact pin `fdc352faba…` = 11.15.0, the HEAD-resolved revision), GoogleSignIn proxy products renamed `GoogleSignIn_proxied`/`GoogleSignInSwift_proxied`, umbrella cache-warmer gains the firebase pin, project `Package.resolved` regains `firebase-ios-sdk 11.15.0` while `googlesignin-ios` stays `08d8dcec…`.
- Unsigned **Release archive producible from the working tree** (`StressMonitor/build/Phase1-Verify.xcarchive`, ARCHIVE SUCCEEDED, signing disabled) — passes the gate with `--skip-entitlements`; `Firebase_FirebaseCore.bundle/PrivacyInfo.xcprivacy` and `GoogleSignIn_GoogleSignIn.bundle/PrivacyInfo.xcprivacy` still flow into StressMonitor.app through the proxy graph (BUILD-01 no-regression half for the dependency set).
- Golden build-13 baseline (`.asc/artifacts/`) untouched throughout (mtimes preserved).

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: failing test for verify-archive gate** — `a1dbfee` (test)
2. **Task 1 GREEN: implement verify-archive artifact gate** — `f34e6d6` (feat)
3. **Task 2: SPM proxy migration — Firebase shim + GoogleSignIn_proxied rename + lockfile pin** — `feb3bf1` (feat)
4. **Task 3 fix: Firebase proxy products → _proxied (PIF duplicate registration)** — `1afb401` (fix)

**Plan metadata:** docs commit (see below)

## Files Created/Modified

- `scripts/verify-archive.sh` — 5-check read-only artifact gate (+ `--scan-binary` single-binary scan mode)
- `scripts/verify-archive-tests.sh` — bidirectional test harness (green/red/entitlements ×3)
- `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` — migration landed (local proxy ref only) + 3 `_proxied` productNames
- `StressMonitor/StressMonitor.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` — regains firebase-ios-sdk pin
- `StressMonitor/spm-cache/packages/proxy/.proxies/Firebase_proxy/` — Package.swift + Auth/Core shims (gitignored tree)
- `StressMonitor/spm-cache/packages/proxy/.proxies/GoogleSignIn-iOS_proxy/Package.swift`, `proxy/Package.swift`, `umbrella/Package.swift` — rename + Firebase wiring + pin (gitignored tree)
- `StressMonitor/build/Phase1-Verify.xcarchive` — local verification artifact (gitignored output)

## Decisions Made

1. **A4 remedy applied (sanctioned by plan frontmatter):** Firebase shim products renamed `FirebaseAuth_proxied`/`FirebaseCore_proxied` after `xcodebuild` failed PIF load with `GUID 'PRODUCTREF-PACKAGE-PRODUCT:FirebaseAuth…' has already been registered`. The plan's letter said Firebase product names "stay unchanged"; its `flagged_assumptions` block pre-authorized exactly this rename if SwiftPM/Xcode still rejected the graph. Same collision shape as GoogleSignIn: upstream enters the graph one hop away through the shim itself, so shim product names must differ from upstream's.
2. **spm-cache/ package sources remain uncommitted:** `.gitignore:165` ignores all of `StressMonitor/spm-cache/` ("sandbox, lockfile, build artifacts - regenerated locally"); HEAD contains zero spm-cache files. The tracked migration artifacts are the pbxproj + Package.resolved; the shim sources live in the working tree where the resolver reads them. ENV-04's bar is archive-from-working-tree (proven), not archive-from-fresh-clone. Force-staging gitignored content would violate repo convention.
3. **Tracer feedback gate ran in autonomous form** (plan frontmatter `autonomous: true`): tracer `<verify>` re-run end-to-end passed before expansion tasks.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Planted-secret test mechanism invisible to macOS strings**
- **Found during:** Task 1 (GREEN iteration)
- **Issue:** The plan's Test 2 / `<automated>` verify appends the planted string past the Mach-O's end; macOS `strings` parses Mach-O structure and stops at the object's last section, so appended bytes are never scanned (`strings -a … | grep -c PLANTEDSECRETVALUE` → 0). The literal automated verify fails at its tail regardless of implementation.
- **Fix:** Harness plants the secret by overwriting 59 bytes at the file midpoint — the copy remains a Mach-O and the unmodified `strings -a` pipeline detects it (verified: 1 hit). The corrected equivalent of the automated verify passes (`grep -c` → 1 ∧ golden_exit=0). Also fixed a `grep -q`-in-pipeline SIGPIPE (141) artifact under `pipefail` by switching to `grep -c`.
- **Files modified:** scripts/verify-archive-tests.sh
- **Verification:** `bash scripts/verify-archive-tests.sh` → 3/3 PASS (red test asserts scan exit ≠ 0 AND visibility ≥ 1)
- **Committed in:** f34e6d6 (part of Task 1 GREEN commit)

**2. [Rule 1 - Bug, per plan's flagged assumption A4] Firebase shim product names collided in the PIF graph**
- **Found during:** Task 3 (smoke build; `xcodebuild` exit 65 at package-graph computation)
- **Issue:** `PRODUCTREF-PACKAGE-PRODUCT:FirebaseAuth--…-dynamic has already been registered` — the shim's `FirebaseAuth` product and upstream firebase-ios-sdk's `FirebaseAuth` product (pulled in by the shim's own dependency) both register. The plan's Task 2 assertion that Firebase names "stay unique" was wrong for the Xcode PIF loader even though raw `swift package resolve` succeeds.
- **Fix:** Applied the plan's pre-authorized A4 remedy — same 3-place atomic rename recipe to `FirebaseAuth_proxied`/`FirebaseCore_proxied` (shim Package.swift, proxy root `.product(name:)`, pbxproj productName + comments). No revert to remote refs; direction unchanged.
- **Files modified:** StressMonitor/StressMonitor.xcodeproj/project.pbxproj, spm-cache shim + proxy Package.swift (gitignored tree)
- **Verification:** smoke build exit 0 → ARCHIVE SUCCEEDED → gate all-PASS; productName hygiene (×1 each, 0 old names); Task 2 automated verify re-run still green
- **Committed in:** 1afb401

---

**Total deviations:** 2 auto-fixed (2 × Rule 1 bug)
**Impact on plan:** Both fixes were within the plan's own sanctioned fallback paths (A4) or pure test-mechanism corrections. No scope creep; ENV-04 closed in the locked direction.

## Issues Encountered

- `swift package resolve` at the proxy root succeeds even when the graph is PIF-invalid for Xcode — the real gate is `xcodebuild` build/archive. Task 3's smoke-build-first ordering (per plan) is what surfaced the Firebase collision cheaply.
- The pbxproj commit (feb3bf1) necessarily includes the user's whole in-flight migration diff (304+/313− vs HEAD, incl. Xcode's cosmetic quoting churn) — that uncommitted migration IS the work Task 2 completes; my own delta on top of the tree snapshot is the rename only (verified by grep-filtered diff).
- The Giphy dSYM stub script phase still runs every build (pre-existing dead machinery; removal belongs to plan 02/BUILD-01, not this plan).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Plans 02-04 can now produce archives and run `scripts/verify-archive.sh <archive>` against them (the reusable gate exists and is proven bidirectionally).
- Entitlements chain: proven on the signed golden archive (all 3 bundles, `group.stress.ai.com`); unsigned local archives use `--skip-entitlements` — signed-archive entitlements re-proof comes with plan 05's CI/upload surface.
- `.asc/artifacts/` golden baseline intact for BUILD-03 plist diffs and AUTH-01 final scan.
- Note for plan 02: the A4 lesson generalizes — any NEW proxy shim must use `_proxied`-style product names distinct from upstream's.

## Self-Check: PASSED

All key-files exist on disk; all 4 production commits found in git log (a1dbfee, f34e6d6, feb3bf1, 1afb401); all plan-level verifications re-run green after the final commit (golden gate 0, harness 0, Task-2 verify 0, archive gate 0).

---
*Phase: 01-binary-manifest-truth*
*Completed: 2026-09-03*
