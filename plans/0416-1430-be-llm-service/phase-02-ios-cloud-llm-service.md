# Phase 2: iOS CloudLLMService

**Priority:** High
**Status:** Complete
**Effort:** Medium
**Depends on:** Phase 1

## Context

- BE API from Phase 1: `POST /v1/chat/completions` with SSE streaming
- Must implement existing `LLMServiceProtocol` (see `Services/LLM/LLMServiceProtocol.swift`)
- Existing `ChatMessage` model has `role` (user/assistant/system), `content`, `timestamp`

## Overview

New `CloudLLMService` that calls the BE via URLSession, parses SSE token stream, and adapts to `AsyncThrowingStream<String, Error>`.

## Requirements

### Functional
- Implement `LLMServiceProtocol`
- `isAvailable()` → reachability check (URLSession ping to `/health` or `/v1/models`)
- `send()` → POST to BE, parse SSE `data: {"token": "..."}` lines, yield tokens
- Configurable server URL + API key via `@AppStorage`
- Handle all `LLMServiceError` cases from HTTP status codes

### Non-functional
- No third-party networking libs (URLSession only, consistent with project conventions)
- Request timeout: 60s
- Proper cancellation via Task cancellation

## Files to Create

### `Services/LLM/CloudLLMService.swift`

```swift
@MainActor
final class CloudLLMService: LLMServiceProtocol, Sendable {
    private let serverURL: String
    private let apiKey: String

    init(serverURL: String, apiKey: String) {
        self.serverURL = serverURL
        self.apiKey = apiKey
    }

    func isAvailable() -> Bool {
        // URLSession HEAD request to serverURL/health
        // synchronous check with short timeout (3s)
    }

    func send(
        messages: [ChatMessage],
        systemPrompt: String
    ) async throws -> AsyncThrowingStream<String, Error> {
        // 1. Build URLRequest to POST /v1/chat/completions
        // 2. Set headers: Authorization, Content-Type
        // 3. Encode body: { messages: [...], system_prompt: "...", stream: true }
        // 4. URLSession.shared.bytes(for: request)
        // 5. Parse SSE lines: extract "token" from data: {"token": "..."}
        // 6. Yield tokens via AsyncThrowingStream
        // 7. Map HTTP errors to LLMServiceError
    }
}
```

## SSE Parsing Logic

```swift
// SSE format from BE:
// data: {"token": "Hello"}\n\n
// data: {"token": "!"}\n\n
// data: [DONE]\n\n

for try await line in byteLines {
    guard line.hasPrefix("data: ") else { continue }
    let payload = String(line.dropFirst(6))

    if payload == "[DONE]" { break }

    if let data = payload.data(using: .utf8),
       let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
       let token = json["token"] {
        continuation.yield(token)
    }
}
```

## Error Mapping (HTTP → LLMServiceError)

| HTTP Status | LLMServiceError |
|-------------|-----------------|
| 401 | `.unavailable(reason: "Invalid API key")` |
| 429 | `.rateLimited` |
| 503 | `.unavailable(reason: "Service unavailable")` |
| 413 | `.exceededContext` |
| Other 4xx/5xx | `.unknown(...)` |

## Implementation Steps

1. Create `CloudLLMService.swift`
2. Implement `isAvailable()` with URLSession HEAD request
3. Implement `send()` with URLSession bytes + SSE parsing
4. Add HTTP error → `LLMServiceError` mapping
5. Handle edge cases: empty response, malformed SSE, network timeout
6. Ensure `Sendable` conformance (no mutable state, thread-safe)

## Success Criteria

- [ ] `CloudLLMService.isAvailable()` returns true when BE is running
- [ ] `CloudLLMService.isAvailable()` returns false when BE is unreachable
- [ ] `send()` streams tokens correctly from BE SSE response
- [ ] HTTP 401 → `.unavailable` error
- [ ] HTTP 429 → `.rateLimited` error
- [ ] Task cancellation stops the stream
- [ ] No third-party dependencies

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| SSE parsing edge cases (multi-line tokens) | Parse line-by-line, handle `data:` prefix strictly |
| URLSession bytes API differences across iOS versions | Use `URLSession.shared.bytes(for:)` (iOS 15+, well within iOS 17+ target) |
| Thread safety with `@MainActor` | `isAvailable()` uses `nonisolated` with synchronous check |
