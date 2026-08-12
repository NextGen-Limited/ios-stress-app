# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — App Store Submission Remediation

**Shipped:** 2026-08-12 (`override_closeout` — see PROJECT.md's "v1.0 Verification Reality Check")
**Phases:** 6 | **Plans:** 11 | **Sessions:** multiple (spanning 2026-08-08 → 2026-08-12)

### What Was Built
- Widget App Group entitlement + Privacy Manifest fixed across all 3 targets; widget resolves fresh/stale/empty via a tested resolver
- Non-fatal SwiftData `ModelContainer` recovery — no crash on any prior store schema state
- Deletion consolidated onto a single `DataDeleterService`; Delete All now actually clears Keychain JWT + App Group cache; CloudKit health fields encrypted via `encryptedValues`
- AI Chat honestly gated off for v1 via a compile-time flag rather than a silently-dead entry point
- IAP purchase flow fixed for Release-config compilation; accessibility gaps addressed in Phase 5

### What Worked
- Re-review after fix (running the code reviewer again against the fixer's own changes) caught two genuine regressions/pre-existing bugs that a single review+fix pass would have missed entirely: a cancel-mid-delete split-brain bug (introduced by the first fix) and a pre-existing "CloudKit delete reports success on failure" swallow. Three rounds of review→fix→re-review on Phase 2 alone.
- Independently re-running `xcodebuild build-for-testing` after every fix pass (rather than trusting the fixer/reviewer subagent's self-reported build status) caught nothing wrong this time, but is cheap insurance against a subagent's own build claim being stale or scoped wrong.
- Surfacing pre-flight/audit-gate conflicts to the user explicitly (rather than silently proceeding or silently blocking) let the user make an informed, fast call each time gaps were found.

### What Was Inefficient
- Phase 2's code review depth was set to `standard` throughout, yet needed 3 full review→fix cycles to reach a stable state on data-integrity-critical code — a `deep` first pass (cross-file, import-graph aware) might have surfaced the CloudKit batch-delete swallow and the cancellation-ordering issue in one pass instead of three.
- Phases 3, 4, and 5 were executed but never ran `verify_phase_goal` — the milestone reached "all plans have SUMMARY.md" without ever confirming any of them actually achieved their stated phase goal. REQUIREMENTS.md's traceability table marked most of their requirements "Complete" purely from plan-level self-report, not independent verification — this is the single biggest gap in this milestone's actual rigor.
- This development host has a persistent, reproducible CoreSimulator device-pairing failure (`No matching device ... in XCTestDevices`) blocking every `xcodebuild test` attempt, across every phase's verification session this milestone (4+ independent occurrences). No workaround was found; every test-execution claim in this milestone rests on compile-only (`build-for-testing`) success, never an actual pass/fail signal. This should be fixed or worked around (different host, CI runner) before it silently erodes confidence in future milestones' test claims.

### Patterns Established
- Independently re-verify a subagent's "build succeeded" / "tests pass" claim with a real command before trusting it in a report to the user — this session found the subagents' self-reports were accurate every time, but the SourceKit "new diagnostics" noise that appeared after several edits looked alarming and would have been mistaken for real errors without an independent build.
- When a pre-close audit or verification gate surfaces `gaps_found`/`human_needed`/unchecked-requirements, present the specific evidence (not just the verdict) before asking the user to decide — options without the underlying evidence invite an uninformed "proceed anyway."

### Key Lessons
1. "All plans have a SUMMARY.md" is not the same as "phase goal verified" — a milestone can look 100% executed while being far short of verified. Run `verify_phase_goal` (or `/gsd-verify-work`) for every phase before treating a milestone as close-ready, not just before `/gsd-complete-milestone` itself.
2. On data-integrity-critical code, budget for multiple review→fix→re-review cycles up front rather than assuming one pass suffices — each re-review in this milestone found something new the prior fix introduced or missed.
3. A host-level test-execution blocker (simulator device-pairing failure) that recurs across multiple phases' verification sessions is itself a project risk worth escalating and fixing, not just re-documenting each time as a one-off environment note.

### Cost Observations
- Sessions: multiple, spanning ~4 days of wall-clock time (2026-08-08 init → 2026-08-12 close)
- Notable: Phase 2 alone consumed 3 full agent-spawned review/fix cycles plus repeated independent build verification in a single session before verification — a disproportionate share of this milestone's total agent-time relative to its 1-plan phase size, driven by the review depth gap noted above.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | multiple | 6 | First milestone. Established: independent build re-verification after every fixer pass; re-review after fix as standard practice for data-integrity code. |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.0 | Never executed (host CoreSimulator blocker) — compile-verified only | Unknown | 0 |

### Top Lessons (Verified Across Milestones)

1. "Plans complete" ≠ "phase verified" — always run the verification gate explicitly, don't infer it from execution completion.
