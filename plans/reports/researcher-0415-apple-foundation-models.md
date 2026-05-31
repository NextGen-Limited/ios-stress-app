# Research Report: Apple Foundation Models Framework for On-Device AI

**Date:** 2026-04-15
**Context:** Architecture decision for AI chat in StressMonitor (ios-stress-app)
**Sources:** Apple official documentation (docs.developer.apple.com), WWDC25 sessions

---

## Executive Summary

Apple's Foundation Models framework (introduced WWDC25, iOS 26+) provides on-device LLM access with structured output, tool calling, and conversational sessions. It is free, private, and requires no API keys -- but limited to 4,096 token context, only works on Apple Intelligence-capable devices (A17 Pro / M1+), and cannot do complex reasoning or math. **Recommended as primary AI strategy for StressMonitor with graceful fallback for unsupported devices.**

---

## Q1: What is the Foundation Models framework?

**Swift framework** for running Apple's on-device large language model. Introduced at WWDC25 (June 2025), shipping with iOS 26 / macOS 26 / watchOS 26.

**Capabilities:**
- Text understanding, summarization, entity extraction
- Structured output (Swift-native types via `@Generable`)
- Tool/function calling
- Multi-turn conversation sessions
- Content tagging
- Streaming responses

**Key types:**
| Type | Purpose |
|------|---------|
| `SystemLanguageModel` | Singleton access to on-device model via `.default` |
| `LanguageModelSession` | Session object holding conversation context + transcript |
| `Instructions` | System-level directives (override user prompts in priority) |
| `Prompt` | User input wrapper |
| `GenerationOptions` | Temperature, sampling mode controls |
| `Transcript` | Observable session history |
| `Guardrails` | Built-in safety content filtering |

**Sources:** Apple docs - FoundationModels overview; WWDC25 Session 9965

---

## Q2: iOS version requirement

**iOS 26+** (next major release after iOS 18). Ships alongside macOS 26, watchOS 26, visionOS 26.

**Device requirements:**
- Apple Intelligence-capable hardware: A17 Pro or later (iPhone 15 Pro+), M1 or later (iPad/Mac)
- User must have Apple Intelligence **enabled** in Settings
- Model must be **downloaded** (automatic after enabling Apple Intelligence)

**Availability checking (required pattern):**
```swift
struct GenerativeView: View {
    private var model = SystemLanguageModel.default

    var body: some View {
        switch model.availability {
        case .available:
            // Show AI chat UI
        case .unavailable(.deviceNotEligible):
            // Show fallback - cloud API or static tips
        case .unavailable(.appleIntelligenceNotEnabled):
            // Prompt user to enable Apple Intelligence
        case .unavailable(.modelNotReady):
            // Show loading state - model downloading
        case .unavailable(let other):
            // Unknown reason fallback
        }
    }
}
```

**Implication for StressMonitor:** Must support iOS 17+ users (current target). Foundation Models only available on iOS 26+ with specific hardware. Graceful degradation is mandatory.

**Sources:** Apple docs - generating-content guide; WWDC25 Session 9966

---

## Q3: Conversational chat with context?

**Yes.** `LanguageModelSession` maintains multi-turn context natively.

**Basic conversation:**
```swift
let session = LanguageModelSession(
    instructions: "You are a wellness assistant..."
)

// First turn
let response1 = try await session.respond(to: "I'm feeling stressed")
// Second turn - session remembers context
let response2 = try await session.respond(to: "What can I do about it?")
```

**Session features:**
- **Instructions** (system prompt): Set via constructor, supports string interpolation for dynamic context
- **Transcript**: Observable history of all prompts, responses, and tool calls
- **Streaming**: `streamResponse()` returns `AsyncSequence` of partial results
- **Context window**: **4,096 tokens per session** (instructions + all prompts + all outputs)
- **Context overflow**: Error `exceededContextWindowSize` when limit hit -- must handle

**Streaming example:**
```swift
let stream = session.streamResponse(
    generating: WellnessAdvice.self,
    options: GenerationOptions(sampling: .greedy)
) { "Given HRV of \(hrv), suggest..." }

for try await partialResponse in stream {
    advice = partialResponse.content  // Updates progressively
}
```

**Dynamic instructions with user context:**
```swift
let session = LanguageModelSession(
    instructions: """
    You are a stress wellness assistant. The user's current data:
    - Stress level: \(stressLevel)/100
    - HRV: \(hrv)ms
    - Heart rate: \(hr) bpm
    - Category: \(stressCategory)
    """
)
```

**Limitation:** 4,096 tokens is ~3,000 words. For health context, keep instructions concise. Long conversations must be summarized or new sessions created.

**Sources:** Apple docs - generating-content guide; Apple docs - sample project guide

---

## Q4: Structured output / tool calling?

**Both supported.** This is a major strength of the framework.

### Structured Output (`@Generable`)

Define Swift types the model must conform its output to:

```swift
@Generable(description: "Personalized wellness recommendation")
struct WellnessAdvice: Codable {
    @Guide(description: "Brief title for the advice")
    var title: String

    @Guide(description: "Detailed recommendation text")
    var detail: String

    @Guide(description: "Urgency: low, medium, high", .count(1))
    var urgency: [String]

    @Guide(description: "Suggested activities", .count(1...3))
    var activities: [String]
}

// Usage
let advice = try await session.respond(
    to: "HRV is low at 18ms, what should I do?",
    generating: WellnessAdvice.self
)
print(advice.title)       // Strongly typed access
print(advice.activities)  // Always an array of 1-3 items
```

**`@Guide` constraints:**
- `.range()` for numeric bounds
- `.count()` for array size bounds
- `.description` for semantic guidance
- Works with: Bool, Int, Float, Double, Decimal, String, Array

**Dynamic schema at runtime** via `DynamicGenerationSchema` for unknown-at-compile-time structures.

### Tool Calling

Tools let the model invoke app functions:

```swift
struct StressDataTool: Tool {
    let name = "getStressHistory"
    let description = "Retrieves the user's stress data for a time period."

    @Generable
    struct Arguments {
        @Guide(description: "Number of days to look back", .range(1...30))
        var days: Int
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        let history = try await stressRepository.fetchRecent(limit: arguments.days)
        return ToolOutput(history.map { "\($0.timestamp): stress \($0.stressLevel)" })
    }
}

// Register tool with session
let session = LanguageModelSession(tools: [StressDataTool()])
let response = try await session.respond(to: "How has my stress been lately?")
// Model can call getStressHistory tool to fetch real data before responding
```

**Tool calling features:**
- Model decides when to call tools autonomously
- Multiple tools can be called concurrently
- Same tool can be called multiple times
- Transcript tracks all tool calls for debugging
- Tools can be `@Observable` for SwiftUI binding

**Sources:** Apple docs - guided generation guide; Apple docs - tool calling guide

---

## Q5: Limitations vs cloud LLMs

| Dimension | Foundation Models (On-Device) | Cloud LLMs (OpenAI, etc.) |
|-----------|-------------------------------|---------------------------|
| **Context window** | 4,096 tokens (~3K words) | 128K-1M+ tokens |
| **Reasoning** | NOT suitable for logical reasoning, math, code | Strong reasoning capabilities |
| **Model capability** | Summarize, classify, extract, creative writing | Full spectrum including complex analysis |
| **Availability** | iOS 26+ only, Apple Intelligence devices only | Any device with internet |
| **Latency** | Low (on-device, no network) | Higher (network round-trip) |
| **Privacy** | Full -- data never leaves device | Data sent to cloud servers |
| **Cost** | Free, unlimited | Per-token pricing |
| **Rate limits** | None documented | Tier-based rate limits |
| **Offline** | Works offline | Requires internet |
| **Health data** | Stays on-device (HIPAA-friendly) | PHI concerns, needs BAA |
| **Consistency** | Deterministic with `.greedy` sampling | Varies by provider/settings |

**Explicitly NOT suitable for** (per Apple docs):
- Basic math
- Code generation
- Logical reasoning

**Well-suited for:**
- Text summarization and classification
- Entity extraction
- Creative writing / conversational responses
- Content tagging
- Structured data generation

**Sources:** Apple docs - generating-content guide (capability table); WWDC25 Session 10049

---

## Q6: Cost and rate limits

**Free.** Zero cost, no API keys, no authentication.

**No documented rate limits.** The model runs entirely on-device. Practical limits are:
- Device thermal throttling under sustained use
- Memory constraints during generation
- Battery impact from heavy model inference

**No external network calls.** Data never leaves the device. No server infrastructure needed.

**Implication for StressMonitor:** Significant advantage -- no backend costs, no API key management, no user-facing usage limits, full privacy compliance for health data.

**Sources:** Apple docs - FoundationModels overview; WWDC25 Session 9965

---

## Q7: SwiftUI integration examples

### Full Chat View Pattern

```swift
import FoundationModels
import SwiftUI

@Observable
class ChatViewModel {
    var messages: [ChatMessage] = []
    var currentResponse: String = ""
    var isLoading = false
    var isAvailable: Bool { SystemLanguageModel.default.availability == .available }

    private var session: LanguageModelSession?

    func startSession(stressContext: StressContext) {
        guard SystemLanguageModel.default.availability == .available else { return }

        session = LanguageModelSession(
            instructions: """
            You are a stress wellness assistant. Current user data:
            - Stress level: \(stressContext.level)/100 (\(stressContext.category))
            - HRV: \(stressContext.hrv)ms
            - Heart rate: \(stressContext.heartRate) bpm
            Give brief, practical advice. Be warm but concise.
            """,
            tools: [StressDataTool(repository: stressContext.repository)]
        )
    }

    func send(_ text: String) async {
        guard let session else { return }
        isLoading = true
        defer { isLoading = false }

        messages.append(ChatMessage(role: .user, content: text))

        do {
            let stream = session.streamResponse { text }
            for try await partial in stream {
                currentResponse = partial.content
            }
            messages.append(ChatMessage(role: .assistant, content: currentResponse))
            currentResponse = ""
        } catch {
            messages.append(ChatMessage(role: .error, content: error.localizedDescription))
        }
    }
}
```

### Structured Wellness Response

```swift
@Generable(description: "A wellness response with actionable advice")
struct WellnessResponse {
    @Guide(description: "Empathetic acknowledgment")
    var acknowledgment: String

    @Guide(description: "1-3 specific recommendations", .count(1...3))
    var recommendations: [String]

    @Guide(description: "A brief encouraging closing")
    var closing: String
}
```

### Availability-Gated UI

```swift
struct AIChatCard: View {
    @State private var model = SystemLanguageModel.default

    var body: some View {
        Group {
            switch model.availability {
            case .available:
                ChatView()  // Full AI chat
            case .unavailable(.deviceNotEligible):
                StaticTipsView()  // Fallback
            case .unavailable(.appleIntelligenceNotEnabled):
                EnableAIView()  // Prompt to enable
            case .unavailable(.modelNotReady):
                ProgressView("Setting up AI...")
            default:
                StaticTipsView()
            }
        }
    }
}
```

**Sources:** Apple docs - sample project guide; Apple docs - generating-content guide

---

## Q8: Health/wellness advice with personalized context?

**Yes -- this is an ideal use case.** The framework excels at:

1. **Structured wellness output** -- `@Generable` types ensure responses always have the right structure (title, advice, urgency, activities)

2. **Tool calling for real data** -- Model can query actual HRV, stress history, sleep data from SwiftData before generating advice

3. **Dynamic instructions** -- Inject live stress data into session instructions so every response is personalized

4. **Privacy-first** -- All health data stays on-device. No PHI sent to external servers. No HIPAA compliance overhead for cloud transmission.

5. **Content tagging** -- `SystemLanguageModel(useCase: .contentTagging)` can categorize stress patterns, journal entries, or mood data

**Concrete pattern for StressMonitor:**

```swift
// Tool that gives the model access to user's stress data
struct StressInsightsTool: Tool {
    let name = "getStressInsights"
    let description = "Gets the user's stress trends and patterns"

    @Generable
    struct Arguments {
        @Guide(description: "Time period: today, week, month", .count(1))
        var period: [String]
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        let data = try await repository.fetchTrends(for: parsePeriod(arguments.period))
        return ToolOutput(formatInsights(data))
    }
}
```

**Limitation:** Model cannot do medical diagnosis or complex clinical reasoning. Must include disclaimers. The framework's built-in `Guardrails` will filter medically sensitive content -- test edge cases.

**Sources:** Apple docs - tool calling guide; Apple docs - guided generation guide; Apple docs - generating-content guide (capability table)

---

## Q9: Devices without Apple Intelligence

**Three fallback tiers required:**

| Tier | Condition | Strategy |
|------|-----------|----------|
| Full AI | iOS 26+ + Apple Intelligence device + enabled | Foundation Models framework |
| Prompt enable | iOS 26+ + capable device + NOT enabled | Show UI directing to Settings > Apple Intelligence |
| No AI | iOS <26 or incompatible device | Static wellness tips, pre-written advice based on stress level |

**Implementation:**
```swift
enum AITier {
    case fullFoundationModels
    case promptEnableIntelligence
    case staticFallback
}

func determineAITier() -> AITier {
    let model = SystemLanguageModel.default
    if #available(iOS 26, *) {
        switch model.availability {
        case .available: return .fullFoundationModels
        case .unavailable(.appleIntelligenceNotEnabled): return .promptEnableIntelligence
        default: return .staticFallback
        }
    }
    return .staticFallback
}
```

**Static fallback should:**
- Map stress levels to pre-written wellness tips (existing `ActionView` content)
- Show breathing exercises, activity suggestions based on category
- Display educational content about HRV and stress
- Maintain app utility without AI

**Sources:** Apple docs - generating-content guide (availability checking); WWDC25 Session 9966

---

## Trade-Off Matrix

| Dimension | Foundation Models (Primary) | Cloud LLM (Fallback) | Static Tips (Fallback) |
|-----------|---------------------------|---------------------|----------------------|
| **Privacy** | Best -- zero data leaves device | Risk -- PHI in transit | Best -- no AI at all |
| **Cost** | Free | $0.01-0.10/conversation | Free |
| **Offline** | Works | No | Works |
| **Quality** | Good for wellness chat | Best reasoning | Fixed, limited |
| **Availability** | ~40% of iOS devices (2026) | 100% with internet | 100% |
| **Latency** | ~1-3s on-device | 2-5s network | Instant |
| **Complexity** | Low (native Swift) | Medium (HTTP client) | Lowest |
| **Maintenance** | Low (Apple updates model) | Medium (API versioning) | Lowest |
| **Health data compliance** | Automatic (on-device) | Requires BAA, audit | N/A |

---

## Adoption Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Low adoption of iOS 26 | Medium | Static fallback covers all users |
| Apple Intelligence not enabled | Low | Prompt user to enable, graceful fallback |
| 4K token limit too small | Medium | Summarize context, new sessions per topic |
| Guardrails block health content | Medium | Test edge cases, add disclaimers |
| Model quality insufficient | Low | Wellness chat is well within documented capabilities |
| Framework breaking changes | Low | Apple first-party, stable API surface |
| Thermal throttling | Low | Short responses, streaming UX |

---

## Architectural Fit for StressMonitor

**Current stack:** MVVM + SwiftUI + SwiftData + HealthKit + Observation
**Foundation Models fit:** Excellent -- native Swift, same paradigms (@Observable sessions, async/await, SwiftUI integration)

**Recommended integration points:**
1. `AIChatCard` on Dashboard -- conversational wellness advice using current stress data
2. `ActionView` enhancement -- AI-generated personalized recommendations instead of static tips
3. Stress insights -- use content tagging model to categorize stress patterns over time

**No new dependencies required.** Foundation Models is a system framework. Zero third-party libs.

**Data flow addition:**
```
StressViewModel --> AIChatViewModel
       |                |
   SwiftData      Foundation Models
       |                |
  Stress Data --> Tool Calling --> Personalized AI Response
```

---

## Concrete Recommendation

**Rank 1 (Recommended): Foundation Models as primary, static tips as fallback.**

Rationale:
- Privacy-first aligns with the app's existing "no external API calls" principle
- Zero cost, zero infrastructure, zero API key management
- Native Swift integration -- no HTTP clients, no JSON parsing of LLM responses
- Structured output via `@Generable` eliminates hallucination risk for data format
- Tool calling lets AI access real HealthKit/SwiftData for personalized responses
- Graceful degradation via availability checking covers all iOS 17+ users

**Rank 2 (Not recommended): Cloud LLM only.** Contradicts the app's privacy-first architecture. Adds backend costs, PHI compliance burden, and network dependency.

**Rank 3 (Not recommended): Hybrid (on-device + cloud).** YAGNI -- adds complexity for marginal benefit. The 4K token limit is sufficient for wellness chat sessions.

---

## WWDC25 Reference Sessions

| Session | Title | Duration | Key Content |
|---------|-------|----------|-------------|
| 9965 | Meet the Foundation Models framework | 23:24 | Overview, architecture, capabilities |
| 9966 | Code-along: Bring on-device AI to your app | 30:32 | Step-by-step SwiftUI integration |
| 9967 | Deep dive into the Foundation Models framework | 25:31 | Advanced: streaming, tools, sessions |
| 10049 | Explore prompt design & safety | 22:11 | Prompt engineering, guardrails |
| 10048 | Discover ML & AI frameworks on Apple platforms | 19:27 | Broader ML ecosystem context |

---

## Unresolved Questions

1. **watchOS support?** Docs mention watchOS 26 but stress app has watchOS component -- need to verify if Foundation Models runs on Apple Watch (thermal/memory constraints may prevent it)
2. **Guardrails boundary testing.** How aggressively does content filtering block health/stress discussions? Must test with real stress-related prompts.
3. **Internationalization.** Framework supports multiple locales but quality may vary for non-English wellness advice.
4. **Siri integration overlap.** Does Apple Intelligence already provide wellness insights that would duplicate this feature?
5. **Actual on-device latency.** No benchmarks yet for response generation time on iPhone 15 Pro vs iPhone 17.
