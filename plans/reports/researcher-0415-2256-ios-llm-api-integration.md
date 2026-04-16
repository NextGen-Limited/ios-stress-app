# Research Report: iOS LLM API Integration for Health Coaching Chat

**Date:** 2026-04-15
**Project:** StressMonitor (iOS 17+ SwiftUI)
**Scope:** Cloud LLM API integration patterns, provider comparison, security, cost, streaming

---

## 1. Recommended Pattern: URLSession + Protocol Abstraction

**Approach:** Use Swift's native `URLSession` with async/await, abstracted behind a protocol.

### Core Architecture

```
LLMServiceProtocol (protocol)
    |-- DirectLLMService (MVP: calls API directly)
    |-- ProxyLLMService  (later: calls your backend)
```

**Why URLSession, not a third-party SDK:**
- Zero dependencies (matches project's "system frameworks only" constraint)
- Full control over SSE parsing, retry logic, error handling
- Easy to swap provider or add proxy layer later
- `URLSession.shared.bytes(for:)` gives native async byte streams (iOS 15+)

### Minimal Implementation Pattern

```swift
protocol LLMServiceProtocol: Sendable {
    func send(messages: [ChatMessage]) async throws -> ChatResponse
    func stream(messages: [ChatMessage]) -> AsyncThrowingStream<String, Error>
}

actor DirectLLMService: LLMServiceProtocol {
    private let session = URLSession.shared
    private let apiKey: String  // from Keychain at runtime
    
    func stream(messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                var request = URLRequest(url: endpoint)
                request.httpMethod = "POST"
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try encode(messages)
                
                let (bytes, _) = try await session.bytes(for: request)
                for try await line in bytes.lines {
                    guard line.hasPrefix("data: "),
                          let json = line.dropFirst(6).data(using: .utf8),
                          let chunk = try? JSONDecoder().decode(SSEChunk.self, from: json)
                    else { continue }
                    
                    if chunk.isDone { continuation.finish(); return }
                    if let text = chunk.deltaText { continuation.yield(text) }
                }
                continuation.finish()
            }
        }
    }
}
```

**Ranking: RECOMMENDED** for this project. No deps, full control, protocol-based swap to proxy later.

---

## 2. Streaming SSE in Swift

### How SSE Works

Both OpenAI and Anthropic use Server-Sent Events for streaming. Format:

```
event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}
```

**OpenAI stream format:** `data: {"choices":[{"delta":{"content":"Hello"}}]}` with `data: [DONE]` sentinel.

**Anthropic stream format:** `event: content_block_delta` / `data: {...}` with `event: message_stop` sentinel.

### Swift Implementation

```swift
// Using URLSession.bytes (iOS 15+)
let (bytes, response) = try await URLSession.shared.bytes(for: request)
for await line in bytes.lines {
    if line.hasPrefix("data: ") {
        let payload = String(line.dropFirst(6))
        if payload == "[DONE]" { break }  // OpenAI sentinel
        // parse JSON delta
    }
    // Anthropic also sends "event: " lines -- parse separately
}
```

**Key gotchas:**
- Anthropic uses BOTH `event:` AND `data:` lines per SSE spec. OpenAI only uses `data:` lines.
- Must handle `:comment` lines (keep-alive pings)
- Must handle `event: error` with `overloaded_error` (529 equivalent)
- Cancellation: `URLSession` task cancels when the async for-loop breaks

**No native SSE parser in Foundation.** Options:
1. Write your own (50-80 lines, fine for single-provider)
2. Use community lib `EventSource` (~500 stars) -- adds a dependency
3. Use MacPaw/OpenAI SDK streaming (handles parsing internally)

**Recommendation:** Write minimal SSE parser inline. The format is simple, and you avoid dependency for ~60 lines of code.

---

## 3. API Key Security: Critical Problem

### The Hard Truth

**Any API key embedded in an iOS app CAN and WILL be extracted.** Tools like `strings`, Hopper, or Frida make this trivial. Obfuscation only slows attackers down.

### Risk Assessment for This Project

| Approach | Security | Complexity | Cost |
|----------|----------|------------|------|
| Hardcode in binary | ZERO - trivially extracted | Minimal | $0 |
| Keychain storage | LOW - still ships with app | Low | $0 |
| .xcconfig + Info.plist | ZERO - plaintext in bundle | Low | $0 |
| Obfuscation (SwiftShield etc.) | LOW - reversible | Medium | $0 |
| Backend proxy | HIGH - key never touches device | Medium | Server costs |
| Runtime fetch from your server | MEDIUM-HIGH | Medium | Server costs |

### Recommended Approach for StressMonitor

**Phase 1 (MVP):** Accept the risk knowingly. Use Keychain + obfuscation for dev/testing only. Ship with a spending cap on the API key. This is the ONLY safe way to go direct-to-API.

**Phase 2 (Production):** Build a lightweight backend proxy. This is the ONLY production-safe approach.

```
iOS App --> Your Backend (Lambda/Cloud Run) --> LLM API
              ^--- API key lives here only ---^
```

**Additional mitigations (defense in depth):**
- Set strict spending caps on API keys
- Rotate keys frequently
- Use Apple App Attest (iOS 14+) to verify genuine app requests
- Rate-limit per device via DeviceCheck

---

## 4. Cost Estimates: Health Coaching Chat (~20 msgs/day/user)

### Token Assumptions per Message

| Component | Tokens (approx) |
|-----------|----------------|
| System prompt (health context) | 300-500 |
| Conversation history (avg 5 msg window) | 400-800 |
| User message | 50-100 |
| AI response | 100-200 |
| **Total per request** | **~850-1600** |

### Per-User Monthly Cost

**Conservative estimate: 1500 tokens/req * 20 msgs/day * 30 days = 900K tokens/month**

| Provider | Model | Input/1M | Output/1M | Monthly/User |
|----------|-------|----------|-----------|--------------|
| OpenAI | GPT-4.1 nano | $0.20 | $1.25 | **~$0.80** |
| OpenAI | GPT-4.1 mini | $0.75 | $4.50 | **~$2.70** |
| OpenAI | GPT-5.4 | $2.50 | $15.00 | **~$9.00** |
| Anthropic | Claude 3.5 Haiku | $0.80 | $4.00 | **~$2.20** |
| Anthropic | Claude 3.7 Sonnet | $3.00 | $15.00 | **~$8.10** |

**Assumes 70% input / 30% output split, ~630K input + 270K output tokens.**

### Scaling Estimates

| Users | GPT-4.1 nano | Claude 3.5 Haiku | GPT-4.1 mini |
|-------|-------------|------------------|--------------|
| 100 | $80/mo | $220/mo | $270/mo |
| 1,000 | $800/mo | $2,200/mo | $2,700/mo |
| 10,000 | $8,000/mo | $22,000/mo | $27,000/mo |

**Recommendation:** Start with **GPT-4.1 nano** or **Claude 3.5 Haiku** for the coaching chat. Health coaching responses don't require frontier reasoning. Move to stronger models only if quality is insufficient.

### Cost Optimization Tactics

1. **Prompt caching** -- OpenAI caches at $0.02-0.25/1M (90% discount). System prompt is identical every request.
2. **Sliding context window** -- Only send last N messages, not full history.
3. **Max tokens limit** -- Set `max_tokens` to 200-300. Coaching responses should be concise.
4. **Batch non-urgent requests** -- OpenAI Batch API is 50% cheaper (24hr turnaround).

---

## 5. Provider Comparison: Health/Wellness Coaching

### Model Quality for Health Coaching

| Dimension | OpenAI GPT-4.1 nano/mini | Anthropic Claude 3.5 Haiku | Winner |
|-----------|--------------------------|---------------------------|--------|
| Empathy/tone in health context | Good | Excellent | Claude |
| Following system prompt instructions | Very good | Very good | Tie |
| Safety guardrails (medical advice) | Good (built-in) | Strong (Constitutional AI) | Claude |
| Latency (first token) | Fast (~300ms) | Fast (~350ms) | OpenAI |
| Structured output (JSON mode) | Yes | Yes | Tie |
| Multilingual | Yes | Yes | Tie |
| Cost efficiency | Best (nano) | Good (Haiku) | OpenAI |
| Context window | 128K | 200K | Claude |

### Concrete Recommendation

**For the StressMonitor AI Kitten coaching chat:**

1. **Primary: OpenAI GPT-4.1 nano** -- cheapest, fast, good enough for empathetic coaching. The "AI Kitten" persona is simple enough that nano handles it well.
2. **Upgrade path: Claude 3.5 Haiku** -- if quality testing shows nano responses feel robotic or generic.
3. **Avoid: GPT-5.4 or Claude 3.7 Sonnet** -- overkill for a coaching chatbot, 5-10x more expensive.

**Why Claude edges for health/wellness:** Claude's training emphasizes helpfulness without being preachy, and its Constitutional AI approach gives stronger refusal behavior for medical advice (important for liability). But the cost difference means you should A/B test nano first.

### Anthropic's Official Swift SDK Status

Anthropic has a Swift SDK repository at `github.com/anthropics/anthropic-sdk-swift` but it requires authentication to view (private/invite-only as of April 2026). The official docs list Python and TypeScript SDKs as primary.

### OpenAI Official Swift SDK Status

The `github.com/openai/openai-swift` repo returns 404 -- OpenAI does NOT currently maintain an official Swift SDK. The OpenAI OpenAPI spec is available at `github.com/openai/openai-openapi` for code generation.

**Community alternatives:**
- **MacPaw/OpenAI** -- Most popular (2.4K+ stars), actively maintained, supports Chat Completions, Responses API, streaming, structured outputs, function calling. Works with OpenAI-compatible providers (Gemini, DeepSeek, Perplexity, OpenRouter) via `.relaxed` parsing mode.
- **Custom URLSession** -- Zero dependency, full control.

**Recommendation for this project:** Custom URLSession + protocol abstraction. Rationale:
- Project policy: "Dependencies: None - system frameworks only"
- You only need chat completions + streaming, not the full API surface
- Protocol-based design means you CAN add MacPaw/OpenAI later without rewriting

---

## 6. Backend Proxy Migration Architecture

### Protocol-Based Design (Swappable Without Rewriting)

```swift
// 1. Define protocol
protocol LLMServiceProtocol: Sendable {
    func stream(messages: [ChatMessage]) -> AsyncThrowingStream<String, Error>
}

// 2. Direct implementation (Phase 1)
struct DirectOpenAIService: LLMServiceProtocol {
    let apiKey: String
    func stream(messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        // Calls api.openai.com directly
    }
}

// 3. Proxy implementation (Phase 2)
struct ProxyLLMService: LLMServiceProtocol {
    let baseURL: URL  // your-backend.com
    func stream(messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        // Calls your-backend.com/api/chat
    }
}

// 4. ViewModel doesn't change
@Observable
class AIChatViewModel {
    let service: LLMServiceProtocol  // injected
    
    func sendMessage(_ text: String) async {
        for try await chunk in service.stream(messages: conversation) {
            response += chunk
        }
    }
}
```

**Migration cost: ONE new struct, ZERO ViewModel changes.**

### What the Backend Proxy Should Do

1. Hold the LLM API key server-side
2. Validate requests (auth, rate limiting, content filtering)
3. Forward to LLM API
4. Stream SSE response back to client unchanged
5. Log usage per user/device
6. Optional: inject additional system prompt context server-side

**Simplest backend:** AWS Lambda function URL or Cloud Run, ~50 lines of code.

---

## 7. Swift SDKs for LLM Providers

| SDK | Type | Status | Streaming | SPM | Notes |
|-----|------|--------|-----------|-----|-------|
| OpenAI official | N/A | **Does not exist** (404) | N/A | N/A | Only Python/TS SDKs |
| MacPaw/OpenAI | Community | Active, 2.4K stars | Yes | Yes | Best community option |
| Anthropic official | Official | Private repo | Unknown | Unknown | Not publicly accessible |
| Custom URLSession | Self | You own it | Manual | N/A | Recommended for this project |

**MacPaw/OpenAI key features (if needed later):**
- Chat Completions + new Responses API
- Streaming via `chatsStream(query:)` -- returns `AsyncThrowingStream`
- Structured outputs (JSON schema)
- Function calling / tool use
- MCP (Model Context Protocol) support
- Multi-provider support (Gemini, DeepSeek, Perplexity) via `.relaxed` mode
- Swift Concurrency (async/await), Combine, and closure APIs

---

## 8. Building Conversation Context with System Prompts

### System Prompt Architecture for Health Coaching

```swift
func buildMessages(userInput: String, healthContext: HealthSnapshot) -> [ChatMessage] {
    var messages: [ChatMessage] = []
    
    // System prompt with health context
    messages.append(.system("""
    You are AI Kitten, a friendly stress management companion. \
    You help users understand their stress patterns and suggest coping strategies.
    
    Current health data:
    - Stress level: \(healthContext.stressLevel)/100 (\(healthContext.stressCategory))
    - HRV: \(healthContext.hrv)ms
    - Heart rate: \(healthContext.heartRate) bpm
    - Sleep: \(healthContext.sleepHours) hours last night
    - Activity: \(healthContext.activeMinutes) min today
    
    Rules:
    - NEVER provide medical diagnosis or treatment advice
    - If user mentions self-harm, provide crisis resources immediately
    - Keep responses concise (2-3 sentences max)
    - Reference their health data naturally
    - Suggest one actionable technique per response
    """))
    
    // Sliding window of last N messages
    messages.append(contentsOf: recentHistory.suffix(10))
    
    // Current user input
    messages.append(.user(userInput))
    
    return messages
}
```

### Context Management Strategy

| Strategy | Token Cost | Quality | Recommendation |
|----------|-----------|---------|----------------|
| Full history | Grows unbounded | Best | Avoid -- expensive |
| Sliding window (last 10 msgs) | ~1K-2K tokens | Good | **Use this** |
| Summarized history | ~500 tokens | Medium | Add later if needed |
| No history | ~500 tokens | Poor | Only for one-shot queries |

### Token Budget per Request

```
System prompt + health data:  ~400 tokens
Conversation history (10 msg): ~800 tokens
User message:                 ~100 tokens
max_tokens (response limit):  ~200 tokens
----------------------------------------
Total per request:            ~1,500 tokens
```

---

## 9. Token Management and Rate Limiting

### Rate Limits by Provider

| Provider | Tier 1 (Free/$0) | Tier 2 ($50+) | Notes |
|----------|------------------|---------------|-------|
| OpenAI | 500 RPM | 5,000 RPM | Per-project limits |
| Anthropic | 50 RPM | 1,000 RPM | Per-account limits |

### Client-Side Rate Limiting Pattern

```swift
actor TokenBucket {
    private var tokens: Int
    private let maxTokens: Int
    private let refillRate: Int  // tokens per second
    private var lastRefill: Date = .now
    
    func consume() async throws -> Bool {
        refill()
        guard tokens > 0 else {
            throw LLMError.rateLimited(retryAfter: timeUntilNextToken)
        }
        tokens -= 1
        return true
    }
}

// In ViewModel
actor RateLimitedLLMService: LLMServiceProtocol {
    let underlying: LLMServiceProtocol
    let bucket = TokenBucket(maxTokens: 20, refillRate: 1)  // 20/min
    
    func stream(messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        // Check bucket before calling underlying service
    }
}
```

### Token Tracking

```swift
// Parse usage from response headers/body
struct TokenUsage {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
}

// Track per-user daily spend
actor UsageTracker {
    private var dailyTokens: [Date: Int] = [:]
    private let dailyLimit: Int = 50_000  // ~$0.05/day with nano
    
    func record(usage: TokenUsage) throws {
        let today = Calendar.current.startOfDay(for: .now)
        dailyTokens[today, default: 0] += usage.totalTokens
        if dailyTokens[today]! > dailyLimit {
            throw LLMError.dailyLimitExceeded
        }
    }
}
```

### Retry Strategy

```swift
func withRetry<T>(maxAttempts: Int = 3, task: () async throws -> T) async throws -> T {
    for attempt in 1...maxAttempts {
        do {
            return try await task()
        } catch let error as URLError {
            if error.statusCode == 429, let retryAfter = error.retryAfter {
                try await Task.sleep(for: .seconds(retryAfter))
                continue
            }
            if attempt == maxAttempts { throw error }
            try await Task.sleep(for: .seconds(pow(2.0, Double(attempt))))  // exp backoff
        }
    }
    throw LLMError.maxRetriesExceeded
}
```

---

## Summary: Concrete Recommendations

### Ranked Choices

1. **USE: Custom URLSession + protocol abstraction** -- zero deps, project-aligned, future-proof
2. **MODEL: OpenAI GPT-4.1 nano** -- cheapest ($0.80/user/month), fast, sufficient for coaching
3. **BACKUP MODEL: Claude 3.5 Haiku** -- if nano quality insufficient, ~2.7x more but better empathy
4. **STREAMING: Hand-rolled SSE parser** -- ~60 lines, no dependency, handles both providers
5. **SECURITY Phase 1: Keychain + spending cap** -- acceptable for MVP/dev only
6. **SECURITY Phase 2: Backend proxy** -- mandatory for production

### Architecture Fit for StressMonitor

```
Services/
├── LLM/
│   ├── LLMServiceProtocol.swift       -- protocol definition
│   ├── Models/
│   │   ├── ChatMessage.swift           -- message types
│   │   ├── LLMResponse.swift           -- response parsing
│   │   └── SSEEvent.swift              -- SSE chunk types
│   ├── DirectOpenAIService.swift       -- direct API calls (Phase 1)
│   ├── ProxyLLMService.swift           -- backend proxy (Phase 2)
│   ├── SSEParser.swift                 -- SSE line parser
│   ├── TokenBucket.swift               -- rate limiting
│   └── UsageTracker.swift              -- token counting + daily limits
├── AI/
│   ├── AIChatViewModel.swift           -- chat state management
│   ├── SystemPromptBuilder.swift       -- builds health context prompts
│   └── ConversationManager.swift       -- sliding window history
```

### Adoption Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| API key extracted from binary | HIGH (if direct) | HIGH (bill abuse) | Spending caps, early proxy |
| Provider rate limits hit | MEDIUM | LOW | Client-side token bucket |
| Model quality insufficient | LOW-MEDIUM | MEDIUM | A/B test nano vs haiku early |
| Provider API changes | LOW | MEDIUM | Pin model version strings |
| Cost overrun at scale | MEDIUM | HIGH | Daily per-user limits, alerts |

---

## Sources

- [OpenAI API Pricing](https://openai.com/api/pricing/) -- verified GPT-4.1 nano $0.20/$1.25, GPT-5.4 $2.50/$15.00 per 1M tokens
- [Anthropic Models Overview](https://docs.anthropic.com/en/docs/about-claude/models) -- verified Claude 3.5 Haiku $0.80/$4.00, Claude 3.7 Sonnet $3.00/$15.00 per 1M tokens
- [Anthropic Streaming Messages API](https://docs.anthropic.com/en/api/messages-streaming) -- SSE event format: message_start, content_block_delta, message_stop
- [OpenAI Chat Completions API](https://platform.openai.com/docs/api-reference/chat/create) -- request/response format, stream: true, data: [DONE] sentinel
- [MacPaw/OpenAI GitHub](https://github.com/MacPaw/OpenAI) -- community Swift SDK, 2.4K stars, supports streaming, Responses API
- [OpenAI OpenAPI Spec](https://github.com/openai/openai-openapi) -- official API specification
- [github.com/anthropics/anthropic-sdk-swift](https://github.com/anthropics/anthropic-sdk-swift) -- exists but requires auth (private/restricted)

---

## Unresolved Questions

1. **Anthropic Swift SDK availability** -- The repo exists but is not publicly accessible. Unknown if/when it will be public. Workaround: direct URLSession or community SDK.
2. **Apple on-device LLM (Foundation Models framework)** -- iOS 18+ may offer on-device inference via Apple Intelligence. Not researched here. Could eliminate API key security issue entirely for simple coaching responses. Worth investigating.
3. **Health data privacy (HIPAA/GDPR)** -- Sending health data (HRV, HR, stress levels) to a third-party LLM API raises privacy concerns. Need legal review. Mitigation: anonymize data in system prompt, use backend proxy to strip PII before forwarding.
4. **Offline support** -- No LLM works offline. Should the AI Kitten chat show a graceful offline state, or fall back to pre-written responses?
5. **Content moderation** -- Both providers have built-in moderation, but user-generated input about mental health could trigger false positives. Need to test and handle refusal responses gracefully.
