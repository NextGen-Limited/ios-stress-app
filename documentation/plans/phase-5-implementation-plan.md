# Phase 5: watchOS App - Implementation Plan

## Overview

This plan implements a minimal watchOS companion app for the StressMonitor iPhone app. The watch app will independently fetch HealthKit data, calculate stress levels locally, and sync results to the iPhone via WatchConnectivity. The implementation includes a compact UI for the small screen, WidgetKit complications for at-a-glance monitoring, and bidirectional communication between devices.

**Key constraint**: Models (`StressResult`, `StressCategory`, `HRVMeasurement`, `HeartRateSample`, `StressCalculator`) are already implemented in the iOS target and must be shared with the watchOS target via Xcode target membership.

---

## Files to Modify (Existing Files)

### 1. `StressMonitor/StressMonitor/Models/StressResult.swift`
**Change**: Add watchOS target membership in Xcode (file inspector)
**Reason**: Watch app needs access to `StressResult` struct for stress calculation results

### 2. `StressMonitor/StressMonitor/Models/StressCategory.swift`
**Change**: Add watchOS target membership in Xcode
**Reason**: Watch app needs stress category enum and associated colors/icons

### 3. `StressMonitor/StressMonitor/Models/HRVMeasurement.swift`
**Change**: Add watchOS target membership in Xcode
**Reason**: Watch HealthKit fetch returns HRV data in this format

### 4. `StressMonitor/StressMonitor/Models/HeartRateSample.swift`
**Change**: Add watchOS target membership in Xcode
**Reason**: Watch HealthKit fetch returns heart rate data in this format

### 5. `StressMonitor/StressMonitor/Models/PersonalBaseline.swift`
**Change**: Add watchOS target membership in Xcode
**Reason**: `StressCalculator` depends on baseline values

### 6. `StressMonitor/StressMonitor/Services/Algorithm/StressCalculator.swift`
**Change**: Add watchOS target membership in Xcode
**Reason**: Watch app performs local stress calculation using same algorithm

### 7. `StressMonitor/StressMonitor/Services/Protocols/StressAlgorithmServiceProtocol.swift`
**Change**: Add watchOS target membership in Xcode
**Reason**: Protocol dependency for `StressCalculator`

### 8. `StressMonitor/StressMonitorWatch Watch App/StressMonitorWatchApp.swift`
**Change**: Replace with full implementation
**Reason**: Currently placeholder; needs HealthKit auth and ViewModel setup

### 9. `StressMonitor/StressMonitorWatch Watch App/ContentView.swift`
**Change**: Replace with full implementation
**Reason**: Currently placeholder; needs stress display and measure button

---

## Files to Create (New Files)

### Watch HealthKit Service

#### `StressMonitor/StressMonitorWatch Watch App/Services/WatchHealthKitManager.swift`
**Purpose**: HealthKit data fetching on watchOS (independent of iPhone)

**Key Functions**:
- `func requestAuthorization() async throws` - Requests HRV and heart rate read authorization from HealthKit on watch
- `func fetchLatestHRV() async throws -> HRVMeasurement?` - Queries HealthStore for most recent HRV sample, returns nil if no data
- `func fetchHeartRate(samples: Int) async throws -> [HeartRateSample]` - Queries HealthStore for N most recent heart rate samples

### Watch ViewModel

#### `StressMonitor/StressMonitorWatch Watch App/ViewModels/WatchStressViewModel.swift`
**Purpose**: State management for watch app, coordinates HealthKit + algorithm + sync

**Key Functions**:
- `func measureStress() async` - Orchestrates HealthKit fetch, stress calculation, updates UI state, triggers phone sync
- `func loadLatestStress() async` - Requests latest measurement from iPhone via WatchConnectivity on app launch
- `private func syncToPhone(result: StressResult)` - Sends calculated stress result to iPhone via WCSession transfer

### Watch Connectivity (Both Sides)

#### `StressMonitor/StressMonitorWatch Watch App/Services/WatchConnectivityManager.swift`
**Purpose**: Watch-side WatchConnectivity wrapper for sending data to iPhone

**Key Functions**:
- `func syncData(_ data: [String: Any])` - Sends dictionary to iPhone via WCSession transferUserInfo
- `func requestData(_ action: String)` - Sends message to iPhone and awaits reply

#### `StressMonitor/StressMonitor/Services/Connectivity/PhoneConnectivityManager.swift`
**Purpose**: iPhone-side WatchConnectivity delegate for receiving watch data and saving to SwiftData

**Key Functions**:
- `func session(_:didReceiveUserInfo:)` - Receives saved measurements from watch, persists via StressRepository
- `func session(_:didReceiveMessage:replyHandler:)` - Handles "fetchLatest" requests from watch, replies with recent data
- `private func handleWatchMeasurement(_ userInfo: [String: Any])` - Parses watch message, creates StressMeasurement, saves to database

### Watch UI Components

#### `StressMonitor/StressMonitorWatch Watch App/Views/Components/CompactStressView.swift`
**Purpose**: Circular progress ring showing stress level 0-100 with color coding

**Key Functions**:
- `private func colorForLevel(_ level: Double) -> Color` - Returns stress color based on level (green/yellow/orange/red)
- `var body: some View` - Renders circle stroke with trim, centered numeric value, animates level changes

### Theme Extensions for Watch

#### `StressMonitor/StressMonitorWatch Watch App/Theme/WatchDesignTokens.swift`
**Purpose**: Watch-specific design constants for smaller screen constraints

**Key Functions**: None (static constants only)
- Defines smaller spacing, font sizes, touch targets optimized for 42mm/44mm watches

### WidgetKit Complications

#### `StressMonitor/StressMonitor Watch Widget/StressComplication.swift`
**Purpose**: WidgetKit configuration for watch face complications

**Key Functions**:
- `func getTimeline(in:completion:)` - Creates TimelineEntry with latest stress data, refreshes every 15 minutes

#### `StressMonitor/StressMonitor Watch Widget/StressComplicationProvider.swift`
**Purpose**: Timeline provider that fetches current stress level for complication display

**Key Functions**:
- `func placeholder(in:) -> StressEntry` - Returns sample data for complication gallery preview
- `func getSnapshot(in:completion:)` - Returns current stress state for complication editor
- `func getTimeline(in:completion:)` - Queries app data, constructs timeline with next update time

#### `StressMonitor/StressMonitor Watch Widget/StressComplicationView.swift`
**Purpose**: SwiftUI view rendering complication content for circular/rectangular families

**Key Functions**: None (view body only)
- Renders stress level number and category label in compact layout

#### `StressMonitor/StressMonitor Watch Widget/StressEntry.swift`
**Purpose**: Timeline entry model holding stress data for complication display

**Key Functions**: None (data model only)
- Conforms to `TimelineEntry`, holds date, stressLevel, category

### Watch App Data Storage (Optional for MVP)

#### `StressMonitor/StressMonitorWatch Watch App/Services/WatchStressStorage.swift`
**Purpose**: Simple UserDefaults or AppStorage wrapper for persisting latest stress on watch

**Key Functions**:
- `func saveLatestStress(_ result: StressResult)` - Encodes and persists StressResult to local storage
- `func loadLatestStress() -> StressResult?` - Decodes and returns cached StressResult, nil if none exists

---

## Implementation Order

1. **Shared Models Setup** (5 min) - Add watchOS target membership to existing model files
2. **WatchHealthKitManager** (30 min) - Core data fetching on watch
3. **WatchStressViewModel** (30 min) - State management and business logic
4. **WatchConnectivityManager** (20 min) - Watch-side communication
5. **PhoneConnectivityManager** (30 min) - iPhone-side receive handler
6. **CompactStressView** (20 min) - Circular progress display
7. **ContentView** (20 min) - Main watch screen with measure button
8. **StressMonitorWatchApp** (10 min) - Entry point with HealthKit auth
9. **Complications** (60 min) - WidgetKit implementation (can be deferred)
10. **Testing** (30 min) - Verify watch-phone communication flow

---

## Testing Checklist

- [ ] Watch app launches and requests HealthKit authorization
- [ ] Measure button fetches HRV/HR and calculates stress locally
- [ ] Stress result syncs to iPhone and appears in history
- [ ] iPhone receives and saves watch measurements via PhoneConnectivityManager
- [ ] Complications display stress level on watch face
- [ ] Watch and iPhone stay in sync during active use

---

## Estimated Time: 3-4 hours
