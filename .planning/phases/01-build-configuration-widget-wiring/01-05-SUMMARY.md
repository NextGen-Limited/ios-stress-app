---
phase: 01-build-configuration-widget-wiring
plan: 05
subsystem: ci-tooling
tags: [ci, testing, xcodebuild, github-actions, xcscheme]
dependency_graph:
  requires: []
  provides:
    - "CI test execution path (macos-15 runner, xcodebuild test on StressMonitor scheme)"
  affects:
    - ".github/workflows/_test.yml (new test job runs alongside lint-and-build on every PR/dispatch)"
    - "StressMonitor.xcscheme TestAction (phantom UITests reference removed)"
tech_stack:
  added:
    - "GitHub Actions `test` job in reusable _test.yml workflow"
  patterns:
    - "Job-level reuse of DerivedData + SPM cache keys from lint-and-build"
    - "CODE_SIGN_IDENTITY=\"\" / CODE_SIGNING_REQUIRED=NO unsigned simulator builds"
key_files:
  created: []
  modified:
    - ".github/workflows/_test.yml"
    - "StressMonitor/StressMonitor.xcodeproj/xcshareddata/xcschemes/StressMonitor.xcscheme"
decisions:
  - "Used iPhone 16 Simulator destination (OS=latest) per plan; no -only-testing filter so the scheme TestAction scopes the bundle"
  - "Matched lint-and-build cache keys verbatim so the test job warms from the same DerivedData/SPM cache lines"
metrics:
  duration: ~3m
  completed: 2026-08-11
  tasks: 2
  commits: 2
status: complete
actuals:
  tokens: 750
  tasks: 2
  commits: 2
estimate_miss_reason: "Plan estimated 18000 tokens at low confidence; realized diff was 3010 chars (47 insertions / 11 deletions across 2 files). Estimate was a gross overestimate for a pure CI-tooling change with no source code."
---

# Phase 1 Plan 5: CI Test Job + Scheme TestAction Cleanup Summary

Added a macos-15 `test` job running `xcodebuild test` against the StressMonitor scheme and removed the dangling `StressMonitorUITests` TestableReference, closing the BUILD-04 execution-path gap.

## What Was Built

### Task 1 — `test` job in `.github/workflows/_test.yml` (commit ae1077f)

Added a fourth job (`test`) to the reusable `_test.yml` workflow, placed after `build-widget`. The job:
- Runs on `macos-15` with `timeout-minutes: 30`, matching `lint-and-build`.
- Selects Xcode 26.3 via `sudo xcode-select -s`, installs `xcpretty`.
- Carries its own DerivedData + SPM cache steps using keys identical to `lint-and-build` (`derived-${{ runner.os }}-${{ hashFiles('.../project.pbxproj') }}` and `spm-${{ runner.os }}-${{ hashFiles('**/Package.resolved') }}`).
- Runs `xcodebuild test -project StressMonitor/StressMonitor.xcodeproj -scheme "$SCHEME" -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -derivedDataPath build -skipPackagePluginValidation CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO | xcpretty` with `set -o pipefail`.
- No `-only-testing` filter — the scheme's TestAction already scopes to registered TestableReferences.

Because `ci.yml` invokes `_test.yml` via `uses: ./.github/workflows/_test.yml` with no job-level filter, the `test` job runs automatically on every PR/dispatch, providing the fresh CoreSimulator that this dev host cannot.

### Task 2 — Scheme TestAction cleanup (commit 0cf7e3b)

Removed the second `<TestableReference>` from `StressMonitor.xcscheme`'s `<Testables>` block — the one referencing BlueprintIdentifier `F2E2EC012F1CC556000C2B53` / BuildableName `StressMonitorUITests.xctest`. No matching `PBXNativeTarget` exists in `project.pbxproj`, so this was a phantom reference that could waste `xcodebuild test` resolution time. The valid `StressMonitorTests` TestableReference (`0685AF23B64355DB99B05140`) is untouched; all other scheme sections (BuildAction, LaunchAction, ProfileAction, AnalyzeAction, ArchiveAction) are unchanged.

## Verification

All plan verification checks passed:

| Check | Expected | Result |
|-------|----------|--------|
| `_test.yml` YAML parses + has `test` job with `xcodebuild test` | pass | PASS |
| `grep -c 'xcodebuild test' _test.yml` | >= 1 | 1 |
| Test job `runs-on` | macos-15 | macos-15 |
| DerivedData + SPM cache keys match lint-and-build | match | match |
| Destination flag | iPhone 16 Simulator, OS=latest | present |
| Scheme `StressMonitorUITests` refs | 0 | 0 |
| Scheme `StressMonitorTests` refs | >= 1 | 2 |
| `xmllint --noout` on scheme | well-formed | PASS |

Note: The runtime pass/fail signal for BUILD-04 will come from the next CI run on a PR or manual dispatch — this plan delivers the execution path, not the runtime test result (which requires a fresh CI runner this dev host cannot provide).

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. No application source code was touched; this is a CI-tooling-only change.

## Self-Check: PASSED

Files verified on disk:
- `.github/workflows/_test.yml` — FOUND (contains `test` job)
- `StressMonitor/StressMonitor.xcodeproj/xcshareddata/xcschemes/StressMonitor.xcscheme` — FOUND (UITests ref removed)

Commits verified in git log:
- `ae1077f` — FOUND
- `0cf7e3b` — FOUND
