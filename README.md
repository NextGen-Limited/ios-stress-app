# StressMonitor iOS App

An iOS application for real-time stress monitoring using Apple Watch sensor data, HealthKit integration, and on-device CoreML inference.

## Features

- Real-time stress level detection from Apple Watch HRV data
- HealthKit integration for health data collection
- CoreML-based stress prediction model
- SwiftUI interface with dashboard and history views
- CloudKit sync across devices
- Notifications for high stress events

## Architecture

- **Pattern:** MVVM + Services
- **UI:** SwiftUI
- **Data:** HealthKit, CoreML, CloudKit
- **Minimum iOS:** 17.0
- **Watch companion:** watchOS 10.0

## Project Structure

```
StressMonitor/
├── Models/           # Data models, CoreML model wrappers
├── Views/            # SwiftUI views
├── ViewModels/       # View models (MVVM)
├── Services/         # HealthKit, CoreML, CloudKit services
├── Utilities/        # Helpers, extensions
└── Resources/        # Assets, CoreML models
```

## Setup

1. Open `StressMonitor.xcodeproj` in Xcode 15+
2. Configure signing with your Apple Developer account
3. Enable HealthKit capability in project settings
4. Build and run on device (HealthKit requires physical device)

## Development

This project is managed via the Hermes Kanban board. The `stress-app` worker profile handles assigned tasks.
