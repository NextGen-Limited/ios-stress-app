# Code Review: AI Chat Mode Feature

**Reviewer:** code-reviewer
**Date:** 2026-04-15
**Scope:** 9 files (8 new, 1 modified) -- AI Chat Mode feature for StressMonitor

## Scope

- **Files:**
  - `Models/ChatMessage.swift` -- Chat message model
  - `Services/LLM/LLMServiceProtocol.swift` -- LLM protocol + error types
  - `Services/LLM/AppleIntelligenceService.swift` -- Apple Intelligence implementation
  - `Services/LLM/ChatContextBuilder.swift` -- System prompt builder
  - `Services/LLM/ChatQuickActions.swift` -- Pre-built prompt suggestions
  - `ViewModels/ChatViewModel.swift` -- Chat state management
  - `Views/Chat/ChatBottomSheetView.swift` -- Chat UI in bottom sheet
  - `Views/Chat/QuickActionChipsView.swift` -- Suggestion chips
  - `Views/Action/ActionView.swift` -- Modified: sheet presentation
- **LOC:** ~600 (new)
- **Focus:** New AI Chat Mode feature
- **Build status:** Verified BUILD SUCCEEDED

## Overall Assessment

Solid implementation. Clean MVVM separation, proper use of `@Observable`, protocol-based DI, and thoughtful graceful degradation. The zero-dependency native SwiftUI chat approach is well-executed. Issues below range from a potential runtime crash to minor accessibility gaps.

---

## Critical Issues

### C1. `ChatBottomSheetView` passes `nil` health data to `ChatViewModel`

**File:** `ActionView.swift:56-59`

```swift
ChatBottomSheetView(
    stressResult: nil,
    baseline: nil
)
```

The sheet is always instantiated with nil health context. The system prompt will have no current stress data, no baseline, and no trend -- making AI Kitten's responses generic rather than personalized. This is the core value prop of the feature.

**Impact:** AI Kitten cannot reference the user's actual stress levels, HRV, or trends. Every response is generic.

**Fix:** Inject the real `StressResult` and `PersonalBaseline` from wherever ActionView gets its data (likely from a parent view or shared state). Example:

```swift
// ActionView needs access to current stress data
@State private var currentStressResult: StressResult?
// ... pass to ChatBottomSheetView when presenting sheet
ChatBottomSheetView(
    stressResult: currentStressResult,
    baseline: currentBaseline
)
```

### C2. `displayName` on `StressCategory` is defined in `Badge.swift` extension -- fragile coupling

**File:** `ChatContextBuilder.swift:43`

`ChatContextBuilder` uses `stress.category.displayName` which is defined in an extension inside `Badge.swift` (a view file). If Badge.swift is ever excluded from a target (e.g., watchOS), this will fail to compile. More importantly, it is a model concern masquerading as a view concern.

**Impact:** Build fragility across targets; semantic misuse of view layer for model data.

**Fix:** Move the `displayName` extension from `Badge.swift` into `StressCategory.swift` alongside the enum definition.

---

## High Priority

### H1. `UnavailableLLMService` does not conform to `Sendable`

**File:** `ChatViewModel.swift:145`

```swift
private final class UnavailableLLMService: LLMServiceProtocol {
```

`LLMServiceProtocol` requires `Sendable`, and `AppleIntelligenceService` (a `final class`) also does not explicitly conform. While Swift may not enforce this at runtime currently, it will become a compiler error under strict concurrency.

**Impact:** Future compilation failure under strict concurrency; protocol contract violation.

**Fix:** Mark both as `Sendable` (they have no mutable state):

```swift
final class AppleIntelligenceService: LLMServiceProtocol, Sendable { ... }
private final class UnavailableLLMService: LLMServiceProtocol, Sendable { ... }
```

### H2. Race condition in `cancelResponse()` -- manual state mutation without defer coordination

**File:** `ChatViewModel.swift:126-132`

```swift
func cancelResponse() {
    streamingTask?.cancel()
    streamingTask = nil

    if !currentStreamingText.isEmpty {
        let partial = ChatMessage(role: .assistant, content: currentStreamingText)
        messages.append(partial)
    }
    currentStreamingText = ""
    isLoading = false
}
```

This method manually sets `isLoading = false` and clears `currentStreamingText`, but the `streamResponse()` method has a `defer` block that also sets these. If the Task's cancellation propagates and `streamResponse` runs its defer after `cancelResponse` mutates state, the defer will set `currentStreamingText = ""` (harmless) and `isLoading = false` (redundant). The current code works because `@MainActor` serializes execution, but this is fragile -- the defer and cancel are fighting over the same state.

**Impact:** Not a current bug due to `@MainActor` serialization, but the dual cleanup paths are a maintenance hazard.

**Fix:** Consider using a flag or having `streamResponse` check `Task.isCancelled` before its defer cleanup:

```swift
defer {
    if !Task.isCancelled {  // only clean up if we weren't cancelled
        isLoading = false
        currentStreamingText = ""
    }
}
```

### H3. `AppleIntelligenceService.send()` only sends last user message, not full conversation history

**File:** `AppleIntelligenceService.swift:39-46`

```swift
guard let lastUserMessage = messages.last(where: { $0.role == .user }) else {
    continuation.finish()
    return
}
let responseStream = session.streamResponse {
    Prompt(lastUserMessage.content)
}
```

The protocol accepts the full message history but the implementation only sends the last user message. The `ChatViewModel` accumulates conversation history and passes all messages, but the LLM only sees the latest prompt. This means the AI has no memory of the conversation.

**Impact:** AI Kitten cannot reference anything said earlier in the conversation. Multi-turn dialogue is broken.

**Fix:** Convert the message history into the Foundation Models conversation format. The `LanguageModelSession` API supports conversation context -- either use `session` with prior turns or reconstruct them via `Prompt` concatenation. If the API does not support multi-turn, document this as a known limitation.

### H4. String-based error matching is fragile and locale-dependent

**File:** `AppleIntelligenceService.swift:71-94`

Error mapping relies on `error.localizedDescription.lowercased()` containing specific English words like "guardrail", "concurrent", "decod". On non-English locales, `localizedDescription` may return localized strings that do not contain these keywords.

**Impact:** All Foundation Models errors will fall through to `.unknown(error)` on non-English devices. No context overflow recovery, no guardrail messaging, no rate limit awareness.

**Fix:** If possible, type-check against the concrete `GenerationError` types from FoundationModels inside the `#available` block. If string matching is truly the only option (because of SDK version constraints), at minimum match against `error._domain` and `error._code` which are locale-independent, or use `String(describing: error)` which includes the type name.

---

## Medium Priority

### M1. No accessibility support on chat views

**Files:** `ChatBottomSheetView.swift`, `QuickActionChipsView.swift`

- Message bubbles have no `.accessibilityLabel` or `.accessibilityValue`
- Quick action chips have no accessibility hints
- Streaming text has no `@A11y` announcement
- Error banner uses color alone (red) without icon/text differentiation

The project's design system explicitly requires dual coding (WCAG). Chat views bypass this.

**Impact:** VoiceOver users cannot effectively use the chat feature.

**Fix:** Add `.accessibilityElement()`, `.accessibilityLabel()`, and `.accessibilityValue()` modifiers. For the error banner, add an SF Symbol alongside the text.

### M2. `ChatQuickAction.id` is generated inline -- not stable across re-renders

**File:** `ChatQuickActions.swift:7`

```swift
struct ChatQuickAction: Identifiable {
    let id = UUID()
```

Every call to `actions(for:)` creates new UUIDs. If the view re-renders (e.g., due to streaming state changes), `ForEach` may see different identity values for the same logical actions, causing unnecessary re-renders or animation glitches.

**Impact:** Minor visual glitch potential; SwiftUI identity churn.

**Fix:** Use stable identifiers based on the action content:

```swift
let id = title  // title is unique per action
```

Or use an explicit enum-based ID.

### M3. `ActionView` creates `DateFormatter` on every render

**File:** `ActionView.swift:393-403`

```swift
private var dayOfWeek: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE"
    return formatter.string(from: currentDate)
}
```

`DateFormatter` is expensive to create. Two are created every time the view body is evaluated.

**Impact:** Performance overhead on every scroll/re-render.

**Fix:** Cache formatters as static properties or use `Date.FormatStyle` (iOS 15+):

```swift
private var dayOfWeek: String {
    currentDate.formatted(.dateTime.weekday(.wide))
}
```

### M4. `ChatBottomSheetView.inputText` declared after methods that use it

**File:** `ChatBottomSheetView.swift:263`

```swift
@State private var inputText = ""
```

This is declared at the bottom of the struct, below `sendMessage()` which reads it. While Swift does not require declaration order, it hurts readability.

**Impact:** Minor readability issue.

**Fix:** Move `@State private var inputText = ""` to the top with other state properties.

### M5. No message count limit or token budget guard

**Files:** `ChatViewModel.swift`, `ChatContextBuilder.swift`

The system prompt is ~600 tokens, but there is no limit on how many messages accumulate. On a 4K context device, users could hit context overflow after ~15-20 messages. The `.exceededContext` handler silently clears all messages, losing the conversation.

**Impact:** Unexpected conversation loss without user confirmation.

**Fix:** Add a warning when approaching the limit (e.g., 12+ messages), or proactively trim older messages to stay within budget.

---

## Low Priority

### L1. `ChatRole.system` is defined but never used in the client code

**File:** `ChatMessage.swift:9`

```swift
case system
```

The system prompt is injected via the LLM service's `systemPrompt` parameter, not as a `.system` role message. The enum case is unused client-side.

**Impact:** Dead code; minor confusion.

**Fix:** Remove unless planned for future use. Document if kept.

### L2. `TypingDotAnimation` delay uses hardcoded values

**File:** `ChatBottomSheetView.swift:334-349`

The animation uses `delay: Double(index) * 0.2` and `duration: 0.5`. These are fine but magic numbers.

**Impact:** Maintainability.

**Fix:** Extract to named constants if the feature evolves.

### L3. `MessageBubbleView` is marked `private` but could be reusable

**File:** `ChatBottomSheetView.swift:284`

```swift
private struct MessageBubbleView: View {
```

Not a problem per se, but if the chat evolves to have different presentation modes, this will need to become internal.

**Impact:** None currently; forward-looking note.

---

## Edge Cases Found by Scout

1. **Empty message list + send:** If `messages` is empty and `send()` is called, then `messages.last(where: { $0.role == .user })` in `AppleIntelligenceService` returns nil and the stream finishes immediately with no response. The user sees their message but never gets a reply. This path should be handled gracefully (it is -- the stream just ends -- but the user sees no feedback).

2. **Rapid send while streaming:** `send()` does not cancel the existing `streamingTask` before starting a new one. If a user taps send while a response is streaming, the old task leaks and both tasks write to `currentStreamingText` concurrently. Since `@MainActor` serializes, the last writer wins, but the old stream continues consuming resources until it naturally completes or errors.

3. **Sheet dismiss during streaming:** If the user swipes the sheet away while streaming, the `@State` viewModel is destroyed, but the `streamingTask` may still be running. The `[weak self]` capture in `send()` handles this correctly -- the task will find `self == nil` and return. Good.

4. **`analyzeTrend` force-unwrap:** `ChatContextBuilder.swift:77` uses `levels.first!` and `levels.last!` after a `count >= 2` guard. Safe but could use `.first!` pattern more clearly or optional binding.

---

## Positive Observations

1. **Clean protocol-based DI** -- `LLMServiceProtocol` makes it trivial to swap in a cloud LLM later.
2. **Graceful degradation** -- `UnavailableLLMService` provides clear user-facing messaging on unsupported devices.
3. **Proper use of `@Observable` + `@MainActor`** -- Follows project conventions exactly.
4. **`#if canImport(FoundationModels)`** -- Correct compile-time guarding for iOS 26 API.
5. **No hardcoded secrets** -- All LLM interaction is on-device; no API keys anywhere.
6. **Zero external dependencies** -- Native SwiftUI chat respects the project's no-third-party rule.
7. **Session-only persistence** -- Appropriate for MVP; no premature SwiftData modeling.
8. **`[weak self]` in streaming Task** -- Prevents retain cycles on sheet dismiss.

---

## Recommended Actions

1. **[CRITICAL]** Wire real stress data into `ActionView`'s sheet presentation (C1)
2. **[CRITICAL]** Move `displayName` from Badge.swift to StressCategory.swift (C2)
3. **[HIGH]** Add `Sendable` conformance to LLM service classes (H1)
4. **[HIGH]** Investigate multi-turn conversation support in Foundation Models API (H3)
5. **[HIGH]** Replace locale-dependent string matching with type-checking or domain/code matching (H4)
6. **[MEDIUM]** Add VoiceOver labels to chat views (M1)
7. **[MEDIUM]** Stabilize `ChatQuickAction` identifiers (M2)
8. **[MEDIUM]** Guard against rapid send without cancel (H2 / edge case 2)

---

## Metrics

- **Type Coverage:** Full (all protocols conformed, Sendable gap noted)
- **Test Coverage:** No unit tests for new code (expected for initial implementation, but should be added)
- **Linting Issues:** 0 (clean compile)
- **Security:** No issues -- on-device only, no secrets, HealthKit data stays in system prompt

---

## Unresolved Questions

1. Does the Foundation Models `LanguageModelSession` API support multi-turn conversation natively, or is single-turn the current API limitation? This determines whether H3 is a bug or a known limitation.
2. Should the chat eventually persist conversations to SwiftData, or is session-only the permanent design? This affects the context overflow handling strategy (M5).
3. Is there a plan to inject real HealthKit data into ActionView's chat presentation? The current nil-passing suggests this is a TODO rather than a bug, but confirmation would help prioritize C1.
