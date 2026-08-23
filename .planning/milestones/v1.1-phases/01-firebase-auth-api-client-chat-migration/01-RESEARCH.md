# Phase 1 Research: Firebase Auth + API Client + Chat Migration

## 1. Current iOS Architecture (Source State)

### Auth Layer (Being Replaced)
- `SupabaseAuthService.swift` — implements `SupabaseAuthServiceProtocol: Sendable` with `signInAnonymously()`, `getSession()`, `signOut()`
- `SupabaseConfig.swift` — 3-tier config: Info.plist key → env var → hardcoded fallback. Resolves `SUPABASE_URL` and `SUPABASE_ANON_KEY`
- `SupabaseSecrets.swift` — gitignored, holds local dev guest JWT fallback (`SUPABASE_GUEST_JWT`)
- Auth flow: guest JWT from env/secrets → `Authorization: Bearer <supabase-jwt>` header on `/chat`

### LLM/Chat Layer (Being Replaced)
- `LLMServiceProtocol.swift` — `isAvailable() -> Bool` + `send(messages:systemPrompt:) -> AsyncThrowingStream<String, Error>`
- `SupabaseLLMService.swift` — current implementation. Constructs `URLRequest(url: SupabaseConfig.chatURL)`, sets Bearer header, streams via `URLSession.shared.bytes(for:)`, parses with `SSEParser`
- `SSEParser` — parses `data:` SSE lines into token strings. Currently does NOT handle `{type:metadata}` events
- `ChatContextBuilder.swift` — builds system prompt from stress data. The `stress_context` payload shape is preserved by the new backend
- `LLMServiceError` — cases: `unavailable`, `exceededContext`, `guardrailViolation`, `rateLimited`, `refused`, `concurrentRequests`, `decodingFailure`, `cancelled`, `unknown`

### Config Resolution Pattern
```
Info.plist build setting → ProcessInfo.processInfo.environment → hardcoded fallback
```
Implemented via `ConfigResolver` struct with `infoPlistKey`, `environmentKey`, `fallback` fields.

### Chat Request Flow (Current)
1. `ChatViewModel` calls `llmService.send(messages:systemPrompt:)`
2. `SupabaseLLMService` constructs request to `{SUPABASE_URL}/functions/v1/chat`
3. Headers: `Authorization: Bearer <jwt>`, `Content-Type: application/json`
4. Body: `{"messages": [...], "systemPrompt": "..."}`
5. Streams SSE via `URLSession.shared.bytes(for:)`
6. `SSEParser.parse(line:)` extracts content tokens from `data:{choices:[{delta:{content}}]}`

### Files to Remove
- `Services/LLM/SupabaseLLMService.swift`
- `Services/LLM/SupabaseConfig.swift`
- `Services/LLM/SupabaseAuthService.swift`
- `Services/LLM/SupabaseSecrets.swift`

### Files to Modify
- `Services/LLM/SSEParser.swift` — add terminal metadata event handling
- `Services/LLM/LLMServiceProtocol.swift` — add `insufficientCredits` error case
- `StressMonitorApp.swift` — update DI wiring (Firebase init, new service injection)
- `project.pbxproj` — add firebase-ios-sdk SPM package, GoogleService-Info.plist
- `Info.plist` / build settings — remove `SUPABASE_*` keys, add `STRESS_API_BASE_URL`
- `.gitignore` — remove `SupabaseSecrets.swift` entry

### Files to Create
- `Services/API/StressAPIConfig.swift` — config for API base URL
- `Services/API/StressAPIClient.swift` — centralized HTTP client
- `Services/Auth/FirebaseAuthService.swift` — Firebase auth implementation
- `Services/LLM/StressLLMService.swift` — new `LLMServiceProtocol` impl

## 2. Target Backend Architecture (Destination State)

### Backend Stack
- Deno 2 + Hono 4, deployed as Docker container on Dokploy (Traefik + Cloudflare Tunnel)
- PostgreSQL 17 (self-hosted, private network, NO RLS — all queries scope by `WHERE user_id = $1`)
- Firebase Admin SDK verifies ID tokens (credential-less, using Google's public certs)
- OpenRouter API for LLM completions (free models with fallback chain)
- SSE streaming to iOS client

### Auth Contract
- Every endpoint except `/health` requires `Authorization: Bearer <firebase-id-token>`
- Token verification via `firebase-admin verifyIdToken` — validates Google + Anonymous tokens
- Lazy user provisioning: `provisionUser()` upserts `users` + `user_preferences` + 50-credit `user_credits` on first authed request (`ON CONFLICT DO NOTHING`)
- Invalid/missing token → 401 `AuthError`

### `/chat` Endpoint Flow (Critical Path)
```
POST /chat
Authorization: Bearer <firebase-id-token>
Content-Type: application/json

{
  "messages": [{"role": "user", "content": "..."}],
  "session_id": "uuid-optional",
  "stress_context": { ... }
}
```

Backend flow:
1. Empty messages → 400
2. `getBalance(uid)` → check credits
3. remaining ≤ 0 AND non-premium → **402 `INSUFFICIENT_CREDITS`**
4. Get/create session (if `session_id` provided, use it; else create new)
5. Save user message to `chat_messages`
6. `streamChatCompletion` → SSE chunks: `data:{choices:[{delta:{content}}]}`
7. Save assistant message (`tokens_used = content.length`)
8. `deductCredit` (1 credit per message)
9. Terminal: `data:{type:metadata, session_id, credits_remaining, model_used, quick_actions}`
10. `data:[DONE]`

Mid-stream errors: `data:{error:"message"}` event before close.

### SSE Parsing Requirements
The terminal metadata event is **non-standard** (no schema version). iOS must:
1. Parse `data:{choices:[{delta:{content}}]}` → extract content tokens (existing behavior)
2. Parse `data:{type:metadata,...}` → extract `credits_remaining`, `session_id`, `model_used`, `quick_actions`
3. Parse `data:{error:"..."}` → surface as error
4. Parse `data:[DONE]` → end stream

**Warning from backend CLAUDE.md:** "Field renames break the client silently."

### CORS
- `hono/cors`, origin `*`, allowed headers: `authorization, x-client-info, api-key, content-type`

## 3. Firebase iOS SDK Integration

### Required Packages
- `firebase-ios-sdk` via SPM — minimally `FirebaseAuth` and `FirebaseCore`
- `GoogleSignIn` framework (for Google Sign-In flow)

### Configuration
- `GoogleService-Info.plist` — Firebase project config (plist, not code). Added to app target.
- Firebase project ID: `stress-io` (from backend `.env.example`: `FIREBASE_PROJECT_ID`)
- Anonymous auth must be enabled in Firebase Console
- Google Sign-In must be enabled with iOS app's reversed client ID as URL scheme

### Auth Flow Design
1. **App launch:** `FirebaseAuth.configure()` in `StressMonitorApp.init`
2. **Anonymous sign-in:** If no current user, `Auth.auth().signInAnonymously()` → get ID token
3. **Token refresh:** `user.getIDToken()` — tokens expire in 1 hour. `getIDTokenResult()` forces refresh if needed.
4. **Google Sign-In (optional upgrade):** `GIDSignIn` flow → credential → `auth.signIn(with: credential)` links anonymous account
5. **Token access:** `Auth.auth().currentUser?.getIDToken()` → pass to `StressAPIClient` as Bearer token

### Thread Safety
- FirebaseAuth is `@MainActor`-safe. Auth state listener runs on main thread.
- Token retrieval (`getIDToken()`) is async — the API client must call it before each request or cache with expiry.

## 4. StressAPIClient Design

### Architecture
```swift
@MainActor
final class StressAPIClient {
    private let baseURL: URL
    private let authService: FirebaseAuthService

    func authorizedRequest(path: String, method: HTTPMethod, body: Data? = nil) async throws -> URLRequest {
        let token = try await authService.getIDToken()
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return request
    }
}
```

### Error Mapping
| HTTP Status | Meaning | Swift Error |
|---|---|---|
| 200 | Success | — |
| 400 | Bad request | `LLMServiceError.unavailable(reason:)` |
| 401 | Auth expired/invalid | Trigger re-auth |
| 402 | Insufficient credits | `LLMServiceError.insufficientCredits` (NEW) |
| 404 | Not found | `LLMServiceError.unavailable(reason:)` |
| 500 | Server error | `LLMServiceError.unavailable(reason:)` |

## 5. Risk Analysis

### High Risk
1. **Firebase SDK bundle size** — `firebase-ios-sdk` is large (~20MB+). Verify it doesn't bloat the app binary unacceptably.
2. **Token lifecycle** — Firebase ID tokens expire in 1 hour. The API client must refresh tokens transparently. If token refresh fails mid-chat, the stream breaks.
3. **GoogleService-Info.plist in version control** — contains API keys. Must be committed (it's not secret per Firebase design) but verify the privacy manifest reflects it.

### Medium Risk
4. **SSEParser backward compatibility** — if the parser changes break the existing `exyte/Chat` library's streaming expectations, the Chat UI could break.
5. **Anonymous auth persistence** — Firebase anonymous accounts are device-local. If the user clears app data, the anonymous account (and its credits) is lost. Phase 2's Google Sign-In upgrade mitigates this.
6. **Existing `ChatViewModel` coupling** — if it references `SupabaseLLMService` directly (not via protocol), it needs rewiring.

### Low Risk
7. **Config migration** — straightforward 3-tier resolution, well-established pattern.
8. **Supabase removal** — clean deletion, no migration path needed (data is ephemeral).

## 6. Validation Architecture

### Unit Tests Needed
- `StressAPIConfig` — 3-tier resolution (Info.plist → env → fallback)
- `StressAPIClient` — request construction, Bearer header injection, error mapping (402 → insufficientCredits)
- `SSEParser` — metadata event parsing, error event parsing, `[DONE]` handling
- `FirebaseAuthService` — token retrieval, refresh logic (mock `Auth.auth()`)

### Integration Tests Needed
- `/health` endpoint — unauthenticated GET returns 200
- `/chat` endpoint — authenticated POST returns SSE stream with tokens + terminal metadata
- `/chat` endpoint — 402 handling when credits exhausted (may need backend test setup)

### Build Verification
- `xcode_build(scheme: "StressMonitor")` — compiles with Firebase SDK added
- No remaining references to `Supabase` in source (grep verification)
- `GoogleService-Info.plist` present in app target

## 7. Dependency Lead Times

- **Firebase project setup** — if not already done, create Firebase project `stress-io`, enable Anonymous + Google Sign-In, download `GoogleService-Info.plist`. This is a manual prerequisite.
- **SPM resolution** — `firebase-ios-sdk` is ~100MB to download. First build will be slow.
- **Google Sign-In URL scheme** — add reversed client ID to `Info.plist` URL schemes.
