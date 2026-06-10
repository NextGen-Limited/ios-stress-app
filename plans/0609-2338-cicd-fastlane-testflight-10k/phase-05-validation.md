---
phase: 5
title: "Validation"
status: completed
priority: P1
effort: "1h"
dependencies: [1, 2, 3, 4]
---

# Phase 5: Validation

## Overview

End-to-end validation of the full pipeline: trigger a push to `main`, verify upload completes in <35 min, then trigger distribute and verify the correct TestFlight group receives the build. Also validate that the old `beta` lane removal doesn't break any docs or scripts.

## Requirements

- Functional:
  - `deploy.yml` completes `upload_beta` successfully on push to `main`
  - `distribute.yml` distributes to `Core Testers` correctly
  - Slack notifications fire for both upload and distribution
  - TestFlight group receives email notification
- Non-functional:
  - Upload job wall-clock time <35 min
  - Distribute job wall-clock time <5 min
  - No regressions to `ci.yml` (PR checks unaffected)

## Related Code Files

- Read: `.github/workflows/deploy.yml`
- Read: `.github/workflows/distribute.yml`
- Read: `.github/workflows/_test.yml`
- Read: `fastlane/Fastfile`

## Implementation Steps

### Pre-flight Checks

1. **Verify `Package.resolved` is committed**:
   ```bash
   git ls-files | grep "Package.resolved"
   # Should output: StressMonitor/StressMonitor.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
   ```

2. **Verify group names exist in App Store Connect**:
   - Log into App Store Connect → App → TestFlight → Groups
   - Confirm `Core Testers`, `Extended Beta`, `Public Beta` groups exist
   - If not, create them (see Phase 3, Step 2)

3. **Verify all secrets are set** in GitHub repo Settings → Secrets:
   - `APP_STORE_CONNECT_API_KEY_ID`
   - `APP_STORE_CONNECT_ISSUER_ID`
   - `APP_STORE_CONNECT_API_KEY_P8`
   - `MATCH_PASSWORD`, `MATCH_GIT_URL`, `MATCH_GIT_BASIC_AUTHORIZATION`
   - `APP_IDENTIFIER`, `APPLE_ID`, `TEAM_ID`, `ITC_TEAM_ID`
   - `SLACK_WEBHOOK_URL` (optional)

4. **Check no references to old `fastlane beta`** remain:
   ```bash
   grep -r "fastlane beta" .github/ fastlane/ docs/ README.md 2>/dev/null
   # Should return nothing
   ```

### Upload Validation

5. **Push a trivial commit to `main`** (or trigger `workflow_dispatch` on `deploy.yml`):
   ```bash
   git commit --allow-empty -m "chore: validate CI/CD pipeline"
   git push origin main
   ```

6. **Monitor `deploy.yml` in GitHub Actions**:
   - `test` job: should pass in ~12-15 min
   - `deploy` job: should complete in <35 min
   - Verify step "Build & Upload via Fastlane" shows `skip_waiting_for_build_processing: true` in logs

7. **Verify in App Store Connect**:
   - TestFlight → Builds → new build appears (status: "Processing" or "Ready to Test")
   - Build number incremented correctly

8. **Verify Slack** (if webhook set): "📦 StressMonitor X.X (NNN) uploaded to TestFlight (processing)"

### Distribution Validation

9. **Wait for build to show "Ready to Test" in ASC** (~30-90 min after upload).

10. **Trigger `distribute.yml`** via GitHub Actions → Run workflow → select `Core Testers`:
    - Job should complete in <5 min
    - Verify in ASC: `Core Testers` group now has the build assigned

11. **Verify testers** in `Core Testers` group receive TestFlight notification email.

12. **Verify Slack**: "📦 StressMonitor X.X (NNN) distributed to Core Testers"

### Cache Validation

13. **On second push to `main`**, check Actions logs for cache hits:
    - "Cache hit for SPM Packages" should appear
    - "Cache hit for Ruby gems" should appear
    - DerivedData cache hit should appear
    - Upload job should be noticeably faster on cache hit (~15-18 min vs ~20-22 min)

### Regression Check

14. **Open a test PR** to `main` and verify `ci.yml` still passes (lint + tests unaffected by changes to `deploy.yml`).

## Success Criteria

- [ ] `deploy.yml` upload job completes in <35 min wall clock (requires live run)
- [ ] New build appears in App Store Connect after upload (requires live run)
- [ ] `distribute.yml` completes in <5 min (requires live run)
- [ ] `Core Testers` group in ASC has the build assigned (requires live run)
- [ ] TestFlight group notification sent (requires live run)
- [ ] Slack messages for both upload and distribution (requires live run)
- [ ] SPM cache hit on second run (requires live run)
- [x] No references to old `fastlane beta` in any file
- [ ] `ci.yml` PR checks unaffected (requires live run)

## Risk Assessment

| Risk | Mitigation |
|------|-----------|
| Build not "Ready to Test" before distribute trigger | Add a note to the distribute workflow description: "Only trigger after ASC shows build as Ready to Test" |
| Group name not found by pilot | Run `bundle exec fastlane pilot builds` locally to list builds/groups and verify names |
| Upload fails with ITMS signing error | Check Match repo is accessible and certs are valid. Run `bundle exec fastlane match appstore --readonly` locally. |
| Cache key wrong for SPM | Run workflow once, check logs — if cache miss every time, verify `Package.resolved` is at the expected path |
