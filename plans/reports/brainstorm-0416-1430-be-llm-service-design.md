# Brainstorm: BE LLM Service for AI Chat

**Date:** 2026-04-16
**Status:** Approved → Planning

## Problem

AI Chat mode currently only works on iOS 26+ via on-device Foundation Models. Need cloud LLM backend to:
1. Support pre-iOS 26 devices
2. Use cheaper models (GLM, MiniMax, Gemini Flash)

## Constraints

- **Tech stack:** Python (FastAPI)
- **Hosting:** Self-hosted (home/local)
- **Provider strategy:** Single configurable provider (YAGNI)
- **Target providers:** Gemini Flash (primary), GLM (ZhipuAI), MiniMax
- **iOS integration:** Must implement existing `LLMServiceProtocol`

## Architecture

```
iOS App                              Self-hosted BE (FastAPI)
┌──────────────────┐                 ┌─────────────────────────┐
│ LLMServiceProtocol│                 │ POST /v1/chat/completions│
│ ┌───────────────┐ │   HTTP/SSE      │                         │
│ │CloudLLMService├─┼────────────────►│ Provider Router         │
│ │  (new)        │◄├─────────────────│  ├─ Gemini Flash        │
│ └───────────────┘ │  token stream   │  ├─ GLM (ZhipuAI)       │
│ ┌───────────────┐ │                 │  └─ MiniMax             │
│ │AppleIntelligence│ │  on-device      │                         │
│ │  (existing)    │ │                 │ Config (.env)           │
│ └───────────────┘ │                 │ LLM_API_KEY=...         │
└──────────────────┘                 │ LLM_PROVIDER=gemini     │
                                     │ LLM_MODEL=gemini-2.0... │
                                     └─────────────────────────┘
```

## iOS Provider Selection Logic

```swift
if cloudService.isReachable() {
    self.llmService = cloudService      // Prefer cloud (all iOS versions)
} else if #available(iOS 26, *) {
    self.llmService = AppleIntelligenceService()  // Fallback on-device
} else {
    self.llmService = UnavailableLLMService()
}
```

## API Contract

```
POST /v1/chat/completions
Content-Type: application/json
Authorization: Bearer <app-api-key>

Request:
{ "messages": [{"role": "user", "content": "..."}],
  "system_prompt": "You are AI Kitten...",
  "stream": true }

Response: SSE stream
data: {"token": "Hello"}
data: {"token": "!"}
data: [DONE]
```

## BE Structure

```
be-llm-service/
├── main.py              # FastAPI app, /v1/chat/completions
├── providers/
│   ├── base.py          # Abstract provider protocol
│   ├── gemini.py        # Gemini Flash via google-genai
│   ├── glm.py           # GLM via ZhipuAI (OpenAI-compatible)
│   └── minimax.py       # MiniMax via OpenAI-compatible endpoint
├── config.py            # .env → provider selection, API keys
├── requirements.txt
└── .env
```

## Concerns & Mitigations

| Concern | Mitigation |
|---------|-----------|
| ATS (HTTPS required) | Cloudflare Tunnel / ngrok for local HTTPS |
| Auth | Simple APP_API_KEY, Bearer token |
| Availability | iOS reachability check → fallback to on-device |
| Provider swap | .env change, restart, zero code changes |

## Out of Scope (YAGNI)

- No user management / auth system
- No usage analytics / billing
- No request queuing / priority
- No admin dashboard
- No multi-model routing per request

## Decisions

- FastAPI for async streaming support + Python ecosystem
- OpenAI-compatible request format for provider interchangeability
- SSE (Server-Sent Events) for streaming (native iOS URL loading support)
- Cloud-first, on-device fallback strategy
