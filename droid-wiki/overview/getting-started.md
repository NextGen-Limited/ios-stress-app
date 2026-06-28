# Getting started

## Prerequisites

| Component | Minimum | Notes |
| --- | --- | --- |
| macOS | 14.0+ | Xcode 15 requires Sonoma or newer |
| Xcode | 15.0+ | Includes iOS 17 and watchOS 10 SDKs |
| iOS deployment target | 17.0+ | Uses `@Observable`, SwiftData, WidgetKit Live Activities |
| watchOS deployment target | 10.0+ | WidgetKit complications (not ClockKit) |
| Apple Developer account | Optional | Required for CloudKit and StoreKit testing on device |

## Build

Open the project and build the iOS scheme:

```bash
cd StressMonitor
open StressMonitor.xcodeproj
# Cmd+R to build and run on the iOS Simulator
```

Command-line build:

```bash
xcodebuild -scheme StressMonitor \
    -destination 'platform=iOS Simulator,name=iPhone 15'
```

Build the watchOS app:

```bash
xcodebuild -scheme "StressMonitorWatch Watch App" \
    -destination 'platform=watchOS Simulator,name=Apple Watch Series 9'
```

The `CLAUDE.md` and `AGENTS.md` files at the repo root document the `xc-all` MCP plugin commands if you prefer to drive Xcode through MCP.

## Demo mode

Real HealthKit data is unavailable on the simulator. Demo mode injects a `SimulatorHealthKitService` that cycles through five stress scenarios (relaxed, mild, moderate, high, edge) every 30 seconds with live HR updates every 3-5 seconds. Enable it by editing the scheme:

1. Product > Scheme > Edit Scheme
2. Run > Arguments > Arguments Passed on Launch
3. Add `-demo-mode` (checkbox enabled)
4. Build and run

The demo pipeline runs the real `MultiFactorStressCalculator` and persists to SwiftData, so it exercises the same code path as production. See `StressMonitor/StressMonitor/Services/HealthKit/SimulatorHealthKitService.swift`.

## Run tests

```bash
xcodebuild test -scheme StressMonitor \
    -destination 'platform=iOS Simulator,name=iPhone 15'
```

Or scope to a single test class:

```bash
xcodebuild test -scheme StressMonitor \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    -only-testing:StressMonitorTests/StressCalculatorTests
```

A Python helper exists at `scripts/run-tests.py` that wraps the same invocation with retries.

## Project layout

The Xcode project lives at `StressMonitor/StressMonitor.xcodeproj`. Source roots:

- `StressMonitor/StressMonitor/` - iPhone app target
- `StressMonitor/StressMonitorWatch Watch App/` - watchOS app target
- `StressMonitor/StressMonitorWidget/` - WidgetKit extension target
- `StressMonitor/StressMonitorTests/` - unit tests

The repo also contains a `docs/` directory with narrative architecture documents, a `design/` directory with HTML mockups, and `fastlane/` for release automation. These are reference materials and do not participate in the build.

## Common setup issues

- **HealthKit authorization denied on simulator**: expected. Use demo mode (`-demo-mode`) or grant Health access under Settings > Privacy & Security > Health > StressMonitor on a real device.
- **CloudKit sync errors**: ensure an iCloud account is signed in on the simulator or device. Private database sync requires an active iCloud account.
- **StoreKit products not loading**: product IDs resolve from `Info.plist` configuration entries or environment variables. In development, `MockStoreKitService` provides canned plans. See [StoreKit IAP](../systems/storekit-iap.md).
- **Build failures after pulling**: the project uses Xcode-managed signing. If signing fails, select your development team in Signing & Capabilities for each target.
