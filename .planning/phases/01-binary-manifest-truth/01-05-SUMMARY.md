---
phase: 01-binary-manifest-truth
plan: 05
subsystem: infra
tags: [ci, github-actions, fastlane, match, testflight, app-store-connect, code-signing]

requires:
  - phase: 01-binary-manifest-truth (plans 01-04)
    provides: committed SPM proxy migration, privacy manifest declarations, plist consolidation, credential-scan gate, widget evidence — everything the two CI surfaces exercise
provides:
  - Draft PR #49 (gsd/v1.2-submission-readiness → main) with green ci.yml runs on clean hardware — ENV-04's CI half
  - ENV-05 verdict: match(readonly: true) GREEN on CI — three App Store profiles + K2TYLYAWMK Distribution cert installed read-only, zero regeneration, fallback unused
  - BUILD-01 SC-1 verdict: TestFlight build 1.0.0 (14) uploaded from the phase-final tree, ASC processing VALID, no ITMS-91053, no missing-SDK-manifest error
  - 01-ENV-05-CI-RECORD.md — the full evidence chain (run URLs, match log excerpt, ASC state)
affects: [phase-2 (ENV-01/02/03 environments), phase-4 submission flow (SHIP gates ride the proven upload pipeline), release recipe (dual-cert note: CI readonly never consults portal dual-cert profiles)]

actuals:
  tokens: 9500
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "User-gated one-way CI actions: TestFlight-visible deploys dispatch only after a blocking-human approval recorded in the evidence file before the dispatch timestamp"

key-files:
  created:
    - .planning/phases/01-binary-manifest-truth/01-ENV-05-CI-RECORD.md
    - .planning/phases/01-binary-manifest-truth/01-05-SUMMARY.md
  modified:
    - StressMonitor/StressMonitorTests/FirebaseBootstrapTests.swift (Task 1: CI-gate the two .configured assertions on plist presence)
    - .gitignore (Task 1: scoped exception so tracked proxy package sources resolve on clean checkouts)
    - StressMonitor/spm-cache/packages/proxy/** (Task 1: 9 shim/manifest files committed)

key-decisions:
  - "Task 1 (prior executor): proxy package sources committed behind a scoped .gitignore exception because clean CI cannot regenerate the local package — commits 483f270/fcd4c87"
  - "FirebaseBootstrap .configured tests gated on GoogleService-Info.plist presence (file is deliberately gitignored; provisioning deferred) — run+pass locally, explicit skip reason on clean CI"
  - "Task 2 dispatched deploy.yml only after the user's explicit approval ('approved — dispatch it'), recorded in the evidence file before the dispatch timestamp; setup_match fallback was NOT pre-authorized and was never needed"

patterns-established:
  - "Approval-before-dispatch evidence ordering: the record file must show the user-approval note before the dispatch timestamp for any TestFlight-visible action"
  - "ENV-05 verdict standard: run URL + match-step log excerpt (cert table + three profile UUIDs + zero regeneration messages) — a run that never exercised match cannot be recorded as validation"

requirements-completed: [ENV-05, BUILD-01]

coverage:
  - id: D1
    description: "Draft PR #49 on gsd/v1.2-submission-readiness with ci.yml green on clean CI hardware (ENV-04 CI half)"
    requirement: ENV-04
    verification:
      - kind: other
        ref: "gh run list --workflow=CI --branch gsd/v1.2-submission-readiness — run 33745603902 success at fcd4c87; docs-only re-run 33746936991 success at 1d29c51"
        status: pass
  - id: D2
    description: "User-approved deploy.yml dispatch: match readonly installed all three App Store profiles with no regeneration (ENV-05)"
    requirement: ENV-05
    verification:
      - kind: other
        ref: "run 33749862925 success; match log excerpt in 01-ENV-05-CI-RECORD.md (cert + 3 profile UUIDs, force:false, zero regeneration)"
        status: pass
  - id: D3
    description: "Pilot upload cleared ASC processing — build 1.0.0 (14) VALID, no ITMS-91053, no missing-SDK-manifest error (BUILD-01 SC-1)"
    requirement: BUILD-01
    verification:
      - kind: other
        ref: "run 33749862925 pilot output + asc builds list: build 14 state=VALID uploaded 2026-09-03T04:37:01-07:00"
        status: pass

status: complete
---

# Phase 1 Plan 05: CI Surfaces — Draft PR + User-Approved TestFlight Deploy Summary

One-liner: Branch pushed, draft PR #49 fired a green clean-machine ci.yml run, and a user-approved deploy.yml dispatch proved match(readonly: true) installs all three App Store profiles with zero regeneration and uploaded TestFlight build 1.0.0 (14) that cleared ASC processing with no privacy-manifest errors.

## What Was Done

### Task 1 — push, draft PR, green CI (prior executor; verified this session)

- Pushed `gsd/v1.2-submission-readiness` (all Phase-1 commits) and opened **draft PR #49** to main. First CI run 33743495896 failed only in FirebaseBootstrapTests (gitignored plist not provisioned on CI — pre-existing deferred gap); fixed by CI-gating those two assertions (fcd4c87). Run **33745603902 green (4/4 jobs)** at fcd4c87 — the ENV-04 clean-machine proof (SPM proxy resolves from a fresh checkout). Docs-only re-run 33746936991 green at 1d29c51.
- Commit chain: 483f270 (proxy sources behind scoped .gitignore exception), fcd4c87 (test gating), 1d29c51 + acea984 (record).

### Task 2 — user-approved deploy dispatch (this session)

- Approval: user replied **"approved — dispatch it"** (with the disclosed empty-widget caveat); recorded in 01-ENV-05-CI-RECORD.md **before** the dispatch timestamp. The setup_match fallback was explicitly NOT pre-authorized.
- Dispatched `gh workflow run deploy.yml --ref gsd/v1.2-submission-readiness` at 2026-09-03T11:28:20Z → run **33749862925**, job success in 11m10s.
- **ENV-05 verdict GREEN**: match summary shows `readonly: true`, `force: false`; cloned + decrypted the match git repo; installed `Apple Distribution: Doan Duy Phuong (K2TYLYAWMK)` (valid →2027-06-11) and the three profiles `match AppStore stress.ai.com` (b45e811f…), `.watchkitapp` (4c637481…), `.widget` (e25888e9…). Zero regeneration messages. The §9 dual-cert failure mode did not materialize — readonly reads the match repo, never the portal's recreated dual-cert profiles, so the fallback stays unused and the path is idempotently repeatable.
- **Gym**: signed Release archive exported (`Signing` observed for app/watch/widget, `signingStyle: manual`, 3 dSYMs) → `StressMonitor.ipa`.
- **BUILD-01 SC-1 verdict GREEN**: build number set to 14 (TF prior 13); pilot uploaded, fastlane observed `Successfully finished processing the build 1.0.0 - 14 for IOS`; authoritative ASC check via asc CLI: `build 14: state=VALID`, `APP_STORE_ELIGIBLE`. No ITMS-91053 and no missing-SDK-manifest error anywhere in the run log or the uploaded build-logs artifact — plan 02's manifest declarations and plans 01/04's SDK-bundle flow cleared the upload gate; no phase-gap finding.
- Threat T-05-02 follow-through: downloaded the run's build-logs artifact and scanned — no secret material.

## Deviations from Plan

None — Task 2 executed exactly as planned (approval first, single dispatch, watch to completion, both verdicts recorded from primary evidence). Task 1's deviations (proxy-source commit, FirebaseBootstrap CI gating) were handled and documented by the prior executor in the record file's iteration section.

## Auth Gates

None this session (gh + asc both pre-authenticated).

## Evidence & Prohibition Checks

- PR #49: `isDraft: true`, `state: OPEN` — never merged; `origin/main` still `fed4b6b`.
- `git diff origin/main...HEAD -- .github/workflows/` → 0 files — workflows observe-only.
- Full evidence: `.planning/phases/01-binary-manifest-truth/01-ENV-05-CI-RECORD.md`.

## Known Stubs

None introduced by this plan. (Pre-existing, already tracked: WIRE-01 widget write-path gap — the user approved this upload with that caveat disclosed; the widget in build 14 renders No Data until the write path is wired.)

## Deferred Issues

None.
