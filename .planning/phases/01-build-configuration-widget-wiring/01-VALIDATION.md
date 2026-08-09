---
phase: 1
slug: build-configuration-widget-wiring
status: validated
nyquist_compliant: true
wave_0_complete: false
created: 2026-08-09
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`@Test`/`#expect`) for new tests per D-04; XCTest retained only for `BioAgeCalculatorTests.swift` |
| **Config file** | None separate — driven by the `StressMonitorTests` native target + `StressMonitor.xcscheme`'s `TestAction` (both already exist in the working tree, per 01-RESEARCH.md) |
| **Quick run command** | `xcodebuild test -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -only-testing:StressMonitorTests` |
| **Full suite command** | `CI=1 python3 scripts/run-tests.py` |
| **Estimated runtime** | ~60-120 seconds (simulator boot + 9 existing test files) |

---

## Sampling Rate

- **After every task commit:** Run the quick run command above
- **After every plan wave:** Run `CI=1 python3 scripts/run-tests.py`
- **Before `/gsd-verify-work`:** Full suite must be green, plus `xcodebuild -showBuildSettings | grep INFOPLIST_FILE` and a manual/simulator pass on the widget's three data states
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 0 | BUILD-04 | — | Establish pass/fail baseline against current working tree before any further change | integration | `xcodebuild test -only-testing:StressMonitorTests ...` (quick run command above) | ✅ target exists | ⬜ pending |
| 01-01-02 | 01 | 1 | BUILD-02 | T-01-01 | Widget process has App Group container access; no `fatalError` on real device | build-setting | `grep -n "CODE_SIGN_ENTITLEMENTS" project.pbxproj` scoped to `StressMonitorWidgetExtension`'s config blocks | ❌ W0 — no script wraps this | ⬜ pending |
| 01-01-03 | 01 | 1 | BUILD-01 | T-01-02 | Manifest declares `1C8F.1` for App-Group UserDefaults access, correct `Linked` flags, and a widget-extension manifest exists | manual/tooling | `xcrun altool --validate-app` (or Xcode Organizer pre-upload validation) against an actual archive | ❌ W0 — no local script wraps ASC's own validator | ⬜ pending |
| 01-01-04 | 01 | 1 | BUILD-03 | — | Single Info.plist source of truth; orphan deleted | build-settings inspection | `xcodebuild -showBuildSettings -project StressMonitor/StressMonitor.xcodeproj -target StressMonitor \| grep INFOPLIST_FILE` | ❌ W0 — trivial, not yet scripted | ⬜ pending |
| 01-01-05 | 01 | 1 | WIRE-01 | — | `WidgetPublisher`'s written UserDefaults keys match `WidgetDataProvider.Keys` exactly (regression-proofs the cross-target duplication-by-convention pattern) | unit | New Swift Testing test asserting key-name equality between the two enums | ❌ W0 — no test exists today; cheap to add | ⬜ pending |
| 01-01-06 | 01 | 1 | WIRE-01 (UI) | — | Provider exposes `.fresh`/`.stale`/`.empty` (not a single `isPlaceholder` bool); each routes to the correct view branch per 01-UI-SPEC.md's Widget State Contract | unit | New Swift Testing test on `StressWidgetProvider`'s state-resolution logic | ❌ W0 — no test exists today | ⬜ pending |

*Full per-task breakdown to be finalized by the planner; this table seeds Wave 0/1 verification intent from research.*

---

## Wave 0 Requirements

- [ ] `xcodebuild test -only-testing:StressMonitorTests` run once against current disk state to establish a pass/fail baseline (not assumed green) — covers BUILD-04
- [ ] New Swift Testing file asserting `WidgetPublisher` / `WidgetDataProvider.Keys` key-name parity — covers WIRE-01
- [ ] New Swift Testing file (or extension of the above) covering the provider's `.fresh`/`.stale`/`.empty` state resolution per 01-UI-SPEC.md — covers WIRE-01's UI-state gap
- [ ] A one-line `xcodebuild -showBuildSettings | grep INFOPLIST_FILE` check, ideally folded into `scripts/run-tests.py` or a small new script — covers BUILD-03

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|--------------------|
| Widget/complication read the live App Group suite on a real device | BUILD-02 | App Group container behavior differs from simulator; no automated device test exists or is expected | Trigger a stress save on a real device, background the app, confirm the home-screen widget updates within its next timeline refresh |
| Release archive passes ASC's Privacy Manifest validation | BUILD-01 | No local equivalent to Apple's own automated validator | Archive via Xcode Organizer or `xcodebuild -exportArchive`, run pre-upload validation, confirm no manifest error |
| Apple Developer Portal capability + Fastlane Match regeneration | BUILD-02 | Requires human credentials an agent does not have (Developer Portal access, Match repo write access) | A human enables App Groups + iCloud on all 3 App IDs in the Developer Portal, then runs the write-access Match lane locally (`bundle exec fastlane match appstore --force` per `fastlane/Fastfile`) — flag as `checkpoint:human-verify` in the plan |
| Widget's three data states (Fresh/Stale/Empty) render correctly per 01-UI-SPEC.md's Widget State Contract | WIRE-01 | Requires visual confirmation in simulator/device across all 3 widget families | Force each state via demo mode or manual UserDefaults manipulation; screenshot Small/Medium/Large in each state; confirm against 01-UI-SPEC.md's per-family table |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s (accepted: `xcodebuild build`/`test` invocations run 60-120s, inherent to the toolchain per gsd-plan-checker's non-blocking note — not a plan defect)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** 2026-08-09 (gsd-plan-checker VERIFICATION PASSED, 4/4 plans valid, 5/5 requirements covered)
