# Phase 3: LLM Chat Service

**Priority:** Critical
**Status:** Pending
**Depends On:** Phase 1
**File Ownership:** `backend/app/routes/chat.py`, `backend/app/services/llm_service.py`, `backend/app/utils/sse.py`

## Overview

Implement OpenAI-compatible chat completions endpoint with SSE streaming.

## Files to Create/Modify

- `backend/app/utils/sse.py`
- `backend/app/services/llm_service.py`
- `backend/app/routes/chat.py`

## Implementation Steps

1. Create `utils/sse.py`:
   - SSE response formatter
   - OpenAI chunk format helper
2. Create `llm_service.py`:
   - LLM provider abstraction (OpenAI, Anthropic, local)
   - System prompt builder (stress coaching persona)
   - Streaming response handler
3. Create `routes/chat.py`:
   - `POST /v1/chat/completions` - OpenAI-compatible streaming
   - `GET /health` - Service health check
   - Inject user context (stress level, baseline) into system prompt

## API Contract (matches iOS SSEParser)

```json
// Request
POST /v1/chat/completions
{
  "model": "auto",
  "messages": [
    {"role": "system", "content": "..."},
    {"role": "user", "content": "..."}
  ],
  "stream": true
}

// Response (SSE)
data: {"choices":[{"delta":{"content":"token1"}}]}
data: {"choices":[{"delta":{"content":"token2"}}]}
data: [DONE]
```

## Success Criteria

- [ ] Endpoint accepts OpenAI-compatible request format
- [ ] Streaming response follows SSE protocol
- [ ] iOS SSEParser can parse the response
- [ ] System prompt includes stress coaching persona
- [ ] Error responses are properly formatted
