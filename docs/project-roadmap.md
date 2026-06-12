# Project Roadmap

**Current Version:** 1.0 (Pre-Ship - RC1)
**Release Date:** Target July/August 2026
**Status:** Feature Complete — 3 blockers pending
**Last Updated:** June 12, 2026

---

## Version 1.0 (Current - Pre-Ship RC1)

**Status:** ✅ Feature Complete — 3 Blockers Pending (B1/B2/B3)

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
- ✅ Enhanced dashboard with unified scroll layout (Feb 2026)
- ✅ OLED dark theme support (Feb 2026)
- ✅ Auto-refresh via HealthKit observer (Feb 2026)
- ✅ AI-powered personalized insights (Feb 2026)
- ✅ Daily timeline chart — redesigned as 7-day × 7-slot weekly dot-matrix grid (Mar 2026)
- ✅ Weekly insight card (week-over-week comparison) (Feb 2026)
- ✅ Custom StressBuddy character illustration (Feb 2026)
  - 5 mood expressions: sleeping, calm, concerned, worried, overwhelmed
  - Mood-specific animations: breathing, fidget, shake, dizzy
  - Custom shapes: TriangleShape, TeardropShape, FlameShape
  - Full Reduce Motion + VoiceOver support
- ✅ Settings screen — Figma card-based design (Mar 2026)
- ✅ **3-Tab Navigation Structure** (Apr 2026)
  - Home: Dashboard with stress monitoring
  - Action: Quick actions, breathing exercises, AI chat
  - Trend: Historical analytics and trends
- ✅ Trends view — Figma alignment (Mar 2026)
  - Scrollable card list; global NavigationStack/TimeRangePicker removed
  - All cards unified: `adaptiveCardBackground` + `settingsCardRadius` + shadow
  - `StressBarChartView`: Swift Charts bar chart (replaces circular indicators)
  - `WeeklyHeatmapView`: Circular dot cells (replaces square cells)
  - `LineChartView` (HRV Trend): Y-axis labels + "Today" marker + subtitle
  - `StressSourcesCard`: Stress sources display (donut chart deleted Mar 2026)
  - `PremiumBannerView`: Light-blue gradient + CharacterCalm mascot + orange CTA
  - `MascotSpeechBubbleView`: New speech bubble component
  - `SmartInsightsTeaser`: Static "Coming Soon" teaser
- ✅ Historical timeline (measurement list)
- ✅ Distribution statistics
- ✅ Onboarding flow
- ✅ HealthKit permission request

#### Recent Completions (June 2026)
- ✅ **Stress History Timeline** - Activity correlation with stress measurements
- ✅ **Guided Breathing with Biofeedback** - Enhanced breathing exercises with real-time feedback
- ✅ **Apple Watch Complications** - Live stress metrics on watch face (WidgetKit)
- ✅ **Morning Readiness Check** - HRV trend analysis for daily readiness
- ✅ **Real-time Stress Score** - HRV analysis with immediate feedback
- ✅ **Mini Walk Exercise** - Walking exercise with circular timer (Apr 2026)
- ✅ **IAP Premium Screen** - Subscription paywall with StoreKit (Apr 2026)
- ✅ **5-Tab Navigation** - Home/Trends/Breathing/Characters/Settings structure (May 2026)
- ✅ **Streaming AI Chat** - Real-time token streaming with SSEParser (Apr 2026)
- ✅ **Box Breathing Figma Alignment** - Enhanced breathing exercise visuals (Apr 2026)
- ✅ **Character Collection UI** - 5 elemental characters with evolution system, 38 SVG assets (Jun 2026)

#### Apple Watch
- ✅ Standalone watch app
- ✅ Circular complications (WidgetKit)
- ✅ Rectangular complications
- ✅ Inline complications
- ✅ Watch-to-iPhone sync (WatchConnectivity)
- ✅ Independent CloudKit sync

#### Additional Features
- ✅ AI Chat Mode with Streaming (Apr 2026)
  - Conversational AI via Apple Intelligence Foundation Models (iOS 26+)
  - **CloudLLMService with SSE streaming** - HTTP/SSE to self-hosted FastAPI gateway (GLM-4.7-flash, no API key)
  - **SSEParser** and **LLMAPITarget** for streaming infrastructure
  - **Hardcoded endpoint configuration** - removed server config UI for simplicity
  - Bottom sheet overlay with native SwiftUI chat UI
  - **Real-time token streaming** - Users see AI response as it's generated
  - Health/stress context injected into system prompt via ChatContextBuilder
  - Quick action prompt suggestions (ChatQuickActions)
  - Protocol-based LLM service for future cloud provider swap
  - Graceful fallback on pre-iOS 26 devices
  - Session-only persistence (no SwiftData for chat)
- ✅ **ActionView** - Quick access to wellness tools (Apr 2026)
  - Breathing exercises with Figma-aligned UI
  - Mini Walk exercise with circular timer (Apr 26, 2026)
  - Direct AI chat access for immediate stress relief
  - Quick action chips for contextual suggestions
  - Streamlined user experience for immediate intervention
- ✅ Guided breathing exercises (4-7-8 technique)
- ✅ Breathing exercise UI redesign — Figma-aligned BreathingCircleView with 3-view session flow (Apr 2026)
- ✅ Home screen widgets (small, medium, large)
- ✅ Background health refresh (optional)
- ✅ WCAG AA accessibility compliance
- ✅ VoiceOver support
- ✅ Dynamic Type support
- ✅ Reduce Motion animation support (Feb 2026)
- ✅ Haptic feedback
- ✅ Dark mode support
- ✅ Spring animations with accessibility fallback (Feb 2026)

#### Testing & Quality
- ✅ GitHub Actions CI/CD pipeline (build + test on macos-15, SPM caching, xcresult, code coverage)
- ⚠️ Test suite removed for rewrite (3 minimal files in StressMonitorTests/)
- [ ] Comprehensive test reimplementation planned for v1.1

### Performance Metrics (v1.0)

| Metric | Target | Actual |
|--------|--------|--------|
| **Stress Calculation** | <1s | ~0.3s |
| **Memory (Idle)** | <50MB | 45MB |
| **Memory (100 measurements)** | <100MB | 87MB |
| **CloudKit Sync** | <30s | ~15s (avg) |
| **App Launch** | <2s | 1.8s |
| **Test Pass Rate** | 100% | Pending rewrite |

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
• Quick access to AI chat for stress support

Navigation:
• 3-tab structure: Home, Action, Trend
• Quick stress relief tools in Action tab
• Historical analytics in Trend tab

Accessibility:
• WCAG AA compliant interface
• Full VoiceOver support
• Dynamic Type scaling
• Haptic feedback

Privacy:
• 13 SPM packages (Moya, Alamofire, Kingfisher, SwiftUICharts, etc.)
• Local-first architecture
• End-to-end encrypted CloudKit sync
• No tracking or analytics
• AI chat with optional cloud streaming (anonymized context only)

CI/CD:
• GitHub Actions pipeline (macos-15 runner)
• SPM + DerivedData caching
• xcresult validation + code coverage reporting
• Python test runner (scripts/run-tests.py)

Note: Privacy-first design ensures all health data
remains on your device or encrypted in iCloud.
```

---

## Version 1.1 (Planned - Q2 2026)

**Status:** 🔄 In Progress
**Estimated Timeline:** 6-8 weeks development
**Target Release:** April/May 2026

### Proposed Features

#### Advanced Breathing Techniques
- [x] Box breathing (4-4-4-4) -- implemented in v1.0
- [ ] Coherent breathing (6 breaths/minute)
- [ ] Custom pattern builder
- [ ] Session effectiveness tracking
- [ ] Breathing history analytics

**Rationale:** Users request variety in breathing exercises to accommodate different preferences and needs.

**Implementation Notes:**
- Create `BreathingExerciseView` variants for each pattern
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
- Create `ReportGenerator` service (new, planned for v2.0)
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

**Recent Improvements (Apr 2026):**
- Enhanced ActionView with streamlined user experience
- Improved streaming chat performance
- Simplified LLM service configuration

**Recently Completed (June 2026):**
- ✅ **Stress History Timeline** - Activity correlation with stress data
- ✅ **Guided Breathing with Biofeedback** - Enhanced breathing with real-time feedback
- ✅ **Apple Watch Complications** - Live stress metrics on watch face
- ✅ **Morning Readiness Check** - HRV trend analysis for daily readiness
- ✅ **Real-time Stress Score** - HRV analysis with immediate feedback
- ✅ **Mini Walk Exercise** - Walking exercise with circular timer
- ✅ **IAP Premium Screen** - Subscription paywall with StoreKit
- ✅ **5-Tab Navigation** - Home/Trends/Breathing/Characters/Settings structure
- ✅ **Streaming AI Chat** - Real-time token streaming with SSEParser
- ✅ **Character Collection UI** - 5 elemental characters with 3-stage evolution system

**Critical Ship Blockers (June 2026):**
1. **B1 (P0)** - CloudLLMService hardcoded ngrok endpoint must use production URL
2. **B2 (P0)** - StoreKit implementation is mock-only, needs real purchase flow
3. **B3 (P0)** - Test suite is placeholder, needs comprehensive rewrite

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
- ✅ CI pipeline passes (build + available tests)
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

**Currently:** 13 SPM packages (Moya, Alamofire, Kingfisher, SwiftUICharts, etc.)

**v2.0 Risk Assessment:**
- **CoreML** (Apple framework, no risk)
- **SiriKit** (Apple framework, no risk)
- **HealthKit Expansion** (Apple framework, no risk)

**Decision:** Evaluate dependency reduction to preserve:
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
| **Test Coverage** | >80% (pending rewrite) |
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
**Last Review:** June 12, 2026
**Next Review:** Post-blocker resolution (target July 2026)