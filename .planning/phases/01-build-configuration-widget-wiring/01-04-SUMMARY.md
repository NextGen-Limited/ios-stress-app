---
phase: 01-build-configuration-widget-wiring
plan: 04
subsystem: docs
tags: [privacy, documentation, chat, supabase, disclosure]

requires: []
provides:
  - "CLAUDE.md, README.md (unchanged, already accurate), docs/project-overview-pdr.md, docs/system-architecture.md, docs/system-architecture-platform.md, docs/INDEX.md corrected to disclose the real /chat payload contents and session-linkage"
  - "docs-site/legal/privacy.md and its Vietnamese mirror carry a new AI Coaching Chat disclosure section, consistent with the corrected architecture docs"
affects: [phase-05-ship (SHIP-03 ASC privacy nutrition label depends on this same D-01 resolution)]

actuals:
  tokens: 2627
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns: ["Privacy disclosure text sourced from StressContextPayload.swift ground truth, not assumed from prior docs"]

key-files:
  created: []
  modified:
    - CLAUDE.md
    - docs/project-overview-pdr.md
    - docs/system-architecture.md
    - docs/system-architecture-platform.md
    - docs/INDEX.md
    - docs-site/legal/privacy.md
    - docs-site/vi/legal/privacy.md

key-decisions:
  - "Verified StressContextPayload.build() ground truth before writing disclosure text: raw HRV/HR/sleep/activity/recovery readings are hardcoded nil and never sent; what actually transmits is the stress score, category, confidence, trend, and a per-factor breakdown of normalized (0-1) scores + weights for HRV/heart-rate/sleep/activity/recovery. Disclosure wording reflects this exactly rather than the plan's shorthand ('HRV, resting heart rate, sleep, activity, recovery')."
  - "Session-linkage disclosed as 'Bearer-JWT-authenticated session (anonymous or signed-in via Supabase Auth)' rather than claiming identity-linkage, since SupabaseLLMService.ensureValidSession() falls back to signInAnonymously() — the JWT proves session continuity, not necessarily real user identity."
  - "README.md left unmodified per plan's own read_first/action guidance — its 'Privacy-First' bullet is about third-party analytics, unrelated to the chat claim, and was already accurate."

requirements-completed: [BUILD-01]

coverage:
  - id: D1
    description: "Root/architecture docs (CLAUDE.md, docs/project-overview-pdr.md, docs/system-architecture.md, docs/system-architecture-platform.md, docs/INDEX.md) no longer claim the AI chat context is anonymized or that health data never leaves the device; each names the actual transmitted fields and Bearer-JWT session-linkage."
    requirement: "BUILD-01"
    verification:
      - kind: other
        ref: "grep -v '^#' CLAUDE.md | grep -c 'No external API calls or servers' == 0; grep -c 'anonymized chat context' across the 4 docs == 0; grep -c 'Supabase Edge Function|stress-context' CLAUDE.md >= 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "docs-site/legal/privacy.md and its Vietnamese mirror carry a new AI Coaching Chat / Trò Chuyện Cùng AI section disclosing the same facts, and no longer claim zero data is ever transmitted to StressMonitor's servers."
    requirement: "BUILD-01"
    verification:
      - kind: other
        ref: "grep -c '^## AI Coaching Chat' docs-site/legal/privacy.md == 1; grep -c '^## Trò Chuyện Cùng AI' docs-site/vi/legal/privacy.md == 1; old zero-transmission bullet count == 0 in both files"
        status: pass
    human_judgment: false

duration: 7min
completed: 2026-08-09
status: complete
---

# Phase 1 Plan 04: Privacy Disclosure Correction Summary

**Corrected 7 docs (CLAUDE.md, 4 docs/ architecture files, and the EN+VI privacy policy) to disclose the actual `/chat` payload — derived stress score/category/confidence/trend plus per-factor HRV/heart-rate/sleep/activity/recovery scores, sent under a Bearer-JWT-authenticated session — replacing the false "anonymized"/"never leaves the device" claim per D-01.**

## Performance

- **Duration:** 7 min (commit-to-commit)
- **Started:** 2026-08-09T13:24:36+07:00 (base commit)
- **Completed:** 2026-08-09T13:30:43+07:00
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Root/architecture docs (`CLAUDE.md`, `docs/project-overview-pdr.md`, `docs/system-architecture.md`, `docs/system-architecture-platform.md`, `docs/INDEX.md`) no longer claim the AI Coaching Chat context is anonymized or that health data never leaves the device — each now names the specific derived fields transmitted and discloses the Bearer-JWT session-linkage.
- `docs-site/legal/privacy.md` and its Vietnamese mirror (`docs-site/vi/legal/privacy.md`) each gained a new "AI Coaching Chat" / "Trò Chuyện Cùng AI" section, positioned after iCloud Sync and before HealthKit, disclosing the same facts; the old absolute "no data is transmitted" bullet was corrected to scope around this exception.
- Disclosure wording was grounded in `StressContextPayload.swift` (the actual `Codable` struct serialized into the `/chat` request body as `stress_context`), not just the plan's shorthand — raw HRV/HR/sleep/activity/recovery values are confirmed hardcoded `nil` in `StressContextPayload.build()`; what transmits is the stress score, category, confidence, trend, and normalized per-factor scores/weights.

## Task Commits

Each task was committed atomically:

1. **Task 1: Correct the false non-transmission claim in root/architecture docs** - `7fc6153` (docs)
2. **Task 2: Add an AI Coaching Chat disclosure section to the privacy policy (EN + VI)** - `f4bcb9c` (docs)

_Note: this is a docs-only plan; no separate plan-metadata commit was made by this executor since STATE.md/ROADMAP.md updates are owned by the orchestrator for this wave._

## Files Created/Modified
- `CLAUDE.md` - Replaced "No external API calls or servers" with a disclosure of the AI Coaching Chat's derived stress-context transmission and Bearer-JWT session
- `docs/project-overview-pdr.md` - Corrected the Privacy & Security success metric, the Privacy-First Design bullet, and the AI Chat data-flow diagram step
- `docs/system-architecture.md` - Corrected the LLM Service section's `StressContextPayload` description and the Security & Privacy section's chat/health-data claims
- `docs/system-architecture-platform.md` - Same correction as system-architecture.md's Privacy section
- `docs/INDEX.md` - Corrected the Security Measures bullets describing what SupabaseLLMService sends and the "health data never leaves device" claim
- `docs-site/legal/privacy.md` - Added "## AI Coaching Chat" section; corrected "Data We Do Not Collect" bullet; bumped Last updated date to 2026-08-09
- `docs-site/vi/legal/privacy.md` - Added "## Trò Chuyện Cùng AI" section (Vietnamese); corrected the equivalent bullet; bumped Last updated date

## Decisions Made
- Read `StressContextPayload.swift`, `ChatContextBuilder.swift`, and `SupabaseLLMService.swift` directly (per the important_context note) rather than trusting the plan's paraphrase of "HRV, resting heart rate, sleep, activity, recovery" as literal field names — the actual payload sends normalized per-factor *scores* (0-1 + static weight) derived from those five signals, plus the overall stress score/category/confidence/trend. Disclosure text reflects this distinction precisely so it stays accurate against the code, not just against the plan's shorthand.
- Session-linkage described as "Bearer-JWT-authenticated session (anonymous or signed-in via Supabase Auth)" rather than asserting identity-linkage, since `ensureValidSession()` falls back to `signInAnonymously()` when no valid token/refresh-token exists — the JWT proves session continuity across requests, not necessarily a real user identity.
- Also corrected `docs/project-overview-pdr.md`'s AI Chat data-flow diagram line (`ChatContextBuilder (assembles anonymized context only)` → `StressContextPayload (derived stress-context sent as 'stress_context', session-linked via Bearer JWT)`) since it named the wrong component: `ChatContextBuilder` builds an on-device system prompt that `SupabaseLLMService` explicitly ignores (comment: "systemPrompt is ignored — backend builds it from stress_context"); `StressContextPayload` is what's actually serialized and sent. This is a Rule 1 (bug/inaccuracy) fix within the same file already in scope for this task, not new scope.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Inaccuracy] Corrected a wrong-component reference in the AI Chat data-flow diagram**
- **Found during:** Task 1 (docs/project-overview-pdr.md)
- **Issue:** The data-flow diagram at line 241 read `-> ChatContextBuilder (assembles anonymized context only)`, but `ChatContextBuilder.buildSystemPrompt()` builds a system prompt that `SupabaseLLMService.send()` explicitly ignores per its own comment ("The systemPrompt is ignored — backend builds it from stress_context"). The component actually serialized into the request body is `StressContextPayload`.
- **Fix:** Replaced the diagram line to name `StressContextPayload` and describe what it actually sends and how it's authenticated.
- **Files modified:** docs/project-overview-pdr.md
- **Verification:** Read `ChatViewModel.swift` (line 101, 108-117) and `SupabaseLLMService.swift` (lines 140-192) to confirm `StressContextPayload` — not `ChatContextBuilder`'s output — is what reaches the network as `stress_context`.
- **Committed in:** 7fc6153 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 inaccuracy correction, same file/task already in scope)
**Impact on plan:** Necessary for the disclosure to be factually correct against the actual code path; no scope creep — this line was part of the same file the task was already editing to fix the exact class of claim (data-flow accuracy) the task exists to fix.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All 8 files named by D-01 are now internally consistent with `StressContextPayload.swift`'s actual behavior; the "never sent"/"anonymized" claim no longer exists anywhere in scope.
- Phase 5's SHIP-03 (ASC privacy nutrition label) remains explicitly out of this plan's scope, as stated — it consumes this same D-01 resolution but is executed separately in App Store Connect's UI.
- No blockers for other Phase 1 plans; this plan touched only documentation files with zero overlap with 01-01/01-02/01-03.

---
*Phase: 01-build-configuration-widget-wiring*
*Completed: 2026-08-09*
