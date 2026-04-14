# Brainstorm: Fastlane vs xcresulttool for CI Test Reporting

**Date:** 2026-04-13
**Status:** APPROVED — proceed with xcresulttool approach
**Decision:** Keep Python script, add xcresulttool GitHub Action. No Fastlane.

---

## Problem Statement

CI test results require downloading xcresult bundle + opening in Xcode. Devs can't see pass/fail in PR checks. Need better test reporting visibility.

## Constraint: Unit tests only for next 3 months. No UI tests, no deployment.

---

## Options Evaluated

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **xcresulttool action** | Native PR Checks, no deps, 5-min setup, code coverage | Limited to GitHub ecosystem | **CHOSEN** |
| **Fastlane scan** | Industry std, future deploy/screenshot ready | Ruby dep, Gemfile, bundle install 30-60s, overkill for reporting only | Rejected — YAGNI |
| **JUnit XML via xcparse** | CI-agnostic reporting | Extra tool, no native GitHub integration | Rejected — unnecessary complexity |

## Rationale

Fastlane adds Ruby dependency (Gemfile, Bundler, gem management) for zero immediate benefit. The `xcresulttool` action provides richer GitHub-native reporting than Fastlane would out-of-the-box. Revisit Fastlane when deployment/screenshots become requirements.

---

## Implementation Plan (3 changes)

### 1. Add xcresulttool step to `ci.yml` (after "Run tests")

```yaml
- name: Publish test results
  uses: kishikawakatsumi/xcresulttool@v1
  if: always()
  with:
    path: StressMonitor/build/TestResults.xcresult
    show-passed-tests: true
    show-code-coverage: true
```

### 2. Enable code coverage in `run-tests.py` line 122

```python
cmd.extend(["CODE_SIGNING_ALLOWED=NO", "CI=1", "-enableCodeCoverage", "YES"])
```

### 3. Add coverage summary to GitHub Step Summary (optional)

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

## Files to Modify

- `.github/workflows/ci.yml` — add xcresulttool + coverage steps
- `scripts/run-tests.py` — add `-enableCodeCoverage YES` to CI mode

## Success Criteria

- PR checks show test results inline (pass/fail per test)
- Code coverage visible in PR checks and GitHub Step Summary
- No new runtime dependencies added
- CI build time does not increase by more than 5s

## Future Consideration

Re-evaluate Fastlane when adding:
- TestFlight beta deployment
- Screenshot automation
- Multi-app orchestration
