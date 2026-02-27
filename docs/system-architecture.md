# System Architecture: Overview

**Pattern:** MVVM + Protocol-Oriented Design
**Concurrency:** async/await
**Data Flow:** Unidirectional (Models → Services → ViewModels → Views)
**Last Updated:** February 2026

---

## Overview

StressMonitor follows a clean, layered architecture designed for testability, maintainability, and scalability. This document provides navigation to detailed architecture information.

## Quick Links

### Core Architecture
Understanding the foundation:
- **[System Architecture: Core](./system-architecture-core.md)** - MVVM pattern, layer responsibilities, service architecture (HealthKit, Algorithm, Repository), data models, data flow, concurrency, error handling, testing architecture

### Platform Features & Security
Advanced platform capabilities:
- **[System Architecture: Platform](./system-architecture-platform.md)** - CloudKit sync, Apple Watch standalone app, WidgetKit complications, home screen widgets, performance considerations, security model, extensibility points

---

## Architecture Layers

### 1. Presentation Layer (SwiftUI Views)
- Declarative, zero business logic
- Render based on ViewModel state
- Forward actions to ViewModels
- Handle loading/error display
- Implement accessibility

### 2. ViewModel Layer (@Observable)
- Manage reactive state
- Coordinate services
- Handle async operations
- Error presentation
- @MainActor for UI thread safety

### 3. Service Layer
- Business logic implementation
- Protocol-based design
- Testable via dependency injection
- Domain-organized (HealthKit, Algorithm, Repository, CloudKit, etc.)

### 4. Data Layer
- SwiftData for local persistence
- CloudKit for cloud sync
- E2E encrypted storage
- Offline-first queue management

---

## Key Technologies

| Technology | Usage | Rationale |
|-----------|-------|-----------|
| **SwiftUI** | UI framework | Modern, declarative, iOS 17+ |
| **MVVM** | Architecture pattern | Testable, reactive, clean separation |
| **SwiftData** | Local persistence | iOS 17+ native, encrypted at rest |
| **CloudKit** | Cloud sync | Apple ecosystem, E2E encryption |
| **HealthKit** | Health data | Official Apple health API, privacy-first |
| **WidgetKit** | Widgets & complications | Modern widget framework, watchOS 10+ |
| **async/await** | Concurrency | Swift 5.9+ native, structured concurrency |

---

## Data Flow

```
User Action
    ↓
SwiftUI View
    ↓
ViewModel (async operation)
    ↓
Service Layer (protocol-based)
    ↓
Data Layer (SwiftData + CloudKit)
    ↓
System APIs (HealthKit)
    ↓
Apple Watch Sensors
```

**Reverse for updates:**
```
Model Change
    ↓
ViewModel Updates State (@Observable)
    ↓
SwiftUI Re-renders
    ↓
UI Updates on screen
```

---

## Core Services

### HealthKit Service
- Request HealthKit authorization
- Fetch HRV data from Apple Watch
- Fetch heart rate samples
- Handle permission denial gracefully

### Algorithm Service
- Calculate stress level (HRV 70% + HR 30%)
- Compute confidence scoring
- Manage 30-day baseline adaptation
- Handle edge cases

### Repository Service
- SwiftData CRUD operations
- Query recent/filtered measurements
- Persist baseline data
- Data cleanup operations

### CloudKit Service
- Sync measurements to iCloud
- Fetch cloud updates
- E2E encrypted storage
- Offline queue management
- Rate limiting (5-record batches, 5-minute throttle)

### DataManagement Service
- Export to CSV/JSON
- Delete by date range
- Delete by category
- Full local/cloud wipe

---

## Design Decisions

| Decision | Rationale | Trade-off |
|----------|-----------|-----------|
| **No external dependencies** | Privacy, control, reduced bloat | More code to maintain |
| **Local-first architecture** | Works offline, fast responsiveness | Eventual consistency |
| **MVVM + Protocols** | Testability, loose coupling | More boilerplate |
| **@Observable macro** | Modern, iOS 17+ reactive | Excludes iOS 16 |
| **CloudKit E2E encryption** | User privacy, Apple ecosystem | Requires iCloud account |
| **WidgetKit (not ClockKit)** | watchOS 10+ requirement | No ClockKit support |

---

## Testing Strategy

### Isolation via Protocols

All services conform to protocols, enabling mock implementations:

```swift
protocol HealthKitServiceProtocol {
  func fetchLatestHRV() async throws -> HRVMeasurement?
}

// Mock for testing
final class MockHealthKitManager: HealthKitServiceProtocol {
  var mockHRV: HRVMeasurement?
  func fetchLatestHRV() async throws -> HRVMeasurement? { mockHRV }
}

// Inject into ViewModel
let viewModel = StressViewModel(healthKit: MockHealthKitManager())
```

### Test Coverage
- **Core Algorithm:** >90% coverage
- **Repository:** >85% coverage
- **Services:** >80% coverage
- **ViewModels:** >80% coverage
- **Overall:** >80% target

---

## Performance Targets

| Operation | Target |
|-----------|--------|
| Stress calculation | <1 second |
| View render time | <16ms (60 FPS) |
| CloudKit sync | <30 seconds |
| App launch | <2 seconds |
| Memory (idle) | <50 MB |
| Memory (100 measurements) | <100 MB |

---

## Security & Privacy

### HealthKit
- Read-only access (HRV + Heart Rate)
- User grants explicit permission
- No writes to Apple Health
- Handle denial gracefully

### CloudKit
- Private database (per-user)
- E2E encryption by default
- No PII transmitted
- User controls sync toggle

### Local Storage
- SwiftData encrypted at rest by iOS
- No hardcoded secrets
- User can export/delete anytime

### Privacy
- No external API calls
- No telemetry or analytics
- No third-party services
- Data never leaves device+iCloud

---

## Extensibility

### Adding a New Service

1. Create protocol: `NewServiceProtocol`
2. Implement service: `NewService: NewServiceProtocol`
3. Create mock for testing: `MockNewService: NewServiceProtocol`
4. Inject into ViewModel
5. Write tests

### Adding a New Widget

1. Create provider: `NewComplicationProvider.swift`
2. Define timeline entries
3. Implement `getTimeline` method
4. Register in `ComplicationBundle`
5. Test on watch simulator

### Adding a New Export Format

1. Create: `NewFormatGenerator.swift`
2. Conform to export protocol
3. Implement serialization logic
4. Register in `DataExporter`
5. Test with sample data

### Adding Custom Shapes (for illustrations)

Custom SwiftUI shapes follow a reusable pattern:

```swift
// Public reusable shape
struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Custom path logic
        return path
    }
}

// Usage in views
TriangleShape()
    .fill(Color.Wellness.figmaIconGray)
    .frame(width: 37, height: 34.5)
```

**Pattern Guidelines:**
- Use `Shape` protocol for reusable geometric shapes
- Keep shapes pure (no side effects)
- Accept configuration via init parameters
- Support accessibility with descriptive labels

---

**Maintained By:** Phuong Doan
**Version:** 1.0 Production
**Last Updated:** February 2026
