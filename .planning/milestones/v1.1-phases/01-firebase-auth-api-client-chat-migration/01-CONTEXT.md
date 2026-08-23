# Phase 1 Context: Firebase Auth + API Client + Chat Migration

## Phase Goal

Migrate the iOS app's backend integration from Supabase (1 endpoint, Supabase JWT auth) to the standalone Deno/Hono backend at `https://stress-api.dropitx.site` (11 endpoints, Firebase auth). This phase delivers the foundational layer: Firebase Authentication, the API client, and chat migration. It unblocks Phase 2 (Credits + IAP) and Phase 3 (Sessions + Preferences + Quick Actions).

## Locked Decisions

### D-01: Firebase SDK for Authentication
**Decision:** Add `firebase-ios-sdk` (FirebaseAuth + FirebaseCore) via SPM. Implement both Anonymous and Google Sign-In auth flows.
**Why:** The backend verifies Firebase ID tokens using Firebase Admin SDK with Google's public certs. No alternative auth mechanism exists. This is a one-way-door dependency addition.
**Impact:** Breaks the project's "no third-party dependencies" principle. Justified by the backend's hard requirement.

### D-02: Auth Flow — Anonymous first, Google Sign-In supported
**Decision:** Implement Firebase Anonymous auth as the default (auto-sign-in on launch). Add Google Sign-In as an upgrade path (user can link anonymous account to Google account).
**Why:** Anonymous auth is frictionless (no UI required) and the backend auto-provisions users on first authed request. Google Sign-In enables account persistence across devices.
**Scope:** Both flows in Phase 1.

### D-03: API Base URL Configuration
**Decision:** `STRESS_API_BASE_URL` Info.plist key with fallback to `https://stress-api.dropitx.site`. Same 3-tier config resolution as existing `SupabaseConfig` pattern (Info.plist → env → hardcoded fallback).
**Why:** Matches existing config pattern. Allows point-in-time testing against staging URLs.

### D-04: Remove Supabase Dependencies in Phase 1
**Decision:** Remove `SupabaseConfig`, `SupabaseSecrets`, `SupabaseAuthService`, `SupabaseLLMService` in this phase. Replace entirely with Firebase auth + new API client.
**Why:** Clean migration — no value in keeping dead Supabase code. The backend was explicitly "rewritten from Supabase" and the iOS contract is preserved.

### D-05: SSE Terminal Metadata Event
**Decision:** Update `SSEParser` to handle the non-standard terminal `data:{type:metadata, session_id, credits_remaining, model_used, quick_actions}` event before `data:[DONE]`.
**Why:** Backend emits this after each chat completion. iOS must parse `credits_remaining` (for Phase 2 credits UI) and `session_id` (for Phase 3 session history). Field names are the contract — renames break silently.

### D-06: LLMServiceProtocol Preserved
**Decision:** Keep `LLMServiceProtocol` unchanged. The new `StressLLMService` (replacing `SupabaseLLMService`) conforms to the same protocol. Same `send(messages:systemPrompt:)` → `AsyncThrowingStream<String, Error>` contract.
**Why:** Backend CLAUDE.md states "The iOS contract is preserved." `ChatViewModel` and `ChatBottomSheetView` should not need changes for the chat migration.

### D-07: HTTP 402 Handling
**Decision:** Map HTTP 402 `INSUFFICIENT_CREDITS` to a new `LLMServiceError.insufficientCredits` case. In Phase 1, surface as an error message. Phase 2 will add the paywall flow.
**Why:** The backend returns 402 before streaming starts when credits are exhausted. Phase 1 must handle it gracefully even though the full credits UI comes later.

## Scope Fences

### In Scope
- Firebase SDK integration (SPM package, `GoogleService-Info.plist`, auth flow)
- `StressAPIClient` — centralized HTTP client with Bearer token injection
- `StressLLMService` — new `LLMServiceProtocol` implementation hitting `/chat`
- `SSEParser` update for terminal metadata event
- Config migration (remove Supabase keys, add `STRESS_API_BASE_URL` + Firebase config)
- Remove all Supabase remnants (`SupabaseConfig`, `SupabaseSecrets`, `SupabaseAuthService`, `SupabaseLLMService`)
- `GET /health` integration (for `isAvailable()` check)
- HTTP 402 error handling (error case, no paywall UI)

### Out of Scope (Deferred to Phase 2/3)
- Credits system UI and balance display (Phase 2)
- StoreKit transition from subscription to consumable (Phase 2)
- Paywall flow for depleted credits (Phase 2)
- `/sessions` server-side chat history (Phase 3)
- `/preferences` sync (Phase 3)
- `/quick-actions` integration (Phase 3)

## API Contract Reference

**Base URL:** `https://stress-api.dropitx.site`
**Auth:** `Authorization: Bearer <firebase-id-token>` on every endpoint except `/health`
**OpenAPI Spec:** `https://stress-api.dropitx.site/openapi.json` (publicly accessible)

### Endpoints Used in Phase 1

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | Liveness probe (public, no auth) — used for `isAvailable()` |
| POST | `/chat` | SSE streaming chat — the core migration target |

### `/chat` Request Shape
```json
{
  "messages": [{"role": "user", "content": "..."}],
  "session_id": "uuid-optional",
  "stress_context": { ... }
}
```

### `/chat` SSE Response
- `data:{choices:[{delta:{content:"token"}}]}` — streaming tokens
- `data:{type:"metadata", session_id, credits_remaining, model_used, quick_actions}` — terminal event
- `data:[DONE]` — stream end
- `data:{error:"message"}` — mid-stream error
- HTTP 402 `{error, code:"INSUFFICIENT_CREDITS"}` — before streaming starts

## Existing iOS Code to Reference

| File | Role |
|---|---|
| `Services/LLM/LLMServiceProtocol.swift` | Protocol contract (UNCHANGED) |
| `Services/LLM/SupabaseLLMService.swift` | Current impl being REPLACED |
| `Services/LLM/SupabaseConfig.swift` | Config pattern to REPLICATE for `StressAPIConfig` |
| `Services/LLM/SupabaseAuthService.swift` | Auth pattern being REPLACED by Firebase |
| `Services/LLM/SupabaseSecrets.swift` | Gitignored secrets file being REMOVED |
| `Services/LLM/ChatContextBuilder.swift` | Builds `stress_context` payload (UNCHANGED) |
| `ViewModels/ChatViewModel.swift` | Consumes `LLMServiceProtocol` (UNCHANGED) |
| `Views/Chat/ChatBottomSheetView.swift` | Chat UI (UNCHANGED for migration) |

## Backend Reference

- **Repo:** `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/`
- **CLAUDE.md:** Comprehensive backend architecture, API patterns, credit system, iOS integration context
- **docs/ios-integration-analysis.md:** Maps all iOS integration points (from pre-Supabase era, but integration points are the same)
- **src/routes/chat.ts:** Exact `/chat` request/response flow
- **src/middleware/auth.ts:** Firebase token verification + lazy user provisioning
- **Deployed URL:** `https://stress-api.dropitx.site`
