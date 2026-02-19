# StressMonitor Documentation Index

**Version:** 1.0 (Production)
**Last Updated:** February 19, 2026

Complete documentation for the StressMonitor iOS/watchOS stress monitoring application.

---

## Quick Navigation

### 1. **[Project Overview & PDR](./project-overview-pdr.md)** (265 lines)
Product vision, requirements, features, algorithm specifications, and success metrics.
- Product value proposition
- Key features (v1.0 + planned)
- Stress algorithm mathematical model
- User stories and acceptance criteria
- Success metrics and acceptance criteria

### 2. **[Codebase Summary](./codebase-summary.md)** (392 lines)
File structure, organization, component breakdown, and code metrics.
- High-level project structure
- iOS app architecture (96 files, ~12,270 LOC)
- watchOS app architecture (28 files, ~2,541 LOC)
- Widget architecture (7 files, ~1,287 LOC)
- Test suite organization (21 files, ~7,073 LOC)
- Component responsibilities and file metrics

### 3. **[Code Standards](./code-standards.md)** (Overview)
Swift conventions, patterns, testing standards, and quality guidelines.

**Quick Links:**
- **[Code Standards: Swift](./code-standards-swift.md)** - File organization, naming, imports, indentation, state management, SwiftUI views
- **[Code Standards: Patterns](./code-standards-patterns.md)** - Dependency injection, async/await, SwiftData, testing, error handling, design patterns, performance targets

### 4. **[System Architecture](./system-architecture.md)** (617 lines)
MVVM architecture, data flow, service layer design, and technical decisions.
- High-level architecture diagram
- Layer responsibilities (Presentation, ViewModel, Services, Data)
- Service protocols and implementations
- Data layer (SwiftData + CloudKit)
- Apple Watch architecture
- Home screen widgets
- Concurrency model (async/await)
- Error handling strategy
- Design decisions and trade-offs
- Testing architecture
- Security considerations
- Extensibility points

### 5. **[Deployment Guide](./deployment-guide.md)** (643 lines)
Build setup, testing, TestFlight distribution, and App Store submission.
- Prerequisites and environment setup
- Build instructions (development + release)
- Testing checklist (unit tests + manual)
- App Store Connect configuration
- HealthKit privacy setup
- Screenshots and app information
- TestFlight distribution workflow
- App Store submission process
- Version management and release cadence
- Troubleshooting guide
- Performance optimization
- Post-release monitoring
- Rollback procedures

### 6. **[Design Guidelines](./design-guidelines.md)** (613 lines)
Color system, typography, components, accessibility, and animations.
- Design philosophy (5 core principles)
- Stress level color system (WCAG AA compliant)
- Typography scale with Dynamic Type
- Spacing and layout tokens
- Component specifications (Ring, Badge, Cards)
- Accessibility requirements (WCAG AA)
- VoiceOver and Dynamic Type support
- Touch target sizing
- Color contrast ratios
- Haptic feedback system
- Animation timing and easing
- StressBuddy character design
- Dark mode support
- Icon usage (SF Symbols)
- Onboarding flow design
- Data visualization guidelines

### 7. **[Project Roadmap](./project-roadmap.md)** (494 lines)
Current status, planned features, timeline, and success metrics.
- Version 1.0 status (complete & shipping)
- Version 1.1 planned features (Q2 2026)
- Version 2.0 future features (2026-2027)
- Maintenance and bug fix timeline
- Release schedule and criteria
- Success metrics (engagement, quality, financial)
- Team capacity and effort estimates
- Stakeholder communication plan

---

## Quick Reference

### File Metrics Summary

| Document | Lines | Focus |
|----------|-------|-------|
| Project Overview | 265 | Requirements, features |
| Codebase Summary | 392 | Code organization |
| Code Standards | 634 | Conventions, patterns |
| System Architecture | 617 | Design, data flow |
| Deployment Guide | 643 | Build, release |
| Design Guidelines | 613 | UI/UX, accessibility |
| Project Roadmap | 494 | Timeline, features |
| **Total** | **3,658** | Complete reference |

### Key Numbers

- **Total Lines of Swift Code:** 22,727
- **Total Swift Files:** 179
- **iOS App:** 12,270 LOC (96 files)
- **watchOS App:** 2,541 LOC (28 files)
- **Widgets:** 1,287 LOC (7 files)
- **Tests:** 7,073 LOC (21 files)
- **Test Methods:** 100+ (>80% coverage)
- **Documentation:** 3,658 LOC (7 files)

---

## Getting Started

### For New Developers

1. Start here: [Project Overview](./project-overview-pdr.md) - understand what the app does
2. Then read: [Codebase Summary](./codebase-summary.md) - learn the structure
3. Before coding: [Code Standards](./code-standards.md) - follow conventions
4. When confused: [System Architecture](./system-architecture.md) - understand data flow

### For Code Review

- Reference: [Code Standards](./code-standards.md) - check conventions
- Verify: [System Architecture](./system-architecture.md) - validate design
- Test with: [Deployment Guide](./deployment-guide.md) - build/test steps

### For Design/UI Work

- Start with: [Design Guidelines](./design-guidelines.md) - component specs
- Verify: Color contrast, touch targets, Dynamic Type support
- Reference: WCAG AA accessibility requirements

### For Release Management

- Follow: [Deployment Guide](./deployment-guide.md) - step-by-step release
- Check: [Project Roadmap](./project-roadmap.md) - timing and criteria
- Monitor: Success metrics and post-release items

---

## Key Technical Decisions

| Decision | Rationale |
|----------|-----------|
| **MVVM + Protocols** | Testability, loose coupling |
| **@Observable macro** | Modern iOS 17+ reactive |
| **SwiftData (not Core Data)** | iOS 17+ native, SwiftUI-friendly |
| **CloudKit E2E encryption** | User privacy guarantee |
| **Zero external dependencies** | Control, privacy, simplicity |
| **WidgetKit (not ClockKit)** | watchOS 10+ requirement |
| **async/await throughout** | Modern concurrency |

---

## Important Constraints

| Constraint | Impact | Mitigation |
|-----------|--------|-----------|
| iOS 17+ only | Excludes iOS 16 users | Target modern users |
| HealthKit dependency | Requires permissions | Graceful degradation |
| iCloud required for sync | CloudKit needs account | Optional feature |
| No third-party deps | More code to maintain | Full control maintained |

---

## Privacy & Security

✅ **Privacy-First Design:**
- Local SwiftData storage (encrypted at rest)
- CloudKit E2E encryption (optional)
- Zero third-party services
- Read-only HealthKit access
- User data ownership (full export/delete)

✅ **Security Measures:**
- No external API calls
- No telemetry or analytics
- HealthKit authorization flow
- Error handling for denied permissions
- User data never leaves device + iCloud

---

## Accessibility (WCAG AA)

✅ **Dual Coding** - Color + icon + text for stress levels
✅ **VoiceOver** - Full screen reader support
✅ **Dynamic Type** - All text scales with system settings
✅ **Touch Targets** - Minimum 44x44 points
✅ **Haptic Feedback** - Tactile confirmation
✅ **Color Contrast** - ≥4.5:1 ratio (WCAG AA)

---

## Architecture Overview

```
SwiftUI Views → @Observable ViewModels → Protocol-based Services
    ↓                  ↓                          ↓
(Presentation)    (State Management)      (Business Logic)
                                              ↓
                                    SwiftData + CloudKit
                                        (Data Layer)
                                              ↓
                                    HealthKit + Sensors
```

---

## Support & Maintenance

| Item | Status | Contact |
|------|--------|---------|
| **Active Development** | ✅ v1.0 shipping | Phuong Doan |
| **Bug Fixes** | ✅ Ongoing | GitHub Issues |
| **Feature Requests** | 📋 Roadmap in docs | Roadmap discussion |
| **Documentation** | ✅ Current | This index |

---

## Version History

| Version | Release | Status |
|---------|---------|--------|
| **1.0** | Feb 2026 | ✅ Production |
| **1.1** | Q2 2026 | 📋 Planned |
| **2.0** | Q4 2026 | 🎯 Concept |

---

**Read the README.md** at project root for quick start and feature overview.

**Last Updated:** February 19, 2026
**Maintained By:** Phuong Doan
