# Journal: BE LLM Service Implementation

**Date:** 2026-04-16 16:07
**Plan:** `plans/0416-1430-be-llm-service/`

## What Happened

Implemented cloud LLM backend + iOS integration across 2 repos in 3 phases.

### Phase 1: FastAPI Gateway (`llm-gateway` repo)
- Created `~/Projects/next-labs/llm-gateway/` — new Python FastAPI backend
- Provider factory pattern: `gemini` / `glm` / `minimax` via `.env` config
- SSE streaming endpoint: `POST /v1/chat/completions`
- Bearer token auth, `/health` endpoint, CORS enabled
- Verified: server boots, health check returns 200, auth rejects invalid tokens

### Phase 2: iOS CloudLLMService
- New `CloudLLMService.swift` — implements `LLMServiceProtocol`
- SSE parsing via `URLSession.shared.bytes(for:)` + line-by-line parsing
- HTTP error mapping (401→unavailable, 429→rateLimited, 413→exceededContext)
- Synchronous `isAvailable()` via semaphore + 3s timeout health check

### Phase 3: Integration & Settings
- Modified `ChatViewModel.init` — cloud-first fallback chain:
  - Cloud (if server URL configured + reachable) → AppleIntelligence (iOS 26) → Unavailable
- New `AIChatSettingsCard.swift` — server URL + API key via `@AppStorage`
- Added to `SettingsView` between PremiumCard and WatchFaceCard

## Key Decisions

- **AsyncThrowingStream disambiguation:** Had to use explicit `Continuation` type annotation to avoid Swift picking the `unfolding:` overload instead of `build:` — `AsyncThrowingStream { (continuation: AsyncThrowingStream<String, Error>.Continuation) in`
- **Token encoding safety:** BE uses `json.dumps({'token': token})` to safely encode special chars (quotes, newlines) in SSE
- **NSError init:** `NSError(domain:code:userInfo:)` not `NSError(domain:description:)` in modern Swift

## Build Issues Resolved

1. `AsyncThrowingStream` closure type ambiguity → explicit Continuation type
2. `NSError` init signature → use `userInfo: [NSLocalizedDescriptionKey:]`
3. `nonisolated` on `mapHTTPError` → fix Swift 6 concurrency warning
4. No iPhone 16 simulator → switched to iPhone 17

## Impact

- Pre-iOS 26 devices can now use AI Chat via cloud LLM
- Settings UI allows self-hosted server configuration
- Zero regression to existing on-device chat flow
- llm-gateway is reusable for other apps

## Uncommitted

- ios-stress-app: 2 modified, 2 new files (user chose to skip commit)
- llm-gateway: initial commit pending (new repo, git init done)
