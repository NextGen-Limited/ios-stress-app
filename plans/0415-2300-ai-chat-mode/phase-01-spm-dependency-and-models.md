# Phase 1: SPM Dependency & Models

**Priority:** High
**Status:** Pending
**blockedBy:** None (safe to start immediately)

## Context Links

- Design report: [brainstorm-0415-2300-ai-chat-mode-design.md](../reports/brainstorm-0415-2300-ai-chat-mode-design.md)
- Existing protocol pattern: `Services/Protocols/HealthKitServiceProtocol.swift`
- Existing model pattern: `Models/StressResult.swift`, `Models/StressContext.swift`
- SPM config: `StressMonitor/StressMonitor.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/`

## Overview

Add exyte/Chat as the project's first SPM dependency via Xcode project (not Package.swift -- this is an Xcode project, not a Swift Package). Create the `ChatMessage` value type model and the `LLMServiceProtocol` that all LLM implementations will conform to.

## Key Insights

- Project uses Xcode project (`.xcodeproj`), not a Swift Package. SPM deps are added via Xcode > File > Add Package Dependencies.
- Existing dependency: AnimatedTabBar (exyte/SPM) already in `Package.resolved` -- proves the pattern works.
- `exyte/Chat` URL: `https://github.com/exyte/Chat.git`
- Models follow `struct` + `Identifiable, Codable, Sendable` pattern (see `StressResult.swift`).
- Protocols follow `Sendable` conformance with extension providing defaults (see `HealthKitServiceProtocol.swift`).
- The LLM protocol must handle streaming via `AsyncThrowingStream<String, Error>`.
- **Note:** Foundation Models' `streamResponse(to:)` returns `ResponseStream<String>` (NOT `AsyncThrowingStream`). Phase 2 bridges this with an adapter.
- `ChatMessage` is session-only (no SwiftData `@Model` for MVP).
- Protocol includes `prewarm() async` method for session prewarming (xcdocs-verified: `session.prewarm(promptPrefix:)`).

## Requirements

### Functional

- exyte/Chat package resolves and builds without errors
- `ChatMessage` model stores role, content, timestamp with `Identifiable, Codable, Sendable`
- `ChatRole` enum covers `.user`, `.assistant`, `.system`
- `LLMServiceProtocol` declares `send(messages:context:)` returning `AsyncThrowingStream<String, Error>`
- `LLMServiceProtocol` declares `isAvailable() -> Bool` static check
- `ChatContext` struct carries health data needed for system prompt building

### Non-Functional

- Zero external API calls from protocol layer
- All types `Sendable` for actor isolation safety
- No force unwraps
- File size <200 LOC each

## Architecture

```
ChatMessage (value type)
    |
    v
LLMServiceProtocol (abstraction)
    |  send(messages:context:) -> AsyncThrowingStream<String, Error>
    |  isAvailable() -> Bool
    v
AppleIntelligenceService (Phase 2)
CloudLLMService (future)
```

## Related Code Files

### To Create

1. `StressMonitor/StressMonitor/Models/ChatMessage.swift` - Chat message value type + ChatRole enum + ChatContext struct
2. `StressMonitor/StressMonitor/Services/LLM/LLMServiceProtocol.swift` - Protocol + LLMError + default unavailable stub

### To Modify

3. Xcode project SPM configuration (via Xcode GUI or `project.pbxproj`) - Add exyte/Chat dependency

### To Delete

None.

## Implementation Steps

1. **Add exyte/Chat SPM dependency**
   - Open `StressMonitor.xcodeproj` in Xcode
   - File > Add Package Dependencies > `https://github.com/exyte/Chat.git`
   - Pin to latest stable version (check GitHub releases)
   - Add `Chat` library to `StressMonitor` target
   - Build to verify resolution

2. **Create `Models/ChatMessage.swift`**
   - Define `ChatRole` enum: `.user`, `.assistant`, `.system` (String raw value, Codable, Sendable, CaseIterable)
   - Define `ChatMessage` struct: `id: UUID`, `role: ChatRole`, `content: String`, `timestamp: Date`
   - Conform to `Identifiable, Codable, Sendable`
   - Add `init` with default `id: UUID()` and `timestamp: Date()`
   - Add computed `isUser: Bool` convenience
   - Add static factory `ChatMessage.user(_ content:)` and `ChatMessage.assistant(_ content:)`

3. **Create `Services/LLM/LLMServiceProtocol.swift`**
   - Define `ChatContext` struct (Separate from `StressContext`): carries `StressResult?`, `PersonalBaseline?`, `SleepData?`, `ActivityData?`, `RecoveryData?`, `trendSummary: String?`, `weeklyAvg: Double?`
   - `ChatContext` conforms to `Sendable`
   - Define `LLMError` enum: `.unavailable`, `.contextTooLong`, `.responseFailed(String)`, `cancelled`
   - Define `LLMServiceProtocol`: `func send(messages: [ChatMessage], context: ChatContext) async throws -> AsyncThrowingStream<String, Error>`, `func isAvailable() -> Bool`, `func prewarm() async`
   - Extension: default `isAvailable() -> false`, default `prewarm() {}` (no-op, concrete impl prewarms Foundation Models session)
   - Protocol conforms to `Sendable`
   - Extension: default `isAvailable() -> false`

4. **Verify build compiles**
   - `xcodebuild build -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 16'`
   - Fix any import errors from exyte/Chat integration

## Todo

- [ ] Add exyte/Chat SPM dependency to Xcode project
- [ ] Create `Models/ChatMessage.swift` with ChatRole, ChatMessage, ChatContext
- [ ] Create `Services/LLM/LLMServiceProtocol.swift` with protocol + LLMError
- [ ] Verify clean build

## Success Criteria

- `xcodebuild build` succeeds with new files and exyte/Chat dependency
- `ChatMessage` conforms to `Identifiable, Codable, Sendable`
- `LLMServiceProtocol` declares streaming API
- No compiler warnings
- Each file <200 LOC

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| exyte/Chat has breaking API on latest version | Medium | High | Pin to specific version, check GitHub releases before adding |
| exyte/Chat requires incompatible iOS version | Low | High | Check minimum deployment target matches (iOS 17+) |
| Swift Package resolution conflicts | Low | Medium | Check Package.resolved for existing conflicts |

## Security Considerations

- No API keys in this phase (Apple Intelligence is local)
- No health data leaves device (protocol is abstract, impl is Phase 2)
- ChatMessage is plain struct -- no persistence, no SwiftData, session-only

## Next Steps

- Phase 2 depends on `LLMServiceProtocol` and `ChatMessage` from this phase
- Phase 2 will implement `AppleIntelligenceService` and `ChatContextBuilder`
