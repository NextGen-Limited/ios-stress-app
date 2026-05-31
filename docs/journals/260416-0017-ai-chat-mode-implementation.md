# AI Chat Mode Implementation - Apple Intelligence Integration

**Date**: 2026-04-16 00:17
**Severity**: Medium
**Component**: AI Chat Mode / LLM Service Layer / Chat UI
**Status**: Resolved (build passing, known gaps documented)

## What Happened

Implemented the AI Chat Mode feature end-to-end: protocol-based LLM service layer, Apple Intelligence (Foundation Models) backend, native SwiftUI chat UI in a bottom sheet, and context-aware health data injection into system prompts. 8 new files, 1 modified. Build succeeded with no new warnings.

## The Brutal Truth

The brainstorm session originally specified exyte/Chat as the UI library. That would have been the first external dependency in a zero-dependency project -- a line the brainstorm journal explicitly flagged as a concern. During implementation, the right call was made: native SwiftUI instead. No adapter pattern complexity, no version pinning headaches, no ABI mismatch with AI streaming. The zero-dep principle held. That is the correct outcome but the fact that it took a plan-reversal mid-stream to get there means the brainstorm over-indexed on "feature richness" over architectural constraints.

## Technical Details

**Protocol layer** (`LLMServiceProtocol`): 8 error cases covering the full Foundation Models error surface -- `exceededContext`, `guardrailViolation`, `rateLimited`, `refused`, `concurrentRequests`, `decodingFailure`, `cancelled`, `unknown(Error)`. Each maps to a user-facing message.

**AppleIntelligenceService** uses `#if canImport(FoundationModels)` + `if #available(iOS 26, *)` double-guard. Error mapping is string-based on `error.localizedDescription.lowercased()` -- this is the most fragile part. It works in English but will silently fall through to `.unknown` on non-English locales because Foundation Models returns localized error descriptions.

**ChatViewModel**: `@Observable @MainActor`, max 20 messages with proactive trim (`trimOldMessagesIfNeeded()`). Streaming uses `AsyncThrowingStream<String, Error>` token-by-token. Cancellation saves partial responses as assistant messages -- a nice touch for UX.

**Multi-turn limitation**: `AppleIntelligenceService.send()` only sends `messages.last(where: { $0.role == .user })` to the LLM. Full conversation history is NOT passed. This is a Foundation Models API constraint -- `LanguageModelSession` should theoretically maintain context across calls, but the current implementation creates a new session per `send()` call, which means the LLM has no memory of prior turns. This needs fixing.

**Unwired data**: `ActionView.swift` passes `nil` for `stressResult` and `baseline` to `ChatViewModel`. The chat will work but give generic wellness advice instead of personalized responses. Parent view integration is the next step.

## Key Decisions

| Decision | Choice | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Chat UI | Native SwiftUI | exyte/Chat library | Zero-dep principle. exyte/Chat is peer-to-peer messaging UI, wrong fit for AI chat |
| Error mapping | String-based `lowercased()` contains | Typed Foundation Models errors | Avoids compile-time dependency on iOS 26 SDK symbols |
| ChatQuickAction ID | `title` as `id` | UUID | Stable identity across view redraws. Titles are unique by design |
| Context trim | FIFO removeFirst | Smart summary | KISS. 20-message cap is generous for a wellness chat |
| Fallback | `UnavailableLLMService` returning error | Stub/mock responses | Honest UX: tell users it needs iOS 26 |

## Issues Carried Forward

1. **New session per send()**: `AppleIntelligenceService` creates a fresh `LanguageModelSession` on every call. Multi-turn conversation context is lost. Fix: persist the session across calls within the same chat session.
2. **String-based error mapping locale fragility**: `error.localizedDescription` is locale-dependent. On Japanese/German/etc devices, the contains checks silently fail and everything becomes `.unknown`. Acceptable for MVP, needs typed error matching later.
3. **Stress data not wired**: `ActionView` passes nil for health data. Chat gives generic advice until parent view integration lands.
4. **ChatContextBuilder duplicates `categoryName()`**: Uses inline `categoryName()` instead of importing from `Badge.swift`'s `displayName`. Minor DRY violation.

## Lessons Learned

- When a brainstorm suggests breaking a core architectural constraint (zero-dep), challenge it immediately. Do not let it survive into the plan.
- `#if canImport` + `if #available` double-guard is the correct pattern for bleeding-edge Apple frameworks. Single-guard compiles on older SDKs but crashes at runtime.
- String-based error matching is a pragmatic shortcut when typed errors require SDK version coupling. Document the locale limitation clearly.
- Creating `LanguageModelSession` per request defeats multi-turn. Session lifetime must match conversation lifetime, not request lifetime.

## Next Steps

- [ ] Fix session persistence in `AppleIntelligenceService` -- session should live on the instance, not created per `send()` call
- [ ] Wire stress data from parent view through `ActionView` to `ChatViewModel`
- [ ] Add typed error matching once Foundation Models API stabilizes post-iOS 26 GM
- [ ] Cloud LLM service implementation (Phase 2) to cover the ~70% of devices without Apple Intelligence
