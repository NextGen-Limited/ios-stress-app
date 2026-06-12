# StressMonitor - Ship Readiness Kanban

> Generated: 2026-06-07 | Target: App Store Submission

---

## 🔴 BLOCKER (Must fix before ship)

### B1: AI Chat - Hardcoded Endpoint ~~(RESOLVED)~~
- [x] ~~Replace ngrok URL `https://hyperpolysyllabically-saronic-mee.ngrok-free.app` with production endpoint~~ — Deleted dead code; SupabaseLLMService is the production service
- [x] ~~Remove hardcoded `Bearer changeme` auth token~~ — Deleted CloudLLMService.swift
- [x] ~~Move API config to Environment / remote config~~ — SupabaseLLMService uses SupabaseConfig for proper endpoint configuration
- **Files:** ~~`CloudLLMService.swift`, `LLMAPITarget.swift`~~ — Both deleted
- **Priority:** P0 | **Effort:** M | **Status:** ✅ Done

### B2: IAP / Premium - No Real StoreKit
- [ ] Implement `StoreKitService` (conform to `StoreKitServiceProtocol`)
- [ ] SKProduct fetching from App Store Connect
- [ ] Purchase flow with Apple's servers
- [ ] Receipt validation
- [ ] Restore purchases flow
- [ ] Subscription status polling
- [ ] Remove `MockStoreKitService` from production builds
- [ ] **Files:** `StoreKitServiceProtocol.swift`, `MockStoreKitService.swift`, `PremiumViewModel.swift`
- **Priority:** P0 | **Effort:** L | **Status:** Backlog

### B3: Test Suite - Placeholder Only
- [ ] Write tests for `MultiFactorStressCalculator` (5 factor tests)
- [ ] Write tests for `StressViewModel` (state management)
- [ ] Write tests for `DashboardViewModel` (data flow)
- [ ] Write tests for `HealthKitManager` (fetch logic)
- [ ] Write tests for `CloudKitManager` (CRUD operations)
- [ ] Write tests for `SyncManager` (bidirectional sync)
- [ ] Write tests for `DataManagementService` (export/delete)
- [ ] Write integration tests for end-to-end stress calculation
- [ ] Remove placeholder test (`@Test func placeholder() { }`)
- [ ] **Files:** `StressMonitorTests/`, `StressMonitorUITests/`
- **Priority:** P0 | **Effort:** XL | **Status:** Backlog

---

## 🟡 HIGH (Should fix before ship)

### H1: Onboarding Flow Not Integrated
- [ ] Add onboarding state check in `StressMonitorApp.swift` or `MainTabView`
- [ ] Route new users through 4-step onboarding
- [ ] Persist onboarding completion in UserDefaults/AppStorage
- [ ] Remove "Sign in" placeholder button from Welcome screen
- [ ] **Files:** `StressMonitorApp.swift`, `MainTabView.swift`, `OnboardingWelcomeView.swift`
- **Priority:** P1 | **Effort:** S | **Status:** Backlog

### H2: CloudKit Sync - Merge Bug
- [ ] Fix `ConflictResolver.mergeMeasurements()` — merged object created but not returned
- [ ] Implement proper merge strategy (weighted average, timestamp priority)
- [ ] Add sync conflict resolution tests
- [ ] **Files:** `ConflictResolver.swift`, `SyncManager.swift`
- **Priority:** P1 | **Effort:** M | **Status:** Backlog

### H3: CloudKit E2E Encryption Missing
- [ ] Implement client-side encryption for CloudKit records
- [ ] Add encryption key management (Keychain)
- [ ] Update `CloudKitSchema` for encrypted fields
- [ ] Update docs to match implementation
- [ ] **Files:** `CloudKitManager.swift`, `CloudKitSchema.swift`
- **Priority:** P1 | **Effort:** L | **Status:** Backlog

### H4: Apple Intelligence Strategy
- [ ] Uncomment cloud-first strategy in `ChatViewModel` (lines 51-57)
- [ ] Make Apple Intelligence the default for iOS 26+ devices
- [ ] Add proper async availability check
- [ ] **Files:** `ChatViewModel.swift`, `AppleIntelligenceService.swift`
- **Priority:** P1 | **Effort:** M | **Status:** Backlog

### H5: Notifications - Incomplete
- [ ] Implement scheduled daily stress summary notification
- [ ] Implement weekly report notification
- [ ] Implement quiet hours logic (user-configurable)
- [ ] Implement morning readiness check notification
- [ ] Wire notification settings UI to actual logic
- [ ] **Files:** `NotificationManager.swift`, `HealthBackgroundScheduler.swift`, `NotificationSettings.swift`
- **Priority:** P1 | **Effort:** M | **Status:** Backlog

---

## 🟢 MEDIUM (Nice to have for v1.0)

### M1: Settings - CloudKit Status Placeholder
- [ ] Replace `// TODO: Implement actual CloudKit status check` with real implementation
- [ ] Wire CloudKit sync status to Settings UI
- [ ] **Files:** `SettingsViewModel.swift`
- **Priority:** P2 | **Effort:** S | **Status:** Backlog

### M2: Watch App - Limited Navigation
- [ ] Add navigation to breathing exercise from Watch
- [ ] Add quick history view on Watch
- [ ] Enhance complication data freshness
- [ ] **Files:** Watch App `ContentView.swift`, `ComplicationBundle.swift`
- **Priority:** P2 | **Effort:** M | **Status:** Backlog

### M3: SyncManager Upload Bug
- [ ] Fix `SyncManager.sync()` — only uploads first measurement when `needsUpload`
- [ ] Batch upload all pending measurements
- [ ] **Files:** `SyncManager.swift`
- **Priority:** P2 | **Effort:** S | **Status:** Backlog

### M4: Accessibility Audit
- [ ] Run VoiceOver audit on all views
- [ ] Verify Dynamic Type on all screens
- [ ] Verify minimum 44x44pt touch targets
- [ ] Verify dual coding (color + icon/text) for stress levels
- [ ] Test with accessibility inspector
- [ ] **Priority:** P2 | **Effort:** M | **Status:** Backlog

### M5: Error Handling Polish
- [ ] Add user-facing error messages for all service failures
- [ ] Add retry UI for CloudKit sync failures
- [ ] Add graceful offline mode indicators
- [ ] **Priority:** P2 | **Effort:** S | **Status:** Backlog

---

## ⚪ LOW (Post-launch backlog)

### L1: UI Tests
- [ ] Write UI tests for critical user flows
- [ ] Onboarding → Dashboard → Stress measurement
- [ ] History view → Detail → Export
- [ ] Settings → Notification preferences
- [ ] **Priority:** P3 | **Effort:** L | **Status:** Backlog

### L2: Performance Optimization
- [ ] Profile dashboard load time
- [ ] Optimize SwiftData queries
- [ ] Reduce HealthKit query frequency
- [ ] Benchmark algorithm calculation time
- [ ] **Priority:** P3 | **Effort:** M | **Status:** Backlog

### L3: Analytics / Telemetry
- [ ] Add analytics events for key actions
- [ ] Track stress measurement frequency
- [ ] Track feature usage (breathing, chat, export)
- [ ] **Priority:** P3 | **Effort:** M | **Status:** Backlog

---

## ✅ READY TO SHIP (No action needed)

| # | Feature | Completeness |
|---|---------|-------------|
| 1 | Dashboard (30+ components) | 95% |
| 2 | Stress Algorithm (5 factors + calibration) | 95% |
| 3 | HealthKit Integration (7 data types) | 90% |
| 4 | iOS Home Screen Widget (3 sizes) | 90% |
| 5 | Data Export (CSV, JSON, delete) | 95% |
| 6 | Breathing Exercises (Box + Walking) | 90% |
| 7 | Trends & History (charts, insights) | 90% |

---

## Progress Tracker

| Column | Count |
|--------|-------|
| 🔴 BLOCKER | 3 |
| 🟡 HIGH | 5 |
| 🟢 MEDIUM | 5 |
| ⚪ LOW | 3 |
| ✅ READY | 7 |
| **Total** | **23** |

---

## Recommended Ship Sequence

```
Phase 1 (Week 1): BLOCKERS
  B1 → H1 → H4 (AI Chat + Onboarding + Apple Intelligence)

Phase 2 (Week 2): SYNC + NOTIFICATIONS  
  H2 → H3 → H5 (CloudKit fixes + Notifications)

Phase 3 (Week 3): IAP + TESTS
  B2 → B3 (StoreKit implementation + Test suite)

Phase 4 (Week 4): POLISH
  M1 → M2 → M3 → M4 → M5 (Settings, Watch, Accessibility)

Phase 5 (Post-launch): L1 → L2 → L3
```
