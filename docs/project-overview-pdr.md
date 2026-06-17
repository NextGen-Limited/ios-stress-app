# StressMonitor: Product Overview & Requirements

**Version:** 1.0 (Pre-Ship - RC1)
**Status:** Feature Complete — 1 Blocker Pending (B3 test suite)
**Platform:** iOS 17+ / watchOS 10+
**Last Updated:** June 17, 2026

---

## Product Vision

StressMonitor is a **privacy-first stress monitoring application** that uses Heart Rate Variability (HRV) data from HealthKit to calculate real-time stress levels. The app features personal baseline adaptation, cross-device synchronization via CloudKit, and a full-featured Apple Watch companion with WidgetKit complications.

**Core Value Proposition:** Understand your stress patterns with a personal, scientifically-grounded stress algorithm—no external servers, zero tracking, complete data ownership.

---

## Key Features

### Core Features (v1.0 - Complete)

| Feature | Description | Status |
|---------|-------------|--------|
| **Real-Time Stress Measurement** | 5-factor algorithm (HRV, HR, Sleep, Activity, Recovery) with confidence scoring | ✅ Complete |
| **Personal Baseline Adaptation** | Learns individual physiology over 30 days | ✅ Complete |
| **Historical Tracking** | Timeline view with date/category filtering | ✅ Complete |
| **Trend Analytics** | Line charts, bar charts, heatmap, distribution stats -- Figma-aligned | ✅ Complete |
| **AI-Powered Insights** | Personalized insights via InsightGeneratorService | ✅ Complete |
| **AI Chat** | Conversational AI via SupabaseLLMService (primary) + Apple Intelligence (iOS 26+ fallback) with SSE streaming | ✅ Complete |
| **Weekly Dot-Matrix Timeline** | 7-day x 7-slot dot grid replacing 24h scatter chart | ✅ Complete |
| **Apple Watch Standalone App** | Independent stress monitoring with WidgetKit complications | ✅ Complete |
| **CloudKit Sync** | E2E encrypted offline-first cloud sync | ✅ Complete |
| **Data Export** | CSV/JSON export with date filtering | ✅ Complete |
| **Data Management** | Delete by range, category, or full wipe | ✅ Complete |
| **Box Breathing** | Figma-aligned 4-4-4-4 pattern, 3-min sessions | ✅ Complete |
| **5-Tab Navigation** | Home/Trends/Breathing/Characters/Settings structure (May 2026) | ✅ Complete |
| **Mini Walk Exercise** | Walking exercise with circular timer and Figma-aligned design | ✅ Complete |
| **Real StoreKit 2 Premium** | Real App Store product fetching + transaction monitoring (PR #19 Jun 12) | ✅ Complete |
| **Stress History Timeline** | Activity correlation with stress measurements | ✅ Complete |
| **Guided Breathing with Biofeedback** | Enhanced breathing with real-time feedback | ✅ Complete |
| **Morning Readiness Check** | HRV trend analysis for daily readiness assessment | ✅ Complete |
| **Home Screen Widgets** | At-a-glance stress display | ✅ Complete |
| **Character Collection UI** | 5 elemental characters with 3-stage evolution, free/premium/streak unlocks, 38 SVG assets | ✅ Complete |
| **3-Tab Navigation** | Home/Action/Trend structure with Settings non-tab (Jun 17) | ✅ Complete |
| **Biological Age Calculator** | Estimates biological age from HRV, resting HR, sleep; 7-day min requirement | ✅ Complete |
| **Watch Face Personalization** | Background style selection synced via WatchConnectivity | ✅ Complete |
| **Weekly Billing Option** | Added `SubscriptionPeriod.weekly` to premium tier | ✅ Complete |
| **WCAG AA Accessibility** | Dual coding, VoiceOver, Dynamic Type | ✅ Complete |

### Ship Blockers (CRITICAL - must resolve before App Store submission)

| Blocker | Issue | Status |
|---------|-------|--------|
| ~~**B1**~~ | ~~CloudLLMService hardcoded ngrok endpoint~~ | ✅ Resolved Jun 7 (SupabaseLLMService) |
| ~~**B2**~~ | ~~StoreKit implementation is mock-only~~ | ✅ Resolved Jun 12 (Real StoreKit 2 - PR #19) |
| **B3** | Test suite is placeholder only | 🚫 P0 Blocking (comprehensive rewrite pending) |

### Planned Features (v1.1)

- Additional breathing techniques (coherent breathing, custom patterns)
- Stress triggers tracking
- Weekly digest reports
- App localization (Spanish, French, German)
- Comprehensive test suite reimplementation

---

## Stress Algorithm

### Multi-Factor Model (5 Factors)

The stress algorithm uses 5 independent factors with dynamic weight redistribution:

**Factors:**
1. **HRV** (HRVStressFactor) — Heart rate variability analysis
2. **Heart Rate** (HeartRateStressFactor) — Elevated HR detection
3. **Sleep Quality** (SleepStressFactor) — Sleep impact on stress
4. **Physical Activity** (ActivityStressFactor) — Activity stress impact
5. **Recovery Status** (RecoveryStressFactor) — Recovery assessment

**Architecture:**
- `StressFactor` protocol — each factor returns a `FactorBreakdown` independently
- `MultiFactorStressCalculator` — orchestrates all factors, applies dynamic weight redistribution
- `FactorWeights` — base weights with redistribution when factors are unavailable
- `FactorBreakdown` — per-factor results for UI display
- `StressContext` — aggregates all health data into single input

```
HealthKit → HRV + HR + Sleep + Activity + Recovery
    → MultiFactorStressCalculator
        → Each StressFactor.calculateContribution(context:)
        → Weight redistribution if factors missing
        → Final Stress Level (0-100) + FactorBreakdown
```

### Stress Categories (0-100 Scale)

| Category | Range | Indicator | User Action |
|----------|-------|-----------|------------|
| **Relaxed** | 0-25 | 🟢 Green | Optimal state |
| **Mild Stress** | 25-50 | 🔵 Blue | Monitor |
| **Moderate Stress** | 50-75 | 🟡 Yellow | Consider intervention |
| **High Stress** | 75-100 | 🟠 Orange | Take action |

### Confidence Scoring

Each measurement includes a confidence value (0-1) based on:
- Factor availability: More available factors increase confidence
- HRV quality: Penalty if <20ms (unreliable)
- Heart rate validity: Penalty if <40 or >180 bpm (outliers)
- Sample count: More historical samples increase confidence
- Weight redistribution reduces confidence when factors are missing

---

## User Stories & Acceptance Criteria

### User Story 1: Measure Stress on Demand
**As a** user
**I want to** access stress measurement from Home dashboard
**So that** I can understand my physiological state at any moment

**Acceptance Criteria:**
- [x] Stress measurement accessible from Dashboard
- [x] Calculation completes within 5 seconds
- [x] Result displays stress level with color and category
- [x] Confidence score visible
- [x] Data auto-saves to SwiftData and CloudKit

### User Story 2: Track Historical Stress
**As a** user
**I want to** see all my past stress measurements with filtering
**So that** I can identify patterns over time

**Acceptance Criteria:**
- [x] History view shows chronological list of measurements
- [x] Filter by date range and category
- [x] Tap measurement to view details with factor breakdown
- [x] Factor progress bars and stress gauge visualization

### User Story 3: Analyze Stress Trends
**As a** user
**I want to** visualize stress trends with charts
**So that** I can see if I'm getting more or less stressed

**Acceptance Criteria:**
- [x] Line chart shows stress over 24h/week/month
- [x] Distribution chart shows % time per category
- [x] Statistics displayed (avg, min, max, std dev)
- [x] Charts update when new data arrives

### User Story 4: Monitor on Apple Watch
**As a** user
**I want to** measure stress directly on my Apple Watch
**So that** I don't need my iPhone

**Acceptance Criteria:**
- [x] Watch app is fully functional standalone
- [x] Complications show current stress level
- [x] Data syncs to CloudKit independently
- [x] Complications update every 5 minutes

### User Story 5: Access Quick Actions and Tools
**As a** user
**I want to** quickly access breathing exercises and AI chat
**So that** I can take immediate action to manage stress

**Acceptance Criteria:**
- [x] ActionView provides quick access to breathing exercises
- [x] AI chat accessible from ActionView
- [x] Figma-aligned breathing guidance with animations
- [x] 3-minute breathing sessions with effectiveness tracking

---

## Non-Functional Requirements

| Requirement | Target | Rationale |
|------------|--------|-----------|
| **Performance** | Stress calculation <1s | Real-time UX |
| **Offline Mode** | Full functionality without internet | Privacy + reliability |
| **Battery Life** | <5% daily impact on typical device | Minimize burden |
| **Data Sync Latency** | <30 seconds between devices | Acceptable delay |
| **Test Coverage** | >80% of core services | Reduce regressions |
| **Accessibility** | WCAG AA compliant | Legal + ethical |
| **Security** | E2E encryption, local-first storage | Privacy promise |

---

## Success Metrics

### User Engagement
- Daily active users (DAU) and monthly active users (MAU)
- Average session duration
- Measurement frequency (per user per day)

### Product Quality
- App crash rate <0.1% (via TestFlight/App Store)
- CloudKit sync success rate >99.5%
- Test coverage >80%

### Privacy & Security
- Zero data breaches
- 100% CloudKit E2E encryption
- Health data never sent externally (only anonymized chat context to CloudLLM)

---

## Technical Constraints

| Constraint | Impact | Mitigation |
|-----------|--------|-----------|
| **iOS 17+ only** | Excludes iOS 16 users | Feature target for modern users |
| **iOS 26+ for Apple Intelligence** | AI Chat limited to newest iOS | SupabaseLLM fallback for older devices |
| **HealthKit dependency** | Requires health data access | Graceful degradation on denial |
| **iCloud requirement** | CloudKit sync needs account | Optional feature, not required |

---

## Data Privacy & Security

### Privacy-First Design
- **Local Storage:** SwiftData (encrypted at rest by iOS)
- **Cloud Chat:** Sends anonymized chat context to Supabase Edge Functions via SupabaseLLMService; health data stays on-device
- **Read-Only HealthKit:** No writes to Apple Health
- **CloudKit E2E Encryption:** End-to-end encrypted sync
- **No Tracking:** No analytics, no advertising IDs
- **User Control:** Full export/delete functionality

### Data Flow
```
HealthKit (Sensors) -> HealthKitManager (read-only)
-> MultiFactorStressCalculator (local computation)
-> SwiftData (local encrypted storage)
-> CloudKit (optional, E2E encrypted)

AI Chat (separate path):
ActionView -> ChatBottomSheetView -> ChatViewModel
-> SupabaseLLMService (SSE streaming to Supabase Edge Functions) OR
   AppleIntelligenceService (on-device, iOS 26+)
-> ChatContextBuilder (assembles anonymized context only)
-> SSEParser for Server-Sent Events streaming
```

---

## Accessibility (WCAG AA)

- **Dual Coding:** Stress levels use color + icon + text
- **VoiceOver:** Full screen reader support
- **Dynamic Type:** All text scales with system settings
- **Touch Targets:** Minimum 44x44 points
- **Haptic Feedback:** Tactile confirmation of actions
- **Color Blindness:** UI usable without color alone

---

## Deployment & Release

### Build Environments
- **Debug:** Development with full logging
- **Release:** Optimized production builds

### Distribution Channels
- TestFlight (beta testing)
- App Store (production)

### Required Capabilities
- HealthKit (read HRV + HR)
- iCloud/CloudKit (sync)
- App Groups (widget data sharing)
- Background Modes (app refresh)

---

## Roadmap

### Version 1.0 (Current)
All core features complete and shipping.

### Version 1.1 (Next)
- Additional breathing techniques
- Stress triggers journal
- Weekly reports
- Localization
- Test suite reimplementation

### Version 2.0 (Future)
- Machine learning insights
- Sleep/activity correlation
- Siri Shortcuts
- iPad app

---

## Acceptance Criteria Summary

**Project is considered complete when:**
1. All core features implemented and tested
2. Test coverage >80%
3. CloudKit sync operates reliably
4. App passes App Store review
5. No critical bugs in TestFlight
6. Accessibility audit passes WCAG AA
7. Privacy policy accepted by legal

---

## Ship Status Summary

**Current:** v1.0 Feature Complete (RC1)
**Blockers:** 1 critical remaining (B3: comprehensive test suite rewrite)
**Resolved:** B1 (Jun 7, SupabaseLLMService) ✅ | B2 (Jun 12, Real StoreKit 2 - PR #19) ✅
**Next Steps:** 
1. Resolve B3 (test suite) — estimated 1-2 weeks
2. TestFlight beta validation
3. App Store submission

---

**Owner:** Phuong Doan
**Status:** Pre-Ship (RC1) — Feature-complete, 1 blocker
**Last Updated:** June 13, 2026
**Target Ship Date:** Post-blocker resolution (target late June 2026)