# Phase 3: Integration & Settings

**Priority:** High
**Status:** Complete
**Effort:** Small
**Depends on:** Phase 2

## Context

- `CloudLLMService` from Phase 2 implements `LLMServiceProtocol`
- `ChatViewModel` currently hardcodes: iOS 26 → AppleIntelligence, else → Unavailable
- Need to add cloud-first selection logic and server config in Settings

## Overview

Wire `CloudLLMService` into `ChatViewModel` with cloud-first fallback chain. Add minimal server URL/API key config.

## Requirements

### Functional
- ChatViewModel tries cloud → on-device → unavailable (in that order)
- Server URL and API key stored via `@AppStorage`
- Settings section for AI Chat server configuration
- BE health endpoint for reachability

### Non-functional
- No UI disruption to existing chat flow
- Settings changes take effect on next chat session (no hot-reload needed)

## Files to Modify

### 1. `ViewModels/ChatViewModel.swift`

Current init logic (lines 49-56):
```swift
if #available(iOS 26, *) {
    self.llmService = AppleIntelligenceService()
} else {
    self.llmService = UnavailableLLMService()
}
```

New logic:
```swift
// Cloud-first strategy
let serverURL = UserDefaults.standard.string(forKey: "ai_server_url") ?? ""
let apiKey = UserDefaults.standard.string(forKey: "ai_api_key") ?? ""

if !serverURL.isEmpty {
    let cloudService = CloudLLMService(serverURL: serverURL, apiKey: apiKey)
    if cloudService.isAvailable() {
        self.llmService = cloudService
    } else if #available(iOS 26, *) {
        self.llmService = AppleIntelligenceService()
    } else {
        self.llmService = UnavailableLLMService()
    }
} else if #available(iOS 26, *) {
    self.llmService = AppleIntelligenceService()
} else {
    self.llmService = UnavailableLLMService()
}
```

### 2. `llm-gateway/main.py` (add health endpoint) — in separate repo

Add one line:
```python
@app.get("/health")
async def health():
    return {"status": "ok"}
```

### 3. `Views/Settings/SettingsView.swift` (optional, minimal)

Add an "AI Chat" settings section with:
- Server URL text field (`@AppStorage("ai_server_url")`)
- API Key secure field (`@AppStorage("ai_api_key")`)

Keep it minimal — a new `AIChatSettingsCard` view in `Views/Settings/Components/`.

## Implementation Steps

1. Add `/health` endpoint to `main.py`
2. Modify `ChatViewModel.init` with cloud-first selection logic
3. Create `AIChatSettingsCard.swift` with server URL + API key fields
4. Add `AIChatSettingsCard` to `SettingsView`
5. Build and verify chat works with cloud → on-device → unavailable chain

## Success Criteria

- [ ] With server URL configured + BE running: cloud LLM used
- [ ] With server URL configured + BE down: falls back to on-device (iOS 26) or unavailable
- [ ] Without server URL: uses AppleIntelligence (iOS 26) or unavailable (same as before)
- [ ] Settings card shows server URL and API key fields
- [ ] Settings persist across app restarts
- [ ] No regression to existing on-device chat flow

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| `isAvailable()` blocks main thread | Use `nonisolated` with synchronous URLSession check + short timeout |
| Settings UI bloat | Keep minimal — 2 fields only, no advanced config |
| UserDefaults key collision | Use prefixed keys: `ai_server_url`, `ai_api_key` |
