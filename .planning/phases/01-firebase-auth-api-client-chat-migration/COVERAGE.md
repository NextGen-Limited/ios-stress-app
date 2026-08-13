# API Coverage — Firebase Auth + Stress API Backend

> Full coverage by default. Opt-outs are explicit, reasoned decisions.

Two external API surfaces are integrated in this phase: the **Firebase Auth SDK** (client-side SDK, not a REST API) and the **Stress API backend** (`https://stress-api.dropitx.site`, REST + SSE). The backend's full surface is 11 endpoints; Phase 1 intentionally integrates only the foundational subset, with the rest explicitly deferred to Phase 2/3.

## Firebase Auth SDK (firebase-ios-sdk 11.x)

| capability | decision | reason |
|---|---|---|
| Anonymous sign-in (`signInAnonymously()`) | INTEGRATE | Default frictionless auth — auto-sign-in on launch |
| Google Sign-In (`signInWithGoogle` + account linking) | INTEGRATE | Upgrade path for cross-device persistence via `link(with:)` |
| ID token retrieval (`getIDToken(forcingRefresh:)`) | INTEGRATE | Bearer token for every backend request |
| `FirebaseApp.configure()` initialization | INTEGRATE | Entry point — first statement in `StressMonitorApp.init` |
| Email/password auth | OPT-OUT | not supported by backend — Firebase Admin verifies Google OAuth + Anonymous only |
| Phone auth | OPT-OUT | not supported by backend |
| Apple Sign-In | OPT-OUT | not needed yet — tracked for potential future auth provider expansion |
| Custom claims / Role management | OPT-OUT | backend uses lazy provisioning on first authed request; no custom claims required |

## Stress API Backend (`https://stress-api.dropitx.site`)

| capability | decision | reason |
|---|---|---|
| `GET /health` (liveness probe, no auth) | INTEGRATE | Used for `isAvailable()` check — public endpoint |
| `POST /chat` (SSE streaming) | INTEGRATE | Core migration target — the primary feature of this phase |
| `/chat` SSE token streaming (`data:{choices:[{delta:{content}}]}`) | INTEGRATE | Streaming response content |
| `/chat` SSE terminal metadata (`data:{type:metadata,...}`) | INTEGRATE | Parses `session_id`, `credits_remaining`, `model_used`, `quick_actions` — D-05 |
| `/chat` HTTP 402 `INSUFFICIENT_CREDITS` handling | INTEGRATE | Maps to `LLMServiceError.insufficientCredits` — D-07 |
| `/chat` HTTP 401 handling | INTEGRATE | Maps to `LLMServiceError.unavailable` — expired/invalid token |
| `/chat` HTTP 429 handling | INTEGRATE | Maps to `LLMServiceError.rateLimited` |
| Bearer token injection (`Authorization` header) | INTEGRATE | `StressAPIClient` injects Firebase ID token on every request except `/health` |
| `POST /credits` (deduct/check balance) | OPT-OUT | Phase 2 — credits system + IAP transition |
| `GET /credits` (balance read) | OPT-OUT | Phase 2 — credits UI + paywall |
| `GET /sessions` (server-side chat history) | OPT-OUT | Phase 3 — sessions integration |
| `POST /sessions` (create session) | OPT-OUT | Phase 3 |
| `GET /preferences` (user preferences sync) | OPT-OUT | Phase 3 |
| `PUT /preferences` (update preferences) | OPT-OUT | Phase 3 |
| `GET /quick-actions` (contextual suggestions) | OPT-OUT | Phase 3 |
| `POST /quick-actions` | OPT-OUT | Phase 3 |

## Configuration Surface

| capability | decision | reason |
|---|---|---|
| `STRESS_API_BASE_URL` (Info.plist → env → fallback) | INTEGRATE | D-03 — 3-tier config resolution matching existing pattern |
| `GoogleService-Info.plist` (Firebase config) | INTEGRATE | Required for Firebase SDK initialization — gitignored, per-project |
| `REVERSED_CLIENT_ID` URL scheme | INTEGRATE | Google Sign-In OAuth callback — registered in Info.plist |
| Legacy Supabase config removal | INTEGRATE | D-04 — all Supabase source/strings scrubbed |
