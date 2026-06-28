# Chat models

Models backing the AI coaching chat.

## Types

| Type | File | Description |
| --- | --- | --- |
| `ChatMessage` | `StressMonitor/StressMonitor/Models/ChatMessage.swift` | One message in the conversation: role, content, timestamp |
| `ChatQuickActions` | `StressMonitor/StressMonitor/Services/LLM/ChatQuickActions.swift` | Canned suggestion chips surfaced above the chat input |
| `StressContextPayload` | `StressMonitor/StressMonitor/Services/LLM/StressContextPayload.swift` | Codable payload sent to the backend so it can build the system prompt |
| `SSEMetadata` | `StressMonitor/StressMonitor/Services/LLM/SSEParser.swift` | Session ID, credits remaining, model used |

## ChatMessage

```swift
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: Role
    var content: String
    let timestamp: Date

    enum Role: String, Codable {
        case user, assistant, system
    }
}
```

`ChatViewModel` (at `StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift`) owns the local `[ChatMessage]` array. Only `user` and `assistant` messages are displayed; `system` is set by `ChatContextBuilder` when constructing the payload but is not rendered in `ChatBottomSheetView`.

## StressContextPayload

`StressContextPayload` is the Codable struct the app sends to the `/chat` Edge Function so the backend can construct a health-aware system prompt without ever seeing raw HealthKit samples. It carries summarized fields: current stress level and category, recent HRV/HR trend direction, factor breakdown percentages, and a short recent-measurements window.

The payload uses snake_case `CodingKeys` to match the backend's JSON schema. `SupabaseLLMService.send` encodes it through `JSONEncoder` and attaches it as the `stress_context` field in the request body.

## Quick actions

`ChatQuickActions` provides context-aware suggestion chips (for example, "Why am I stressed?", "Suggest a breathing exercise"). `ChatQuickActionsView` (at `StressMonitor/StressMonitor/Views/Chat/QuickActionChipsView.swift`) renders them above the input bar; tapping a chip sends its prompt as a user message.
