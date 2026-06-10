---
phase: 3
title: "Distribute Workflow"
status: completed
priority: P1
effort: "1h"
dependencies: [1]
---

# Phase 3: Distribute Workflow

## Overview

Create `.github/workflows/distribute.yml` — a manual `workflow_dispatch` workflow that calls `fastlane distribute_beta` to push a processed build to a specific TestFlight group. Runs in <5 minutes (no build, pure ASC API call).

## Requirements

- Functional:
  - `workflow_dispatch` trigger with `group` dropdown (4 options) and optional `build_number`
  - Requires `production` environment (approval gate)
  - Calls `fastlane distribute_beta`
  - Passes `TESTFLIGHT_GROUPS` env var from input
  - Passes all ASC + Match secrets (same as deploy.yml)
- Non-functional:
  - `timeout-minutes: 10`
  - No Xcode build — only Ruby + Fastlane needed

## Architecture

```
workflow_dispatch(group: "Core Testers")
  └─► distribute.yml
        └─ job: distribute
              ├─ Checkout
              ├─ Cache Ruby Gems
              ├─ Install Dependencies
              └─ Distribute via Fastlane   ← fastlane distribute_beta
```

**TestFlight group tiers** (must be pre-created in App Store Connect):

| Group Name (exact) | Capacity | Purpose |
|-------------------|----------|---------|
| `Internal Testers` | 100 max | Auto-added team members (not via this workflow) |
| `Core Testers` | ~500 | First external group; sanity check builds |
| `Extended Beta` | ~2,000 | Wider beta; invited via link |
| `Public Beta` | ~10,000 | Open public link; full 10K |

## Related Code Files

- Create: `.github/workflows/distribute.yml`

## Implementation Steps

1. **Create `.github/workflows/distribute.yml`**:
   ```yaml
   name: Distribute to TestFlight

   on:
     workflow_dispatch:
       inputs:
         group:
           description: "TestFlight group to distribute to"
           required: true
           type: choice
           options:
             - "Core Testers"
             - "Extended Beta"
             - "Public Beta"
         build_number:
           description: "Build number to distribute (leave blank = latest processed)"
           required: false
           type: string

   concurrency:
     group: distribute-${{ github.ref }}-${{ inputs.group }}
     cancel-in-progress: false   # never cancel an in-flight distribution

   env:
     LANG: "en_US.UTF-8"

   jobs:
     distribute:
       name: Distribute to ${{ inputs.group }}
       runs-on: macos-15
       timeout-minutes: 10
       environment: production

       steps:
         - name: Checkout
           uses: actions/checkout@v4

         - name: Cache Ruby Gems
           uses: actions/cache@v4
           with:
             path: vendor/bundle
             key: gems-${{ runner.os }}-${{ hashFiles('**/Gemfile.lock') }}
             restore-keys: gems-${{ runner.os }}-

         - name: Install Dependencies
           run: |
             bundle config path vendor/bundle
             bundle install --jobs 4 --retry 3

         - name: Distribute via Fastlane
           env:
             APP_STORE_CONNECT_API_KEY_ID: ${{ secrets.APP_STORE_CONNECT_API_KEY_ID }}
             APP_STORE_CONNECT_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
             APP_STORE_CONNECT_API_KEY_P8: ${{ secrets.APP_STORE_CONNECT_API_KEY_P8 }}
             MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
             MATCH_GIT_URL: ${{ secrets.MATCH_GIT_URL }}
             MATCH_GIT_BASIC_AUTHORIZATION: ${{ secrets.MATCH_GIT_BASIC_AUTHORIZATION }}
             APP_IDENTIFIER: ${{ secrets.APP_IDENTIFIER }}
             APPLE_ID: ${{ secrets.APPLE_ID }}
             TEAM_ID: ${{ secrets.TEAM_ID }}
             ITC_TEAM_ID: ${{ secrets.ITC_TEAM_ID }}
             SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
             TESTFLIGHT_GROUPS: ${{ inputs.group }}
             # Note: no BUILD_NUMBER — pilot auto-selects latest processed build
           run: bundle exec fastlane distribute_beta
   ```

2. **Pre-create TestFlight groups in App Store Connect** (manual step, one-time):
   - App Store Connect → Your App → TestFlight → Internal/External Groups
   - Create groups: `Core Testers`, `Extended Beta`, `Public Beta`
   - Note: group names must match exactly the `options` values in `distribute.yml`

3. **Set up public link for `Public Beta` group** in ASC (optional, for open enrollment):
   - TestFlight → `Public Beta` group → Enable Public Link
   - Share link in app's marketing channels

4. **Test the workflow** with a dry run:
   - Go to GitHub → Actions → "Distribute to TestFlight" → Run workflow
   - Select `Core Testers`
   - Verify Fastlane connects to ASC API and finds the processed build
   - Verify testers in `Core Testers` receive notification

## Success Criteria

- [x] `.github/workflows/distribute.yml` created and committed
- [x] `workflow_dispatch` shows `group` dropdown with 3 external options
- [x] Job `timeout-minutes: 10`
- [x] `environment: production` set (triggers approval gate)
- [x] `TESTFLIGHT_GROUPS` env var maps from `inputs.group`
- [x] `concurrency.cancel-in-progress: false` (distributions must never be cancelled mid-flight)
- [ ] Workflow completes in <5 min on first run
- [ ] TestFlight groups `Core Testers`, `Extended Beta`, `Public Beta` exist in ASC

## Risk Assessment

| Risk | Mitigation |
|------|-----------|
| `distribute_only: true` fails if build not yet processed | Fastlane will error with a clear message. Wait for ASC to show "Ready to Test" before triggering. |
| Group name mismatch (case-sensitive in ASC) | Use exact names as created in ASC. Validate by running `bundle exec fastlane pilot builds` to list available builds and groups. |
| Notifying wrong group | `concurrency` group includes `inputs.group` — can't run two distributions to different groups simultaneously by accident. Each is a separate dispatch. |
| 10K notification spam | `Public Beta` group should only be triggered after 24h in `Extended Beta` with no crashes. This is a process control, not a code control. |

## Phased Rollout Protocol (Operational Runbook)

After each push to `main`:
1. **Wait** for `deploy.yml` to complete (build uploaded, ~20 min)
2. **Wait** for ASC to show build as "Ready to Test" (~30-90 min, check App Store Connect)
3. **Trigger** `distribute.yml` → `Core Testers` → verify no crash reports (24h)
4. **Trigger** `distribute.yml` → `Extended Beta` → monitor (24-48h)
5. **Trigger** `distribute.yml` → `Public Beta` → full 10K notified
