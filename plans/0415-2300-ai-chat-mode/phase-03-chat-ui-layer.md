# Phase 3: Chat UI Layer

**Priority:** High
**Status:** Pending
**blockedBy:** Phase 2 (AppleIntelligenceService, ChatContextBuilder, ChatQuickActions)

## Context Links

- Design report: [brainstorm-0415-2300-ai-chat-mode-design.md](../reports/brainstorm-0415-2300-ai-chat-mode-design.md)
- Phase 1 output: `ChatMessage.swift`, `LLMServiceProtocol.swift` (with `ChatContext`)
- Phase 2 output: `AppleIntelligenceService.swift`, `ChatContextBuilder.swift`, `ChatQuickActions.swift`
- ViewModel pattern: `ViewModels/StressViewModel.swift` (`@Observable @MainActor final class`)
- DI pattern: Constructor injection with protocol defaults (see `StressViewModel.init`)
- Theme: `Views/Theme/` (Wellness color extensions, custom fonts)

## Overview

Build the chat UI layer: (1) `ChatViewModel` managing message state and streaming, (2) `ChatBottomSheetView` wrapping exyte/Chat in a sheet, (3) `ChatMessageAdapter` mapping between our `ChatMessage` and exyte/Chat's `Message`/`DraftMessage` types, and (4) `QuickActionChipsView` for suggestion prompt chips.

## Key Insights

- `ChatViewModel` must follow `@Observable @MainActor final class` pattern exactly (see `StressViewModel`).
- DI via constructor injection: `LLMServiceProtocol` with default `AppleIntelligenceService()`.
- exyte/Chat provides its own `Message` type. `ChatMessageAdapter` converts between our `ChatMessage` and theirs. This isolates the external dependency.
- `ChatBottomSheetView` is a regular SwiftUI view presented via `.sheet` modifier (NOT a custom sheet controller).
- Streaming: ViewModel holds a `Task?` for the current stream, cancels on dismiss or new send.
- **Prewarming (xcdocs-verified):** `LanguageModelSession.prewarm(promptPrefix:)` loads model early. Call in `ChatViewModel.init` or on sheet appear.
- **`isResponding` guard (xcdocs-verified):** `session.isResponding` is a `Bool` property. Must disable send button while `true` to prevent `GenerationError.concurrentRequests`.
- The sheet should use `presentationDetents([.large])` for near-fullscreen chat.
- `QuickActionChipsView` is a horizontal scroll of pill-shaped buttons.
- No emoji in code per project rules.

## Requirements

### Functional

- `ChatViewModel` manages `[ChatMessage]`, streaming state, and LLM interaction
- User can type messages and send them
- Streaming response updates assistant message in real-time
- Quick action taps insert their prompt as a user message and trigger response
- Chat can be dismissed (sheet) -- cancels any in-progress stream
- "Not available" state shown when `LLMService.isAvailable()` returns false

### Non-Functional

- ViewModel on `@MainActor` for thread safety
- Streaming Task cancelled on `deinit` or explicit cancel
- No memory leaks from Task retention
- exyte/Chat types isolated to adapter -- ViewModel never imports exyte/Chat
- Accessibility: VoiceOver labels on interactive elements
- Dynamic Type support

## Architecture

```
ChatBottomSheetView (SwiftUI + exyte/Chat)
    |  uses ChatMessageAdapter to convert messages
    |  contains QuickActionChipsView
    |  binds to ChatViewModel
    v
ChatViewModel (@Observable @MainActor)
    |  messages: [ChatMessage]
    |  isStreaming: Bool
    |  isAvailable: Bool
    |  sendMessage(_ text:)
    |  sendQuickAction(_ action:)
    |  cancelStream()
    |
    +--> LLMServiceProtocol (injected)
    +--> ChatContext (injected, from stress data)
    v
LLMServiceProtocol.send() -> AsyncThrowingStream<String, Error>
```

```
ChatMessageAdapter
    |  toExyteMessage(_ chatMessage:) -> exyte.Chat.Message
    |  toExyteDraft(_ text:) -> exyte.Chat.DraftMessage
    |  (all exyte types stay inside adapter)
```

## Related Code Files

### To Create

1. `StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift` - Chat state management
2. `StressMonitor/StressMonitor/Views/Chat/ChatBottomSheetView.swift` - Bottom sheet wrapper
3. `StressMonitor/StressMonitor/Views/Chat/ChatMessageAdapter.swift` - Type mapping
4. `StressMonitor/StressMonitor/Views/Chat/QuickActionChipsView.swift` - Suggestion chips

### To Modify

None.

### To Delete

None.

## Implementation Steps

1. **Create `ViewModels/ChatViewModel.swift`**
   - `@Observable @MainActor final class ChatViewModel`
   - Properties:
     - `var messages: [ChatMessage] = []`
     - `var isStreaming: Bool = false`
     - `var isAvailable: Bool` (computed from `llmService.isAvailable()`)
     - `var streamingText: String?` (current partial response)
     - `var errorMessage: String?`
   - Private: `let llmService: LLMServiceProtocol`, `let context: ChatContext`, `var streamTask: Task<Void, Never>?`
   - `init(llmService: LLMServiceProtocol = AppleIntelligenceService(), context: ChatContext)`
   - **Prewarm in init:** Call `llmService.prewarm()` if available, or create session early to reduce first-response latency (xcdocs: `session.prewarm(promptPrefix:)`)
   - `func sendMessage(_ text: String)`:
     - Guard `!isStreaming` to prevent `GenerationError.concurrentRequests` (xcdocs-verified)
     - Append `ChatMessage.user(text)` to messages
     - Set `isStreaming = true`, clear error
     - Create `streamTask = Task { ... }`
     - In task: call `llmService.send(messages:messages, context:context)`
     - Iterate stream, append tokens to `streamingText`
     - On stream completion: append `ChatMessage.assistant(streamingText)` to messages, clear streamingText
     - On error: map `GenerationError` cases to user-friendly messages:
       - `.exceededContextWindowSize` → "Conversation too long, starting fresh"
       - `.guardrailViolation` → "I can't help with that"
       - `.rateLimited` → "Slow down, try again in a moment"
       - `.refusal` → "AI Kitten can't help with that"
       - Other → Generic error message
     - Always: `isStreaming = false`
   - `func sendQuickAction(_ action: QuickAction)`:
     - Same as `sendMessage(action.prompt)`
   - `func cancelStream()`:
     - `streamTask?.cancel()`, `streamTask = nil`
   - `deinit`: cancel stream task

2. **Create `Views/Chat/ChatMessageAdapter.swift`**
   - `import Chat` (exyte/Chat module)
   - `enum ChatMessageAdapter` (static-only)
   - `static func toExyteMessage(from message: ChatMessage) -> Message`:
     - Map `.user` -> exyte `Message` with user sender
     - Map `.assistant` -> exyte `Message` with custom "AI Kitten" sender + avatar
   - `static func toExyteMessages(from messages: [ChatMessage]) -> [Message]`
   - `static func createAIKittenSender() -> ChatMessage.ChatUser` (or exyte's sender type)
   - Note: exact exyte/Chat types to be determined from the library's API. Adapter isolates these details.

3. **Create `Views/Chat/QuickActionChipsView.swift`**
   - `struct QuickActionChipsView: View`
   - Property: `onAction: (QuickAction) -> Void`
   - Body: horizontal `ScrollView` with `HStack` of pill-shaped buttons
   - Each chip: icon + title, rounded capsule, `.adaptiveCardBackground` fill, tap calls `onAction`
   - Uses `ChatQuickActions.allActions` for data
   - Hidden when `isStreaming == true` (passed as binding or parameter)
   - Accessibility: each chip labeled with action title

4. **Create `Views/Chat/ChatBottomSheetView.swift`**
   - `struct ChatBottomSheetView: View`
   - `@State private var viewModel: ChatViewModel`
   - `@Environment(\.dismiss) private var dismiss`
   - `init(context: ChatContext)`
   - Body:
     - `NavigationStack` with title "AI Chat" and dismiss button
     - If `!viewModel.isAvailable`: show "Requires iOS 26" placeholder with AI Kitten image
     - Else: `ChatView` (exyte/Chat) with:
       - `messages` from adapter
       - Custom `messageBuilder` for AI Kitten avatar on assistant messages
       - `inputView` area with quick action chips above input bar
       - `onSendMessage` callback that calls `viewModel.sendMessage()`
     - Quick action chips shown above input when not streaming
   - `.presentationDetents([.large])`
   - `.presentationDragIndicator(.visible)`
   - On disappear: `viewModel.cancelStream()`

5. **Verify build compiles**
   - All exyte/Chat types isolated in `ChatMessageAdapter`
   - ViewModel has no exyte/Chat imports
   - Bottom sheet view is the only bridge between the two

## Todo

- [ ] Create `ViewModels/ChatViewModel.swift` with message state and streaming
- [ ] Create `Views/Chat/ChatMessageAdapter.swift` mapping our models to exyte/Chat
- [ ] Create `Views/Chat/QuickActionChipsView.swift` with 5 suggestion chips
- [ ] Create `Views/Chat/ChatBottomSheetView.swift` with exyte/Chat integration
- [ ] Verify clean build

## Success Criteria

- `ChatViewModel` compiles with zero exyte/Chat imports
- `ChatMessageAdapter` handles user and assistant message conversion
- `QuickActionChipsView` renders 5 chips with icons
- `ChatBottomSheetView` presents in a sheet with dismiss capability
- Streaming state (`isStreaming`, `streamingText`) observable by views
- "Not available" state shown when LLM unavailable
- Each file <200 LOC
- No compiler warnings

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| exyte/Chat `ChatView` API doesn't support custom message builder well | Medium | High | Adapter isolates; may need custom SwiftUI chat list instead of exyte/Chat ChatView |
| exyte/Chat input bar conflicts with quick action chips layout | Medium | Medium | Custom `inputViewBuilder` parameter or overlay chips above input |
| Streaming token display jank (flicker, layout jumps) | Low | Medium | Batch UI updates, use `withAnimation` sparingly |
| Memory leak from retained stream Task | Low | High | `deinit` cancels, `cancelStream()` on sheet dismiss |
| `GenerationError.concurrentRequests` from double-send | Low | Medium | Guard `!isStreaming` before creating stream task |

## Security Considerations

- Chat content is session-only -- nothing persisted to disk
- No health data in user-visible chat bubbles (only in system prompt sent to on-device LLM)
- Disclaimer text visible in chat header or footer
- Sheet dismissal cancels in-flight LLM requests

## Next Steps

- Phase 4 wires `ChatBottomSheetView` into `ActionView.swift`
- Phase 4 depends on cross-plan `0415-2219-aichat-card-figma-alignment` completing first
