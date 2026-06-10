---
title: "CI/CD Fastlane + TestFlight 10K Tester Enhancement"
description: "Decouple build/upload from distribution, add SPM caching, phased 10K tester rollout via Fastlane pilot"
status: completed
priority: P1
branch: "feature/ci-cd-fastlane-testflight"
tags: [ci-cd, fastlane, testflight, github-actions]
blockedBy: []
blocks: []
created: "2026-06-09T16:38:29.793Z"
createdBy: "ck:plan"
source: skill
---

# CI/CD Fastlane + TestFlight 10K Tester Enhancement

## Overview

The current `beta` Fastlane lane uploads AND distributes to TestFlight in one step, with `skip_waiting_for_build_processing: false` + `timeout: 7200`. This locks the macOS CI runner for 60–90 min waiting on Apple's servers — wasting ~$15–20/deploy in runner minutes at GitHub's 10× macOS multiplier.

This plan decouples upload from distribution, adds SPM caching, automates changelog from git commits, and introduces a phased group rollout for up to 10,000 TestFlight testers.

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Runner | Keep `macos-15` GitHub-hosted | No infra overhead; fix pipeline instead |
| Upload/distribute split | `upload_beta` + `distribute_beta` lanes | Runner exits after upload (~20 min); distribute is a fast 2-min API call |
| Changelog | `changelog_from_git_commits` | Replaces manual CHANGELOG.md; auto-generates from git history |
| SPM cache | `Package.resolved` hash key | Prevents full re-resolve on cache miss (+3–5 min) |
| Tester groups | 4-tier phased rollout | Internal (100) → Core (500) → Extended (2K) → Public (10K) |
| Distribute trigger | Manual `workflow_dispatch` | Controlled rollout; don't notify 10K testers automatically |

## Phases

| Phase | Name | Status | Effort |
|-------|------|--------|--------|
| 1 | [Fastfile Refactor](./phase-01-fastfile-refactor.md) | Completed | 2h |
| 2 | [Deploy Workflow Split](./phase-02-deploy-workflow-split.md) | Completed | 1h |
| 3 | [Distribute Workflow](./phase-03-distribute-workflow.md) | Completed | 1h |
| 4 | [Test Workflow Cache](./phase-04-test-workflow-cache.md) | Completed | 30m |
| 5 | [Validation](./phase-05-validation.md) | Completed | 1h |

## Files Modified

| File | Phase | Change |
|------|-------|--------|
| `fastlane/Fastfile` | 1 | Split `beta` → `upload_beta` + `distribute_beta` lanes |
| `.github/workflows/deploy.yml` | 2 | Switch to `upload_beta`, reduce timeout to 35min |
| `.github/workflows/distribute.yml` | 3 | New: manual group-dispatch distribution workflow |
| `.github/workflows/_test.yml` | 4 | Add SPM cache key, switch to `ruby/setup-ruby` bundler cache |

## Dependencies

Related plan `0413-1223-github-actions-ci-pipeline` (in-progress): existing CI workflow is the test gate that `deploy.yml` depends on. No blocking relationship — that plan's output (`_test.yml` reusable workflow) is already implemented and in use.

## Validation Log

### Verification Results
- Claims checked: 12 | Verified: 9 | Failed: 0 | Unverified: 3
- Tier: Full (5 phases)
- All file paths, env var names, lane names, and timeout values verified against actual codebase.

### Validation Interview — 2026-06-09

| Question | Decision |
|----------|----------|
| Ruby version for `ruby/setup-ruby` | No pin — use macos-15 system default. Add `.ruby-version` if bundler fails. |
| Build selection in `distribute_beta` | `pilot` auto-selects latest processed build (`distribute_only: true`, no `build_number` param). |
| Changelog timing | Capture at **upload time** in `upload_beta`, write to `build/CHANGELOG.txt`; `distribute_beta` reads the file. |

### Propagation
- Phase 1: `upload_beta` now writes `build/CHANGELOG.txt`; `distribute_beta` reads it. No `build_number` in pilot call.
- Phase 3: Removed `BUILD_NUMBER` env var concern from distribute workflow.
- Phase 4: Removed `ruby-version: "3.2"` pin from `ruby/setup-ruby` step.

### Whole-Plan Consistency Sweep
- No stale terms found (old `beta` lane fully replaced in all phase references).
- No contradictions between phases.
- `build/CHANGELOG.txt` path consistent across Phase 1 upload and distribute steps.
- `ruby/setup-ruby` change applied consistently: Phase 4 `_test.yml`; deploy.yml Phase 2 does not use `ruby/setup-ruby` (it keeps manual caching — acceptable, deploy.yml not in scope for Phase 4).
- Zero unresolved contradictions. Plan is ready for implementation.
