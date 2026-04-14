---
name: CI Test Reporting with xcresulttool
description: Add xcresulttool GitHub Action for PR test reports + code coverage in CI
status: completed
created: 2026-04-13
author: phuongddx
blockedBy: [0413-1223-github-actions-ci-pipeline]
---

# CI Test Reporting with xcresulttool

## Overview

Add test result visibility to GitHub PR checks using `xcresulttool` action. Enable code coverage collection. No new dependencies — keeps existing Python script approach.

## Context

| Item | Value |
|------|-------|
| Brainstorm report | `plans/reports/brainstorm-0413-2113-ci-fastlane-vs-xcresulttool.md` |
| Research report | `plans/reports/researcher-0413-ci-unit-test-best-practices.md` |
| Parent plan | `plans/0413-1223-github-actions-ci-pipeline/` |
| Files to modify | 2 |
| Lines to change | ~10 |

## Key Decision

Fastlane rejected — adds Ruby dependency for zero benefit when only unit tests needed. `xcresulttool` gives native GitHub PR check integration with no runtime deps.

## Files to Modify

| File | Change |
|------|--------|
| `.github/workflows/ci.yml` | Add xcresulttool step + coverage summary step |
| `scripts/run-tests.py` | Add `-enableCodeCoverage YES` to CI mode |

## Phases

### Phase 1 — Enable Code Coverage in Test Runner

**File:** `scripts/run-tests.py`
**Priority:** High
**Effort:** 1 min

Add `-enableCodeCoverage YES` to the xcodebuild command when running in CI mode.

**Change at line 122:**
```python
# Before:
cmd.extend(["CODE_SIGNING_ALLOWED=NO", "CI=1"])

# After:
cmd.extend(["CODE_SIGNING_ALLOWED=NO", "CI=1", "-enableCodeCoverage", "YES"])
```

**Success criteria:** xcodebuild runs with coverage enabled, xcresult contains coverage data.

### Phase 2 — Add xcresulttool PR Test Reports

**File:** `.github/workflows/ci.yml`
**Priority:** High
**Effort:** 5 min

Add `kishikawakatsumi/xcresulttool@v1` step after "Run tests" step.

**Add after line 45 (after "Run tests" step):**
```yaml
- name: Publish test results
  uses: kishikawakatsumi/xcresulttool@v1
  if: always()
  with:
    path: StressMonitor/build/TestResults.xcresult
    show-passed-tests: true
    show-code-coverage: true
```

**Success criteria:** PR checks tab shows individual test pass/fail with coverage.

### Phase 3 — Add Coverage Summary to GitHub Step Summary

**File:** `.github/workflows/ci.yml`
**Priority:** Medium
**Effort:** 2 min

Add xccov summary step that renders in the Actions run summary page.

**Add after xcresulttool step:**
```yaml
- name: Code coverage summary
  if: always()
  run: |
    if [ -d "StressMonitor/build/TestResults.xcresult" ]; then
      echo "## Code Coverage" >> $GITHUB_STEP_SUMMARY
      echo '```' >> $GITHUB_STEP_SUMMARY
      xcrun xccov view --report StressMonitor/build/TestResults.xcresult 2>/dev/null >> $GITHUB_STEP_SUMMARY || true
      echo '```' >> $GITHUB_STEP_SUMMARY
    fi
```

**Success criteria:** Actions run summary page shows coverage table.

## Success Criteria

- [ ] PR checks show test results inline (pass/fail per test)
- [ ] Code coverage visible in PR checks
- [ ] Coverage summary in GitHub Step Summary
- [ ] No new runtime dependencies
- [ ] CI build time increase < 5s

## Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| xcresultbundle path mismatch | Low | Path already verified in current workflow |
| xcresulttool action fails on large results | Low | Small test suite (~20 tests), well under limits |
| Coverage collection slows build | Low | Negligible for <50 tests |

## No Security Concerns

No secrets, no external services, no code changes to app logic.
