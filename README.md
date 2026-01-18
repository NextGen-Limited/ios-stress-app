# StressMonitor

An iOS 17+ and watchOS 10+ stress monitoring app that uses Heart Rate Variability (HRV) and heart rate data from HealthKit to help users understand their stress levels.

## Overview

StressMonitor provides real-time stress level calculations by analyzing your HRV and heart rate data. The app features a clean, privacy-first design with automatic background monitoring, iCloud sync, and Apple Watch integration.

### Key Features

- **Real-time Stress Monitoring**: Calculates stress levels (0-100) using HRV (70% weight) and heart rate (30% weight)
- **Personal Baseline**: Adapts to your individual physiology over time
- **Confidence Scoring**: Shows how reliable each reading is
- **Apple Watch Support**: View stress levels on your wrist with complications
- **Background Monitoring**: Automatic stress checks throughout the day
- **Privacy-First**: All data stored locally, synced via end-to-end encrypted CloudKit
- **No Third-Party Services**: Uses only Apple frameworks - no external dependencies

## Stress Levels

| Level | Range | Description |
|-------|-------|-------------|
| 🟢 Relaxed | 0-24 | Low stress, optimal state |
| 🔵 Mild Stress | 25-49 | Slightly elevated, manageable |
| 🟡 Moderate Stress | 50-74 | Elevated stress, take notice |
| 🟠 High Stress | 75-100 | High stress, consider action |

## How It Works

The stress algorithm combines two key physiological indicators:

```
Stress = (HRV_Component × 0.7) + (Heart_Rate_Component × 0.3)

Where:
- HRV_Component = Normalized_HRV^0.8
- Heart_Rate_Component = atan(Normalized_HR × 2) / (π/2)
```

**Lower HRV = Higher Stress** (Your heart rhythm becomes less variable when stressed)
**Higher Heart Rate = Higher Stress** (Your heart beats faster when stressed)

## Requirements

- **iOS 17.0+** / **watchOS 10.0+**
- **iPhone** (any model from iPhone XS or later)
- **Apple Watch** (Series 4 or later recommended)
- **HealthKit** authorization for HRV and heart rate data
- **iCloud** account (for data sync across devices)

## Installation

### From Xcode

1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/ios-stress-app.git
   cd ios-stress-app/StressMonitor
   ```

2. Open the project:
   ```bash
   open StressMonitor.xcodeproj
   ```

3. Select your target device (iPhone or Apple Watch simulator)

4. Build and run (⌘R)

### Building for Device

1. Select your development team in project settings
2. Configure signing certificates
3. Build and deploy to your device

## Permissions

The app requires the following permissions:

- **HealthKit** - Read access to HRV and heart rate data
- **Notifications** - High stress alerts (optional)
- **Background App Refresh** - Automatic monitoring (optional)

## Project Structure

```
StressMonitor/
├── StressMonitor/              # Main iOS app
│   ├── App/                    # App entry point
│   ├── Models/                 # Data models
│   ├── ViewModels/             # MVVM view models
│   ├── Views/                  # SwiftUI views
│   └── Services/               # Business logic
│       ├── Algorithm/          # Stress calculation
│       ├── HealthKit/          # Health data fetching
│       └── Repository/         # Data persistence
├── StressMonitorWatch/         # watchOS app
└── StressMonitorTests/         # Unit tests
```

## Development

### Prerequisites

- **Xcode 15.0+**
- **macOS 14.0+**
- **iOS 17.0+ SDK**

### Building

```bash
# Build iOS app
xcodebuild -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 15'

# Build watchOS app
xcodebuild -scheme StressMonitorWatch Watch App -destination 'platform=watchOS Simulator,name=Apple Watch Series 9'
```

### Testing

```bash
# Run all tests
xcodebuild test -scheme StressMonitor

# Run specific test
xcodebuild test -scheme StressMonitor -only-testing:StressMonitorTests/StressCalculatorTests
```

## Current Status

### Completed Phases

| Phase | Status | Description |
|-------|--------|-------------|
| 1. Project Foundation | ✅ Complete | Project setup, protocols, models |
| 2. Data Layer | ✅ Complete | SwiftData persistence, repository |
| 3. Core Algorithm | ✅ Complete | Stress calculation, confidence scoring |
| 4. iPhone UI | ⚠️ Partial | Dashboard, history, settings |
| 5. watchOS App | ⬜ Not Started | Watch app and complications |
| 6. Background Tasks | ⬜ Not Started | BGAppRefreshTask, notifications |
| 7. CloudKit Sync | ⬜ Not Started | iCloud data synchronization |
| 8. Testing & Polish | ⬜ Not Started | Comprehensive testing, performance |

### Test Coverage

```
StressCalculatorTests:      20/20 passed ✅
BaselineCalculatorTests:    10/10 passed ✅
StressViewModelTests:         7/7 passed ✅
```

## Privacy

This app is built with privacy as a core principle:

- **Local Storage**: All data stored locally using SwiftData (encrypted at rest)
- **No Third Parties**: No analytics, tracking, or external servers
- **Read-Only HealthKit**: We only read your health data, never write to it
- **CloudKit**: End-to-end encrypted sync through Apple's servers
- **Transparent**: You can view and delete all your data at any time

## Contributing

This is a proprietary project. For questions or feedback, please contact the development team.

## License

Proprietary and confidential. All rights reserved.

---

**Created by:** Phuong Doan
**Last Updated:** January 2026
**Version:** 0.3.0 (Phase 3 Complete)
