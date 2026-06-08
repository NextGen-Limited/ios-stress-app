# System Architecture: Platform Features & Security

**Pattern:** MVVM + Protocol-Oriented Design
**Concurrency:** async/await
**Section:** CloudKit, Watch, widgets, security, extensibility
**Last Updated:** June 7, 2026

---

## CloudKit Architecture

### CloudKit Services

**Files:**
- `Services/CloudKit/CloudKitManager.swift` (294 LOC)
- `Services/CloudKit/CloudKitSchema.swift` (80 LOC)
- `Services/CloudKit/CloudKitSyncEngine.swift` (222 LOC)

```swift
protocol CloudKitServiceProtocol {
  func sync(measurement: StressMeasurement) async throws
  func fetchCloudMeasurements() async throws -> [StressMeasurement]
  func deleteCloudRecords(ids: [String]) async throws
}
```

**Responsibilities:**
- CloudKit record management
- E2E encrypted sync
- Conflict resolution
- Offline queue handling
- Rate limiting (5-minute throttle, 5-record batches)

**Sync Flow:**
```
Local Measurement → Queue → Batch (5 records) → CloudKit
     ↓                                            ↓
  SwiftData ← ← ← ← ← ← ← ← ← ← ← ← ← ← CloudKit Fetch
```

### Supporting Services

**Sync Manager** (278 LOC)
- Coordinate local + cloud sync
- Handle conflicts
- Queue management

**Connectivity Manager** (198 LOC)
- WatchConnectivity bridge
- iPhone ↔ Watch real-time sync
- Message handling

**Background Scheduler** (156 LOC)
- BGAppRefreshTask setup
- Periodic health data refresh
- Notification scheduling

### DataManagement Service

**Files:** 8 files (~2,173 LOC)

**Key Files:**
- `DataManagementService.swift` - Orchestrator
- `DataDeleter.swift` - Delete operations
- `CloudKitResetService.swift` - Wipe CloudKit
- `CSVGenerator.swift` / `JSONGenerator.swift` - Export formats
- `DataManagementUtilities.swift` - Helper functions

**Responsibilities:**
- Export data (CSV, JSON)
- Delete by date range
- Delete by category
- Full local wipe
- Full CloudKit reset

---

## Apple Watch Architecture

### Standalone Design

Watch app operates **independently** without iPhone:

```
Apple Watch
├── HealthKit (direct sensor access)
├── WatchHealthKitManager
├── WatchStressCalculator
├── SwiftData (local storage)
├── CloudKit (E2E sync)
└── WidgetKit Complications
```

### Watch Complications (WidgetKit)

Three families supported:

| Family | Size | Use Case |
|--------|------|----------|
| **Circular** | Small | Watch face corner |
| **Rectangular** | Wide | Watch face bar |
| **Inline** | Narrow | Watch face text |

**Data Sources:**
- `CircularComplicationProvider` - Updates every 5 minutes
- `RectangularComplicationProvider` - Fetches from CloudKit
- `InlineComplicationProvider` - Text-only format

**Timeline Example:**
```swift
func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
  let currentDate = Date()
  let nextRefresh = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!

  let entry = SimpleEntry(date: currentDate, stressLevel: 45.0)
  let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
  completion(timeline)
}
```

---

## Home Screen Widgets (WidgetKit)

### Widget Families

| Family | Size | Content |
|--------|------|---------|
| **Small** | 2x2 | Current stress level + ring |
| **Medium** | 2x4 | Stress + last 6 hours trend |
| **Large** | 4x4 | Full day chart + stats |

### Widget Data Access

```swift
// Shared via App Groups
let defaults = UserDefaults(suiteName: "group.com.stressmonitor.widgets")
let lastStress = defaults?.double(forKey: "lastStressLevel") ?? 0
```

**Data Shared:**
- Latest stress level
- Last 24 hours measurements
- Statistics (avg, min, max)

---

## Performance Considerations

### Stress Calculation
- Target: <1 second
- Runs on background thread
- Caches baseline for quick reuse

### CloudKit Sync
- Batches 5 records per request
- Throttles to 5-minute intervals
- Queues offline, syncs when online

### Memory Management
- SwiftData auto-manages object lifecycle
- No circular references
- Lazy loading for large lists

### Battery Impact
- Background refresh every 4 hours (optional)
- Minimal HealthKit queries (cached 5 minutes)
- Widget updates every 5 minutes

---

## Security Considerations

### HealthKit Authorization
- Request only HRV + Heart Rate (read-only)
- No writes to Apple Health
- Handle denial gracefully

### CloudKit Security
- Private database (per-user)
- E2E encryption (CKEncryptionLevel.default)
- No PII transmitted

### Local Storage
- SwiftData encrypted at rest by iOS
- No hardcoded secrets
- User control via export/delete

### Privacy
- CloudLLMService sends anonymized chat context to self-hosted gateway; health data stays on-device
- No telemetry or analytics
- Health data never leaves device+iCloud
- SSE streaming ensures real-time AI responses without persistent data storage

---

## Extensibility Points

### Adding New Calculation Service

1. Create protocol: `NewCalculationServiceProtocol`
2. Implement: `NewCalculationService: NewCalculationServiceProtocol`
3. Inject into ViewModel via constructor
4. Add tests with mock

### Adding New Data Export Format

1. Create: `NewFormatGenerator.swift`
2. Conform to export protocol
3. Register in `DataExporter`
4. Test with sample data

### Adding New Widget Family

1. Create provider: `NewComplicationProvider.swift`
2. Define timeline entries
3. Register in `ComplicationBundle`
4. Test on watch simulator

---

## Streaming Architecture (LLM Chat)

**UPDATED - Apr 2026:**

CloudLLMService uses `AsyncThrowingStream<String, Error>` for SSE token delivery.

```
CloudLLMService.send()
  → URLRequest to /v1/chat/completions (stream: true) - **HARDCODED ENDPOINT**
  → URLSession.shared.bytes(for:) -- async byte stream
  → Parse SSE lines ("data: {...}")
  → Extract choices[0].delta.content
  → yield tokens via AsyncThrowingStream continuation
  → ChatViewModel appends to messages[]
  → SwiftUI renders incrementally
```

**SSE Infrastructure:**
- `SSEParser.swift` - Server-Sent Events parser
- `LLMAPITarget.swift` - API configuration for cloud LLM endpoints

**Key Details:**
- OpenAI-compatible SSE format (`data: [DONE]` terminator)
- `continuation.onTermination` cancels upstream URLSession task
- **Hardcoded endpoint configuration** (removed server config UI)
- Health check via synchronous `GET /health` with 3s timeout
- Error mapping: 422 (bad request), 502 (provider failure), network errors
- AppleIntelligenceService uses same `AsyncThrowingStream` interface but via Foundation Models `streamResponse`

---

## CI/CD Pipeline

**File:** `.github/workflows/ci.yml`
**Runner:** macos-15
**Trigger:** push/PR to `main`, manual dispatch

### Pipeline Steps

| Step | Purpose |
|------|---------|
| Checkout | `actions/checkout@v4` |
| Select Xcode | `maxim-lobanov/setup-xcode@v1` (latest-stable) |
| Cache | SPM packages + DerivedData (keyed on `Package.resolved` hash) |
| Run tests | `scripts/run-tests.py` with `CI=1` |
| Validate | Check `xcresult` bundle exists |
| Publish | Test results summary to `$GITHUB_STEP_SUMMARY` |
| Coverage | `xccov view` report (first 100 lines) |
| Upload | `xcresult` artifact (7-day retention) |

### Test Runner (`scripts/run-tests.py`, 148 LOC)

- Python script wrapping `xcodebuild test`
- Auto-discovers available iPhone simulator (prefers iPhone 16)
- CI mode: name-based destination, `CODE_SIGNING_ALLOWED=NO`, code coverage enabled
- Local mode: finds/boots simulator via `simctl`, UUID-based destination
- Outputs `TestResults.xcresult` bundle

### Breathing Exercise Session Lifecycle

```
BreathingExerciseView (setup)
  → BreathingSessionView (active session with BreathingCircleView)
    → BreathingSummaryView (post-session with BeforeAfterChart)
```

3-view session flow with `BreathingCircleView` providing animated phase visualization (inhale/hold/exhale with scale + pulse animations).

---

## Design Decisions

| Decision | Rationale | Trade-off |
|----------|-----------|-----------|
| **CloudKit E2E encryption** | User privacy, Apple ecosystem | Requires iCloud account |
| **WidgetKit (not ClockKit)** | watchOS 10+ requirement | No ClockKit support |
| **Offline-first sync** | UX resilience | Conflict complexity |
| **Self-hosted LLM gateway** | No API keys, full control, cloud fallback | Requires ngrok for dev; chat context leaves device |
| **Hardcoded LLM endpoint** | Simplified configuration, removed UI complexity | Requires deployment updates for endpoint changes |

---

## Architecture Diagram Legend

```
┌─ Presentation Layer
│  └─ SwiftUI Views (declarative, no business logic)
│
├─ ViewModel Layer
│  └─ @Observable state managers (coordinate services)
│
├─ Service Layer
│  ├─ HealthKit (sensor data)
│  ├─ Algorithm (calculations)
│  ├─ Repository (local persistence)
│  ├─ LLM (AI chat: Apple Intelligence + Cloud with SSE)
│  ├─ CloudKit (cloud sync)
│  ├─ DataManagement (export/delete)
│  └─ Connectivity (watch sync)
│
└─ Data Layer
   ├─ SwiftData (local encrypted DB)
   └─ CloudKit (iCloud E2E encrypted)
```

---

**Previous:** See `system-architecture-core.md` for core MVVM and service architecture.
**Maintained By:** Phuong Doan
**Version:** 1.0 Production
**Last Updated:** June 7, 2026