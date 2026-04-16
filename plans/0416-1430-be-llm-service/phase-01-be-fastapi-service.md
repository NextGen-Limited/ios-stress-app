# Phase 1: BE FastAPI Service

**Priority:** High
**Status:** Complete
**Effort:** Medium

## Context

- Design: [brainstorm report](../reports/brainstorm-0416-1430-be-llm-service-design.md)
- Separate repo: `~/Projects/next-labs/llm-gateway/`
- Reusable LLM proxy — not tied to ios-stress-app
- No existing code to modify — greenfield

## Overview

FastAPI backend with single SSE endpoint, configurable LLM provider, Bearer auth.

## Architecture

```
Request flow:
iOS App → POST /v1/chat/completions → ProviderRouter → {Gemini|GLM|MiniMax} SDK → SSE response

Config flow:
.env → config.py → provider factory → provider instance
```

## Requirements

### Functional
- `POST /v1/chat/completions` accepts `{ messages, system_prompt, stream }` 
- Returns SSE stream: `data: {"token": "..."}\n\n` → `data: [DONE]\n\n`
- Bearer token auth via `Authorization: Bearer <APP_API_KEY>`
- Provider selected by `LLM_PROVIDER` env var (gemini/glm/minimax)
- Graceful error responses (provider down, rate limit, context exceeded)

### Non-functional
- Streaming response (no buffering full response)
- Request timeout: 60s
- CORS enabled for local dev

## Files to Create

### 1. `llm-gateway/config.py`

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    llm_provider: str = "gemini"        # gemini | glm | minimax
    llm_api_key: str = ""
    llm_model: str = ""                 # model name, provider-specific
    app_api_key: str = "changeme"       # auth token for iOS app
    llm_base_url: str | None = None     # override for OpenAI-compatible endpoints

    class Config:
        env_file = ".env"

settings = Settings()
```

### 2. `llm-gateway/providers/base.py`

```python
from abc import ABC, abstractmethod
from typing import AsyncGenerator

class LLMProvider(ABC):
    @abstractmethod
    async def chat_stream(
        self, messages: list[dict], system_prompt: str
    ) -> AsyncGenerator[str, None]:
        """Yield tokens from the LLM."""
        ...
```

### 3. `llm-gateway/providers/gemini.py`

- Use `google-genai` SDK
- `gemini-2.0-flash` model default
- Convert messages to Gemini format (`contents` + `system_instruction`)
- Stream via `client.models.generate_content_stream()`
- Yield `chunk.text` tokens

### 4. `llm-gateway/providers/glm.py`

- ZhipuAI OpenAI-compatible endpoint
- Use `openai` SDK with `base_url="https://open.bigmodel.cn/api/paas/v4"`
- Model: `glm-4-flash` default
- Stream via `client.chat.completions.stream()`
- Yield `chunk.choices[0].delta.content`

### 5. `llm-gateway/providers/minimax.py`

- MiniMax OpenAI-compatible endpoint
- Use `openai` SDK with `base_url="https://api.minimax.chat/v1"`
- Model: `MiniMax-Text-01` default
- Stream via `client.chat.completions.stream()`
- Yield `chunk.choices[0].delta.content`

### 6. `llm-gateway/main.py`

```python
from fastapi import FastAPI, Header, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from config import settings
from providers import create_provider

app = FastAPI()

class ChatRequest(BaseModel):
    messages: list[dict]      # [{role: "user"|"assistant", content: "..."}]
    system_prompt: str
    stream: bool = True

def verify_auth(authorization: str = Header(...)):
    token = authorization.replace("Bearer ", "")
    if token != settings.app_api_key:
        raise HTTPException(401, "Invalid API key")

@app.post("/v1/chat/completions")
async def chat(request: ChatRequest, _auth=Depends(verify_auth)):
    provider = create_provider()
    return StreamingResponse(
        _stream_tokens(provider, request),
        media_type="text/event-stream"
    )

async def _stream_tokens(provider, request):
    async for token in provider.chat_stream(request.messages, request.system_prompt):
        yield f'data: {{"token": "{token}"}}\n\n'
    yield "data: [DONE]\n\n"
```

### 7. `llm-gateway/requirements.txt`

```
fastapi>=0.115.0
uvicorn>=0.34.0
pydantic-settings>=2.7.0
google-genai>=1.0.0
openai>=1.60.0
python-dotenv>=1.0.0
```

### 8. `llm-gateway/.env.example`

```
LLM_PROVIDER=gemini
LLM_API_KEY=your-api-key-here
LLM_MODEL=gemini-2.0-flash
APP_API_KEY=changeme
# LLM_BASE_URL=   # optional override
```

## Implementation Steps

1. Create `~/Projects/next-labs/llm-gateway/` repo with `providers/` subdirectory
2. Write `config.py` with pydantic-settings
3. Write `providers/base.py` abstract class
4. Write `providers/gemini.py` (primary target)
5. Write `providers/glm.py` (OpenAI-compatible adapter)
6. Write `providers/minimax.py` (OpenAI-compatible adapter)
7. Write `providers/__init__.py` factory function
8. Write `main.py` with FastAPI endpoint
9. Write `requirements.txt` and `.env.example`
10. Test: `uvicorn main:app --reload` → curl POST to verify SSE stream

## Success Criteria

- [ ] `POST /v1/chat/completions` returns SSE stream
- [ ] Gemini provider works end-to-end
- [ ] GLM provider works (OpenAI-compatible)
- [ ] MiniMax provider works (OpenAI-compatible)
- [ ] Invalid auth → 401
- [ ] Provider config swap via `.env` with restart only
- [ ] Token escaping handled (JSON special chars in token text)

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Gemini SDK streaming API differs from docs | Test with curl before iOS integration |
| Token contains `"` or `\n` breaking SSE | Use `json.dumps()` for token encoding |
| ZhipuAI endpoint auth format | Verify against ZhipuAI docs, may need JWT |
