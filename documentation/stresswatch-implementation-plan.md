# Stress Monitoring App Implementation Plan

Based on research of [StressWatch.app](https://stresswatch.app/), this plan outlines building an iOS/watchOS stress monitoring application using Heart Rate Variability (HRV) data.

---

## Executive Summary

**App Concept**: A health monitoring app that tracks physical stress levels through Apple Watch sensors, using HRV and heart rate data to provide users with real-time stress insights and trends.

**Target Platform**: iOS 17+ / watchOS 9+

**Core Value Proposition**: Turn Apple Watch into a real-time stress monitor to help users understand their body's stress signals and improve wellbeing.

---

## 1. Core Technology & Measurement Principle

### 1.1 What is HRV?
- **HRV (Heart Rate Variability)**: Natural fluctuations in time intervals between heartbeats
- Regulated by autonomic nervous system (sympathetic vs parasympathetic)
- **Higher HRV** = Better nervous system balance, more relaxed state
- **Lower HRV** = More stressed, fatigued, or ill

### 1.2 Stress Types Detected
| Type | Detected? | Method |
|------|-----------|--------|
| Physical Stress | ✅ Yes | HRV + Heart Rate data |
| Emotional Stress | ⚠️ Partially | May affect physical markers |
| Cognitive Stress | ⚠️ Partially | May affect physical markers |

### 1.3 Measurement Frequency (Apple Watch System)
| Data Type | Frequency | Notes |
|-----------|-----------|-------|
| HRV | Every 2-5 hours | Automatic, when conditions met |
| Heart Rate | Every minute | Continuous |
| Real-time Stress | Every 6 minutes | Calculated from historical data |

### 1.4 Conditions That Prevent HRV Measurement
- Low Power Mode enabled
- Exercise tracking active
- High movement (running, cycling, driving)
- Watch locked
- Watch not securely worn
- watchOS 7 or earlier

---

## 2. Feature Architecture

### 2.1 Core Features (MVP)

```
┌─────────────────────────────────────────────────────────────┐
│                      Core Features                          │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   HRV Monitor   │  │  Stress Levels  │  │   Trends    │ │
│  │                 │  │                 │  │             │ │
│  │ • Today's HRV   │  │ • Real-time     │  │ • Hourly    │ │
│  │ • Current HRV   │  │ • Level display │  │ • Daily     │ │
│  │ • 30-day avg    │  │ • Notifications │  │ • Monthly   │ │
│  └─────────────────┘  └─────────────────┘  │ • Yearly    │ │
│                                              └─────────────┘ │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Extended Features (Pro/Post-MVP)

| Feature | Description | Data Source |
|---------|-------------|-------------|
| Sleep Analysis | Track sleep patterns | HealthKit Sleep |
| Mood Tracking | Log emotional states | User input |
| Hydration Tracking | Water intake monitoring | User input |
| Caffeine Tracking | Caffeine consumption | User input |
| Breathing Exercises | Guided breathing sessions | In-app |
| Workout Zones | Heart rate zone training | HealthKit Workouts |
| Custom Watch Faces | Personalized complications | WatchKit |
| Themes & Animations | Visual stress representation | In-app |

---

## 3. Technical Architecture

### 3.1 Stack

```
┌───────────────────────────────────────────────────────────────┐
│                        Tech Stack                             │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  Frontend:         Swift / SwiftUI / UIKit                    │
│  Watch App:       WatchKit / SwiftUI for watchOS             │
│  Data Layer:      Core Data / SwiftData                      │
│  Health:          HealthKit Framework                         │
│  Sync:            CloudKit (iCloud sync)                      │
│  Notifications:   UNUserNotificationCenter                   │
│  Background:      Background Tasks / App Refresh             │
│  Analytics:       (Optional) Firebase / Mixpanel              │
│  Payments:        StoreKit (In-app purchases)                │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

### 3.2 Data Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ Apple Watch  │────▶│  HealthKit   │────▶│   Our App    │
│   Sensors    │     │  (System)    │     │  (Read/Write)│
└──────────────┘     └──────────────┘     └──────┬───────┘
                                                   │
                                                   ▼
                                          ┌──────────────┐
                                          │ Core Data    │
                                          │ (Local DB)   │
                                          └──────┬───────┘
                                                 │
                                                 ▼
                                          ┌──────────────┐
                                          │  CloudKit    │
                                          │ (iCloud Sync)│
                                          └──────────────┘
```

### 3.3 Module Structure

```
StressMonitorApp/
├── App/
│   ├── StressMonitorApp.swift
│   └── AppDelegate.swift
├── Features/
│   ├── Dashboard/
│   │   ├── Views/
│   │   │   ├── DashboardView.swift
│   │   │   ├── StressLevelView.swift
│   │   │   └── HRVTrendView.swift
│   │   └── ViewModels/
│   │       └── DashboardViewModel.swift
│   ├── HRVMonitoring/
│   │   ├── Services/
│   │   │   ├── HealthKitService.swift
│   │   │   ├── HRVCalculator.swift
│   │   │   └── StressAlgorithm.swift
│   │   └── Models/
│   │       ├── HRVReading.swift
│   │       └── StressLevel.swift
│   ├── Trends/
│   │   ├── Views/
│   │   │   ├── TrendsView.swift
│   │   │   └── ChartComponents.swift
│   │   └── ViewModels/
│   │       └── TrendsViewModel.swift
│   ├── Settings/
│   │   ├── Views/
│   │   │   └── SettingsView.swift
│   │   └── ViewModels/
│   │       └── SettingsViewModel.swift
│   └── Notifications/
│       ├── Services/
│       │   └── NotificationService.swift
│       └── Models/
│           └── NotificationSettings.swift
├── WatchApp/
│   ├── WatchApp.swift
│   ├── ComplicationController.swift
│   └── Views/
│       ├── WatchStressView.swift
│       └── WatchDetailView.swift
├── Shared/
│   ├── Models/
│   │   ├── UserSettings.swift
│   │   └── HealthDataModels.swift
│   ├── Services/
│   │   ├── CloudKitService.swift
│   │   └── PersistenceService.swift
│   └── Utilities/
│       ├── Extensions.swift
│       └── Constants.swift
└── Resources/
    ├── Assets.xcassets
    └── Localizable.strings
```

---

## 4. Implementation Phases

### Phase 1: Foundation (Weeks 1-2)

**Goal**: Set up project structure and establish HealthKit integration

#### Tasks:
- [ ] Create Xcode project with iOS and watchOS targets
- [ ] Configure app signing and capabilities
- [ ] Set up HealthKit entitlements and permissions
- [ ] Create data models (HRVReading, StressLevel, UserSettings)
- [ ] Implement HealthKit service for reading HRV data
- [ ] Implement basic Core Data stack
- [ ] Set up CloudKit for iCloud sync

#### Deliverables:
- Working project that can read and display HRV data from HealthKit
- Basic data persistence layer

---

### Phase 2: Core Stress Algorithm (Weeks 3-4)

**Goal**: Implement stress level calculation algorithm

#### Tasks:
- [ ] Research HRV-to-stress calculation methodology
- [ ] Implement personalized baseline calculation (30-day rolling average)
- [ ] Create stress level classification system
- [ ] Handle edge cases (undefined data, insufficient data)
- [ ] Add unit tests for algorithm

#### Stress Level Classification:
```
┌─────────────────────────────────────────────────────────────┐
│                    Stress Level Matrix                       │
├───────────────┬───────────────────┬─────────────────────────┤
│   Level       │    HRV Status     │    Resting HR           │
├───────────────┼───────────────────┼─────────────────────────┤
│ Relaxed       │ High (above avg)  │ Normal/Low              │
│ Normal        │ Near personal avg │ Normal                  │
│ Elevated      │ Below avg         │ Slightly elevated       │
│ High Stress   │ Significantly low │ Elevated                │
│ Overload      │ Very low          │ Very high               │
└───────────────┴───────────────────┴─────────────────────────┘
```

#### Deliverables:
- Working stress calculation algorithm
- Test suite for validation

---

### Phase 3: iPhone App UI (Weeks 5-7)

**Goal**: Build main iPhone application interface

#### Tasks:
- [ ] Design and implement Dashboard view
- [ ] Create stress level visualization components
- [ ] Build HRV trend charts (hourly, daily, weekly, monthly)
- [ ] Implement historical data views
- [ ] Add settings screen
- [ ] Implement onboarding flow
- [ ] Add notification permission handling

#### Key Views:
```
┌─────────────────────────────────────────────────────┐
│                    Dashboard                         │
├─────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────┐   │
│  │          Current Stress Level                │   │
│  │         [Large circular indicator]           │   │
│  │           "Elevated - 67"                    │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │ Today's  │  │ Current  │  │ 30-Day   │        │
│  │   HRV    │  │   HRV    │  │   Avg    │        │
│  │   45ms   │  │   42ms   │  │   48ms   │        │
│  └──────────┘  └──────────┘  └──────────┘        │
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │         Today's Stress Trend                 │   │
│  │         [Line chart - 24h]                   │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

#### Deliverables:
- Fully functional iPhone app with all core views

---

### Phase 4: Watch App & Complications (Weeks 8-10)

**Goal:** Build watchOS app and watch face complications

#### Tasks:
- [ ] Create watchOS app target
- [ ] Design watch app UI (simplified from iPhone)
- [ ] implement complications for different watch face types
- [ ] Handle complication updates and timeline
- [ ] Implement watch-iPhone data synchronization
- [ ] Add stress notifications on watch
- [ ] Optimize for battery life

#### Complication Templates:
```
Modular Small:     [65] - Stress number
Modular Large:     [Stress: Elevated]
Circular Small:    [Color indicator]
Graphic Corner:    [Stress gauge]
Graphic Bezel:     [Circular stress meter]
```

#### Deliverables:
- Working watch app with complications

---

### Phase 5: Background Monitoring & Notifications (Weeks 11-12)

**Goal:** Implement continuous monitoring and alerts

#### Tasks:
- [ ] Set up background app refresh scheduling
- [ ] Implement background HRV data fetching
- [ ] Create stress threshold detection
- [ ] Build notification scheduling system
- [ ] Add notification preferences in settings
- [ ] Handle notification permission changes
- [ ] Test battery impact and optimize

#### Notification Triggers:
- HRV drops below personal threshold
- Stress level remains "High" for extended period
- Daily stress summary (morning/evening)
- Weekly insights

#### Deliverables:
- Background monitoring system
- Notification system

---

### Phase 6: Data Sync & Cloud Features (Weeks 13-14)

**Goal:** Implement iCloud sync and data management

#### Tasks:
- [ ] Set up CloudKit container and schema
- [ ] Implement sync for all user data
- [ ] Handle sync conflicts
- [ ] Add sync status indicator
- [ ] Implement data export functionality
- [ ] Add data deletion capability (GDPR compliance)

#### Data to Sync:
- HRV readings
- Stress level history
- User settings and preferences
- Custom stress thresholds
- Notification preferences

#### Deliverables:
- Working iCloud sync across devices

---

### Phase 7: Pro Features (Weeks 15-18) - Optional

**Goal:** Implement premium subscription features

#### Tasks:
- [ ] Set up StoreKit for subscriptions
- [ ] Implement sleep tracking integration
- [ ] Build mood logging system
- [ ] Create hydration tracking
- [ ] Add caffeine consumption tracker
- [ ] Implement breathing exercise feature
- [ ] Build heart rate zone analysis
- [ ] Add custom theme system

#### Pro Feature Matrix:
```
┌─────────────────────┬──────────┬──────────┐
│     Feature         │   Free   │   Pro    │
├─────────────────────┼──────────┼──────────┤
│ Today's HRV         │    ✓     │    ✓     │
│ Current HRV         │    ✓     │    ✓     │
│ Real-time Stress    │    ✓     │    ✓     │
│ Stress Trends       │    ✓     │    ✓     │
│ Historical Data     │    ✓     │    ✓     │
│ Sleep Analysis      │    ✗     │    ✓     │
│ Mood Tracking       │    ✗     │    ✓     │
│ Water Tracking      │    ✗     │    ✓     │
│ Caffeine Tracking   │    ✗     │    ✓     │
│ Breathing Exercises │    ✗     │    ✓     │
│ Custom Themes       │    Limited│   Full   │
└─────────────────────┴──────────┴──────────┘
```

#### Deliverables:
- Premium feature set
- Subscription system

---

### Phase 8: Testing & Optimization (Weeks 19-20)

**Goal:** Polish and prepare for App Store submission

#### Tasks:
- [ ] Comprehensive testing on multiple devices
- [ ] Battery usage optimization
- [ ] Performance profiling
- [ ] UI/UX refinement
- [ ] Accessibility audit
- [ ] Localization (if applicable)
- [ ] App Store preview preparation
- [ ] Documentation and help content

#### Testing Checklist:
- [ ] iPhone 15 Pro Max, 15 Pro, 15, SE
- [ ] Apple Watch Series 9, Ultra 2, SE
- [ ] Different iOS/watchOS versions
- [ ] Low battery scenarios
- [ ] Background sync reliability
- [ ] Notification delivery
- [ ] App lifecycle (background, terminate)

#### Deliverables:
- Production-ready app
- App Store submission assets

---

## 5. Key Algorithms

### 5.1 Stress Level Calculation

```swift
// Pseudo-code for stress calculation
func calculateStressLevel(
    currentHRV: Double,
    restingHeartRate: Double,
    personalBaseline: PersonalBaseline
) -> StressLevel {

    // HRV deviation from personal baseline
    let hrvDeviation = (currentHRV - personalBaseline.averageHRV) / personalBaseline.hrvStdDev

    // Resting HR comparison
    let rhrElevation = (restingHeartRate - personalBaseline.averageRHR) / personalBaseline.averageRHR

    // Combined stress score
    let stressScore = (-hrvDeviation * 0.6) + (rhrElevation * 0.4)

    // Map to stress level
    switch stressScore {
    case ...(-1.5): return .relaxed
    case -1.5...(-0.5): return .normal
    case -0.5...0.5: return .elevated
    case 0.5...1.5: return .highStress
    case 1.5...: return .overload
    default: return .undefined
    }
}
```

### 5.2 Personal Baseline Calculation

```swift
// 30-day rolling average calculation
func updatePersonalBaseline(readings: [HRVReading]) -> PersonalBaseline {
    let last30Days = readings.filter { $0.date >= Date().addingTimeInterval(-30*24*3600) }

    let avgHRV = last30Days.map { $0.hrv }.reduce(0, +) / Double(last30Days.count)
    let avgRHR = last30Days.map { $0.restingHeartRate }.reduce(0, +) / Double(last30Days.count)

    let variance = last30Days.map { pow($0.hrv - avgHRV, 2) }.reduce(0, +) / Double(last30Days.count)
    let stdDev = sqrt(variance)

    return PersonalBaseline(averageHRV: avgHRV, averageRHR: avgRHR, hrvStdDev: stdDev)
}
```

---

## 6. Data Models

### 6.1 Core Models

```swift
struct HRVReading: Identifiable, Codable {
    let id: UUID
    let date: Date
    let hrv: Double          // in milliseconds
    let heartRate: Double    // BPM
    let restingHeartRate: Double?
    let source: Source       // watch, manual, etc.
    let quality: MeasurementQuality
}

struct StressLevel: Identifiable, Codable {
    let id: UUID
    let date: Date
    let level: Level
    let score: Double        // -2.0 to 2.0
    let hrvValue: Double
    let rhrValue: Double?
    let factors: [StressFactor]

    enum Level: String, CaseIterable {
        case relaxed = "Relaxed"
        case normal = "Normal"
        case elevated = "Elevated"
        case highStress = "High Stress"
        case overload = "Overload"
        case undefined = "Undefined"
    }
}

struct PersonalBaseline: Codable {
    let averageHRV: Double
    let averageRHR: Double
    let hrvStdDev: Double
    let lastUpdated: Date
    let minimumDataPoints: Int = 30  // days needed
}

struct UserSettings: Codable {
    var notificationsEnabled: Bool
    var stressThreshold: StressLevel.Level
    var syncToCloud: Bool
    var preferredTheme: Theme
    var units: UnitPreference
}
```

---

## 7. HealthKit Integration

### 7.1 Required HealthKit Permissions

```swift
let healthTypesToRead: Set<HKObjectType> = [
    HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
    HKQuantityType.quantityType(forIdentifier: .heartRate)!,
    HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
    HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!,
    HKObjectType.workoutType()
]
```

### 7.2 Query Strategy

```swift
// Query HRV data for the last 24 hours
func queryHRVData(completion: @escaping ([HKQuantitySample]) -> Void) {
    let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    let now = Date()
    let startOfDay = Calendar.current.startOfDay(for: now)

    let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

    let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
        completion(samples ?? [])
    }

    healthStore.execute(query)
}
```

---

## 8. Notification Strategy

### 8.1 Notification Types

| Type | Trigger | Content |
|------|---------|---------|
| Stress Alert | HRV below threshold | "Your stress level is elevated. Consider taking a break." |
| Daily Summary | 9 AM / 9 PM | "Your average stress today: Normal" |
| Weekly Report | Sunday 8 PM | "This week's stress insights..." |
| Achievement | Milestone reached | "30-day stress baseline established!" |

### 8.2 Scheduling Code Pattern

```swift
func scheduleStressNotifications() {
    let center = UNUserNotificationCenter.current()

    // Daily morning summary
    let morningTrigger = UNCalendarNotificationTrigger(
        dateMatching: DateComponents(hour: 9, minute: 0),
        repeats: true
    )

    let morningContent = UNMutableNotificationContent()
    morningContent.title = "Good Morning"
    morningContent.body = "Check your stress baseline for today"

    let morningRequest = UNNotificationRequest(
        identifier: "morning-summary",
        content: morningContent,
        trigger: morningTrigger
    )

    center.add(morningRequest)
}
```

---

## 9. Privacy & Security

### 9.1 Privacy Principles (Following StressWatch's Approach)

```
┌─────────────────────────────────────────────────────────────┐
│                    Privacy First                            │
├─────────────────────────────────────────────────────────────┤
│  ✓ Health data stored locally on device                     │
│  ✓ Seamless iCloud sync (end-to-end encrypted)              │
│  ✓ No health data uploads to external servers               │
│  ✓ No ads or analytics on health data                       │
│  ✓ User has full control over data deletion                 │
│  ✓ Comply with GDPR, CCPA, and App Store guidelines         │
└─────────────────────────────────────────────────────────────┘
```

### 9.2 Data Storage

- **Local Health Data**: Stored in HealthKit (system encrypted)
- **App Settings**: UserDefaults + Keychain for sensitive values
- **Sync**: CloudKit private database (user-specific, encrypted)
- **Analytics**: Only non-identifiable usage patterns (optional)

---

## 10. Monetization Strategy

### 10.1 Freemium Model

| Tier | Price | Features |
|------|-------|----------|
| Free | $0 | Basic HRV, stress levels, 7-day trends |
| Monthly | $4.99/mo | All features, unlimited history |
| Yearly | $29.99/yr | All features, ~50% savings |

### 10.2 StoreKit Configuration

```swift
enum SubscriptionProduct: String, CaseIterable {
    case monthlyPremium = "com.yourapp.premium.monthly"
    case yearlyPremium = "com.yourapp.premium.yearly"

    var localizedTitle: String {
        switch self {
        case .monthlyPremium: return "Monthly Premium"
        case .yearlyPremium: return "Yearly Premium"
        }
    }
}
```

---

## 11. Development Checklist Summary

### Pre-Development
- [ ] Apple Developer Program enrollment
- [ ] Xcode 15+ installation
- [ ] Test devices (iPhone + Apple Watch)
- [ ] Design mockups (Figma/Sketch)
- [ ] Technical specs finalization

### Development
- [ ] Project setup (iOS + watchOS)
- [ ] HealthKit integration
- [ ] Core data models
- [ ] Stress algorithm implementation
- [ ] iPhone UI development
- [ ] Watch app development
- [ ] Complications implementation
- [ ] Background tasks setup
- [ ] Notification system
- [ ] CloudKit sync
- [ ] Testing & bug fixes
- [ ] Performance optimization

### Pre-Launch
- [ ] App Store Connect setup
- [ ] Privacy policy & terms
- [ ] Screenshots & previews
- [ ] App description
- [ ] TestFlight beta testing
- [ ] App Store submission

---

## 12. Success Metrics

| Metric | Target | Timeline |
|--------|--------|----------|
| App Store Approval | ✅ Approved | Week 21 |
| First 100 Downloads | 100 users | Month 1 |
| App Store Rating | 4.5+ stars | Month 3 |
| Active Users (DAU/MAU) | 30%+ | Month 3 |
| Subscription Conversion | 5-10% | Month 6 |

---

## 13. Potential Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| HealthKit API changes | High | Keep updated with Apple docs, use stable APIs |
| watchOS bugs (known from StressWatch FAQ) | Medium | Document workarounds, provide user support |
| Battery drain concerns | High | Aggressive testing, optimization |
| App Store rejection (medical claims) | High | Avoid medical language, focus on wellness |
| Low user retention | Medium | Build engaging features, notifications |
| Competition (StressWatch, Welltory, etc.) | Medium | Focus on UX, unique features |

---

## 14. Resources & References

### Apple Documentation
- [HealthKit](https://developer.apple.com/documentation/healthkit)
- [WatchKit](https://developer.apple.com/documentation/watchkit)
- [CloudKit](https://developer.apple.com/documentation/cloudkit)
- [Background Tasks](https://developer.apple.com/documentation/backgroundtasks)

### Research Papers (Referenced by StressWatch)
1. Shaffer, F., & Ginsberg, J. P. (2017). An overview of heart rate variability metrics and norms
2. Kim, H. G., et al. (2018). Stress and Heart Rate Variability: A Meta-Analysis
3. Delaney, J. P. A., & Brodie, D. A. (2000). Effects of Short-Term Psychological Stress on HRV

### Similar Apps for Research
- StressWatch (https://stresswatch.app/)
- Welltory
- WHOOP
- Oura Ring

---

## 15. Next Steps

1. **Immediate Actions:**
   - Create Apple Developer account
   - Set up development environment
   - Create detailed UI mockups
   - Define exact stress algorithm parameters

2. **Week 1 Priorities:**
   - Initialize Xcode project
   - Implement HealthKit reader
   - Create first prototype

3. **Validation:**
   - Test with small group of users
   - Validate stress algorithm accuracy
   - Gather feedback on UX

---

**Document Version:** 1.0
**Last Updated:** 2025-01-18
**Created By:** Phuong Doan
