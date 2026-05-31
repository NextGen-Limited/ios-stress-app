---
title: AI Chat Mode - Brainstorm Design Report
date: 2026-04-15
type: brainstorm
status: approved
author: claude-code
---

# AI Chat Mode - Brainstorm Design Report

## Summary

AI Chat Mode feature for StressMonitor app. Apple Intelligence (on-device LLM) as primary, cloud LLM fallback later. Bottom sheet overlay UI using exyte/Chat library. AI Kitten persona with full health data context.

## Problem Statement

Users need personalized, conversational guidance about their stress levels, health data, and wellness strategies. Current app provides metrics and rule-based insights but no interactive coaching or Q&A capability.

## User Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Purpose | Stress coach + wellness Q&A + data analyst | Comprehensive AI companion |
| LLM Provider (Phase 1) | Apple Intelligence (Foundation Models) | Privacy-first, free, on-device |
| LLM Provider (Phase 2) | Cloud LLM (OpenAI/Claude) via backend proxy | Expand to iOS 17-25 devices |
| Data Access | Full stress/health context | Personalized advice requires real data |
| Backend (MVP) | None (on-device only) | Apple Intelligence runs locally |
| Backend (Later) | Direct API → backend proxy migration | Protocol swap, minimal rewrite |
| Chat UI | Bottom sheet overlay (exyte/Chat) | User stays on current view |
| Chat Persistence | Pro feature (implement later) | MVP keeps session-only |
| Persona | AI Kitten (existing mascot) | Consistent branding |

## Evaluated Approaches

### Approach A: Cloud LLM with Provider Abstraction (Rejected for Phase 1)

**Pros:** Works on all iOS 17+ devices, better reasoning quality, clear migration path
**Cons:** First external API dependency, API key security risk, health data leaves device, cost ~$0.80/user/month
**Why rejected:** User prefers privacy-first approach, zero cost, and the app's architectural principle of no external servers

### Approach B: Apple Intelligence Only (Chosen for Phase 1)

**Pros:** Free, zero privacy risk, native Swift integration, on-device, no backend needed
**Cons:** iOS 26+ only (~30% devices at launch), A17 Pro+ chips only, 4K token context limit, limited reasoning for complex health questions
**Why chosen:** Aligns with privacy-first architecture, zero dependencies, zero cost

### Approach C: Hybrid (Deferred to Phase 2)

**Pros:** Best coverage, graceful degradation
**Cons:** Two LLM backends to maintain, different response quality levels, highest complexity
**Why deferred:** Ship faster on new devices first, add cloud fallback when user demand warrants it

## Recommended Architecture

### Component Overview

```
┌─────────────────────────────────────────┐
│           ActionView / Dashboard        │
│         (AIChatCard tap triggers)        │
└───────────────┬─────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│        ChatBottomSheetView              │
│   (exyte/Chat in .sheet modifier)       │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  ChatView (exyte/Chat)          │    │
│  │  - AI Kitten avatar on AI msgs  │    │
│  │  - Quick action chips at top    │    │
│  │  - Streaming token display      │    │
│  │  - Custom message cells         │    │
│  └─────────────────────────────────┘    │
└───────────────┬─────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│         ChatViewModel                   │
│  - Message state management             │
│  - Streaming response handling          │
│  - Quick action triggers                │
│  - Session lifecycle                    │
└───────────┬─────────────────────────────┘
            │
    ┌───────┴──────────┐
    ▼                  ▼
┌────────────┐  ┌──────────────────┐
│ LLMService │  │ ChatContextBuilder│
│ Protocol   │  │ - Stress data    │
│            │  │ - HRV trends     │
│            │  │ - Sleep/activity  │
│            │  │ - System prompt  │
└─────┬──────┘  └──────────────────┘
      │
      ▼
┌─────────────────────┐
│AppleIntelligence    │ ← Phase 1
│Service              │
│(Foundation Models)  │
└─────────────────────┘
      │ (later)
      ▼
┌─────────────────────┐
│CloudLLMService      │ ← Phase 2
│(OpenAI/Claude API)  │
└─────────────────────┘
```

### File Structure (New Files)

```
StressMonitor/
├── Services/
│   └── LLM/
│       ├── LLMServiceProtocol.swift        # Protocol + types (ChatMessage, ChatRole, LLMResponse)
│       ├── AppleIntelligenceService.swift   # Foundation Models implementation
│       ├── ChatContextBuilder.swift         # Health data → system prompt assembler
│       └── ChatQuickActions.swift           # Pre-built prompt definitions
├── ViewModels/
│   └── ChatViewModel.swift                 # Chat state, message management, streaming
├── Views/
│   └── Chat/
│       ├── ChatBottomSheetView.swift        # Bottom sheet wrapper with exyte/Chat
│       ├── ChatMessageAdapter.swift         # Map between exyte/Chat Message and our models
│       └── QuickActionChipsView.swift       # Suggestion prompt chips UI
└── Models/
    └── ChatMessage.swift                    # Chat message value type (not SwiftData for MVP)
```

### Key Protocols

```swift
// LLMServiceProtocol.swift
protocol LLMServiceProtocol {
    func send(messages: [ChatMessage], context: ChatContext) async throws -> AsyncThrowingStream<String, Error>
    func isAvailable() -> Bool
}

// ChatMessage.swift
enum ChatRole { case user, assistant, system }
struct ChatMessage: Identifiable {
    let id: UUID
    let role: ChatRole
    let content: String
    let timestamp: Date
}
```

### System Prompt Strategy (4K Token Budget)

Given Apple Intelligence's 4K token context limit, the system prompt must be efficient:

| Component | Est. Tokens | Content |
|-----------|-------------|---------|
| Persona instructions | ~200 | "You are AI Kitten, a friendly wellness companion..." |
| Current stress data | ~150 | Stress level, category, HRV, heart rate, confidence |
| Recent trend summary | ~100 | "Stress trending up over last 3 hours" |
| Available data flags | ~50 | "Sleep data available, Activity data available" |
| Response guidelines | ~100 | "Be supportive, suggest breathing exercises when high stress..." |
| **Total context** | **~600** | **Leaves ~3400 tokens for conversation** |

### Quick Action Suggestions (MVP)

Pre-built prompts for common interactions:

| Prompt | Purpose |
|--------|---------|
| "Why am I stressed?" | Analyzes current factors contributing to stress |
| "How's my sleep affecting me?" | Sleep-stress correlation analysis |
| "Suggest a breathing exercise" | Context-aware breathing recommendations |
| "Analyze my trends" | 7-day pattern analysis |
| "What can I do right now?" | Immediate actionable advice based on current state |

### exyte/Chat Integration

**Package dependency:** Add via Swift Package Manager
- URL: `https://github.com/exyte/Chat.git`
- This is the project's FIRST external dependency - significant architectural change

**Customization needed:**
- Custom `messageBuilder` for AI Kitten avatar on assistant messages
- Custom `inputViewBuilder` for quick action chips above input bar
- Map our `ChatMessage` model ↔ exyte's `Message`/`DraftMessage` types
- Wrap `ChatView` in a `.sheet` modifier for bottom sheet presentation

### Fallback for Non-Apple Intelligence Devices

On devices without Apple Intelligence support (iOS <26 or non-A17 Pro+ chips):
- Show `AIChatCard` with "AI Chat requires iOS 26" message
- OR: Show the chat UI with a static "Coming soon to your device" placeholder
- This will be resolved in Phase 2 when cloud LLM is added

### Data Flow

```
User taps "Chat with StressCat" on AIChatCard
    → ActionView presents ChatBottomSheetView as .sheet
    → ChatViewModel initializes with ChatContext (stress data, trends)
    → User types message or taps quick action
    → ChatViewModel builds full message array + system prompt via ChatContextBuilder
    → LLMServiceProtocol.send() called
    → AppleIntelligenceService streams response tokens
    → ChatViewModel updates messages array
    → ChatView (exyte/Chat) renders new message with streaming text
```

## Phase Plan

| Phase | Scope | Status |
|-------|-------|--------|
| Phase 1 (MVP) | Apple Intelligence + exyte/Chat bottom sheet + quick actions + session-only chat | Upcoming |
| Phase 2 | Cloud LLM service (OpenAI/Claude) for iOS 17-25 device support | Deferred |
| Phase 3 | Chat persistence (SwiftData) as Pro feature | Deferred |
| Phase 4 | Backend proxy for cloud LLM (API key security) | Deferred |

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| exyte/Chat API doesn't fit AI chat use case well | Medium | Custom messageBuilder/inputViewBuilder, may need forking |
| 4K token context too tight for health data + conversation | Medium | Efficient context builder, truncate old messages |
| Apple Intelligence quality insufficient for nuanced health advice | Medium | Phase 2 cloud LLM handles complex queries |
| First external dependency breaks zero-dep principle | Low-Medium | Isolate exyte/Chat behind adapter, easy to swap later |
| iOS 26+ requirement cuts user base | High | Phase 2 cloud fallback addresses this |
| Health advice liability | High | Clear disclaimer, not medical advice, wellness coaching only |

## Trade-off Acknowledged

Using exyte/Chat library introduces the project's first external dependency, which conflicts with the "Dependencies: None - system frameworks only" principle in CLAUDE.md. The adapter pattern (`ChatMessageAdapter`) isolates this dependency so it can be swapped if needed.

## Unresolved Questions

1. **watchOS support**: Apple Intelligence on watchOS unclear. Should chat be iPhone-only?
2. **Content moderation**: How to handle health-related queries that edge into medical advice?
3. **Stream cancellation**: What happens when user dismisses bottom sheet mid-response?
4. **Demo mode**: How does AI chat work in simulator demo mode without Apple Intelligence?
5. **exyte/Chat version pinning**: Which version to use, and how to handle breaking updates?
6. **Token counting**: Need accurate token counting for context window management within 4K limit?
