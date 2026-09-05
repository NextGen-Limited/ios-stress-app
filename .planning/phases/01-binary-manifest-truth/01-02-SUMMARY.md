---
phase: 01-binary-manifest-truth
plan: 02
subsystem: infra
tags: [privacy-manifest, xcprivacy, required-reason-api, CA92.1, UserDefaults, BUILD-01, docs, firebase-auth, privacy-policy]

# Dependency graph
requires:
  - phase: 01-binary-manifest-truth (plan 01)
    provides: archive-from-tree provenance + verify-archive gate that re-runs SDK-manifest checks on the phase-final archive
provides:
  - Watch target PrivacyInfo.xcprivacy declares the full scan-backed UserDefaults reason set (CA92.1 + 1C8F.1) — BUILD-01's manifest-content half closed
  - D3 doc corrections — root CLAUDE.md and EN/VI privacy policies now describe the real architecture (StressAPIClient → https://stress-api.dropitx.site, Firebase Auth, derived-scores-only payload) with zero payload/code churn
affects: [01-binary-manifest-truth plan 04 (archive re-verification), 01-binary-manifest-truth plan 05 (ASC upload), Phase 4 SHIP-03 privacy answers, docs-site]

# Actuals (#2632) — pairs with the plan's `estimate` to calibrate future estimates.
actuals:
  tokens: 1793
  tasks: 2
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Scan-then-declare: required-reason manifest declarations generated from a fresh grep of APIs actually used ( UserDefaults.standard → CA92.1, suite → 1C8F.1 ), re-run at execution time rather than copied from research"
    - "EN/VI privacy-policy lockstep editing: both mirrors edited in the same section in the same commit"

key-files:
  created: []
  modified:
    - StressMonitor/StressMonitorWatch Watch App/PrivacyInfo.xcprivacy
    - CLAUDE.md
    - docs-site/legal/privacy.md
    - docs-site/vi/legal/privacy.md

key-decisions:
  - "Watch UserDefaults reason set = CA92.1 + 1C8F.1, backed by a fresh usage scan (4 .standard files + 3 suite files, zero delta vs research §5.3); no other required-reason category is used by any target"
  - "EN/VI policy: dropped the stale trailing clause 'not an anonymous one' alongside the Supabase→Firebase correction — it contradicted the (corrected) anonymous-sign-in mode; 'authenticated session (a Bearer JWT)' already carries the meaning"
  - "CLAUDE.md no-tracking line now cites manifest alignment explicitly (NSPrivacyTracking false; DeviceID/ProductInteraction collected-data entries exist solely because of the Google/Firebase auth SDKs)"

patterns-established:
  - "Scan-then-declare for privacy manifests: the declaration is regenerated from a current-usage grep at execution time, never copied blind from research"
  - "EN/VI policy mirrors are edited in lockstep — same section, same commit — so the two files never drift"

requirements-completed: [BUILD-01]

# Coverage metadata (#1602)
coverage:
  - id: D1
    description: "Watch privacy manifest declares both UserDefaults reason codes (CA92.1 + 1C8F.1), all three target manifests lint clean, app/widget manifests untouched"
    requirement: BUILD-01
    verification:
      - kind: other
        ref: 'plutil -lint on all three PrivacyInfo.xcprivacy → OK ×3; plutil -extract NSPrivacyAccessedAPITypes.0.NSPrivacyAccessedAPITypeReasons json → ["CA92.1","1C8F.1"]'
        status: pass
      - kind: other
        ref: 'git diff a0cd0dd~1 HEAD -- app/widget manifests → empty; grep -c CA92.1 watch manifest → 1'
        status: pass
    human_judgment: false
  - id: D2
    description: "CLAUDE.md carries the real backend contract (StressLLMService via StressAPIClient → chat endpoint on https://stress-api.dropitx.site, Firebase Auth) with zero Supabase-era references"
    requirement: BUILD-01
    verification:
      - kind: other
        ref: 'grep -c "SupabaseLLMService" CLAUDE.md → 0; grep -in supabase CLAUDE.md → 0 lines; grep stress-api.dropitx.site → lines 215/481/494; grep -c "Firebase Auth" → 2'
        status: pass
    human_judgment: false
  - id: D3
    description: "EN/VI privacy policies corrected in lockstep (Bearer session provider Supabase Auth → Firebase Auth: anonymous sign-in or Google Sign-In)"
    verification:
      - kind: other
        ref: 'grep -in supabase docs-site/legal/privacy.md docs-site/vi/legal/privacy.md → 0 lines; both edited at line 30 (same section)'
        status: pass
    human_judgment: true
    rationale: "Structural mirroring and provider claims are grep-verified, but the naturalness of the Vietnamese phrasing and EN↔VI semantic parity beyond structure require a human read before public policy publication"

# Metrics
duration: 8min
completed: 2026-09-03
status: complete
---

# Phase 1 Plan 2: Binary & Manifest Truth — Watch CA92.1 + D3 Doc Corrections Summary

**Watch privacy manifest closed its one under-declaration gap (CA92.1 added next to 1C8F.1, scan-backed), and CLAUDE.md + EN/VI privacy policies were corrected from Supabase-era claims to the real Firebase/stress-api.dropitx.site architecture with zero Swift churn**

## Performance

- **Duration:** 8 min
- **Started:** 2026-09-03T08:18:56Z
- **Completed:** 2026-09-03T08:27:10Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Watch target `PrivacyInfo.xcprivacy` now declares `CA92.1` + `1C8F.1` for UserDefaults — closing the ITMS-91053-class under-declaration risk (Apple rejects under-declaration, tolerates over-declaration)
- Root `CLAUDE.md` purged of all 4 Supabase-era references (3× `SupabaseLLMService`, 1× `/chat` Supabase Edge Function claim); AI Chat now documented as `StressLLMService` via `StressAPIClient` → chat endpoint on `https://stress-api.dropitx.site` under Firebase Auth (anonymous sign-in or Google Sign-In)
- EN + VI privacy policies corrected in lockstep (both line 30): Bearer session provider changed from Supabase Auth to Firebase Auth
- D3 invariant proven: the plan's commits touch zero `.swift` files — `StressContextPayload.swift` and its tests are byte-identical (docs moved toward code, never the reverse)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add CA92.1 to the watch privacy manifest, backed by a fresh usage scan** - `a0cd0dd` (fix)
2. **Task 2: D3 doc corrections — CLAUDE.md and EN/VI privacy policies move to the code's truth** - `4b9e4ae` (fix)

**Plan metadata:** (docs commit follows this SUMMARY)

## Scan Evidence (Task 1 acceptance)

Fresh usage scan re-run at execution time — matches research §5.3 exactly (zero delta):

| Category | Target | Files | Call sites |
|----------|--------|-------|-----------|
| UserDefaults.standard | watch | `ViewModels/WatchMoodViewModel.swift`, `ViewModels/WatchHabitViewModel.swift`, `Models/TierNamePreferences.swift`, `Services/CloudKit/WatchCloudKitManager.swift` | lines 68,82 / 55,76 / 51 / 38,44 |
| UserDefaults(suiteName:) | watch | `Complications/Services/ComplicationDataProvider.swift:25`, `Models/WatchFacePreferences.swift:18`, `Services/WatchSharedDataStore.swift:21` | already covered by 1C8F.1 |
| SystemBootTime | all 3 | none | correctly undeclared |
| DiskSpace | all 3 | none | correctly undeclared |
| ActiveKeyboard | all 3 | none | correctly undeclared |
| FileTimestamp | app only | `Views/Settings/DataManagement/DataExportView.swift:393,398` | already declared C617.1 |

## Files Created/Modified

- `StressMonitor/StressMonitorWatch Watch App/PrivacyInfo.xcprivacy` - one inserted line (`<string>CA92.1</string>` before `1C8F.1`, app-target ordering, tab indentation preserved)
- `CLAUDE.md` - 4 edit sites: Tech Stack bullet (line 215), directory tree (line 321), Key Technical Decisions table (line 481), Privacy & Security section (lines 493-494)
- `docs-site/legal/privacy.md` - AI Coaching Chat section (line 30): Supabase Auth → Firebase Auth
- `docs-site/vi/legal/privacy.md` - Trò Chuyện Cùng AI section (line 30): same correction in Vietnamese (mirror)

## Decisions Made

- **Scan-then-declare confirmed the research's reason set with zero delta** — declaration generated from the live grep, not copied blindly
- **Dropped the self-contradictory "not an anonymous one" clause** in both policies (see Deviations #1)
- **Kept CLAUDE.md's "On-device privacy when available" rationale cell and all non-Supabase table rows unchanged** — minimal-churn discipline; stale-but-out-of-scope rows logged to deferred-items.md instead of fixed
- **CLAUDE.md staged via HEAD+edits blob** (git hash-object + update-index --cacheinfo) so the pre-existing unrelated GitNexus-section WIP in the working tree stayed uncommitted — task commits contain only this plan's changes

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Doc bug] Removed self-contradictory trailing clause in EN/VI policies**
- **Found during:** Task 2 (privacy policy corrections)
- **Issue:** The sentence said "(a Bearer JWT, established via Supabase Auth — anonymous or signed-in), not an anonymous one" — after correcting the provider to Firebase Auth (whose default mode IS anonymous sign-in), the trailing "not an anonymous one" clause contradicts the parenthetical in both languages
- **Fix:** Dropped the clause; "authenticated session (a Bearer JWT)" already conveys that every request is authenticated
- **Files modified:** docs-site/legal/privacy.md, docs-site/vi/legal/privacy.md (both line 30, lockstep)
- **Verification:** grep shows no "not an anonymous one" / "không phải một yêu cầu ẩn danh" remnants; EN/VI remain paragraph-for-paragraph mirrors
- **Committed in:** 4b9e4ae

---

**Total deviations:** 1 auto-fixed (1 doc bug)
**Impact on plan:** None on scope — the clause removal was required for the corrected sentence to be internally consistent (docs-to-code direction per D3).

## Issues Encountered

- `plutil -extract … raw` on an array prints the element count (`2`), not the values — a plutil quirk that made the plan's literal verify command grep for CA92.1 against a count. Resolved by using `json` format (`plutil -extract … json` → `["CA92.1","1C8F.1"]`), which proves the criterion's intent. No code or plan artifact changed.
- Pre-existing unrelated WIP was present in the working tree before execution (CLAUDE.md GitNexus section refresh, AGENTS.md, .planning/config.json, .planning/codebase/*, .planning/WINDOWS.md). Task commits exclude all of it via per-file/blob staging; it remains uncommitted in the working tree, untouched.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- BUILD-01's manifest-content half is now true: every required-reason API the targets actually use is declared (watch gap closed), all three manifests lint clean
- D3's doc corrections are complete: every §5.6 overshoot fixed, EN/VI in lockstep, code untouched
- Plan 04 re-runs the SDK-manifest checks on the phase-final archive; ASC-upload acceptance lands in plan 05
- Shared-ID note: BUILD-01 is also declared by plans 01-03 and 01-05 (no SUMMARYs yet) — the REQUIREMENTS.md checkbox intentionally stays pending until they finish (#2388 gate)
- Deferred (out of scope, logged to deferred-items.md): CLAUDE.md "Dependencies | None (system only)" table row is stale (firebase-ios-sdk + GoogleSignIn are SPM deps); "iOS 17+" persistence-row claim is stale (18.6/26.1)

## Self-Check: PASSED

- Files: watch manifest / CLAUDE.md / EN privacy / VI privacy — all modified as committed (FOUND via git show + working tree)
- Commits: a0cd0dd, 4b9e4ae FOUND in git log
- Task 1 acceptance: plutil OK ×3, reasons extract = ["CA92.1","1C8F.1"], scan recorded above, app/widget manifests byte-identical, 0 watch .swift changed
- Task 2 acceptance: SupabaseLLMService count 0, supabase grep 0 lines across all three docs, endpoint + Firebase Auth present, EN/VI mirrors edited in same section, 0 .swift in task diff, 0 .vitepress paths
- Plan-level: 0 .swift churn across both commits; StressContextPayload.swift byte-identical; commit author = user identity, no AI attribution lines
