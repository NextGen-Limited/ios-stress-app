# Phases 6-7: Background Notifications & CloudKit Sync - Implementation Plan

## Overview

This plan implements two complementary features: (1) background fetch for automatic stress monitoring with local notifications for high stress events, and (2) CloudKit sync for seamless data continuity across iPhone, watch, and multiple devices. The implementation builds on the existing `HealthBackgroundScheduler` and extends it with notifications, then adds CloudKit integration using SwiftData+CloudKit sync.

**Key constraint**: Implementing minimal viable functionality only—no backward compatibility, no complex conflict resolution beyond "last write wins" timestamp ordering.

---

## Phase 6: Background Notifications

### Overview

Enable the app to fetch health data and calculate stress periodically in the background (every 15 minutes minimum per iOS), then notify the user when stress levels exceed 75%. Both iOS and watchOS will run independent background tasks and sync results to the central iPhone database.

---

### Files to Modify (Phase 6)

#### 1. `StressMonitor/StressMonitor/Models/StressMeasurement.swift`
**Change**: Add `restingHeartRate` and `confidences` properties for complete measurement storage
**Reason**: The current model is missing fields referenced in phase 6 plan; needed for complete stress data

#### 2. `StressMonitor/StressMonitor/Services/Background/HealthBackgroundScheduler.swift`
**Change**: Add notification trigger for high stress, improve error handling, add rescheduling
**Reason**: Currently exists but doesn't trigger notifications or reschedule after completion

#### 3. `StressMonitor/StressMonitor/StressMonitorApp.swift`
**Change**: Initialize background scheduler and request notification authorization on launch
**Reason**: App entry point needs to register background tasks and request notification permissions

#### 4. `StressMonitor/StressMonitor/Views/SettingsView.swift`
**Change**: Add toggle for background notifications, display last fetch time
**Reason**: Users need control over background monitoring and visibility into last fetch

---

### Files to Create (Phase 6)

#### `StressMonitor/StressMonitor/Services/Background/NotificationManager.swift`
**Purpose**: Wrapper around UNUserNotificationCenter for stress alert notifications

**Key Functions**:
- `func requestAuthorization() async throws` - Requests alert/sound/badge permissions from user
- `func notifyHighStress(level: Double)` - Creates and delivers local notification for stress > 75
- `func scheduleNotification(content: UNMutableNotificationContent, trigger: UNNotificationTrigger)` - Schedules notification delivery with UNUserNotificationCenter

#### `StressMonitor/StressMonitorWatch Watch App/Services/Background/WatchBackgroundScheduler.swift`
**Purpose**: watchOS background refresh coordinator (WKExtension)

**Key Functions**:
- `func scheduleBackgroundRefresh()` - Schedules next background refresh with WKExtension (15min minimum)
- `func handleBackgroundRefresh()` - Called by system when app runs in background, fetches health data
- `private func syncToPhone(result: StressResult)` - Sends calculated stress to iPhone via WCSession

#### `StressMonitor/StressMonitorWatch Watch App/ExtensionDelegate.swift`
**Purpose**: watchOS app lifecycle delegate for background task handling

**Key Functions**:
- `func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>)` - Receives background tasks from system, delegates to scheduler
- `func applicationDidFinishLaunching()` - Registers for background refresh on app launch

---

## Phase 7: CloudKit Sync

### Overview

Implement iCloud sync using SwiftData's CloudKit integration (iOS 17+) for seamless data continuity. Measurements sync automatically across devices via the private database. Conflict resolution uses simple timestamp ordering (newer wins). Watch optionally syncs via shared database or defers to iPhone.

---

### Project Configuration (Phase 7)

**Xcode Capabilities to Add**:
- iOS Target → Signing & Capabilities → + Capability → iCloud → CloudKit (container: `iCloud.com.stressmonitor.app`)
- watchOS Target → Signing & Capabilities → + Capability → iCloud → CloudKit (same container)

---

### Files to Modify (Phase 7)

#### 1. `StressMonitor/StressMonitor/Models/StressMeasurement.swift`
**Change**: Add CloudKit sync properties (`isSynced`, `cloudKitRecordID`, `deviceID`)
**Reason**: Track sync status and enable conflict resolution

#### 2. `StressMonitor/StressMonitor/StressMonitorApp.swift`
**Change**: Enable CloudKit for SwiftData schema, add `ModelConfiguration.cloudKit`
**Reason**: Enable automatic CloudKit sync for SwiftData

#### 3. `StressMonitor/StressMonitor/Services/Repository/StressRepository.swift`
**Change**: Add `fetchUnsynced()` method for sync manager to query pending uploads
**Reason**: Sync manager needs to find measurements not yet uploaded to CloudKit

#### 4. `StressMonitor/StressMonitor/Views/SettingsView.swift`
**Change**: Add sync status indicator, last sync date, manual sync button
**Reason**: Users need visibility into sync state and ability to trigger manual sync

#### 5. `StressMonitor/StressMonitor/Views/Components/` (new location)
**Change**: Create sync status component for reuse across dashboard and settings
**Reason**: Consistent sync UI across app

---

### Files to Create (Phase 7)

#### `StressMonitor/StressMonitor/Services/CloudKit/CloudKitSyncMonitor.swift`
**Purpose**: Observe SwiftData+CloudKit sync state and provide status to UI

**Key Functions**:
- `func observeSyncStatus()` - Watches SwiftData sync state changes, updates `syncStatus` property
- `var syncStatus: SyncStatus` - Published property indicating current sync state (syncing, success, error)
- `var lastSyncDate: Date?` - Published property of last successful CloudKit sync

#### `StressMonitor/StressMonitor/Services/Sync/ConflictResolver.swift`
**Purpose**: Resolve duplicate measurements from different devices

**Key Functions**:
- `static func resolve(local: StressMeasurement, remote: StressMeasurement) -> StressMeasurement` - Compares timestamps, returns newer measurement
- `private static func isDuplicate(_ lhs: StressMeasurement, _ rhs: StressMeasurement) -> Bool` - Checks if two measurements are duplicates (same timestamp + device)

#### `StressMonitor/StressMonitor/Views/Components/SyncStatusIndicator.swift`
**Purpose**: Visual indicator showing sync state (syncing spinner, checkmark, warning icon)

**Key Functions**:
- `var body: some View` - Renders spinner if syncing, checkmark if recently synced, warning if error
- `private var syncIcon: String` - Returns appropriate SF Symbol based on sync state
- `private var syncColor: Color` - Returns green (recent), gray (stale), or red (error)

---

## Implementation Order

### Phase 6 First (2-3 hours)
1. **NotificationManager** (30 min) - UNUserNotificationCenter wrapper, permission request
2. **HealthBackgroundScheduler enhancements** (30 min) - Add notification trigger, rescheduling
3. **StressMonitorApp initialization** (15 min) - Register background tasks, request notifications
4. **WatchBackgroundScheduler** (45 min) - watchOS WKExtension background refresh
5. **ExtensionDelegate** (30 min) - watchOS background task handler
6. **SettingsView updates** (15 min) - Notification toggle, last fetch display
7. **Testing** (30 min) - Simulate background fetch, verify notifications

### Phase 7 Second (3-4 hours)
1. **Xcode CloudKit configuration** (15 min) - Enable capability, create container
2. **StressMeasurement CloudKit properties** (15 min) - Add isSynced, cloudKitRecordID, deviceID
3. **StressMonitorApp CloudKit enablement** (15 min) - Add ModelConfiguration.cloudKit
4. **StressRepository fetchUnsynced** (30 min) - Query pending measurements
5. **CloudKitSyncMonitor** (60 min) - Observe SwiftData sync state, expose to UI
6. **ConflictResolver** (30 min) - Timestamp-based duplicate resolution
7. **SyncStatusIndicator** (30 min) - Visual sync state component
8. **SettingsView sync UI** (30 min) - Add sync status, manual trigger
9. **Testing** (30 min) - Multi-device sync testing, conflict scenarios

---

## Data Flow Diagrams

### Background Fetch Flow (Phase 6)
```
iOS System (every 15min)
    ↓
BGAppRefreshTask triggers
    ↓
HealthBackgroundScheduler.handleBackgroundRefresh()
    ↓
HealthKitManager.fetchLatestHRV() + fetchHeartRate()
    ↓
StressCalculator.calculateStress()
    ↓
StressRepository.save(measurement)
    ↓
IF level > 75: NotificationManager.notifyHighStress()
    ↓
scheduleNextRefresh()
```

### Watch Background Flow (Phase 6)
```
Watch System (every 15min)
    ↓
WKExtension.backgroundRefresh
    ↓
WatchBackgroundScheduler.handleBackgroundRefresh()
    ↓
WatchHealthKitManager.fetchLatestHRV() + fetchHeartRate()
    ↓
StressCalculator.calculateStress()
    ↓
WCSession.transferUserInfo() → iPhone
    ↓
scheduleNextRefresh()
```

### CloudKit Sync Flow (Phase 7)
```
SwiftData auto-sync (iOS 17+)
    ↓
StressMeasurement saved locally
    ↓
SwiftData+CloudKit uploads to private database
    ↓
CloudKitSyncMonitor observes state change
    ↓
Remote devices receive push notification
    ↓
SwiftData downloads changes to local store
    ↓
ConflictResolver resolves duplicates if needed
    ↓
UI updates via @Query
```

---

## Testing Checklist

### Phase 6: Background
- [ ] Background fetch runs every 15 minutes (simulate via Debug → Simulate Background Fetch)
- [ ] Notification permission requested on first launch
- [ ] High stress (>75) triggers notification with sound
- [ ] Watch background refresh runs and syncs to iPhone
- [ ] Settings toggle enables/disables notifications
- [ ] Last fetch time displays correctly
- [ ] App handles expiration gracefully

### Phase 7: CloudKit
- [ ] CloudKit container configured in Xcode
- [ ] Measurements sync to iCloud automatically
- [ ] New measurements appear on second device
- [ ] Conflicts resolve by timestamp (newer wins)
- [ ] Sync status indicator shows correct state
- [ ] Manual sync button triggers immediate sync
- [ ] Watch measurements sync via iPhone or directly
- [ ] Error states display appropriately

---

## Estimated Time: 5-7 hours total
- Phase 6 (Background): 2-3 hours
- Phase 7 (CloudKit): 3-4 hours

---

## Key Technical Notes

1. **SwiftData+CloudKit (iOS 17+)**: Leveraging built-in sync instead of manual CKRecord operations—simpler, more reliable
2. **Background Limits**: iOS minimum 15min interval, not guaranteed; watchOS similar limits
3. **Notification Limits**: iOS may coalesce notifications; don't rely on immediate delivery
4. **Conflict Strategy**: Timestamp-based "last write wins" sufficient for stress measurements (immutable after creation)
5. **Watch CloudKit**: Watch can optionally sync directly; simpler to route via iPhone for MVP

---

## Dependencies Between Phases

Phase 6 must be completed before Phase 7 because:
- Background tasks create measurements that need to sync
- StressMeasurement schema changes (isSynced, cloudKitRecordID) needed for both
- Notification permission flow separate from CloudKit setup

However, Phase 7 can be tested independently by manually creating measurements.
