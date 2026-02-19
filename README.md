# StressMonitor

**Privacy-first stress monitoring for iOS and watchOS using Heart Rate Variability.**

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue) ![watchOS 10+](https://img.shields.io/badge/watchOS-10%2B-blue) ![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange) ![License](https://img.shields.io/badge/License-Proprietary-red)

---

## Overview

StressMonitor is a **production-ready** iOS and watchOS application that calculates stress levels using Heart Rate Variability (HRV) and heart rate data from HealthKit. Built with modern Swift frameworks (SwiftUI, SwiftData, CloudKit), the app provides real-time stress monitoring with **zero external dependencies** and **end-to-end encrypted** cloud sync.

### Key Features

- **Real-Time Stress Calculation**: Science-based algorithm combining HRV (70% weight) and heart rate (30% weight)
- **Personal Baseline Adaptation**: Learns your individual physiology over time
- **Confidence Scoring**: Reliability indicator for each measurement
- **Cross-Device Sync**: CloudKit integration with offline-first architecture
- **Apple Watch App**: Standalone stress monitoring with complications (WidgetKit)
- **Home Screen Widgets**: At-a-glance stress levels on iPhone
- **Breathing Exercises**: Guided sessions to reduce stress
- **Data Export**: CSV and JSON export for external analysis
- **Privacy-First**: Local SwiftData storage, no third-party services

---

## Quick Start

### Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **Xcode** | 15.0 | 15.4+ |
| **macOS** | 14.0 Sonoma | 15.0 Sequoia |
| **iOS** | 17.0 | 17.5+ |
| **watchOS** | 10.0 | 10.5+ |
| **Device** | iPhone 12, Apple Watch Series 6 | iPhone 15, Apple Watch Series 9 |

### Installation

```bash
# Clone repository
git clone https://github.com/your-org/ios-stress-app.git
cd ios-stress-app/StressMonitor

# Open project
open StressMonitor.xcodeproj

# Build and run (⌘R)
# Select iPhone or Apple Watch simulator
```

### First Launch

1. Grant **HealthKit** permission (HRV + Heart Rate read access)
2. Complete **onboarding** and baseline calibration
3. Tap **"Measure"** to calculate your first stress level

---

## How It Works

### Stress Algorithm

The app uses a **scientifically grounded** algorithm combining two physiological signals:

```
Normalized HRV = (Baseline HRV - Current HRV) / Baseline HRV
Normalized HR = (Current HR - Resting HR) / Resting HR

HRV Component = (Normalized HRV) ^ 0.8
HR Component = atan(Normalized HR × 2) / (π/2)

Stress Level = ((HRV × 0.7) + (HR × 0.3)) × 100
```

**Why these metrics?**
- **Lower HRV = Higher Stress**: Heart rhythm variability decreases under stress
- **Higher Heart Rate = Higher Stress**: Heart beats faster under stress

### Stress Categories

| Level | Range | Color | Icon | Description |
|-------|-------|-------|------|-------------|
| **Relaxed** | 0-25 | 🟢 Green | 😊 | Low stress, optimal state |
| **Mild** | 25-50 | 🔵 Blue | 😐 | Slightly elevated, manageable |
| **Moderate** | 50-75 | 🟡 Yellow | 〰️ | Elevated stress, take notice |
| **High** | 75-100 | 🟠 Orange | ⚠️ | High stress, consider action |

### Confidence Scoring

Each measurement includes a **confidence score (0-1)** based on:
- HRV quality (penalty if <20ms)
- Heart rate validity (penalty if <40 or >180 bpm)
- Sample count (more samples = higher confidence)

---

## Project Structure

```
ios-stress-app/
├── StressMonitor/
│   ├── StressMonitor/                    # iOS App (96 files, ~12,270 LOC)
│   │   ├── Models/                       # Data models (9 files)
│   │   ├── Services/                     # Business logic (25 files)
│   │   │   ├── HealthKit/                # HealthKit integration
│   │   │   ├── Algorithm/                # Stress calculator
│   │   │   ├── Repository/               # SwiftData persistence
│   │   │   ├── CloudKit/                 # iCloud sync
│   │   │   └── DataManagement/           # Export/delete features
│   │   ├── ViewModels/                   # MVVM presentation (2 files)
│   │   ├── Views/                        # SwiftUI views (57 files)
│   │   │   ├── Dashboard/                # Main stress display
│   │   │   ├── History/                  # Measurement timeline
│   │   │   ├── Trends/                   # Analytics charts
│   │   │   ├── Breathing/                # Breathing exercises
│   │   │   ├── Settings/                 # App settings
│   │   │   └── Onboarding/               # First-launch flow
│   │   └── Theme/                        # Design system (2 files)
│   ├── StressMonitorWatch Watch App/     # watchOS App (28 files, ~2,541 LOC)
│   │   ├── Models/                       # Shared data models
│   │   ├── Services/                     # HealthKit + CloudKit
│   │   ├── ViewModels/                   # Watch app state
│   │   ├── Views/                        # Compact watch UI
│   │   └── Complications/                # WidgetKit complications (9 files)
│   ├── StressMonitorWidget/              # Home Screen Widgets (7 files)
│   └── StressMonitorTests/               # Unit Tests (21 files, ~7,073 LOC)
├── docs/                                 # Comprehensive documentation
│   ├── project-overview-pdr.md           # Product requirements
│   ├── codebase-summary.md               # Codebase organization
│   ├── code-standards.md                 # Swift coding conventions
│   ├── system-architecture.md            # MVVM architecture guide
│   ├── deployment-guide.md               # Build & release process
│   └── design-guidelines.md              # UI/UX design system
└── README.md                             # This file
```

---

## Architecture

### MVVM + Protocol-Oriented Design

```
Views (SwiftUI)
    ↓
ViewModels (@Observable)
    ↓
Services (Protocol-based)
    ↓
Data Layer (SwiftData + CloudKit)
```

### Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **UI** | SwiftUI | Declarative interface |
| **State** | @Observable (iOS 17+) | Reactive state management |
| **Persistence** | SwiftData | Local database |
| **Cloud Sync** | CloudKit | iCloud synchronization |
| **Health Data** | HealthKit | HRV/HR access |
| **Widgets** | WidgetKit | Home screen & complications |
| **Concurrency** | async/await | Structured concurrency |

**Zero External Dependencies**: System frameworks only.

---

## Development

### Build from Source

```bash
# Build iOS app
xcodebuild -scheme StressMonitor \
    -destination 'platform=iOS Simulator,name=iPhone 15'

# Build watchOS app
xcodebuild -scheme "StressMonitorWatch Watch App" \
    -destination 'platform=watchOS Simulator,name=Apple Watch Series 9'

# Run tests
xcodebuild test -scheme StressMonitor \
    -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Test Coverage

| Component | Tests | Status |
|-----------|-------|--------|
| **StressCalculator** | 20 tests | ✅ 100% passing |
| **BaselineCalculator** | 10 tests | ✅ 100% passing |
| **HealthKitManager** | 8 tests | ✅ 100% passing |
| **StressRepository** | 15 tests | ✅ 100% passing |
| **ViewModels** | 25+ tests | ✅ 100% passing |
| **CloudKit Sync** | 12 tests | ✅ 100% passing |

**Total:** 100+ test methods, comprehensive coverage of core functionality.

### Code Quality

- **Lines of Code**: ~22,000 (iOS + watchOS + tests)
- **Average File Size**: 128 lines
- **Architecture**: MVVM with protocol-based DI
- **SwiftLint**: Configured (if enabled)
- **Code Style**: 2-space indentation, 120 char line limit

---

## Features In-Depth

### 1. Stress Measurement

- **On-Demand**: Manual measurement via "Measure" button
- **Algorithm**: HRV (70%) + Heart Rate (30%) weighted combination
- **Baseline**: Personalized baseline from 30 days of data
- **Confidence**: Data quality indicator (0-1 scale)
- **Save**: Automatic save to SwiftData + CloudKit sync

### 2. Historical Tracking

- **Timeline View**: Chronological list of all measurements
- **Date Filtering**: Today, week, month, all time
- **Category Filtering**: By stress level (relaxed, mild, moderate, high)
- **Detail View**: Drill down into individual measurements

### 3. Trend Analytics

- **Line Charts**: Stress over time (24h, week, month)
- **Distribution**: Category breakdown (% time in each level)
- **Insights**: Automated trend detection (up/down/stable)
- **Statistics**: Average, min, max, standard deviation

### 4. Apple Watch Integration

- **Standalone App**: Full stress monitoring on watch
- **Complications**: Three families (Circular, Rectangular, Inline)
- **Independent CloudKit**: Watch syncs directly to iCloud
- **Optional iPhone Sync**: WatchConnectivity for real-time updates
- **Battery-Optimized**: 5-minute sync throttle, 5-record batches

### 5. Breathing Exercises

- **Guided Sessions**: 4-7-8 breathing technique
- **Before/After HRV**: Measure stress reduction
- **Session History**: Track exercise effectiveness
- **Customizable**: Adjustable duration

### 6. Data Management

- **Export**: CSV and JSON formats
- **Date Range Export**: Filter by time period
- **Statistical Summary**: Include aggregations
- **Delete**: By date range, category, or all data
- **CloudKit Reset**: Wipe cloud data separately

---

## Deployment

### Build Configurations

| Configuration | Use Case | Optimization |
|--------------|----------|--------------|
| **Debug** | Development | `-Onone` (no optimization) |
| **Release** | Production | `-O` (optimize for speed) |

### Capabilities Required

- **HealthKit**: Read HRV and Heart Rate
- **iCloud (CloudKit)**: Data synchronization
- **App Groups**: Widget data sharing
- **Background Modes**: App Refresh (optional)

### TestFlight / App Store

1. Archive app in Xcode (Product → Archive)
2. Upload to App Store Connect
3. Configure TestFlight or submit for review
4. See `docs/deployment-guide.md` for detailed steps

---

## Privacy & Security

### Privacy-First Design

- **Local Storage**: SwiftData (encrypted at rest by iOS)
- **No External Servers**: Zero third-party services
- **Read-Only HealthKit**: No writes to Apple Health
- **CloudKit E2E Encryption**: End-to-end encrypted sync
- **No Tracking**: No analytics, no advertising IDs
- **User Control**: Export and delete all data

### Data Flow

```
HealthKit (Apple Watch Sensors)
    ↓
HealthKitManager (read only)
    ↓
StressCalculator (local computation)
    ↓
SwiftData (local encrypted storage)
    ↓
CloudKit (optional, E2E encrypted)
```

---

## Accessibility

- **Dual Coding**: Color + Icon + Text (WCAG AA compliant)
- **VoiceOver**: Full screen reader support
- **Dynamic Type**: Text scales with user settings
- **Touch Targets**: Minimum 44x44 points
- **Haptic Feedback**: Tactile feedback on interactions
- **Color Blindness**: Icons ensure usability

---

## Documentation

Comprehensive documentation available in `docs/`:

1. **[Project Overview & PDR](docs/project-overview-pdr.md)** - Product requirements and vision
2. **[Codebase Summary](docs/codebase-summary.md)** - File structure and organization
3. **[Code Standards](docs/code-standards.md)** - Swift conventions and patterns
4. **[System Architecture](docs/system-architecture.md)** - MVVM design and data flow
5. **[Deployment Guide](docs/deployment-guide.md)** - Build and release process
6. **[Design Guidelines](docs/design-guidelines.md)** - UI/UX design system

---

## Roadmap

### Version 1.0 (Current - Production Ready)

- ✅ Core stress measurement
- ✅ Historical tracking and trends
- ✅ Apple Watch app with complications
- ✅ CloudKit sync
- ✅ Data export/delete
- ✅ Breathing exercises
- ✅ Comprehensive test coverage

### Version 1.1 (Planned)

- [ ] Advanced breathing techniques (box breathing, coherent breathing)
- [ ] Stress triggers tracking
- [ ] Weekly stress reports
- [ ] Localization (Spanish, French, German)

### Version 2.0 (Future)

- [ ] Machine learning insights
- [ ] Sleep/activity correlation
- [ ] Siri Shortcuts integration
- [ ] iPad app

---

## Contributing

This is a **proprietary project**. For questions, feedback, or collaboration inquiries, please contact:

- **Author**: Phuong Doan
- **Email**: ddphuong@example.com (update with actual)

---

## License

**Proprietary and Confidential**. All rights reserved.

This software and associated documentation files are the exclusive property of the author. Unauthorized copying, modification, distribution, or use is strictly prohibited.

---

## Acknowledgments

- **Apple HealthKit** - For providing access to HRV and heart rate data
- **CloudKit** - For secure, end-to-end encrypted cloud sync
- **SwiftUI & SwiftData** - For modern, declarative app development
- **SF Symbols** - For beautiful, consistent iconography

---

**Created by:** Phuong Doan
**Last Updated:** 2026-02-13
**Version:** 1.0 (Production)
**Platform:** iOS 17+ / watchOS 10+
