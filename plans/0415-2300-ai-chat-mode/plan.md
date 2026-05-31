# AI Chat Mode - Implementation Plan

**Date:** 2026-04-15
**Status:** Complete
**blockedBy:** 0415-2219-aichat-card-figma-alignment (ActionView.swift + AIChatCard.swift)
**Design:** [brainstorm-0415-2300-ai-chat-mode-design.md](../reports/brainstorm-0415-2300-ai-chat-mode-design.md)

## Overview

Add conversational AI chat to StressMonitor via Apple Intelligence (iOS 26+ Foundation Models). Bottom sheet overlay with exyte/Chat library. AI Kitten persona receives full health/stress context. Session-only persistence (Pro later).

## Phases

| # | Phase | Status | Files |
|---|-------|--------|-------|
| 1 | Models + LLM Protocol | Complete | `ChatMessage.swift`, `LLMServiceProtocol.swift` |
| 2 | LLM Service Layer | Complete | `AppleIntelligenceService.swift`, `ChatContextBuilder.swift`, `ChatQuickActions.swift` |
| 3 | Chat UI Layer | Complete | `ChatViewModel.swift`, `ChatBottomSheetView.swift`, `QuickActionChipsView.swift` |
| 4 | Integration + Navigation | Complete | `ActionView.swift` |

## Dependencies

- Phase 1 -> Phase 2 -> Phase 3 -> Phase 4 (sequential)
- Cross-plan: `0415-2219-aichat-card-figma-alignment` must complete before Phase 4 (ActionView.swift ownership)

## Key Decisions (Final)

- **LLM:** Apple Intelligence Foundation Models (iOS 26+), protocol for future cloud swap
- **UI:** Native SwiftUI chat UI in `.sheet` modifier (bottom sheet) -- exyte/Chat dropped in favor of native implementation
- **Persona:** AI Kitten with health data context via ChatContextBuilder
- **Persistence:** Session-only (no SwiftData for chat in MVP)
- **Fallback:** Graceful "requires iOS 26" message on older devices
- **Streaming:** `AsyncThrowingStream<String, Error>` adapter in `AppleIntelligenceService`
- **Error handling:** All `GenerationError` cases handled via `LLMServiceError` enum
- **Quick actions:** Pre-built prompt suggestions via `ChatQuickActions`

## File Ownership (New)

```
Models/ChatMessage.swift
Services/LLM/LLMServiceProtocol.swift
Services/LLM/AppleIntelligenceService.swift
Services/LLM/ChatContextBuilder.swift
Services/LLM/ChatQuickActions.swift
ViewModels/ChatViewModel.swift
Views/Chat/ChatBottomSheetView.swift
Views/Chat/QuickActionChipsView.swift
```

## File Ownership (Modified)

```
Views/Action/ActionView.swift  (Phase 4 only, after cross-plan clears)
```

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| exyte/Chat API mismatch | Medium | Adapter pattern isolates dependency |
| 4K token context too tight | Medium | Efficient context builder, truncate old messages |
| iOS 26+ cuts user base | High | Phase 2 cloud LLM addresses this |
| Health advice liability | High | Disclaimer, wellness coaching only, not medical |
| `ResponseStream` != `AsyncThrowingStream` | Medium | Adapter layer in AppleIntelligenceService (verified via xcdocs API audit) |
| 7 GenerationError cases, plan only handled 3 | Medium | Expand error handling switch in AppleIntelligenceService |
