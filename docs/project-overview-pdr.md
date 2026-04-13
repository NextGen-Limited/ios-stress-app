# StressMonitor: Product Overview & Requirements

**Version:** 1.0 (Production)
**Status:** Complete and Shipping
**Platform:** iOS 17+ / watchOS 10+
**Last Updated:** April 13, 2026

---

## Product Vision

StressMonitor is a **privacy-first stress monitoring application** that uses Heart Rate Variability (HRV) data from HealthKit to calculate real-time stress levels. The app features personal baseline adaptation, cross-device synchronization via CloudKit, and a full-featured Apple Watch companion with WidgetKit complications.

**Core Value Proposition:** Understand your stress patterns with a personal, scientifically-grounded stress algorithm—no external servers, zero tracking, complete data ownership.

---

## Key Features

### Core Features (v1.0 - Complete)

| Feature | Description | Status |
|---------|-------------|--------|
| **Real-Time Stress Measurement** | On-demand HRV + HR calculation with confidence scoring | ✅ Complete |
| **Personal Baseline Adaptation** | Learns individual physiology over 30 days | ✅ Complete |
| **Historical Tracking** | Timeline view with date/category filtering | ✅ Complete |
| **Trend Analytics** | Line charts, bar charts, heatmap, distribution stats — Figma-aligned | ✅ Complete |
| **AI-Powered Insights** | Personalized insights via InsightGeneratorService | ✅ Complete |
| **Weekly Dot-Matrix Timeline** | 7-day × 7-slot dot grid replacing 24h scatter chart | ✅ Complete |
| **Apple Watch Standalone App** | Independent stress monitoring with WidgetKit complications | ✅ Complete |
| **CloudKit Sync** | E2E encrypted offline-first cloud sync | ✅ Complete |
| **Data Export** | CSV/JSON export with date filtering | ✅ Complete |
| **Data Management** | Delete by range, category, or full wipe | ✅ Complete |
| **Breathing Exercises** | Guided 4-7-8 technique sessions | ✅ Complete |
| **Home Screen Widgets** | At-a-glance stress display | ✅ Complete |
| **WCAG AA Accessibility** | Dual coding, VoiceOver, Dynamic Type | ✅ Complete |

### Planned Features (v1.1)

- Advanced breathing techniques (box breathing, coherent breathing)
- Stress triggers tracking
- Weekly digest reports
- App localization (Spanish, French, German)

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
- `StressFactor` protocol — each factor calculates `FactorContribution` independently
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
**I want to** tap a button and get my current stress level
**So that** I can understand my physiological state at any moment

**Acceptance Criteria:**
- [x] Measure button accessible from Dashboard
- [x] Calculation completes within 5 seconds
- [x] Result displays stress level with color and category
- [x] Confidence score visible
- [x] Data auto-saves to SwiftData and CloudKit

### User Story 2: Track Historical Stress
**As a** user
**I want to** see all my past stress measurements with filtering
**So that** I can identify patterns over time

**Acceptance Criteria:**
- [x] ~~History view shows chronological list~~ (REMOVED - Mar 2026)
- [x] ~~Filter by date range~~ (REMOVED)
- [x] ~~Filter by stress category~~ (REMOVED)
- [x] ~~Tap measurement to view details~~ (REMOVED)
- [x] ~~Export available from detail view~~ (REMOVED)

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

### User Story 5: Reduce Stress with Breathing
**As a** user
**I want to** follow guided breathing exercises
**So that** I can actively reduce my stress level

**Acceptance Criteria:**
- [x] Breathing exercise available from Dashboard
- [x] Guided visual/haptic feedback
- [x] Before/after HRV measurement option
- [x] Session history tracked

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
- Zero external API calls

---

## Technical Constraints

| Constraint | Impact | Mitigation |
|-----------|--------|-----------|
| **iOS 17+ only** | Excludes iOS 16 users | Feature target for modern users |
| **HealthKit dependency** | Requires health data access | Graceful degradation on denial |
| **iCloud requirement** | CloudKit sync needs account | Optional feature, not required |
| **No external dependencies** | Limited third-party libraries | Leverage system frameworks |

---

## Data Privacy & Security

### Privacy-First Design
- **Local Storage:** SwiftData (encrypted at rest by iOS)
- **No External Servers:** Zero third-party services
- **Read-Only HealthKit:** No writes to Apple Health
- **CloudKit E2E Encryption:** End-to-end encrypted sync
- **No Tracking:** No analytics, no advertising IDs
- **User Control:** Full export/delete functionality

### Data Flow
```
HealthKit (Sensors) → HealthKitManager (read-only)
→ StressCalculator (local computation)
→ SwiftData (local encrypted storage)
→ CloudKit (optional, E2E encrypted)
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
- Advanced breathing techniques
- Stress triggers journal
- Weekly reports
- Localization

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

**Owner:** Phuong Doan
**Status:** ✅ Production v1.0
**Next Review:** May 2026 (post v1.1 release)
