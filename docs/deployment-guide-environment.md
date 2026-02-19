# Deployment Guide: Environment Setup & Build

**Platform:** iOS 17+ / watchOS 10+
**Section:** Setup, Requirements, Build Instructions
**Last Updated:** February 2026

---

## Prerequisites

### Development Environment

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **Xcode** | 15.0 | 15.4+ |
| **macOS** | 14.0 Sonoma | 15.0 Sequoia |
| **iOS** | 17.0 | 17.5+ |
| **watchOS** | 10.0 | 10.5+ |
| **Swift** | 5.9 | 5.9+ |

### Required Accounts

- Apple Developer account ($99/year)
- App Store Connect access
- Apple Developer Program enrollment

### Certificates & Provisioning

- iOS Development Certificate
- iOS Distribution Certificate
- Apple Watch Development Certificate
- App ID for StressMonitor (bundle ID: `com.stressmonitor.app`)
- App ID for Watch App
- Provisioning profiles (Development + Distribution)

---

## Environment Setup

### 1. Clone Repository

```bash
git clone https://github.com/your-org/ios-stress-app.git
cd ios-stress-app/StressMonitor
```

### 2. Open Xcode Project

```bash
open StressMonitor.xcodeproj
```

### 3. Configure Signing

In Xcode:
1. Select project `StressMonitor`
2. Targets → `StressMonitor`
3. Signing & Capabilities
4. Team: Select your development team
5. Bundle Identifier: `com.stressmonitor.app`

**Repeat for:**
- `StressMonitorWatch Watch App`
- `StressMonitorWidget`

### 4. Enable Required Capabilities

In Signing & Capabilities, add:

#### For iOS App
- ✅ HealthKit
- ✅ iCloud (CloudKit)
- ✅ App Groups: `group.com.stressmonitor.app`
- ✅ Background Modes (App Refresh)

#### For Watch App
- ✅ HealthKit
- ✅ iCloud (CloudKit)

#### For Widget
- ✅ App Groups: `group.com.stressmonitor.app`

### 5. Verify Bundle IDs

```
iOS App:             com.stressmonitor.app
Watch App:           com.stressmonitor.app.watchkitapp
Widget:              com.stressmonitor.app.widgets
App Groups:          group.com.stressmonitor.app
iCloud Container:    iCloud.com.stressmonitor.app
```

---

## Build Instructions

### Build for Development

```bash
# Build iOS app
xcodebuild -scheme StressMonitor \
    -destination 'platform=iOS Simulator,name=iPhone 15'

# Build Watch app
xcodebuild -scheme "StressMonitorWatch Watch App" \
    -destination 'platform=watchOS Simulator,name=Apple Watch Series 9'

# Run tests
xcodebuild test -scheme StressMonitor \
    -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Build for Release

```bash
# Build for App Store
xcodebuild \
    -scheme StressMonitor \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath ./build/StressMonitor.xcarchive \
    archive

# Build watch for App Store
xcodebuild \
    -scheme "StressMonitorWatch Watch App" \
    -configuration Release \
    -destination 'generic/platform=watchOS' \
    -archivePath ./build/StressMonitorWatch.xcarchive \
    archive
```

### Verify Build

```bash
# Check archive size
du -h ./build/StressMonitor.xcarchive/

# Validate signing
codesign -v ./build/StressMonitor.app

# Verify capabilities
codesign -d --entitlements :- ./build/StressMonitor.app
```

---

## Testing Before Release

### Unit Tests

```bash
xcodebuild test \
    -scheme StressMonitor \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    -resultBundlePath ./TestResults
```

**Expected Results:**
- 100+ test methods
- Core algorithm tests: ✅
- Repository tests: ✅
- ViewModel tests: ✅
- CloudKit sync tests: ✅

### Manual Testing Checklist

#### Stress Measurement
- [ ] Tap "Measure" button
- [ ] HRV data fetches (mock if needed)
- [ ] Stress calculation completes <2 seconds
- [ ] Result displays with color + category
- [ ] Measurement saves to history

#### History & Trends
- [ ] History view loads recent measurements
- [ ] Date filtering works (today/week/month)
- [ ] Category filtering works
- [ ] Trend charts render correctly
- [ ] Drill-down to detail view works

#### Apple Watch
- [ ] Watch app launches independently
- [ ] Measure button works on watch
- [ ] Complications display stress level
- [ ] Watch data syncs to iPhone

#### CloudKit Sync
- [ ] Sign into iCloud on device
- [ ] Measure on iPhone → appears on watch
- [ ] Measure on watch → appears on iPhone
- [ ] Delete on iPhone → deletes on watch
- [ ] Offline queue syncs when online

#### Data Management
- [ ] Export to CSV works
- [ ] Export to JSON works
- [ ] Delete by date range works
- [ ] Delete all data works
- [ ] CloudKit reset works

#### Accessibility
- [ ] VoiceOver reads all elements
- [ ] Tap targets are ≥44x44 points
- [ ] Dynamic Type scales all text
- [ ] Stress level visible without color

---

**Next:** See `deployment-guide-release.md` for TestFlight & App Store submission.
