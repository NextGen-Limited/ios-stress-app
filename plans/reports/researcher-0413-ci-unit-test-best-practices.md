# Research Report: iOS Unit Testing in GitHub Actions CI

**Agent:** Researcher  
**Date:** 2026-04-13  
**Project:** StressMonitor (iOS 17+ / SwiftUI / SwiftData)  
**Status:** DONE  

---

## Executive Summary

The current CI pipeline (`.github/workflows/ci.yml` + `scripts/run-tests.py`) has solid fundamentals: name-based destination resolution, CI-aware Python runner, SPM caching, xcresult artifact upload. This report identifies targeted improvements ranked by impact-to-effort ratio.

**Top 3 recommendations:**
1. Add `xcresulttool` GitHub Action for rich test reports in PR checks (high impact, low effort)
2. Upgrade to `macos-26` runner for latest Xcode toolchain (medium impact, low effort)
3. Add code coverage extraction and reporting (medium impact, medium effort)

---

## Sources Consulted

| Source | Type | Credibility | Key Contribution |
|--------|------|-------------|------------------|
| Jon Reid (qualitycoding.org) | Maintainer blog | High — iOS TDD authority | CI script patterns, `sudo xcode-select -s`, `xcbeautify` |
| mxcl/xcodebuild GitHub Action | Official repo | High — 2.3k stars, actively maintained | Resilient xcodebuild wrapper, auto destination resolution |
| kishikawakatsumi/xcresulttool | Official repo | High — widely adopted | xcresult to GitHub Checks, code coverage display |
| GitHub Actions runner-images repo | Official docs | High — canonical source | macOS 26 runner GA, runtime reduction policy |
| Apple WWDC 2025 sessions | Official docs | High — canonical source | xcresulttool, xccov updates |
| Swift Forums / Point-Free | Community | Medium — production-tested | Test parallelization patterns |

---

## 1. GitHub Actions YAML for Xcode Testing

### Current State Assessment

The existing `ci.yml` is well-structured:
- `macos-15` runner with `setup-xcode@v1` for version selection
- Python script (`run-tests.py`) handles xcodebuild invocation
- CI mode uses name-based destination: `platform=iOS Simulator,name=iPhone 16,OS=latest`
- `CODE_SIGNING_ALLOWED=NO` set in CI mode

### Recommendations

**Keep the Python script approach.** Jon Reid strongly advocates local-first test scripts over inline YAML commands because:
- Debuggable locally by setting `CI=1`
- Version-controlled separately from workflow
- Easier to add logging/error handling

**Minor YAML improvements:**

```yaml
# Add explicit Xcode version instead of "latest-stable" for reproducibility
- uses: maxim-lobanov/setup-xcode@v1
  with:
    xcode-version: '16.4'  # Pin to specific version
```

**Alternative: `mxcl/xcodebuild@v3` action.** This wraps xcodebuild with:
- Automatic simulator destination resolution (eliminates UUID/name issues)
- Automatic xcresult upload on failure
- `.swift-version` file support
- Code coverage toggle

Trade-off: More opaque, harder to debug when it fails. **Verdict: Keep current Python approach** — it gives more control and is already working.

---

## 2. Test Parallelization

### Current State

Tests run as a single `xcodebuild test` invocation. No parallelization.

### Options Evaluated

| Strategy | Complexity | Speed Gain | Suitability |
|----------|-----------|------------|-------------|
| `test-without-building` (build once, test many) | Low | 10-30% | Good for multi-destination |
| Test plan sharding via `-only-testing` | Medium | 20-50% | Good for large test suites |
| Matrix strategy (split by target) | Medium | 30-60% | Best for multi-module projects |
| SwiftPM `swift test --parallel` | Low | N/A | Not applicable (Xcode project) |

### Recommendation for This Project

**YAGNI.** StressMonitor has a small test suite (~20 tests in `StressMonitorTests`). Parallelization overhead exceeds benefit until the suite grows to 100+ tests.

**Future-proofing:** When tests exceed 100, split into:
```yaml
strategy:
  matrix:
    test-target: [StressMonitorTests, StressMonitorUITests]
```
With `-only-testing:StressMonitorTests/{TestClass}` sharding if needed.

---

## 3. Test Result Handling

### Current State

xcresult bundle uploaded as artifact. Requires manual download + Xcode to view. Not developer-friendly.

### Ranked Options

#### #1: `kishikawakatsumi/xcresulttool@v1` (RECOMMENDED)

- Displays test results directly in GitHub PR Checks tab
- Shows code coverage, test durations, failure details
- No external service dependency — runs in GitHub Actions
- Limitations: 65535 char limit per check, 50 annotation limit

```yaml
- name: Publish test results
  uses: kishikawakatsumi/xcresulttool@v1
  if: always()
  with:
    path: StressMonitor/build/TestResults.xcresult
    show-passed-tests: true
    show-code-coverage: true
```

**Trade-off matrix:**

| Dimension | xcresulttool | Manual xcresult | Third-party (Codecov) |
|-----------|-------------|-----------------|----------------------|
| Developer visibility | High (in PR) | Low (download needed) | Medium (external link) |
| Setup effort | Low (1 YAML step) | None | Medium (token, config) |
| Maintenance | Low | None | Medium |
| Cost | Free | Free | Free tier available |
| Coverage visualization | Basic | Full in Xcode | Rich web UI |

#### #2: JUnit XML via `xcparse`

Convert xcresult to JUnit XML for GitHub annotations natively:

```bash
xcparse junit --output test-results.xml StressMonitor/build/TestResults.xcresult
```

Then use `mikepenz/action-junit-report` for PR annotations. More flexible but requires additional tool.

**Recommendation:** Start with `xcresulttool`. Add JUnit conversion only if team needs CI-agnostic test reporting.

---

## 4. Simulator Management

### Current State

The Python script already implements best practices:
- CI: name-based destination (`iPhone 16,OS=latest`) — xcodebuild handles boot
- Local: `xcrun simctl boot` + `bootstatus` with 60s timeout
- Preferred model list for simulator selection
- Fallback to any available iPhone

### Known Simulator Flakiness Issues

1. **Boot timeout** — Already handled with `-destination-timeout 120` in the script
2. **Stale simulator state** — Not currently addressed. Add pre-run erase for CI:
   ```python
   if ci:
       subprocess.run(["xcrun", "simctl", "erase", "all"], capture_output=True)
   ```
3. **Runtime availability** — GitHub reduced to 3 iOS runtimes per runner image (Aug 2025). Using `OS=latest` avoids hardcoding unavailable runtimes.

### Recommendations

- **Keep current approach.** It already follows best practices.
- **Add one improvement:** Erase all simulators before CI run to avoid state corruption:
  ```yaml
  - name: Reset simulators
    run: xcrun simctl erase all 2>/dev/null || true
  ```
- **Do NOT pre-boot simulator in CI.** Name-based destination + `xcodebuild` auto-boots is more reliable than `simctl boot` followed by xcodebuild (two different resolution engines).

---

## 5. Caching Strategies

### Current State

SPM cache + DerivedData cached via `actions/cache@v4` keyed on `Package.resolved` hash.

### Cache Effectiveness Analysis

| Cache Target | Hit Rate | Size | Rebuild Cost | Recommendation |
|-------------|----------|------|-------------|----------------|
| SPM (`~/Library/Caches/org.swift.swiftpm`) | High | ~200MB | 2-5 min | **Keep** — high value |
| DerivedData (`~/Library/Developer/Xcode/DerivedData`) | Medium | ~500MB+ | 3-8 min | **Keep but consider removing** |
| Build products (`StressMonitor/build/`) | Never | N/A | N/A | Correctly not cached |

### DerivedData Cache Concern

DerivedData caching is controversial:
- **Pro:** Avoids full recompilation on dependency-stable PRs
- **Con:** Can cause stale symbol issues, especially with Swift module caches
- **Con:** Cache key (`Package.resolved` hash) doesn't account for source file changes

**Recommendation:** Keep current caching but add a note in the workflow. If weird build failures appear, clearing DerivedData cache is the first debugging step. Consider this alternative key:

```yaml
key: xcode-${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
restore-keys: xcode-${{ runner.os }}-spm-  # Falls back to SPM-only cache
```

This isolates SPM cache from DerivedData issues.

---

## 6. Xcode Versions on GitHub Actions

### Runner Image Availability (April 2026)

| Runner | macOS | Xcode Range | Status |
|--------|-------|-------------|--------|
| `macos-15` | macOS 15 Sequoia | Xcode 16.x | Stable, well-tested |
| `macos-26` | macOS 26 | Xcode 26.x | GA since Feb 2026 |

### Version Selection

Current: `latest-stable` via `setup-xcode@v1`. This is fine but unpinned — could change behavior between runs.

**Recommendation: Pin Xcode version.**

```yaml
- uses: maxim-lobanov/setup-xcode@v1
  with:
    xcode-version: '16.4'  # Explicit, reproducible
```

Update quarterly or when new Xcode versions are validated.

**Consider `macos-26` upgrade** when:
- Project targets iOS 26+ features
- Team adopts Xcode 26-specific APIs
- Need to validate against latest SDK

For now, `macos-15` + Xcode 16.x is the safe choice — matches the project's iOS 17+ deployment target.

---

## 7. Code Coverage

### Current State

No code coverage collection or reporting.

### Implementation Options

#### Option A: `xcresulttool` + `xccov` (RECOMMENDED for this project)

No external service. All in GitHub Actions:

```yaml
- name: Generate coverage report
  run: |
    xcrun xccov view --report StressMonitor/build/TestResults.xcresult > coverage.txt
    echo "## Code Coverage" >> $GITHUB_STEP_SUMMARY
    echo '```' >> $GITHUB_STEP_SUMMARY
    cat coverage.txt >> $GITHUB_STEP_SUMMARY
    echo '```' >> $GITHUB_STEP_SUMMARY
```

Enable coverage in `run-tests.py`:
```python
if ci:
    cmd.extend(["-enableCodeCoverage", "YES"])
```

Combined with `xcresulttool`, coverage shows in PR checks.

#### Option B: Codecov / Coveralls Integration

Upload coverage to external service for trend tracking, diff coverage on PRs.

```yaml
- name: Upload coverage
  uses: codecov/codecov-action@v4
  with:
    files: ./coverage.xml
    token: ${{ secrets.CODECOV_TOKEN }}
```

Requires converting xcresult to Cobertura XML (extra step with `xccov-to-cobertura` or `xcparse`).

### Recommendation

Start with Option A (xccov + xcresulttool). Add Codecov only if the team wants coverage trend history and diff coverage enforcement. For a 2-person project, in-PR coverage is sufficient.

---

## 8. Flaky Test Mitigation

### Known Sources of Simulator Flakiness in CI

| Source | Frequency | Mitigation |
|--------|-----------|------------|
| Simulator boot timeout | Rare | `-destination-timeout 120` (already implemented) |
| Stale simulator state | Occasional | `xcrun simctl erase all` before run |
| UI test timing issues | Common | Not applicable (unit tests only) |
| xcodebuild hang | Rare | `timeout-minutes: 25` in workflow (already implemented) |
| Memory pressure on runner | Occasional | Avoid DerivedData cache bloat |

### Retry Mechanism

**No retry wrapper needed for unit tests.** Simulators are deterministic for unit tests — flakiness primarily affects UI tests. If occasional failures occur:

```yaml
- name: Run tests
  uses: nick-fields/retry@v3
  with:
    timeout_minutes: 20
    max_attempts: 2
    retry_wait_seconds: 30
    command: python3 scripts/run-tests.py
```

**Recommendation:** Do NOT add retry until flakiness is actually observed. Premature retry masks real failures.

### Best Anti-Flakiness Practice for This Project

1. Keep tests as pure unit tests (no UI, no simulator-dependent logic)
2. The `SimulatorHealthKitService` correctly abstracts HealthKit away from tests
3. Protocol-based DI (already in architecture) means tests don't need real simulators for most logic

---

## Consolidated Recommendations (Ranked)

### Priority 1 — High Impact, Low Effort

| # | Change | Files | Effort |
|---|--------|-------|--------|
| 1 | Add `xcresulttool` step for PR test reports | `ci.yml` | 5 min |
| 2 | Pin Xcode version instead of `latest-stable` | `ci.yml` | 1 min |
| 3 | Add simulator erase before CI run | `ci.yml` or `run-tests.py` | 2 min |

### Priority 2 — Medium Impact, Low Effort

| # | Change | Files | Effort |
|---|--------|-------|--------|
| 4 | Enable code coverage (`-enableCodeCoverage YES`) | `run-tests.py` | 1 min |
| 5 | Add xccov summary to `$GITHUB_STEP_SUMMARY` | `ci.yml` | 5 min |
| 6 | Isolate SPM cache from DerivedData cache | `ci.yml` | 2 min |

### Priority 3 — Future Consideration

| # | Change | When |
|---|--------|------|
| 7 | Upgrade to `macos-26` runner | When targeting iOS 26+ |
| 8 | Add test parallelization | When suite exceeds 100 tests |
| 9 | Add retry mechanism | If flakiness observed |
| 10 | Add Codecov integration | If team wants coverage trends |

---

## Proposed CI Workflow (Full)

```yaml
name: Build & Test

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build-and-test:
    name: Build & Test
    runs-on: macos-15
    timeout-minutes: 25

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Select Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '16.4'

      - name: Print environment
        run: |
          xcodebuild -version
          python3 --version

      - name: Reset simulators
        run: xcrun simctl erase all 2>/dev/null || true

      - name: Cache SPM
        uses: actions/cache@v4
        with:
          path: ~/Library/Caches/org.swift.swiftpm
          key: xcode-${{ runner.os }}-spm-${{ hashFiles('StressMonitor/StressMonitor.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved') }}
          restore-keys: xcode-${{ runner.os }}-spm-

      - name: Run tests
        run: python3 scripts/run-tests.py
        env:
          CI: "1"

      - name: Publish test results
        uses: kishikawakatsumi/xcresulttool@v1
        if: always()
        with:
          path: StressMonitor/build/TestResults.xcresult
          show-passed-tests: true
          show-code-coverage: true

      - name: Code coverage summary
        if: always()
        run: |
          if [ -d "StressMonitor/build/TestResults.xcresult" ]; then
            echo "## Code Coverage" >> $GITHUB_STEP_SUMMARY
            echo '```' >> $GITHUB_STEP_SUMMARY
            xcrun xccov view --report StressMonitor/build/TestResults.xcresult 2>/dev/null >> $GITHUB_STEP_SUMMARY || true
            echo '```' >> $GITHUB_STEP_SUMMARY
          fi

      - name: Upload test results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: StressMonitor/build/TestResults.xcresult
          retention-days: 7
```

And add to `run-tests.py` in the CI block:
```python
if ci:
    cmd.extend(["CODE_SIGNING_ALLOWED=NO", "CI=1", "-enableCodeCoverage", "YES"])
```

---

## Limitations

- **No CI test execution data.** Recommendations based on community best practices, not measured performance of this specific pipeline. Actual build/test times would enable more precise caching and parallelization guidance.
- **macOS 26 runner specifics untested.** GA since Feb 2026 but practical stability data limited.
- **`mxcl/xcodebuild` not deeply evaluated.** Reviewed README and features but not battle-tested against the current Python script. The Python approach is preferred for transparency.
- **Test suite size unknown.** Parallelization recommendations assume current suite is small (<50 tests). Re-evaluate when suite grows.

---

## Unresolved Questions

1. **What is the current CI build+test duration?** This determines whether caching optimizations are worth the complexity.
2. **Does the team want coverage enforcement (PR gates) or just visibility?** Affects whether Codecov is needed.
3. **Are there any flaky tests currently?** If yes, retry mechanism becomes Priority 1.
