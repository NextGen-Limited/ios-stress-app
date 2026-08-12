---
phase: 01-build-configuration-widget-wiring
plan: 01
subsystem: infra
tags: [xcodeproj, entitlements, app-group, privacy-manifest, widgetkit, xcodebuild]

requires: []
provides:
  - "StressMonitorWidgetExtension target with a wired CODE_SIGN_ENTITLEMENTS build setting (App Group container access on real devices)"
  - "Per-bundle PrivacyInfo.xcprivacy for all 3 targets (app, widget, watch), each declaring 1C8F.1 App-Group UserDefaults usage"
  - "Main app manifest's HealthAndFitness collected-data entry corrected to Linked=true per D-01"
  - "Single Info.plist source of truth for the app target (orphan deleted)"
  - "Documented (not assumed) xcodebuild test baseline status for StressMonitorTests"
affects: ["01-02", "01-03", "01-04", "phase-02-data-integrity"]

actuals:
  tokens: 1784
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns: ["Per-target CODE_SIGN_ENTITLEMENTS wiring matched to sibling app/watch targets", "Per-bundle PrivacyInfo.xcprivacy scoped to that bundle's own Required-Reason API usage only"]

key-files:
  created:
    - StressMonitor/StressMonitorWidget/PrivacyInfo.xcprivacy
    - "StressMonitor/StressMonitorWatch Watch App/PrivacyInfo.xcprivacy"
  modified:
    - StressMonitor/StressMonitor.xcodeproj/project.pbxproj
    - StressMonitor/StressMonitor/PrivacyInfo.xcprivacy
    - StressMonitor/Info.plist (deleted)

key-decisions:
  - "Left the scheme's dangling StressMonitorUITests TestableReference untouched — the 3 observed test failures were CoreSimulator device-pairing/socket errors, not target-resolution errors, so there is no evidence the dangling reference caused friction"
  - "Copied StressMonitor/spm-cache/ from the main repo checkout into this worktree (environment-only, not committed — spm-cache is gitignored) so xcodebuild could resolve the local package proxy at all in a fresh worktree checkout"
  - "Restored StressMonitor.xcodeproj/project.xcworkspace/.../Package.resolved via git checkout after every build — the spm-cache proxy tooling deletes it as an unrelated side effect of package-graph resolution; none of this plan's 3 commits carry that deletion"

patterns-established:
  - "CODE_SIGN_ENTITLEMENTS insertion point: alphabetically before CODE_SIGN_IDENTITY/CODE_SIGN_STYLE within a target's XCBuildConfiguration buildSettings dict, matching the App/Watch target convention"
  - "Widget/watch-extension PrivacyInfo.xcprivacy: empty NSPrivacyCollectedDataTypes array + single NSPrivacyAccessedAPICategoryUserDefaults/1C8F.1 entry — do not copy the main app's full NSPrivacyCollectedDataTypes array into an extension's manifest"

requirements-completed: [BUILD-01, BUILD-02, BUILD-03, BUILD-04]

coverage:
  - id: D1
    description: "StressMonitorWidgetExtension's Debug and Release XCBuildConfiguration blocks both carry CODE_SIGN_ENTITLEMENTS = StressMonitorWidget/StressMonitorWidget.entitlements, closing the fatalError risk in WidgetDataProvider.init on real devices (BUILD-02 Gap 1)"
    requirement: "BUILD-02"
    verification:
      - kind: other
        ref: "awk-scoped grep count == 1 for both Debug (F211BBEF2FD9112200A6E25D) and Release (F211BBF02FD9112200A6E25D) blocks"
        status: pass
      - kind: integration
        ref: "xcodebuild build -project StressMonitor.xcodeproj -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'"
        status: pass
    human_judgment: false
  - id: D2
    description: "All three compiled bundles (app, widget, watch) carry a valid PrivacyInfo.xcprivacy declaring 1C8F.1 for App-Group UserDefaults usage; main app's HealthAndFitness entry now declares Linked=true"
    requirement: "BUILD-01"
    verification:
      - kind: other
        ref: "plutil -lint on all three PrivacyInfo.xcprivacy files"
        status: pass
      - kind: other
        ref: "grep -c '1C8F.1' == 1 on all three files; grep HealthAndFitness/true == 1 on main app manifest"
        status: pass
      - kind: integration
        ref: "xcodebuild build (all three manifests auto-included via PBXFileSystemSynchronizedRootGroup)"
        status: pass
    human_judgment: true
    rationale: "Local plutil-lint and a schema-shape match to Apple's documented reason codes is the only verification available offline; actual ASC privacy-manifest validation only occurs at archive/upload time (per 01-RESEARCH.md's Validation Architecture table — no local script wraps ASC's own validator). A human must still confirm this passes on the next real archive/TestFlight upload."
  - id: D3
    description: "Orphaned top-level StressMonitor/Info.plist deleted; xcodebuild -showBuildSettings confirms a single Info.plist source of truth for the app target"
    requirement: "BUILD-03"
    verification:
      - kind: other
        ref: "find StressMonitor -maxdepth 2 -iname Info.plist | wc -l == 2"
        status: pass
      - kind: other
        ref: "xcodebuild -showBuildSettings -target StressMonitor | grep INFOPLIST_FILE == StressMonitor/Info.plist (resolves to the nested stub, relative to the .xcodeproj's own dir)"
        status: pass
      - kind: integration
        ref: "xcodebuild build"
        status: pass
    human_judgment: false
  - id: D4
    description: "xcodebuild test -only-testing:StressMonitorTests baseline documented (not assumed) per BUILD-04's acceptance criterion"
    requirement: "BUILD-04"
    verification:
      - kind: integration
        ref: "xcodebuild test -project StressMonitor.xcodeproj -scheme StressMonitor -only-testing:StressMonitorTests (3 attempts, 3 different destinations/UDIDs)"
        status: unknown
    human_judgment: true
    rationale: "3 consecutive attempts failed at the CoreSimulator device-pairing/socket layer (Mach error -308, then twice 'No matching device ... in XCTestDevices'), not at test-code compilation or assertion level — every attempt's build phases for the StressMonitorTests target completed successfully; only runtime device install/communication failed. This is an environment-level CoreSimulator flake, not evidence the tests themselves pass or fail. Logged to .planning/WINDOWS.md (kind: unrun-verify) and .planning/phases/01-build-configuration-widget-wiring/deferred-items.md. A human with a stable local CoreSimulator environment should re-run this command to get a real pass/fail signal before BUILD-04 is considered independently verified."

duration: 24min
completed: 2026-08-09
status: complete
---

# Phase 1 Plan 1: Build Configuration & Widget Wiring — Audit & Gap Closure Summary

**Wired the widget extension's App Group entitlement (closing a live fatalError risk), completed per-bundle Privacy Manifest disclosure across all three compiled targets, and deleted the orphaned top-level Info.plist — three concrete, verified gaps closed against an already-mostly-correct uncommitted working tree.**

## Performance

- **Duration:** ~24 min
- **Started:** 2026-08-09T06:24:46Z
- **Completed:** 2026-08-09T06:48:26Z
- **Tasks:** 3
- **Files modified:** 5 (1 build-setting file, 3 privacy manifests, 1 deletion)

## Accomplishments

- `StressMonitorWidgetExtension`'s Debug and Release `XCBuildConfiguration` blocks now both carry `CODE_SIGN_ENTITLEMENTS = StressMonitorWidget/StressMonitorWidget.entitlements` — the widget process gets real App Group container access on a real device instead of a latent `fatalError` in `WidgetDataProvider.init`.
- All three compiled bundles (main app, widget extension, watch app) now ship a valid `PrivacyInfo.xcprivacy`. The main app's manifest gained the `1C8F.1` (App-Group UserDefaults) reason code alongside the existing `CA92.1`, and its `HealthAndFitness` collected-data entry now correctly declares `Linked=true` per D-01 (the `/chat` request carries a Bearer JWT, so the health-derived context is identity-linked server-side). The widget and watch manifests are new files, each declaring only their own actual Required-Reason API usage (`1C8F.1`) and no collected data of their own.
- The orphaned top-level `StressMonitor/Info.plist` — confirmed unreferenced by any build target via `xcodebuild -showBuildSettings` — is deleted outright per D-05. `find StressMonitor -maxdepth 2 -iname Info.plist` now returns exactly the two legitimate files (app target's nested stub, widget target's own).
- Established (and honestly documented, not assumed) the `xcodebuild test -only-testing:StressMonitorTests` baseline: it did not pass in 3 attempts, but every failure was a CoreSimulator device-pairing/socket-layer error unrelated to this plan's code changes — see "Task 1 Baseline" below.

## Task Commits

1. **Task 1: Establish build/test baseline and wire the widget's App Group entitlement (BUILD-02 Gap 1, BUILD-04 baseline)** — `9f6e253` (fix)
2. **Task 2: Complete the Privacy Manifest disclosure across all three targets (BUILD-01)** — `261ee6f` (fix)
3. **Task 3: Delete the orphaned top-level Info.plist and confirm the single source of truth (BUILD-03)** — `86d900f` (chore)

**Plan metadata:** (this SUMMARY + final metadata commit)

## Files Created/Modified

- `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` — added `CODE_SIGN_ENTITLEMENTS` to the widget extension target's Debug/Release build configs
- `StressMonitor/StressMonitor/PrivacyInfo.xcprivacy` — added `1C8F.1` reason, flipped `HealthAndFitness` `Linked` to `true`
- `StressMonitor/StressMonitorWidget/PrivacyInfo.xcprivacy` (new) — per-bundle manifest for the widget extension
- `StressMonitor/StressMonitorWatch Watch App/PrivacyInfo.xcprivacy` (new) — per-bundle manifest for the watch app
- `StressMonitor/Info.plist` (deleted) — orphaned, unreferenced top-level stub

## Decisions Made

- **Left the dangling `StressMonitorUITests` `TestableReference` in `StressMonitor.xcscheme` untouched.** Per the plan's own conditional ("if it causes friction... otherwise leave the scheme untouched"): all 3 test-run failures were CoreSimulator device-pairing/socket errors that occurred identically regardless of which testable target was targeted, with zero evidence the dangling reference caused or contributed to them. No project.pbxproj native target search shows `StressMonitorUITests` exists (confirmed again this session), but removing an unrelated, currently-inert reference outside any observed failure mode would be scope creep beyond this task's `<action>`.
- **Copied `StressMonitor/spm-cache/` from the main repo checkout into this worktree (not committed).** `spm-cache/` is gitignored (build-cache artifacts, `.gitignore:167-169`); this worktree — a fresh git worktree checkout — did not inherit it, so `xcodebuild` could not resolve the `XCLocalSwiftPackageReference "proxy"` package at all. Copying the already-resolved cache from the main checkout (verified to use only relative paths, so portable across worktrees) unblocked every `<verify>` step in this plan. See `deferred-items.md` item 1 for the full writeup — this is an environment/harness gap, not a Phase 1 code fix.
- **Restored `Package.resolved` via `git checkout --` after every build.** Every `xcodebuild build`/`test` invocation deleted the tracked `.../swiftpm/Package.resolved` as a side effect of the local spm-cache proxy's package-graph resolution — unrelated to any file this plan touches. Restored before every commit so none of the 3 task commits carry that deletion. See `deferred-items.md` item 2.

## Task 1 Baseline (documented per plan requirement, not assumed)

- `xcodebuild build` — **succeeded** both before and after the entitlement edit.
- `xcodebuild test -only-testing:StressMonitorTests` — **did not complete successfully in 3 attempts**, all failing at the CoreSimulator layer, not at test compilation/assertion level:
  1. Destination `platform=iOS Simulator,name=iPhone 17,OS=latest` → `Mach error -308 (ipc/mig) server died` during test-runner launch.
  2. Same destination, after `xcrun simctl shutdown all` → `No matching device (D8F4276E-...) in set at .../XCTestDevices` (test-clone device vanished before the runner could pair with it).
  3. Destination pinned to a specific booted-device UDID (`id=760BEEAE-...`) → same class of failure: `No matching device (CB974840-...) in set at .../XCTestDevices`, "Failed to establish communication with the test runner ... Error retrieving daemon unix domain socket ... failed after 30 attempts."
  - In every attempt, the build phases for the `StressMonitorTests` target itself (compile, `ProcessInfoPlistFile`, `CopySwiftLibs`) completed without error — only the runtime device-install/test-runner-communication step failed. `/Users/ddphuong/Library/Developer/XCTestDevices/` is empty on this machine, consistent with the CoreSimulator test-clone-device registration mechanism itself being unstable in this environment (also `iPhone 16` — the plan's suggested destination — is not an available simulator on this machine at all; substituted `iPhone 17`/its UDID, which is available).
  - **Per plan Task 1 step 4's explicit allowance:** this is documented as a pre-existing environment failure unrelated to the widget-entitlement change, not attributed to this task. Logged to `.planning/WINDOWS.md` (kind: `unrun-verify`) and `deferred-items.md` item 3 for cross-phase visibility.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Substituted the plan's `iPhone 16` simulator destination with `iPhone 17`**
- **Found during:** Task 1
- **Issue:** No `iPhone 16` simulator exists on this machine (`xcrun simctl list devices available` confirms); the plan's `<verify>` commands hardcode `name=iPhone 16,OS=latest`.
- **Fix:** Used `iPhone 17` (and its UDID directly on the 3rd attempt) for every `xcodebuild build`/`test` invocation instead. This is a destination-name substitution only — no code or configuration semantics changed.
- **Files modified:** None (command-line argument only, not committed).
- **Verification:** `xcodebuild -showdestinations` confirmed `iPhone 17` is the closest available simulator; build succeeded against it every time.

---

**Total deviations:** 1 auto-fixed (1 blocking — simulator destination substitution). No code-level deviations; all 3 tasks executed exactly as written.
**Impact on plan:** None on scope or correctness — purely a local-machine simulator-availability substitution required to run the plan's own verify commands at all.

## Issues Encountered

- **Fresh worktree missing gitignored `spm-cache/` build cache** — blocked all package resolution until manually copied from the main checkout (environment-only fix, not committed; see Decisions Made and `deferred-items.md` item 1).
- **`xcodebuild`'s spm-cache proxy resolution deletes the checked-in `Package.resolved` on every build** — restored via targeted `git checkout --` before every commit; not attributable to this plan's code changes (see Decisions Made and `deferred-items.md` item 2).
- **CoreSimulator test-runner pairing is unstable in this environment** — 3 consecutive `xcodebuild test` attempts failed at the device-pairing/socket layer; documented as an honest, unresolved baseline per the plan's own instructions rather than force-fit to a pass/fail claim not actually observed (see Task 1 Baseline above and `deferred-items.md` item 3).

## Known Stubs

None — this plan's scope is build-configuration correctness (entitlements, privacy manifest, Info.plist), not feature code; no stub data paths were introduced or discovered.

## Threat Flags

None beyond what the plan's own `<threat_model>` already registers (T-01-01/T-01-02/T-01-03, all already dispositioned `accept`/`mitigate` in 01-01-PLAN.md) — no new security-relevant surface was introduced by this plan's build-configuration-only changes.

## User Setup Required

None — no external service configuration required. (Note: 01-RESEARCH.md's BUILD-02 Gap 2 — Apple Developer Portal App Groups capability + Fastlane Match profile regeneration for the widget's new entitlement — is real-device-signing groundwork explicitly out of this plan's scope; it requires a human with Developer Portal + Match write access and is not blocking for this plan's own simulator-based verification.)

## Next Phase Readiness

- BUILD-02's entitlement wiring is code-complete and simulator-build-verified; real-device verification still requires the Developer Portal/Match step noted above (unchanged from 01-RESEARCH.md — not newly discovered here).
- BUILD-01's Privacy Manifest disclosure is locally lint-clean and schema-correct for all 3 targets; final confirmation is ASC's own validator at the next real archive/upload (not locally automatable per 01-RESEARCH.md's Validation Architecture table).
- BUILD-03 is fully closed — single Info.plist source of truth confirmed via build settings.
- BUILD-04's test-target wiring itself is unchanged/untouched by this plan (it was already correct per 01-RESEARCH.md) — the open item is a CoreSimulator environment flake in getting a pass/fail signal locally, not a wiring defect. Flagged in `.planning/WINDOWS.md` for follow-up before this phase's overall verification is considered fully closed.
- No blockers for proceeding to 01-02/01-03/01-04 — none of their file scopes (per 01-CONTEXT.md's canonical refs) overlap with what this plan touched.

---
*Phase: 01-build-configuration-widget-wiring*
*Completed: 2026-08-09*

## Self-Check: PASSED

- FOUND: `StressMonitor/StressMonitorWidget/PrivacyInfo.xcprivacy`
- FOUND: `StressMonitor/StressMonitorWatch Watch App/PrivacyInfo.xcprivacy`
- CONFIRMED DELETED: `StressMonitor/Info.plist`
- FOUND commit: `9f6e253`
- FOUND commit: `261ee6f`
- FOUND commit: `86d900f`
