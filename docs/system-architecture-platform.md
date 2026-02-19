# System Architecture: Platform Features & Security

**Pattern:** MVVM + Protocol-Oriented Design
**Concurrency:** async/await
**Section:** CloudKit, Watch, widgets, security, extensibility
**Last Updated:** February 2026

---

## CloudKit Architecture

### CloudKit Services

**Files:**
- `Services/CloudKit/CloudKitManager.swift` (294 LOC)
- `Services/CloudKit/CloudKitSchema.swift` (198 LOC)
- `Services/CloudKit/CloudKitSyncEngine.swift` (377 LOC)

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

**Files:** 9 files (~2,789 LOC)

**Key Files:**
- `DataManagementService.swift` - Orchestrator
- `DataDeleterService.swift` - Delete operations
- `CloudKitResetService.swift` - Wipe CloudKit
- `CSVGenerator.swift` / `JSONGenerator.swift` - Export formats

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
- No external API calls
- No telemetry or analytics
- User data never leaves device+iCloud

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

## Design Decisions

| Decision | Rationale | Trade-off |
|----------|-----------|-----------|
| **CloudKit E2E encryption** | User privacy, Apple ecosystem | Requires iCloud account |
| **WidgetKit (not ClockKit)** | watchOS 10+ requirement | No ClockKit support |
| **Offline-first sync** | UX resilience | Conflict complexity |

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
**Last Updated:** February 2026
