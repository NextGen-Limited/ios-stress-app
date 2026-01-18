# iOS Stress Monitor - Implementation Guide

Complete implementation guide for the iOS 17+ / watchOS 10+ stress monitoring app.

## Overview

This app monitors user stress levels using Heart Rate Variability (HRV) and heart rate data from HealthKit, with iCloud sync and background monitoring.

### Tech Stack

- **Platform:** iOS 17.0+ / watchOS 10.0+
- **Language:** Swift
- **UI Framework:** SwiftUI
- **Architecture:** MVVM
- **Data Persistence:** SwiftData
- **Health Data:** HealthKit
- **Cloud Sync:** CloudKit
- **Background Tasks:** BackgroundTasks framework
- **Watch Complications:** WidgetKit (NOT ClockKit)
- **Observability:** @Observable macro (iOS 17+)

---

## Phase Overview

| Phase | Title | Time | Status |
|-------|-------|------|--------|
| 1 | [Project Foundation](./phase-1-project-foundation.md) | 2-3h | ⬜ Not Started |
| 2 | [Data Layer](./phase-2-data-layer.md) | 4-5h | ⬜ Not Started |
| 3 | [Core Algorithm](./phase-3-core-algorithm.md) | 3-4h | ⬜ Not Started |
| 4 | [iPhone UI](./phase-4-iphone-ui.md) | 4-5h | ⬜ Not Started |
| 5 | [watchOS App](./phase-5-watchos-app.md) | 3-4h | ⬜ Not Started |
| 6 | [Background Notifications](./phase-6-background-notifications.md) | 2-3h | ⬜ Not Started |
| 7 | [Data Sync](./phase-7-data-sync.md) | 3-4h | ⬜ Not Started |
| 8 | [Testing & Polish](./phase-8-testing-polish.md) | 5-6h | ⬜ Not Started |

**Total Estimated Time:** 26-34 hours

---

## Quick Start

1. **Start with Phase 1** to set up the project
2. Follow each phase in order
3. Complete the testing checklist at the end of each phase
4. Update the status above as you progress

---

## Critical Technical Decisions

### Architecture

**Decision:** MVVM with @Observable

**Rationale:**
- SwiftUI's @Observable macro (iOS 17+) provides clean state management
- Separation of concerns enables testing
- ViewModels encapsulate business logic
- Models remain simple data structures

---

### Data Layer

**Decision:** SwiftData for local persistence + CloudKit for sync

**Rationale:**
- SwiftData is native to iOS 17+ and SwiftUI-friendly
- CloudKit provides seamless iCloud sync
- Repository pattern abstracts implementation details
- Enables offline-first architecture

---

### Health Data

**Decision:** Direct HealthKit access with background fetching

**Rationale:**
- Real-time access to latest HRV/heart rate
- Background fetch ensures automatic updates
- No need for intermediary servers
- Privacy-focused (data stays on device)

---

### Stress Algorithm

**Decision:** Multi-factor algorithm with confidence scoring

**Rationale:**
- HRV is primary factor (70% weight)
- Heart rate is secondary factor (30% weight)
- Confidence scoring indicates reliability
- Personal baseline improves accuracy

**Formula:**
```
Normalized HRV = (Baseline - HRV) / Baseline
Normalized HR = (HR - Resting HR) / Resting HR

HRV Component = Normalized HRV ^ 0.8
HR Component = atan(Normalized HR * 2) / (π/2)

Stress Level = (HRV Component * 0.7) + (HR Component * 0.3)
```

---

### watchOS Complications

**Decision:** WidgetKit (NOT ClockKit)

**Rationale:**
- Required for watchOS 10+
- Modern API with better performance
- Consistent with iOS widgets
- Easier timeline management

---

### Background Execution

**Decision:** BGAppRefreshTask for periodic fetches

**Rationale:**
- 15-minute minimum interval
- System-managed for battery efficiency
- Reliable execution on iOS and watchOS
- Supports high-stress notifications

---

## Project Structure

```
ios-stress-app/
├── StressMonitor/
│   ├── App/
│   │   └── StressMonitorApp.swift
│   ├── Models/
│   │   ├── HRVMeasurement.swift
│   │   ├── HeartRateSample.swift
│   │   └── StressMeasurement.swift
│   ├── ViewModels/
│   │   └── StressViewModel.swift
│   ├── Views/
│   │   ├── MainTabView.swift
│   │   ├── DashboardView.swift
│   │   ├── HistoryView.swift
│   │   ├── SettingsView.swift
│   │   └── Components/
│   │       └── StressRingView.swift
│   └── Services/
│       ├── HealthKit/
│       │   └── HealthKitManager.swift
│       ├── Algorithm/
│       │   ├── StressCalculator.swift
│       │   └── BaselineCalculator.swift
│       ├── Repository/
│       │   └── StressRepository.swift
│       ├── Background/
│       │   ├── BackgroundTaskManager.swift
│       │   └── BackgroundHealthFetcher.swift
│       ├── CloudKit/
│       │   └── CloudKitManager.swift
│       └── Connectivity/
│           └── PhoneConnectivityManager.swift
├── StressMonitorWatch/
│   ├── App/
│   ├── Models/
│   ├── ViewModels/
│   ├── Views/
│   └── Services/
├── StressMonitorTests/
├── StressMonitorUITests/
└── references/
    ├── README.md (this file)
    ├── phase-1-project-foundation.md
    ├── phase-2-data-layer.md
    ├── phase-3-core-algorithm.md
    ├── phase-4-iphone-ui.md
    ├── phase-5-watchos-app.md
    ├── phase-6-background-notifications.md
    ├── phase-7-data-sync.md
    └── phase-8-testing-polish.md
```

---

## Key Dependencies

### System Frameworks (No external packages required)

- SwiftUI
- SwiftData
- HealthKit
- CloudKit
- BackgroundTasks
- WidgetKit
- WatchConnectivity
- UserNotifications

---

## Testing Strategy

### Unit Tests
- Algorithm logic
- Data persistence
- ViewModels
- Service layers

### Integration Tests
- End-to-end flows
- Cross-device sync
- Background tasks

### UI Tests
- View rendering
- User interactions
- Navigation

### Device Testing
- iPhone (various sizes)
- Apple Watch (various sizes)
- Different iOS/watchOS versions

---

## Privacy & Security

### Health Data
- All data stored locally using SwiftData
- Encrypted at rest via iOS
- Never transmitted to third-party servers
- CloudKit sync is end-to-end encrypted

### Permissions
- HealthKit: Read-only access to HRV and heart rate
- Notifications: For high-stress alerts
- Background: For automatic monitoring

### Transparency
- Clear disclosure of data usage
- User can delete all data
- No tracking or analytics

---

## Common Issues & Solutions

### HealthKit Authorization Denied
**Solution:** Guide user to Settings → Privacy & Security → Health → StressMonitor

### CloudKit Sync Errors
**Solution:** Check iCloud account status, handle network errors gracefully

### Background Tasks Not Running
**Solution:** Ensure Background Modes enabled, verify device not in Low Power Mode

### Watch Not Syncing
**Solution:** Verify WCSession activation, check Bluetooth connectivity

---

## Performance Targets

| Metric | Target | Notes |
|--------|--------|-------|
| App Launch | < 2s | Cold start on iPhone 15 |
| Stress Calculation | < 100ms | Algorithm execution |
| Background Fetch | Every 15min | System-controlled |
| Battery Impact | < 2%/day | Background monitoring |
| Memory Usage | < 50MB | iPhone app |
| Watch Memory | < 30MB | watchOS app |

---

## Next Steps

1. **Review Phase 1** - [Project Foundation](./phase-1-project-foundation.md)
2. **Set up development environment** - Xcode 15+, macOS 14+
3. **Create project** - Follow Phase 1 instructions
4. **Start building** - Work through phases sequentially

---

## Support

For issues or questions during implementation:

1. Review the specific phase documentation
2. Check testing checklists
3. Verify prerequisites are met
4. Consult Apple's documentation for framework-specific issues

---

## License

This project is proprietary and confidential.

---

**Last Updated:** 2026-01-18

**Version:** 1.0.0

**Status:** Planning Complete - Ready for Implementation
