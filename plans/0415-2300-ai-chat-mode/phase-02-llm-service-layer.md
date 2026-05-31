# Phase 2: LLM Service Layer

**Priority:** High
**Status:** Pending
**blockedBy:** Phase 1 (LLMServiceProtocol, ChatMessage, ChatContext)

## Context Links

- Design report: [brainstorm-0415-2300-ai-chat-mode-design.md](../reports/brainstorm-0415-2300-ai-chat-mode-design.md)
- Phase 1 output: `LLMServiceProtocol.swift`, `ChatMessage.swift`
- Stress data model: `Models/StressResult.swift`, `Models/StressContext.swift`
- Existing context assembly pattern: `ViewModels/StressViewModel.swift` (lines 91-138)
- Existing insight pattern: `Services/InsightGeneratorService.swift`
- Health data models: `Models/SleepData.swift`, `Models/ActivityData.swift`, `Models/RecoveryData.swift`

## Overview

Implement three service-layer components: (1) `AppleIntelligenceService` wrapping Foundation Models framework, (2) `ChatContextBuilder` assembling health data into a system prompt within the 4K token budget, and (3) `ChatQuickActions` defining the 5 pre-built prompts.

## Key Insights

- Apple Intelligence Foundation Models requires iOS 26+. All code must use `#available(iOS 26, *)` guards.
- The `AppleIntelligenceService` must be a concrete type, NOT annotated with `@available` at the class level. Instead, wrap all Foundation Models calls in `#available` checks so the type itself compiles on iOS 17+ SDK.
- Foundation Models API: `import FoundationModels`, create `LanguageModelSession`, call `session.respond(to:)` or use streaming with `session.streamResponse(to:)`.
- **Streaming adapter required (xcdocs-verified):** `streamResponse(to:)` returns `ResponseStream<String>` (typed `AsyncSequence`), NOT `AsyncThrowingStream<String, Error>`. Must bridge via `AsyncThrowingStream` continuation.
- `ResponseStream<String>` iterates `ResponseStream.Snapshot` objects — extract `.content` from each snapshot for progressive text.
- `GenerationError` has 7 cases (xcdocs-verified): `exceededContextWindowSize`, `guardrailViolation`, `unsupportedLanguageOrLocale`, `rateLimited`, `refusal`, `concurrentRequests`, `assetsUnavailable`, `decodingFailure`, `unsupportedGuide`.
- System prompt budget: ~600 tokens for context, ~3400 for conversation.
- `ChatContextBuilder` must handle nil health data gracefully (user may not have granted all permissions).
- `ChatQuickActions` are static definitions, no state, no dependencies.
- **Prewarming:** `LanguageModelSession.prewarm(promptPrefix:)` loads model resources before user interaction, saving 1-2s on first generation.

## Requirements

### Functional

- `AppleIntelligenceService` conforms to `LLMServiceProtocol`
- `isAvailable()` returns `true` only on iOS 26+ with Apple Intelligence support
- `send()` streams response tokens via `AsyncThrowingStream<String, Error>`
- System prompt includes: persona, current stress data, trend summary, data flags, guidelines
- 5 quick actions defined with title, prompt text, icon
- Graceful fallback: returns `LLMError.unavailable` on unsupported devices

### Non-Functional

- All types `Sendable` or `@unchecked Sendable` where needed
- No health data in prompts beyond what's in `ChatContext`
- Streaming response must be cancellable (Task cancellation)
- System prompt construction <10ms (no async work)

## Architecture

```
ChatContext (from Phase 1)
    |
    v
ChatContextBuilder
    |  buildSystemPrompt(context:) -> String
    |  buildMessages(chatMessages:context:) -> [ChatMessage] (with system prepended)
    v
AppleIntelligenceService
    |  send(messages:context:) -> AsyncThrowingStream<String, Error>
    |  isAvailable() -> Bool
    v
Foundation Models framework (iOS 26+)
```

```
ChatQuickActions (static)
    |  .allActions -> [QuickAction]
    |  QuickAction: id, title, prompt, icon
    v
ChatViewModel / QuickActionChipsView (Phase 3)
```

## Related Code Files

### To Create

1. `StressMonitor/StressMonitor/Services/LLM/AppleIntelligenceService.swift` - Foundation Models wrapper
2. `StressMonitor/StressMonitor/Services/LLM/ChatContextBuilder.swift` - System prompt assembler
3. `StressMonitor/StressMonitor/Services/LLM/ChatQuickActions.swift` - Pre-built prompt definitions

### To Modify

None.

### To Delete

None.

## Implementation Steps

1. **Create `Services/LLM/ChatContextBuilder.swift`**
   - Define `ChatContextBuilder` as `enum` (static-only, no instances)
   - `static func buildSystemPrompt(from context: ChatContext) -> String`
   - Persona section: "You are AI Kitten, a friendly wellness companion cat..."
   - Stress data section: level, category, HRV, HR, confidence (skip if nil)
   - Trend section: weeklyAvg comparison text (skip if nil)
   - Data flags: list which health data types are available
   - Guidelines: "Be supportive but not medical. Suggest breathing when high stress. Keep responses concise."
   - Estimated total: ~600 tokens
   - All sections optional-graceful -- empty string for missing data sections

2. **Create `Services/LLM/ChatQuickActions.swift`**
   - Define `QuickAction` struct: `id: String`, `title: String`, `prompt: String`, `icon: String` (SF Symbol name)
   - Conform to `Identifiable, Sendable`
   - Define `ChatQuickActions` enum with static `allActions: [QuickAction]` property
   - 5 actions:
     - "Why am I stressed?" -> "Analyze what factors are currently contributing to my stress level."
     - "How's my sleep affecting me?" -> "How is my recent sleep quality affecting my stress levels?"
     - "Suggest a breathing exercise" -> "Recommend a breathing exercise suitable for my current stress level."
     - "Analyze my trends" -> "Analyze my stress patterns over the past week and identify any trends."
     - "What can I do right now?" -> "What's the single most impactful thing I can do right now to reduce my stress?"

3. **Create `Services/LLM/AppleIntelligenceService.swift`**
   - `import FoundationModels` (conditional)
   - `final class AppleIntelligenceService: LLMServiceProtocol, Sendable`
   - `func isAvailable() -> Bool`: check `#available(iOS 26, *)` AND `SystemLanguageModel.default.availability == .available`
   - `func send(messages:context:) async throws -> AsyncThrowingStream<String, Error>`:
     - Guard `isAvailable()`, else throw `LLMError.unavailable`
     - Use `#available(iOS 26, *)` block
     - Build system prompt via `ChatContextBuilder.buildSystemPrompt(from: context)`
     - Create `LanguageModelSession` with system prompt
     - **Prewarm** session: call `session.prewarm()` to reduce first-response latency
     - Convert `[ChatMessage]` to conversation input
     - **Streaming adapter (xcdocs-verified):** Wrap `session.streamResponse(to:)` which returns `ResponseStream<String>` into an `AsyncThrowingStream<String, Error>` continuation:
       ```swift
       AsyncThrowingStream { continuation in
           Task {
               let responseStream = session.streamResponse(to: prompt)
               for try await snapshot in responseStream {
                   continuation.yield(snapshot.content)
               }
               continuation.finish()
           }
       }
       ```
     - Handle `Task.isCancelled` for cleanup
     - **Error handling (all 7 cases from xcdocs audit):**
       ```swift
       catch GenerationError.exceededContextWindowSize(_) { /* condense transcript, retry */ }
       catch GenerationError.guardrailViolation(_) { /* "I can't help with that" */ }
       catch GenerationError.unsupportedLanguageOrLocale(_) { /* language disclaimer */ }
       catch GenerationError.rateLimited(_) { /* back off, retry after delay */ }
       catch GenerationError.refusal(_, _) { /* "AI Kitten can't help with that" */ }
       catch GenerationError.concurrentRequests(_) { /* cancel previous, shouldn't happen */ }
       catch GenerationError.decodingFailure(_) { /* structured output parse failure */ }
       ```
   - For iOS <26: method body returns a failing stream with `LLMError.unavailable`
   - Use `@available(iOS 26, *)` on internal helper methods, NOT on the class itself

4. **Verify build compiles on iOS 17+ SDK**
   - The `import FoundationModels` must compile-guard: use `#if canImport(FoundationModels)` / `#endif`
   - All Foundation Models API calls inside `@available(iOS 26, *)` blocks
   - Class itself must compile on iOS 17+ SDK -- only the runtime path gated

## Todo

- [ ] Create `Services/LLM/ChatContextBuilder.swift` with system prompt builder
- [ ] Create `Services/LLM/ChatQuickActions.swift` with 5 pre-built prompts
- [ ] Create `Services/LLM/AppleIntelligenceService.swift` with Foundation Models wrapper
- [ ] Verify build compiles on iOS 17+ deployment target
- [ ] Verify `isAvailable()` returns `false` on simulator < iOS 26

## Success Criteria

- `AppleIntelligenceService` compiles without errors on iOS 17+ SDK
- `isAvailable()` returns `false` on current simulators (iOS 18)
- `ChatContextBuilder` produces system prompt from full `ChatContext`
- `ChatContextBuilder` produces valid system prompt when health data is nil (graceful degradation)
- `ChatQuickActions.allActions.count == 5`
- All types conform to `Sendable`
- Each file <200 LOC

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Foundation Models API shape unknown (iOS 26 unreleased) | ~~Medium~~ Resolved | ~~High~~ | **xcdocs audit confirmed all API names/signatures.** `streamResponse` returns `ResponseStream<String>`, NOT `AsyncThrowingStream`. Adapter pattern documented. |
| System prompt exceeds token budget on edge cases | Low | Medium | Add character count assertion, truncate sections with priority ordering |
| Build fails on iOS 17 SDK due to Foundation Models import | Medium | High | `#if canImport` guard + `@available` runtime checks |
| `ResponseStream` -> `AsyncThrowingStream` adapter leaks memory | Low | High | Continuation must call `finish()` in all exit paths (success, error, cancellation) |
| Rate limiting during streaming | Low | Medium | Handle `GenerationError.rateLimited` with exponential backoff or user-facing "slow down" message |

## Security Considerations

- System prompt must NOT contain raw user identifiers
- Health data in system prompt stays on-device (Apple Intelligence runs locally)
- No network calls from this service layer
- Disclaimer included in persona: "not medical advice"

## Next Steps

- Phase 3 depends on all three files from this phase
- Phase 3 will create `ChatViewModel` using `LLMServiceProtocol` and `ChatContextBuilder`
