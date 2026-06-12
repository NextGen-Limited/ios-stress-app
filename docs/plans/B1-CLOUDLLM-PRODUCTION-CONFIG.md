# B1: CloudLLMService — Remove Hardcoded Endpoint & Auth Token

> **Kanban:** B1 (P0 BLOCKER) | **Branch:** fix/b1-cloudllm-hardcoded-endpoint
> **Created:** 2026-06-13 | **Status:** Plan

---

## Problem

`CloudLLMService.swift` and `LLMAPITarget.swift` contain hardcoded values:

| Location | Hardcoded Value | Risk |
|----------|----------------|------|
| `CloudLLMService.swift:56` | `https://hyperpolysyllabically-saronic-mee.ngrok-free.app/v1/chat/completions` | Ngrok URL is temporary, will break |
| `CloudLLMService.swift:64` | `Bearer changeme` | Exposed auth token in source code |
| `LLMAPITarget.swift:17` | `https://hyperpolysyllabically-saronic-mee.ngrok-free.app` | Same ngrok URL |

Additionally:
- Moya + Alamofire are imported only by these two files (dead weight)
- `CloudLLMService.isAvailable()` uses `DispatchSemaphore` on `@MainActor` — potential deadlock
- `CloudLLMService` is **dead code** — `ChatViewModel` already uses `SupabaseLLMService` as of recent commits

---

## Current Architecture (as of main@6893433)

```
ChatViewModel
  └─► SupabaseLLMService (PRIMARY — in use)
        ├─ SupabaseConfig (URL + anonKey from static config)
        ├─ SSEParser (shared)
        └─ StressContextPayload (health context for backend)

  Dead code (not referenced by any view/viewmodel):
  ├─► CloudLLMService (hardcoded ngrok + Bearer changeme)
  │     └─ MoyaProvider<LLMAPITarget>
  └─► LLMAPITarget (hardcoded ngrok baseURL, uses Moya + Alamofire)
```

**Key finding:** `CloudLLMService` is NOT used by `ChatViewModel` or any other production code path. It is only self-referencing. The app has already migrated to `SupabaseLLMService`.

---

## Solution: Delete Dead Code + Remove Unused Dependencies

Since `SupabaseLLMService` is already the production LLM service, the cleanest fix is:

1. **Delete** the dead code files with hardcoded secrets
2. **Remove** Moya/Alamofire dependencies (only used by deleted files)
3. **Verify** `SupabaseConfig` has production values
4. **Update** docs to remove ngrok references

---

## Implementation Tasks

### TASK 1: Delete CloudLLMService.swift [P0]
**File:** `StressMonitor/StressMonitor/Services/LLM/CloudLLMService.swift`
**Action:** DELETE

Contains:
- Hardcoded ngrok URL (line 56)
- Hardcoded `Bearer changeme` (line 64)
- DispatchSemaphore blocking on MainActor (lines 29-40)
- Only import of Moya in service layer (besides LLMAPITarget)

**Verification:** Search entire codebase for `CloudLLMService` — only self-reference exists. No other file imports or instantiates it.

### TASK 2: Delete LLMAPITarget.swift [P0]
**File:** `StressMonitor/StressMonitor/Services/LLM/LLMAPITarget.swift`
**Action:** DELETE

Contains:
- Hardcoded ngrok baseURL (line 17)
- Only import of Alamofire in the project
- Only Moya `TargetType` conformance

**Verification:** `LLMAPITarget` only referenced in `CloudLLMService` (also being deleted).

### TASK 3: Remove Xcode file references [P0]
**File:** `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`
**Action:** MODIFY — remove pbxproj entries for both deleted files

### TASK 4: Remove Moya + Alamofire from SPM [P0]
**File:** `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` (or Package.swift if external)
**Action:** MODIFY — remove Moya, Alamofire package dependencies

**Pre-check:** Search confirms `import Moya` and `import Alamofire` ONLY appear in the two deleted files.

### TASK 5: Verify SupabaseConfig is production-ready [P0]
**File:** `StressMonitor/StressMonitor/Services/LLM/SupabaseConfig.swift`
**Action:** VERIFY — ensure `anonKey` has production value (currently empty string)

- `url` points to `https://fqurrfnfczeozvaxjrcu.supabase.co` (production Supabase project)
- `anonKey` is empty — **needs real anon key before ship** (separate task, not this PR)
- All Edge Function endpoints derived from base URL (correct)

**Note:** The `anonKey` being empty is a known issue. This PR documents it but does NOT commit the key. The key should be injected via CI/CD or build config.

### TASK 6: Update docs referencing ngrok [P1]
**Files to update:**
- `docs/KANBAN-SHIP-READINESS.md` — mark B1 as done
- `docs/system-architecture.md` — remove ngrok references
- `docs/system-architecture-platform.md` — update LLM service description
- `docs/project-overview-pdr.md` — update risk table
- `docs/INDEX.md` — update constraints table
- `docs/project-roadmap.md` — update bug tracking
- `docs/plans/AI-CHAT-COMPLETION-PLAN.md` — update task status
- `docs/deployment-guide-release.md` — remove ngrok tunnel verification step

---

## Files Changed

| File | Action | Size |
|------|--------|------|
| `Services/LLM/CloudLLMService.swift` | DELETE | 117 lines |
| `Services/LLM/LLMAPITarget.swift` | DELETE | 53 lines |
| `project.pbxproj` | MODIFY | remove refs + deps |
| `SupabaseConfig.swift` | VERIFY | no change |
| `docs/KANBAN-SHIP-READINESS.md` | MODIFY | mark B1 done |
| `docs/system-architecture*.md` | MODIFY | remove ngrok refs |
| `docs/project-overview-pdr.md` | MODIFY | update risk table |
| `docs/INDEX.md` | MODIFY | update constraints |
| `docs/project-roadmap.md` | MODIFY | update bug tracking |
| `docs/plans/AI-CHAT-COMPLETION-PLAN.md` | MODIFY | update status |
| `docs/deployment-guide-release.md` | MODIFY | remove ngrok step |

---

## What This PR Does NOT Do (Out of Scope)

- Does NOT fill in `SupabaseConfig.anonKey` (secrets management is separate)
- Does NOT add unit tests (per user request)
- Does NOT fix H4 (Apple Intelligence strategy — separate kanban item)
- Does NOT refactor `SupabaseLLMService` or `ChatViewModel`
- Does NOT modify `AppleIntelligenceService` or `SSEParser`
- Does NOT remove Moya/Alamofire if they're in a Package.swift (needs SPM audit)

---

## Acceptance Criteria

- [ ] No hardcoded ngrok URLs anywhere in `StressMonitor/` source code
- [ ] No `Bearer changeme` anywhere in source code
- [ ] `CloudLLMService.swift` and `LLMAPITarget.swift` deleted
- [ ] Moya/Alamofire imports removed (or files deleted that use them)
- [ ] Xcode project builds successfully without deleted files
- [ ] No dangling references in `project.pbxproj`
- [ ] Docs updated to reflect Supabase-first LLM architecture
- [ ] `grep -r "ngrok" StressMonitor/` returns zero matches in Swift files
- [ ] `grep -r "changeme" StressMonitor/` returns zero matches

---

## Remaining Files in Services/LLM/ After Cleanup

| File | Purpose | Status |
|------|---------|--------|
| `LLMServiceProtocol.swift` | Protocol + error types | KEEP |
| `SupabaseLLMService.swift` | Primary production service | KEEP |
| `SupabaseConfig.swift` | Backend configuration | KEEP (needs anonKey) |
| `StressContextPayload.swift` | Health context for backend | KEEP |
| `SSEParser.swift` | SSE token extraction | KEEP |
| `ChatContextBuilder.swift` | Local system prompt builder | KEEP |
| `ChatQuickActions.swift` | Quick action suggestions | KEEP |
| `AppleIntelligenceService.swift` | On-device iOS 26+ fallback | KEEP |

---

## Execution Order for Implementer

```
Phase 1 — Delete dead code:
  1. Delete CloudLLMService.swift
  2. Delete LLMAPITarget.swift
  3. Remove pbxproj file references
  4. Remove Moya/Alamofire SPM deps (if applicable)

Phase 2 — Verify build:
  5. Build StressMonitor scheme
  6. Fix any compilation errors from missing references

Phase 3 — Update docs:
  7. Update KANBAN-SHIP-READINESS.md (mark B1 complete)
  8. Update architecture docs (remove ngrok references)
  9. Update plan docs (mark tasks done)

Phase 4 — Final verification:
  10. grep -r "ngrok" StressMonitor/ — should be zero in .swift
  11. grep -r "changeme" StressMonitor/ — should be zero
  12. Build succeeds
```
