---
name: BE LLM Service for AI Chat
status: complete
created: 2026-04-16
updated: 2026-04-16
author: phuongddx
blockedBy: []
blocks: []
---

# BE LLM Service — Implementation Plan

**Design:** [brainstorm-0416-1430-be-llm-service-design.md](../reports/brainstorm-0416-1430-be-llm-service-design.md)

## Overview

Add self-hosted FastAPI backend (separate repo) + iOS client integration for AI Chat, enabling pre-iOS 26 support and cheaper model options (GLM, MiniMax, Gemini Flash). Plugs into existing `LLMServiceProtocol`.

## Repo Split

| Repo | Location | Purpose |
|------|----------|---------|
| **llm-gateway** | `~/Projects/next-labs/llm-gateway/` | FastAPI backend (reusable for other apps) |
| **ios-stress-app** | `~/Projects/next-labs/ios-stress-app/` | iOS CloudLLMService + integration |

## Phases

| # | Phase | Repo | Status | Effort |
|---|-------|------|--------|--------|
| 1 | FastAPI Gateway Service | `llm-gateway` | Complete | Medium |
| 2 | iOS CloudLLMService | `ios-stress-app` | Complete | Medium |
| 3 | Integration & Settings | `ios-stress-app` | Complete | Small |

## Dependencies

- Phase 1 (llm-gateway) must be built and running before Phase 2 can test
- Phase 2 → Phase 3 (integration needs CloudLLMService)
- Cross-plan: extends `0415-2300-ai-chat-mode` (Complete)

## Key Decisions

- **Project name:** `llm-gateway` (reusable LLM proxy for multiple apps)
- **Tech:** Python FastAPI, self-hosted locally, Cloudflare Tunnel for HTTPS
- **Provider strategy:** Single configurable via `.env` (Gemini Flash / GLM / MiniMax)
- **iOS integration:** Cloud-first, on-device fallback via `LLMServiceProtocol`
- **Auth:** Simple Bearer token (APP_API_KEY)
- **Streaming:** SSE (`data: {"token": "..."}\n\n`)
- **Config:** `@AppStorage` for server URL + API key on iOS side

## File Ownership (llm-gateway repo — Phase 1)

```
~/Projects/next-labs/llm-gateway/
├── main.py
├── config.py
├── requirements.txt
├── .env.example
├── providers/
│   ├── __init__.py
│   ├── base.py
│   ├── gemini.py
│   ├── glm.py
│   └── minimax.py
└── README.md
```

## File Ownership (ios-stress-app repo — Phases 2-3)

```
Services/LLM/CloudLLMService.swift          (NEW)
ViewModels/ChatViewModel.swift              (MODIFY — cloud-first init)
Views/Settings/Components/AIChatSettingsCard.swift  (NEW — optional)
Views/Settings/SettingsView.swift           (MODIFY — add AI Chat settings)
```

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Local BE intermittent | Medium | Reachability check + on-device fallback |
| ATS requires HTTPS | Medium | Cloudflare Tunnel for free HTTPS |
| Provider SDK changes | Low | OpenAI-compatible format as abstraction |
| API key in iOS binary | Low | Acceptable for personal-use app |
