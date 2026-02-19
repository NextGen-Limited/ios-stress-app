# StressMonitor: Product Overview & Requirements

**Version:** 1.0 (Production)
**Status:** Complete and Shipping
**Platform:** iOS 17+ / watchOS 10+
**Last Updated:** February 2026

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
| **Trend Analytics** | Line charts (24h/week/month), distribution stats | ✅ Complete |
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

### Mathematical Model

```
Normalized HRV = (Baseline HRV - Current HRV) / Baseline HRV
Normalized HR = (Current HR - Resting HR) / Resting HR

HRV Component = (Normalized HRV) ^ 0.8
HR Component = atan(Normalized HR × 2) / (π/2)

Final Stress Level = ((HRV Component × 0.7) + (HR Component × 0.3)) × 100
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
- HRV quality: Penalty if <20ms (unreliable)
- Heart rate validity: Penalty if <40 or >180 bpm (outliers)
- Sample count: More samples increase confidence

---

## User Stories & Acceptance Criteria

### User Story 1: Measure Stress on Demand
**As a** user
**I want to** tap a button and get my current stress level
**So that** I can understand my physiological state at any moment

**Acceptance Criteria:**
- [ ] Measure button accessible from Dashboard
- [ ] Calculation completes within 5 seconds
- [ ] Result displays stress level with color and category
- [ ] Confidence score visible
- [ ] Data auto-saves to SwiftData and CloudKit

### User Story 2: Track Historical Stress
**As a** user
**I want to** see all my past stress measurements with filtering
**So that** I can identify patterns over time

**Acceptance Criteria:**
- [ ] History view shows chronological list
- [ ] Filter by date range (today/week/month/all)
- [ ] Filter by stress category
- [ ] Tap measurement to view details
- [ ] Export available from detail view

### User Story 3: Analyze Stress Trends
**As a** user
**I want to** visualize stress trends with charts
**So that** I can see if I'm getting more or less stressed

**Acceptance Criteria:**
- [ ] Line chart shows stress over 24h/week/month
- [ ] Distribution chart shows % time per category
- [ ] Statistics displayed (avg, min, max, std dev)
- [ ] Charts update when new data arrives

### User Story 4: Monitor on Apple Watch
**As a** user
**I want to** measure stress directly on my Apple Watch
**So that** I don't need my iPhone

**Acceptance Criteria:**
- [ ] Watch app is fully functional standalone
- [ ] Complications show current stress level
- [ ] Data syncs to CloudKit independently
- [ ] Complications update every 5 minutes

### User Story 5: Reduce Stress with Breathing
**As a** user
**I want to** follow guided breathing exercises
**So that** I can actively reduce my stress level

**Acceptance Criteria:**
- [ ] Breathing exercise available from Dashboard
- [ ] Guided visual/haptic feedback
- [ ] Before/after HRV measurement option
- [ ] Session history tracked

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
**Next Review:** March 2026
