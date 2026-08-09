# System Architecture: Platform Features & Security

**Pattern:** MVVM + Protocol-Oriented Design
**Concurrency:** async/await
**Section:** CloudKit, Watch, widgets, security, extensibility
**Last Updated:** July 19, 2026

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
├── MultiFactorStressCalculator
├── SwiftData (local storage)
├── CloudKit (E2E sync)
├── WidgetKit Complications
├── WatchFacePreferences (background personalization)
├── SeasonalTheme (character costume overlays)
└── WatchConnectivityManager (sync with iPhone)
```

### List-Based Navigation Redesign (Jul 2026)

The watch app replaced its 6-page swipe `TabView` (which violated Apple HIG's 2–4 page limit for page-based navigation) with a root `NavigationStack` + scrollable list menu (`WatchMenuView`). Every screen is one tap away; the Digital Crown scrolls naturally.

**Menu destinations:** Home, Bio Age, Breathe, Workout, Cycle, Logging, History.

**New watch screens (Jul 2026):**
- **Workout** — live heart-rate zones during a workout (BPM hero, current-zone badge, per-zone distribution chart)
- **Cycle** — menstrual-cycle phase tracking with stress-correlation notes
- **Logging** — daily habit check-in (hydration/caffeine/sunlight rings) + 5-button mood picker
- **Bio Age** — biological age card with confidence bar

**Seasonal themes:** Optional costume/overlay themes for the watch character (`SeasonalTheme`: none, spring, lunarNewYear, halloween, holiday).

### Watch Face Background Personalization (NEW - Jun 17)

**Files:**
- `WatchFacePreferences.swift` - Persists background style selection
- `WatchFaceBackgroundStyle.swift` - Enum of available backgrounds
- `WatchFaceSettingsView.swift` - Settings UI in Watch app
- `WatchHomeView.swift` - Applies selected background style
- `WatchConnectivityManager.swift` - Syncs preferences with iPhone

**Features:**
- User-selectable background styles stored in SwiftData
- Synced to iPhone via WatchConnectivity for cross-device consistency
- Persists across app launches and device reboots

### Watch Character-Reactive Design (NEW - Jun 2026)

**5 Stress Tiers (stress category enum, dual-coded color + icon):**
- **Relaxed** → Green
- **Mild** → Blue
- **Moderate** → Indigo
- **High** → Orange
- **Severe** → Purple

**WatchHomeView** displays the character face with tier mood, full-day sparkline, and watch-face background personalization. Numeric scores appear in the menu header and complications but the home canvas leads with the character.

### Watch Complications (WidgetKit)

Four families supported:

| Family | Size | Use Case |
|--------|------|----------|
| **Circular** | Small | Full-circle stress gauge + emoji center |
| **Rectangular** | Wide | Icon + stress mood + HRV/HR metrics |
| **Inline** | Narrow | Text-only mood label |
| **Corner** | Watchkit 10+ | Emoji in corner (NEW Jun 2026) |

**Data Sources:**
- `CircularComplicationProvider` - Updates every 5 minutes, displays stress gauge + character emoji
- `RectangularComplicationProvider` - Fetches from CloudKit, shows mood label + health metrics
- `InlineComplicationProvider` - Text-only mood label (e.g. "Calm")
- `CornerComplicationProvider` - Emoji-only display (watchOS 10+ feature)

**Data Sharing:**
- App Groups: `group.com.stressmonitor.watch` for inter-app timeline data sharing

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

| Family | Size | Content | Policy |
|--------|------|---------|--------|
| **Small** | 1×1 | Character face + mood label (NO numeric scores) | 15-min iOS refresh |
| **Medium** | 2×1 | Character + mini sparkline (12-point history) | 15-min iOS refresh |
| **Large** | 2×2 | Character + 24-hour area chart + mood pills | 15-min iOS refresh |
| **Lock Screen** | Varies | Rectangular, Circular, Inline variants with emoji | 15-min iOS refresh |
| **Live Activity** | Dynamic Island | Breathing session counter + progress (NEW Jun 2026) | Real-time updates |
| **Control** | Control Center | Button → Opens app (NEW Jun 2026) | On-demand |

**Policy:** Dynamic refresh (15min iOS, 30min watchOS), with real-time updates for breathing sessions.

### Widget Data Access

```swift
// Shared via App Groups (iPhone ↔ Watch)
let defaults = UserDefaults(suiteName: "group.com.stressmonitor.app")
let lastStress = defaults?.double(forKey: "lastStressLevel") ?? 0

// Watch-specific data
let watchDefaults = UserDefaults(suiteName: "group.com.stressmonitor.watch")
```

**Data Shared:**
- Latest stress level (character emoji + category label, NO numeric score)
- Last 24 hours measurements (sparkline)
- Character mood state (5 tiers)
- Live Activity breathing session progress
- Control Center app launcher metadata

**Design Policy:**
- **NO numeric stress scores** in any widget or watch complication
- All stress display via emoji + color-coded category
- Character evolution state shown (if applicable)
- Ripple AI Coach teaser on premium upsell cards

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

### Credential Management (KeychainService)
- API tokens stored via Security framework (Keychain)
- `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` access level (no cloud migration)
- Used for SupabaseLLM authentication and external API tokens
- Graceful error handling on access denied or keychain unavailable

### Privacy
- SupabaseLLMService sends derived stress-context (score, category, confidence, trend, per-factor HRV/heart-rate/sleep/activity/recovery scores — never raw HealthKit readings) to Supabase Edge Functions, under a Bearer-JWT-authenticated session
- No telemetry or analytics
- Raw HealthKit readings never leave device+iCloud; the AI Coaching Chat context above is the one exception that is transmitted
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

**UPDATED - Jun 2026:**

SupabaseLLMService uses `AsyncThrowingStream<String, Error>` for SSE token delivery.

```
SupabaseLLMService.send()
  → URLRequest to Supabase Edge Function (stream: true) — configured via SupabaseConfig
  → URLSession.shared.bytes(for:) -- async byte stream
  → Parse SSE lines ("data: {...}")
  → Extract choices[0].delta.content
  → yield tokens via AsyncThrowingStream continuation
  → ChatViewModel appends to messages[]
  → SwiftUI renders incrementally
```

**SSE Infrastructure:**
- `SSEParser.swift` - Server-Sent Events parser

**Key Details:**
- OpenAI-compatible SSE format (`data: [DONE]` terminator)
- `continuation.onTermination` cancels upstream URLSession task
- Configurable endpoint via `SupabaseConfig` (URL + anonKey)
- Error mapping: 422 (bad request), 502 (provider failure), network errors

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
| **Self-hosted LLM via Supabase** | Full control, cloud fallback via Edge Functions | Chat context leaves device |

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
│  ├─ LLM (AI chat: Supabase Cloud with SSE)
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
**Last Updated:** July 19, 2026