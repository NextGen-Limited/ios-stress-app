# AI Chat Feature - Completion Plan

> Created: 2026-06-07 | Priority: P0 BLOCKER | Target: Production Ready

## Current State

The AI Chat feature is **80% complete** but has critical blockers preventing shipping.

### What Works
- Chat UI (bottom sheet, message bubbles, streaming, quick actions) — COMPLETE
- ChatViewModel (streaming, context trim, cancellation) — COMPLETE
- ChatContextBuilder (system prompt with live health data) — COMPLETE
- SSEParser (OpenAI-compatible SSE parsing) — COMPLETE
- ChatQuickActions (contextual suggestions) — COMPLETE
- ChatMessage model — COMPLETE
- AIChatCard (dashboard entry point) — COMPLETE
- AppleIntelligenceService (iOS 26+ Foundation Models) — COMPLETE but buggy

### What's Broken / Missing
1. **CloudLLMService**: Hardcoded ngrok URL + "Bearer changeme" — WILL BREAK
2. **ChatViewModel init**: Cloud-first fallback chain is COMMENTED OUT, forces CloudLLMService
3. **AppleIntelligenceService**: Creates new LanguageModelSession per send() — loses multi-turn context
4. **ActionView**: Passes nil for stressResult and baseline — chat gives generic advice
5. **isAvailable()**: Uses DispatchSemaphore (blocking MainActor) — will deadlock
6. **No LLM backend**: Original llm-gateway Python repo no longer exists
7. **Moya+Alamofire dependency**: Only used for LLM health check — overkill

---

## Architecture Decision: LLM Backend

**Option A: Use DS2API (existing at localhost:5001)**
- Already running in ~/telegram-ai-bot/
- Supports OpenAI-compatible endpoint
- No new infrastructure needed
- BUT: localhost only, not accessible from iOS devices in production

**Option B: Rebuild llm-gateway + deploy to Render**
- FastAPI SSE gateway (same pattern as original)
- Deploy to Render (free tier)
- Production URL, proper auth
- BUT: New infrastructure to maintain

**Option C: Cloud-first with Apple Intelligence fallback**
- Make AppleIntelligenceService the PRIMARY for iOS 26+ devices
- CloudLLMService as PRIMARY for iOS 17-25 devices
- Fix AppleIntelligenceService multi-turn bug
- Remove Moya/Alamofire, use plain URLSession
- Simplest path to production

**RECOMMENDED: Option C** — Zero external infrastructure needed for iOS 26+ devices. For pre-iOS 26, use DS2API or a simple cloud endpoint.

---

## Implementation Tasks

### TASK 1: Fix AppleIntelligenceService — Multi-turn Context [CRITICAL]
**Files:** `Services/LLM/AppleIntelligenceService.swift`
**Estimate:** 1 hour

Problem: `LanguageModelSession` is created fresh per `send()` call, losing conversation history.

Fix:
```swift
final class AppleIntelligenceService: LLMServiceProtocol, Sendable {
    // Store session as optional, re-use across calls
    // Use actor isolation or @MainActor for session management
    
    func send(messages: [ChatMessage], systemPrompt: String) async throws -> AsyncThrowingStream<String, Error> {
        // Create session ONCE, re-use for subsequent calls
        // Session maintains its own conversation history
    }
}
```

Key considerations:
- `LanguageModelSession` should be stored on the instance
- Thread safety: AppleIntelligenceService is `Sendable`, but LanguageModelSession may not be
- May need to wrap in an actor or use `@unchecked Sendable` with proper isolation
- Session should be reset when `clearConversation()` is called (need a `reset()` method on protocol)

### TASK 2: Remove Moya/Alamofire — Use Plain URLSession [CRITICAL]
**Files:** `Services/LLM/LLMAPITarget.swift`, `Services/LLM/CloudLLMService.swift`

Why: Moya+Alamofire are heavy dependencies used only for a health check. The actual streaming already uses plain URLSession. Remove the dependency entirely.

Changes:
1. Delete `LLMAPITarget.swift` entirely
2. Move health check into `CloudLLMService` using URLSession
3. Remove `import Moya` and `import Alamofire` from CloudLLMService
4. Remove Moya/Alamofire from Package.swift / SPM dependencies

### TASK 3: Fix CloudLLMService — Configurable Endpoint [CRITICAL]
**Files:** `Services/LLM/CloudLLMService.swift`
**Estimate:** 2 hours

Changes:
1. Replace hardcoded ngrok URL with configurable endpoint:
   ```swift
   // Read from UserDefaults/AppStorage (configurable in Settings)
   private let serverURL: String
   private let apiKey: String
   
   init(serverURL: String? = nil, apiKey: String? = nil) {
       self.serverURL = serverURL ?? UserDefaults.standard.string(forKey: "llm_server_url") ?? ""
       self.apiKey = apiKey ?? UserDefaults.standard.string(forKey: "llm_api_key") ?? ""
   }
   ```
2. Replace "Bearer changeme" with configurable API key
3. Fix `isAvailable()` — make it async, remove DispatchSemaphore:
   ```swift
   func isAvailable() async -> Bool {
       guard !serverURL.isEmpty else { return false }
       // Use async URLSession instead of semaphore
   }
   ```
   NOTE: This changes the protocol signature. `LLMServiceProtocol.isAvailable()` must become `async`.

### TASK 4: Fix LLMServiceProtocol — Async isAvailable [CRITICAL]
**Files:** `Services/LLM/LLMServiceProtocol.swift`

Change protocol:
```swift
protocol LLMServiceProtocol: Sendable {
    func isAvailable() async -> Bool  // was sync
    func send(messages: [ChatMessage], systemPrompt: String) async throws -> AsyncThrowingStream<String, Error>
    func reset()  // NEW: reset session/conversation context
}
```

Update all conforming types: AppleIntelligenceService, CloudLLMService, UnavailableLLMService.

### TASK 5: Fix ChatViewModel — Uncomment Fallback Chain [CRITICAL]
**Files:** `ViewModels/ChatViewModel.swift`
**Estimate:** 1.5 hours

Changes:
1. Uncomment the cloud-first fallback chain (lines 51-57)
2. Make it async since `isAvailable()` is now async:
   ```swift
   init(...) async {
       let cloudService = CloudLLMService()
       if await cloudService.isAvailable() {
           self.llmService = cloudService
       } else {
           self.llmService = AppleIntelligenceService()
       }
       self.isAvailable = await llmService.isAvailable()
   }
   ```
3. Since `@Observable @MainActor` init can't be async, consider:
   - Option A: Factory method `static func create(...) async -> ChatViewModel`
   - Option B: Two-phase init (create then `configure()` async method)
   - Option C: Check availability in `onAppear` / `.task {}`
4. Add `reset()` call when clearing conversation

### TASK 6: Wire Stress Data from ActionView [HIGH]
**Files:** `Views/Action/ActionView.swift`
**Estimate:** 30 min

Current:
```swift
ChatBottomSheetView(stressResult: nil, baseline: nil)
```

Fix: Pass real data from the environment/view model:
```swift
// ActionView needs access to StressViewModel or at least the current data
ChatBottomSheetView(
    stressResult: stressViewModel.currentStress,
    baseline: stressViewModel.currentBaseline,
    recentHistory: stressViewModel.recentMeasurements
)
```

### TASK 7: Add LLM Settings UI [HIGH]
**Files:** New or modify existing settings components
**Estimate:** 1 hour

- Server URL text field (for CloudLLMService)
- API key text field (secure)
- "Test Connection" button
- Show connection status
- Save to UserDefaults with AppStorage

Note: Journal mentions `AIChatSettingsCard.swift` was created but check if it still exists.

### TASK 8: Add LLM Service Tests [HIGH]
**Files:** New test file `StressMonitorTests/LLMServiceTests.swift`
**Estimate:** 1.5 hours

Test cases:
- SSEParser: valid content, [DONE], error, empty lines, non-data lines
- ChatContextBuilder: with/without stress data, with/without baseline, trend analysis
- ChatQuickActions: all categories, nil category
- ChatViewModel: send, cancel, clear, context trim, error handling
- MockLLMService for deterministic testing

### TASK 9: Add reset() to Protocol + Implementations [MEDIUM]
**Files:** `LLMServiceProtocol.swift`, all service implementations

Add `func reset()` to reset session state:
- AppleIntelligenceService: create new LanguageModelSession
- CloudLLMService: no-op (stateless)
- UnavailableLLMService: no-op

---

## File Change Summary

| File | Action | Priority |
|------|--------|----------|
| `Services/LLM/LLMAPITarget.swift` | DELETE | P0 |
| `Services/LLM/LLMServiceProtocol.swift` | MODIFY (async isAvailable + reset) | P0 |
| `Services/LLM/CloudLLMService.swift` | MODIFY (remove Moya, configurable URL, async isAvailable) | P0 |
| `Services/LLM/AppleIntelligenceService.swift` | MODIFY (session persistence, async isAvailable) | P0 |
| `ViewModels/ChatViewModel.swift` | MODIFY (uncomment fallback, async init, reset) | P0 |
| `Views/Action/ActionView.swift` | MODIFY (wire real data) | P1 |
| `Views/Chat/ChatBottomSheetView.swift` | MODIFY (handle async init) | P1 |
| Settings (LLM config UI) | CREATE or MODIFY | P1 |
| `StressMonitorTests/LLMServiceTests.swift` | CREATE | P1 |
| SPM Package dependencies | MODIFY (remove Moya/Alamofire) | P0 |

---

## Execution Order

```
Phase 1 (Core fixes — P0):
  1. Delete LLMAPITarget.swift
  2. Update LLMServiceProtocol (async isAvailable + reset)
  3. Rewrite CloudLLMService (plain URLSession, configurable endpoint)
  4. Fix AppleIntelligenceService (session persistence, async isAvailable)
  5. Fix ChatViewModel (uncomment fallback chain, handle async init)
  6. Remove Moya/Alamofire from SPM

Phase 2 (Integration — P1):
  7. Wire stress data in ActionView
  8. Add LLM settings UI
  9. Update ChatBottomSheetView for async init

Phase 3 (Testing — P1):
  10. Write LLM service tests
  11. Verify build passes
  12. Manual testing on simulator
```

---

## Known Gotchas

1. **@Observable init can't be async**: ChatViewModel uses @Observable. Need factory pattern or two-phase init.
2. **LanguageModelSession Sendability**: Foundation Models session may not be Sendable. May need actor wrapper.
3. **iOS 26 availability**: AppleIntelligenceService code uses `#if canImport(FoundationModels)` + `if #available(iOS 26, *)`. Both guards needed.
4. **Protocol change is breaking**: Changing `isAvailable()` to async requires updating ALL conforming types simultaneously.
5. **Moya removal**: Check if any other part of the app uses Moya/Alamofire before removing from SPM.
6. **CloudLLMService @MainActor**: Currently marked @MainActor with @unchecked Sendable. After removing Moya, check if @MainActor is still needed.

---

## Acceptance Criteria

- [ ] No hardcoded URLs or auth tokens in the codebase
- [ ] No Moya/Alamofire dependencies
- [ ] CloudLLMService reads endpoint from UserDefaults
- [ ] AppleIntelligenceService maintains conversation context across sends
- [ ] ChatViewModel uses fallback chain: Cloud → Apple Intelligence → Unavailable
- [ ] ActionView passes real stress data to ChatBottomSheetView
- [ ] isAvailable() is async (no DispatchSemaphore)
- [ ] All existing tests pass
- [ ] New LLM tests written and passing
- [ ] Build succeeds with zero new warnings
