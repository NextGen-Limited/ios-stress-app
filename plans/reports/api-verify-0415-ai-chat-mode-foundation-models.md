# API Verification Report: AI Chat Mode Plan

**Plan:** `plans/0415-2300-ai-chat-mode/`
**Date:** 2026-04-15
**Deployment Target:** iOS 26 (FoundationModels), iOS 17 (app minimum)
**Verified Against:** Xcode 26.3 local docs (xcdocs)

---

## Summary

| Status | Count | Details |
|--------|-------|---------|
| PASS | 12 | API exists, correct name/signature |
| WARNING | 4 | API exists but missing from plan error handling |
| FAIL | 1 | API shape mismatch — plan protocol won't compile |
| SKIP | 6 | Project-specific types (excluded) |

---

## FAIL — Blocks Implementation

### F1: `LLMServiceProtocol.send()` return type mismatch

**Plan declares:**
```swift
func send(messages: [ChatMessage], context: ChatContext) async throws -> AsyncThrowingStream<String, Error>
```

**Actual FoundationModels API:**
```swift
func streamResponse(to prompt: Prompt, options: GenerationOptions = GenerationOptions()) -> sending LanguageModelSession.ResponseStream<String>
```

`ResponseStream<String>` conforms to `AsyncSequence` but is NOT `AsyncThrowingStream<String, Error>`. The `AppleIntelligenceService` must create an adapter:

```swift
// Required conversion pattern
func send(messages: [ChatMessage], context: ChatContext) async throws -> AsyncThrowingStream<String, Error> {
    AsyncThrowingStream { continuation in
        Task {
            let stream = session.streamResponse(to: prompt)
            for try await snapshot in stream {
                continuation.yield(snapshot.content)  // or partial content
            }
            continuation.finish()
        }
    }
}
```

**Impact:** Phase 2 `AppleIntelligenceService.send()` will need a `ResponseStream -> AsyncThrowingStream` adapter layer. Plan doesn't document this.

**Fix:** Update Phase 2 implementation steps to include adapter logic.

---

## WARNINGS — Missing Error Handling

### W1: `GenerationError.rateLimited(_:)` not handled

**API exists:** `/documentation/FoundationModels/LanguageModelSession/GenerationError/rateLimited(_:)`

Streaming responses in background can trigger rate limiting. Plan's error handling only covers 3 cases. Must handle rate limiting, especially for streaming chat.

### W2: `GenerationError.refusal(_:_:)` not handled

**API exists:** `/documentation/FoundationModels/LanguageModelSession/GenerationError/refusal(_:_:)`

Distinct from `guardrailViolation` — model can refuse a specific request. Should show "AI Kitten can't help with that" UI.

### W3: `GenerationError.concurrentRequests(_:)` not handled

**API exists:** `/documentation/FoundationModels/LanguageModelSession/GenerationError/concurrentRequests(_:)`

If user sends message while previous response streaming, this fires. Plan's `ChatViewModel` should either cancel previous request (it does) or disable send button (it checks `isStreaming`). Verify cancel actually stops the session response.

### W4: `session.prewarm(promptPrefix:)` not mentioned

**API exists:** `/documentation/FoundationModels/LanguageModelSession/prewarm(promptPrefix:)`

First generation takes 1-2s. Plan doesn't include prewarming. Should prewarm in `ChatViewModel.init` or when sheet appears.

---

## PASS — Verified Correct

| # | Symbol | Framework | Verified |
|---|--------|-----------|----------|
| P1 | `LanguageModelSession` (final class) | FoundationModels | xcdocs confirmed |
| P2 | `LanguageModelSession(instructions:)` | FoundationModels | Convenience init exists |
| P3 | `session.respond(to:options:)` → `Response<String>` | FoundationModels | `.content: Content` confirmed |
| P4 | `session.streamResponse(to:options:)` → `ResponseStream<String>` | FoundationModels | Returns typed async sequence |
| P5 | `SystemLanguageModel.default.availability` | FoundationModels | Returns `Availability` enum |
| P6 | `SystemLanguageModel.Availability.available` | FoundationModels | Enum case confirmed |
| P7 | `SystemLanguageModel.Availability.unavailable(_:)` | FoundationModels | Enum case with reason |
| P8 | `session.transcript` → `Transcript` | FoundationModels | Full history access |
| P9 | `session.isResponding` → `Bool` | FoundationModels | For UI gating |
| P10 | `Transcript.Entry` (.instructions, .prompt, .response) | FoundationModels | All entry types confirmed |
| P11 | `Transcript.init(entries:)` | FoundationModels | For context condensation |
| P12 | `GenerationError.exceededContextWindowSize(_:)` | FoundationModels | Plan error handling correct |
| P13 | `GenerationError.guardrailViolation(_:)` | FoundationModels | Plan error handling correct |
| P14 | `GenerationError.unsupportedLanguageOrLocale(_:)` | FoundationModels | Plan error handling correct |
| P15 | `@Generable` macro | FoundationModels | `macro Generable(description: String?)` |
| P16 | `Tool` protocol | FoundationModels | In FoundationModels framework |
| P17 | `Response.content` property | FoundationModels | `let content: Content` |
| P18 | `ResponseStream<Content>` conforms to `AsyncSequence` | FoundationModels | Can iterate with `for try await` |

---

## SKIP — Project-Specific Types

ChatMessage, ChatRole, ChatContext, LLMServiceProtocol, LLMError, AppleIntelligenceService, ChatContextBuilder, ChatQuickActions, QuickAction, ChatViewModel, ChatBottomSheetView, ChatMessageAdapter, QuickActionChipsView

---

## Must-Fix Before Implementation

1. **F1:** Add `ResponseStream → AsyncThrowingStream` adapter in Phase 2 plan
2. **W1-W3:** Add `rateLimited`, `refusal`, `concurrentRequests` to error handling switch
3. **W4:** Add `session.prewarm()` call in Phase 3 ChatViewModel init

## Review Items

- The `Prompt` parameter type is `ExpressibleByStringLiteral` (Xcode docs example passes string literals directly) — no code change needed, but be aware
- `ResponseStream.Snapshot` is the streaming unit, not raw strings — adapter must extract content from snapshots
- `concurrentRequests` error means plan's `isResponding` check in ChatViewModel is critical

---

**Unresolved Questions:**
- Does `ResponseStream.Snapshot` expose partial text content for progressive display? Need to verify `.content` property on Snapshot type.
- Is `Prompt` literally `String` or a wrapper? Xcode docs show string literals working but type is opaque.
