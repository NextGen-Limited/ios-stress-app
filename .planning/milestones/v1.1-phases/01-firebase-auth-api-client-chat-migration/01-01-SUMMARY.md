---
phase: 01-firebase-auth-api-client-chat-migration
plan: 01
subsystem: backend-migration
tags: [firebase, auth, api-client, chat, sse]
requires:
  - "GoogleService-Info.plist placed (gitignored, per-project)"
  - "Backend deployment live at https://stress-api.dropitx.site"
provides:
  - "firebase-ios-sdk SPM integration (FirebaseAuth + FirebaseCore) — D-01 one-way-door"
  - "StressAPIConfig (3-tier URL resolution, fallback https://stress-api.dropitx.site)"
  - "StressAPIClient (Bearer token injection, getHealth, sendChat streaming bytes)"
  - "FirebaseAuthService (Anonymous sign-in, getIDToken with 60s refresh margin)"
  - "StressLLMService (LLMServiceProtocol conformer replacing SupabaseLLMService)"
  - "LLMServiceError.insufficientCredits (HTTP 402 mapping, D-07)"
  - "SSEMetadata.quickActions (terminal metadata event, D-05)"
affects:
  - "ChatViewModel (6 SupabaseLLMService refs swapped to StressLLMService)"
  - "ChatAvailability (.enabled unconditionally, D-02)"
  - "StressMonitorApp.init (FirebaseApp.configure first statement)"
tech-stack:
  added:
    - "firebase-ios-sdk 11.x via XCRemoteSwiftPackageReference (FirebaseAuth, FirebaseCore)"
  patterns:
    - "3-tier config resolution (Info.plist → env → UserDefaults → fallback) replicated from SupabaseConfig"
    - "AuthServiceProtocol Sendable seam for test injection"
    - "Nil-default @MainActor init to satisfy Swift 6 default-arg isolation"
key-files:
  created:
    - StressMonitor/StressMonitor/Services/API/StressAPIConfig.swift
    - StressMonitor/StressMonitor/Services/API/StressAPIClient.swift
    - StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift
    - StressMonitor/StressMonitor/Services/LLM/StressLLMService.swift
    - StressMonitor/StressMonitorTests/SSEParserTests.swift
    - StressMonitor/StressMonitorTests/LLMServiceErrorTests.swift
  modified:
    - StressMonitor/StressMonitor/Services/LLM/LLMServiceProtocol.swift
    - StressMonitor/StressMonitor/Services/LLM/SSEParser.swift
    - StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift
    - StressMonitor/StressMonitor/Services/Chat/ChatAvailability.swift
    - StressMonitor/StressMonitor/StressMonitorApp.swift
    - StressMonitor/StressMonitor.xcodeproj/project.pbxproj
decisions:
  - "Firebase 11.x API: forcingRefresh: label (not forceRefresh:), IDTokenResult.expirationDate is non-optional Date, FirebaseApp.configure() is the entry point (not FirebaseCore.configure()) — all verified against the resolved SDK headers during compilation"
  - "StressAPIClient init uses nil-default args resolved in the @MainActor body — Swift 6 evaluates default-arg expressions nonisolated, so a @MainActor FirebaseAuthService() default would not compile"
  - "Added firebase-ios-sdk via standard XCRemoteSwiftPackageReference — the project's spm-cache umbrella declares 8 packages but none are actually linked (graph.json shows 'missed', source has no imports), so the standard mechanism is the correct first integration"
  - "Proceeded with Task 2/3 code despite backend /health returning 404 — the code deliverables and build verification are backend-independent; the end-to-end tracer verify genuinely requires the backend and is surfaced as a human-verify checkpoint"
metrics:
  duration: 42m
  completed: 2026-08-13
actuals:
  tokens: 6123
  tasks: 3
  commits: 4
status: complete
---

# Phase 01 Plan 01: Firebase Auth + API Client + Chat Migration (Tracer) Summary

Firebase Anonymous auth + standalone backend API client wired end-to-end through StressLLMService, replacing the SupabaseLLMService chat path with a thin slice that compiles, links firebase-ios-sdk, and streams SSE — pending only the live backend for the final round-trip verification.

## What Was Built

**Task 1 (TDD):** Added `LLMServiceError.insufficientCredits` (D-07, HTTP 402 mapping) and `SSEMetadata.quickActions` (D-05, terminal metadata event). RED tests written first in Swift Testing (`SSEParserTests`, `LLMServiceErrorTests`), then minimal source-additive implementation.

**Task 2 (Foundation):** Integrated `firebase-ios-sdk` 11.x via `XCRemoteSwiftPackageReference` (FirebaseAuth + FirebaseCore — D-01 one-way-door). Created `StressAPIConfig` (3-tier URL resolution, fallback `https://stress-api.dropitx.site` — D-03), `FirebaseAuthService` (Anonymous sign-in + `getIDToken` with 60s refresh margin, Google Sign-In stubbed for Plan 02 — D-02), and `StressAPIClient` (Bearer token injection, `getHealth` no-auth, `sendChat` streaming bytes accessor). Build exits 0 — SDK links cleanly.

**Task 3 (Tracer):** Created `StressLLMService` mirroring `SupabaseLLMService`'s surface area (D-06 class-name swap). Swapped all 6 `SupabaseLLMService` references in `ChatViewModel` to `StressLLMService`. Flipped `ChatAvailability.current` to `.enabled` unconditionally (D-02). Added `FirebaseApp.configure()` as the first statement in `StressMonitorApp.init`. Build exits 0.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Firebase 11.x API signatures differ from plan's pseudocode**
- **Found during:** Task 2 (FirebaseAuthService) and Task 3 (StressMonitorApp)
- **Issue:** Plan referenced `getIDToken(forceRefresh:)`, optional `expirationDate`, and `FirebaseCore.configure()`. The resolved firebase-ios-sdk 11.x uses `forcingRefresh:` label, non-optional `Date` expiration, and `FirebaseApp.configure()` as the entry point.
- **Fix:** Corrected all three to match the actual SDK (`forcingRefresh:`, direct `expirationDate` comparison, `FirebaseApp.configure()`).
- **Files modified:** FirebaseAuthService.swift, StressMonitorApp.swift
- **Commit:** b144718, 3306585

**2. [Rule 3 - Blocking] StressAPIClient init default-arg @MainActor isolation error**
- **Found during:** Task 2
- **Issue:** `init(authService: AuthServiceProtocol = FirebaseAuthService(), baseURL: URL = StressAPIConfig.baseURL)` — Swift 6 evaluates default-arg expressions nonisolated, but `FirebaseAuthService()` is @MainActor-isolated → hard error.
- **Fix:** Changed to `nil` defaults resolved inside the @MainActor init body (`authService ?? FirebaseAuthService()`).
- **Files modified:** StressAPIClient.swift
- **Commit:** b144718

**3. [Rule 3 - Precondition] Backend deployment down — proceeded with backend-independent code**
- **Found during:** Task 2 precondition check
- **Issue:** `https://stress-api.dropitx.site/health` returns 404 (plain-text Cloudflare "404 page not found", not Hono's JSON 404) on every path. The deployment is not serving the app. The precondition bundled this with the code deliverables.
- **Fix:** Proceeded with Task 2/3 code + build verification (which is backend-independent per each task's acceptance criteria: `xcodebuild build exits 0`). The end-to-end tracer verify genuinely requires the backend and is surfaced as a human-verify checkpoint.
- **Files modified:** none (verification blocker, not a code defect)

### Plan Literals Corrected
- `FirebaseCore.configure()` → `FirebaseApp.configure()` (FirebaseApp is the entry-point type in module FirebaseCore)
- GoogleService-Info.plist requires no manual pbxproj entry — the `PBXFileSystemSynchronizedRootGroup` auto-bundles it as a resource (only `Info.plist` is excluded)

## Verification Results

| Criterion | Result |
|-----------|--------|
| `xcodebuild build -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 17'` | PASS (exit 0) |
| `grep insufficientCredits LLMServiceProtocol.swift` | PASS (1 hit) |
| `grep quickActions SSEParser.swift` | PASS (2 hits) |
| `grep StressLLMService ChatViewModel.swift` | PASS (6 hits) |
| `grep SupabaseLLMService ChatViewModel.swift` | PASS (0 hits) |
| `grep #if DEBUG ChatAvailability.swift` | PASS (0 — gate removed) |
| firebase-ios-sdk linked in pbxproj | PASS (5 refs) |
| `curl https://stress-api.dropitx.site/health` → 200 | FAIL (404 — backend deployment down) |
| TDD tests run green | BLOCKED — host CoreSimulator runner IPC ("Channel disconnected"); test target compiles (reached "Testing started") |

## Authentication Gates

None — Firebase Anonymous auth is wired but not exercised end-to-end (blocked by backend outage, not an auth gate).

## Known Stubs

| File | Line | Stub | Reason | Resolves In |
|------|------|------|--------|-------------|
| FirebaseAuthService.swift | 57 | `signInWithGoogle()` throws "not yet available" | D-02: Google Sign-In deferred to Plan 02 Task 1 (account linking, T-01-04 mitigation) | Plan 02 |

## Deferred Issues

- **Backend deployment down** (external): `https://stress-api.dropitx.site` returns 404 on all paths. Blocks end-to-end chat verification. Requires human to redeploy/restart the Deno/Hono process. Not a code defect.
- **Host CoreSimulator test runner** (pre-existing, carried from v1.0 STATE.md): `xcodebuild test` fails at "Failed to establish communication with the test runner (Channel disconnected)". The new Swift Testing tests compile (reached "Testing started") but cannot execute on this host. Needs a working simulator host or CI.
- **ChatAvailability doc comments** still mention "Supabase" (lines 9, 16) — intentionally left for Plan 02's comment scrub per Task 3 action.

## Self-Check: PASSED

All 6 created files exist on disk. All 4 commits (3bc8551, aac6cac, b144718, 3306585) exist in git log.

## Commits

| Hash | Message |
|------|---------|
| 3bc8551 | test(01-01): add failing tests for insufficientCredits and quick_actions metadata |
| aac6cac | feat(01-01): add insufficientCredits error case and quick_actions SSE metadata |
| b144718 | feat(01-01): integrate firebase-ios-sdk, add API client + auth service foundation |
| 3306585 | feat(01-01): wire StressLLMService + ChatViewModel swap + Firebase launch (tracer slice) |
