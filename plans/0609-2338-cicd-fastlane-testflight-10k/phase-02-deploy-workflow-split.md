---
phase: 2
title: "Deploy Workflow Split"
status: completed
priority: P1
effort: "1h"
dependencies: [1]
---

# Phase 2: Deploy Workflow Split

## Overview

Update `.github/workflows/deploy.yml` to call `upload_beta` instead of `beta`, reduce timeout from 90 to 35 minutes (no more Apple-processing wait), and add SPM cache to the deploy job.

## Requirements

- Functional:
  - Deploy job calls `fastlane upload_beta`
  - Deploy job has `timeout-minutes: 35`
  - SPM packages cache added alongside existing DerivedData cache
  - Artifacts upload unchanged (build logs retained 14 days)
- Non-functional:
  - Deploy job must complete in <35 min end-to-end on `macos-15`
  - No change to trigger conditions (`push` to `main`/`release/*`, `workflow_dispatch`)

## Architecture

```
push to main
  └─► deploy.yml
        ├─ job: test  (uses _test.yml — unchanged)
        └─ job: deploy (needs: test)
              ├─ Checkout
              ├─ Select Xcode 16.3
              ├─ Cache Ruby Gems
              ├─ Cache SPM Packages          ← NEW
              ├─ Cache DerivedData
              ├─ Install Dependencies
              ├─ Free Disk Space
              ├─ Build & Deploy via Fastlane  ← calls upload_beta
              └─ Upload Build Artifacts
```

## Related Code Files

- Modify: `.github/workflows/deploy.yml`

## Implementation Steps

1. **Open `.github/workflows/deploy.yml`**.

2. **Change `timeout-minutes`** on the `deploy` job from `90` to `35`:
   ```yaml
   deploy:
     name: Build & Deploy to TestFlight
     needs: test
     runs-on: macos-15
     timeout-minutes: 35        # was 90
   ```

3. **Add SPM cache step** after the DerivedData cache step (around line 45):
   ```yaml
   - name: Cache SPM Packages
     uses: actions/cache@v4
     with:
       path: |
         ~/Library/Developer/Xcode/DerivedData/**/SourcePackages/checkouts
         ~/Library/Developer/Xcode/DerivedData/**/SourcePackages/repositories
       key: spm-${{ runner.os }}-${{ hashFiles('**/Package.resolved') }}
       restore-keys: |
         spm-${{ runner.os }}-
   ```

4. **Update the Fastlane step** to call `upload_beta`:
   ```yaml
   - name: Build & Upload via Fastlane
     env:
       # ... all existing env vars unchanged ...
       DISTRIBUTE_EXTERNAL: ""        # remove — no longer used in upload_beta
       TESTFLIGHT_GROUPS: ""          # remove — no longer used in upload_beta
     run: bundle exec fastlane upload_beta
   ```
   Remove `DISTRIBUTE_EXTERNAL` and `TESTFLIGHT_GROUPS` env vars — they are no longer needed in the upload step.

5. **Remove the `distribute_external` and `testflight_groups` workflow inputs** from `workflow_dispatch` (they belong in `distribute.yml` now):
   ```yaml
   workflow_dispatch:
     inputs:
       # Remove distribute_external input
       # Remove testflight_groups input
       # (no inputs needed — upload_beta doesn't distribute)
   ```
   If `workflow_dispatch` has no inputs left, simplify to:
   ```yaml
   workflow_dispatch:
   ```

6. **Verify** the deploy job no longer references `fastlane beta` anywhere:
   ```bash
   grep -n "fastlane beta" .github/workflows/deploy.yml  # should return nothing
   grep -n "upload_beta" .github/workflows/deploy.yml    # should return 1 match
   ```

## Success Criteria

- [x] `deploy.yml` calls `fastlane upload_beta` (not `fastlane beta`)
- [x] `timeout-minutes: 35` on deploy job
- [x] SPM cache step present with `Package.resolved` hash key
- [x] `DISTRIBUTE_EXTERNAL` and `TESTFLIGHT_GROUPS` env vars removed from deploy job
- [x] `workflow_dispatch` inputs simplified or removed
- [x] `grep "fastlane beta" .github/workflows/deploy.yml` returns nothing

## Risk Assessment

| Risk | Mitigation |
|------|-----------|
| SPM cache key collision with `_test.yml` | Both use same key format — this is intentional; they share the cache |
| 35-min timeout too tight if build is slow | Gym build on clean runner takes ~18-22 min; 35 min has 13-min buffer. If consistently tight, raise to 40. |
| Removing `workflow_dispatch` inputs breaks existing bookmarks | Inputs were optional anyway; anyone using `workflow_dispatch` for manual deploys just won't see the distribution options (moved to `distribute.yml`) |
