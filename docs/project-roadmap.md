# Project Roadmap

**Current Version:** 1.0 (Production)
**Release Date:** February 2026
**Maintenance Mode:** Active
**Last Updated:** February 2026

---

## Version 1.0 (Current - Production)

**Status:** ✅ Complete & Shipping

### Implemented Features

#### Core Functionality
- ✅ Real-time stress measurement (HRV + HR algorithm)
- ✅ Personal baseline adaptation (30-day learning)
- ✅ Confidence scoring (data quality indicator)
- ✅ Stress categorization (Relaxed, Mild, Moderate, High)

#### Data Management
- ✅ Local SwiftData persistence
- ✅ CloudKit E2E encrypted sync
- ✅ CSV export functionality
- ✅ JSON export functionality
- ✅ Delete by date range
- ✅ Delete by category
- ✅ Full data wipe
- ✅ CloudKit reset

#### User Interface
- ✅ Dashboard with stress ring display
- ✅ Historical timeline (measurement list)
- ✅ Trend analytics (24h/week/month charts)
- ✅ Distribution statistics
- ✅ Settings screen
- ✅ Onboarding flow
- ✅ HealthKit permission request

#### Apple Watch
- ✅ Standalone watch app
- ✅ Circular complications (WidgetKit)
- ✅ Rectangular complications
- ✅ Inline complications
- ✅ Watch-to-iPhone sync (WatchConnectivity)
- ✅ Independent CloudKit sync

#### Additional Features
- ✅ Guided breathing exercises (4-7-8 technique)
- ✅ Home screen widgets (small, medium, large)
- ✅ Background health refresh (optional)
- ✅ WCAG AA accessibility compliance
- ✅ VoiceOver support
- ✅ Dynamic Type support
- ✅ Haptic feedback
- ✅ Dark mode support

#### Testing & Quality
- ✅ 100+ unit tests
- ✅ >80% code coverage (core logic)
- ✅ Algorithm validation tests
- ✅ CloudKit sync tests
- ✅ UI component tests
- ✅ Accessibility tests

### Performance Metrics (v1.0)

| Metric | Target | Actual |
|--------|--------|--------|
| **Stress Calculation** | <1s | ~0.3s |
| **Memory (Idle)** | <50MB | 45MB |
| **Memory (100 measurements)** | <100MB | 87MB |
| **CloudKit Sync** | <30s | ~15s (avg) |
| **App Launch** | <2s | 1.8s |
| **Test Pass Rate** | 100% | 100% |

### Release Notes (v1.0)

```
StressMonitor 1.0 - Initial Release

Core Features:
• Heart Rate Variability stress measurement
• Personal baseline adaptation algorithm
• Real-time stress level calculation (0-100 scale)
• Historical tracking with filtering
• Trend analysis with charts

Apple Watch:
• Standalone watch app (independent of iPhone)
• Three complication families (WidgetKit)
• Direct CloudKit sync
• WatchConnectivity bridge to iPhone

Data Management:
• Export to CSV and JSON formats
• Delete data by date range or category
• Complete CloudKit reset
• User data ownership and control

Wellness:
• Guided 4-7-8 breathing exercises
• Session history tracking
• Stress reduction measurement

Accessibility:
• WCAG AA compliant interface
• Full VoiceOver support
• Dynamic Type scaling
• Haptic feedback

Privacy:
• Zero external dependencies
• Local-first architecture
• End-to-end encrypted CloudKit sync
• No tracking or analytics

Note: Privacy-first design ensures all health data
remains on your device or encrypted in iCloud.
```

---

## Version 1.1 (Planned - Q2 2026)

**Status:** 📋 Planned
**Estimated Timeline:** 6-8 weeks development
**Target Release:** April/May 2026

### Proposed Features

#### Advanced Breathing Techniques
- [ ] Box breathing (4-4-4-4)
- [ ] Coherent breathing (6 breaths/minute)
- [ ] Custom pattern builder
- [ ] Session effectiveness tracking
- [ ] Breathing history analytics

**Rationale:** Users request variety in breathing exercises to accommodate different preferences and needs.

**Implementation Notes:**
- Create `BreathingPattern` protocol
- Add UI for pattern visualization
- Store session effectiveness scores
- Integrate with stress measurement

#### Stress Triggers Tracking
- [ ] Event logging system
- [ ] Trigger categories (work, sleep, exercise, food, etc.)
- [ ] Correlation analysis (what increases stress)
- [ ] Pattern detection
- [ ] Personalized insights

**Rationale:** Understanding stress triggers helps users make proactive lifestyle changes.

**Implementation Notes:**
- Extend `StressMeasurement` with optional trigger field
- Add simple event picker UI
- Implement analytics service for correlation
- Display trigger heatmap in Trends

#### Weekly Digest Reports
- [ ] Generate weekly PDF reports
- [ ] Include statistics and charts
- [ ] Trend summaries
- [ ] Breathing effectiveness
- [ ] Shared insights
- [ ] Email delivery (optional)

**Rationale:** Users want a high-level review of their stress patterns.

**Implementation Notes:**
- Create `ReportGenerator` service
- Use PDFKit for PDF generation
- Store report preferences
- Optional email integration (evaluate privacy)

#### App Localization
- [ ] Spanish (es-ES, es-MX)
- [ ] French (fr-FR)
- [ ] German (de-DE)
- [ ] Portuguese (pt-BR)
- [ ] Japanese (ja-JP)

**Rationale:** Expand accessibility to non-English speaking users.

**Implementation Notes:**
- Use Xcode Localization features
- Create Localizable.strings files
- Test on simulated locales
- Gather translations from native speakers

### v1.1 Success Criteria

- [ ] All new features tested with >80% coverage
- [ ] Zero regressions from v1.0
- [ ] Localization completes for Spanish + French (MVP)
- [ ] Triggers feature validates with 50+ test users
- [ ] Weekly reports generate without errors
- [ ] App Store review approval

---

## Version 2.0 (Future - 2026-2027)

**Status:** 🎯 Concept Phase
**Estimated Timeline:** 3-4 months full development
**Target Release:** Late 2026 / Early 2027

### Proposed Features

#### Machine Learning Insights
- [ ] Stress prediction (forecasting tomorrow's stress)
- [ ] Anomaly detection (unusual patterns)
- [ ] Trend classification (improving/declining)
- [ ] Personal stress profile
- [ ] ML model on-device (CoreML)

**Rationale:** Predictive insights help users plan and prepare.

**Technical Approach:**
- Collect 6+ months of data (v1.x)
- Train CoreML models offline
- Deploy models with app updates
- Privacy-preserving (no data sent to cloud)

#### Sleep & Activity Correlation
- [ ] HealthKit integration (sleep, exercise)
- [ ] Correlation analysis (how sleep affects stress)
- [ ] Activity tracking (exercise reduces stress?)
- [ ] Holistic wellness dashboard
- [ ] Recommendations based on patterns

**Rationale:** Stress doesn't exist in isolation; correlations with sleep/exercise are valuable.

**Implementation Notes:**
- Extend HealthKit queries
- Add correlation service
- Display correlation charts
- Generate insights feed

#### Siri Shortcuts Integration
- [ ] Voice shortcuts for measurement
- [ ] Automation triggers ("Run when stressed")
- [ ] Quick actions
- [ ] Custom intent handlers
- [ ] Voice feedback

**Rationale:** Voice-first interaction for accessibility and convenience.

**Implementation Notes:**
- Define custom SiriKit intents
- Implement intent handlers
- Document public API for shortcuts
- Test with common automations

#### iPad Application
- [ ] Responsive layout for larger screens
- [ ] Split view support
- [ ] External keyboard support
- [ ] Trackpad/mouse support
- [ ] iPadOS-specific features

**Rationale:** Tablet users want same experience on iPad.

**Implementation Notes:**
- Use adaptive layouts
- Test on iPad Pro models
- Support keyboard shortcuts
- Optimize charts for larger displays

### v2.0 Success Criteria

- [ ] ML predictions validated with 100+ users
- [ ] Sleep/activity correlation implemented and tested
- [ ] Siri Shortcuts fully documented
- [ ] iPad app feature parity with iPhone
- [ ] 4.8+ star rating maintained
- [ ] <0.05% crash rate

---

## Beyond 2.0 (Exploration Phase)

### Potential Future Directions

#### Wearable Integrations
- Oura Ring (additional HRV source)
- Fitbit/Garmin watch integration
- Third-party HRV devices

#### Medical Integration
- HIPAA-compliant data export
- Healthcare provider sharing
- Medical research participation
- Integration with health records

#### Community Features
- Anonymous stress patterns (global)
- Stress reduction challenges
- Group breathing sessions
- Community support (moderated)

#### AI Coach
- Personalized stress management coach
- Real-time recommendations
- Adaptive breathing guidance
- Progress tracking

---

## Maintenance & Bug Fixes

### Current Issues (v1.0)

**Known Limitations:**
- CloudKit sync requires iCloud account (expected)
- Watch app requires watchOS 10+ (intentional)
- No iPad support yet (planned for v2.0)

**Bug Tracking:**
Use GitHub Issues for bug reports:
```
Label: bug
Severity: critical/high/medium/low
Platform: iOS/watchOS/both
```

### Support Timeline

| Version | Support Until | Status |
|---------|---------------|--------|
| **1.0** | Feb 2027 | Active |
| **1.1** | Feb 2028 | Planned |
| **2.0** | Feb 2029 | Future |

---

## Release Schedule

### Quarterly Releases

```
Q1 2026 (Jan-Mar)
└─ v1.0 Release (Feb 19)
   └─ Bug fixes + minor improvements

Q2 2026 (Apr-Jun)
└─ v1.1 Release (May)
   ├─ Advanced breathing
   ├─ Stress triggers
   ├─ Weekly reports
   └─ Localization MVP

Q3 2026 (Jul-Sep)
└─ v1.2 Release (Aug)
   ├─ Additional locales
   ├─ Performance improvements
   └─ Community feedback features

Q4 2026 (Oct-Dec)
└─ v2.0 Release (Dec)
   ├─ ML insights
   ├─ Sleep/activity correlation
   ├─ Siri Shortcuts
   └─ iPad support
```

### Release Criteria

Every release must meet:
- ✅ All tests passing
- ✅ Zero critical bugs
- ✅ Code review approval
- ✅ TestFlight validation (7+ days)
- ✅ App Store review passage
- ✅ Accessibility audit (WCAG AA)
- ✅ Privacy review
- ✅ Release notes complete

---

## Dependency Timeline

### External Dependency Risks

**Currently:** Zero external dependencies ✅

**v2.0 Risk Assessment:**
- **CoreML** (Apple framework, no risk)
- **SiriKit** (Apple framework, no risk)
- **HealthKit Expansion** (Apple framework, no risk)

**Decision:** Maintain zero third-party dependencies to preserve:
- Privacy guarantee
- App size (<30MB)
- Launch performance
- Offline functionality

---

## Team & Capacity

### Estimated Effort

| Phase | Duration | FTE |
|-------|----------|-----|
| **v1.0** | Feb 2026 | 1.0 |
| **v1.1** | 6-8 weeks | 1.0 |
| **v2.0** | 3-4 months | 1.0 |

### Roles Needed

- **iOS Developer** (primary)
- **QA / Tester** (part-time)
- **Product Manager** (oversight)
- **Designer** (UI/UX for v1.1+)

---

## Success Metrics

### User Engagement (v1.0 → v1.1)

| Metric | v1.0 Target | v1.1 Target |
|--------|-------------|-------------|
| **Daily Active Users** | 1,000 | 3,000 |
| **Monthly Active Users** | 5,000 | 15,000 |
| **Avg Session Length** | 3 min | 5 min |
| **Measurements/User/Day** | 1-2 | 2-3 |
| **User Retention (30-day)** | 40% | 55% |

### Quality Metrics

| Metric | Target |
|--------|--------|
| **Crash Rate** | <0.1% |
| **CloudKit Sync Success** | >99.5% |
| **Test Coverage** | >85% |
| **App Store Rating** | 4.5+ stars |
| **Review Approval Time** | <48 hours |

### Financial Metrics

| Metric | Target |
|--------|--------|
| **App Store Downloads** | 50k+ (first year) |
| **Premium Features** | None (free forever) |
| **IAP Revenue** | Not planned |
| **Sponsorship/Ads** | None (privacy-first) |

---

## Stakeholder Communication

### Release Announcements

Each release includes:
- In-app release notes
- GitHub release page
- Social media announcement
- Email to TestFlight beta testers
- App Store description update

### Feedback Channels

- **App Store Reviews** - Monitor for common issues
- **GitHub Issues** - Detailed bug reports
- **Email** - Direct user feedback (privacy-respecting)
- **TestFlight Beta** - Early access & feedback

---

## Backlog (Not Prioritized)

Potential features for future consideration:

- [ ] Android port
- [ ] Web dashboard
- [ ] Smartwatch companion (non-Apple)
- [ ] Telemedicine integration
- [ ] Third-party app integrations
- [ ] Advanced statistical analysis
- [ ] Data visualization enhancements
- [ ] Offline-first improvements
- [ ] Performance optimizations
- [ ] Accessibility enhancements

---

**Owner:** Phuong Doan
**Last Review:** February 19, 2026
**Next Review:** May 2026 (post v1.0 launch)
