# StressMonitor Documentation Index

**Version:** 1.0 (Production)
**Last Updated:** February 28, 2026

Complete documentation for the StressMonitor iOS/watchOS stress monitoring application.

---

## Quick Navigation

### 1. **[Project Overview & PDR](./project-overview-pdr.md)**
Product vision, requirements, features, algorithm specifications, and success metrics.
- Product value proposition
- Key features (v1.0 + planned)
- Stress algorithm mathematical model
- User stories and acceptance criteria
- Success metrics and acceptance criteria

### 2. **[Codebase Summary](./codebase-summary.md)**
File structure, organization, component breakdown, and code metrics.
- High-level project structure
- iOS app architecture (136 files)
- watchOS app architecture (29 files)
- Widget architecture (7 files)
- Test suite organization (27 files)
- Component responsibilities and file metrics

### 3. **[Code Standards](./code-standards.md)** (Overview)
Swift conventions, patterns, testing standards, and quality guidelines.

**Quick Links:**
- **[Code Standards: Swift](./code-standards-swift.md)** - File organization, naming, imports, indentation, state management, SwiftUI views
- **[Code Standards: Patterns](./code-standards-patterns.md)** - Dependency injection, async/await, SwiftData, testing, error handling, design patterns, performance targets

### 4. **[System Architecture](./system-architecture.md)** (Overview)
MVVM architecture, data flow, service layer design, and technical decisions.

**Quick Links:**
- **[System Architecture: Core](./system-architecture-core.md)** - MVVM pattern, layer responsibilities, service architecture, data models, data flow, concurrency, error handling
- **[System Architecture: Platform](./system-architecture-platform.md)** - CloudKit sync, Apple Watch standalone app, WidgetKit complications, home screen widgets, security model

### 5. **[Deployment Guide](./deployment-guide.md)** (Overview)
Build setup, testing, TestFlight distribution, and App Store submission.

**Quick Links:**
- **[Deployment: Environment](./deployment-guide-environment.md)** - Prerequisites, signing, capabilities, build instructions, testing checklist
- **[Deployment: Release](./deployment-guide-release.md)** - App Store configuration, TestFlight distribution, review process, version management, rollback

### 6. **[Design Guidelines](./design-guidelines.md)** (Overview)
Color system, typography, components, accessibility, and animations.

**Quick Links:**
- **[Design Guidelines: Visual](./design-guidelines-visual.md)** - Color system, typography, spacing, components, dark mode, iconography
- **[Design Guidelines: UX](./design-guidelines-ux.md)** - WCAG AA compliance, VoiceOver, Dynamic Type, haptics, StressBuddy character, onboarding

### 7. **[Project Roadmap](./project-roadmap.md)**
Current status, planned features, timeline, and success metrics.
- Version 1.0 status (complete & shipping)
- Version 1.1 planned features (Q2 2026)
- Version 2.0 future features (2026-2027)
- Maintenance and bug fix timeline
- Release schedule and criteria
- Success metrics (engagement, quality, financial)

---

## Quick Reference

### Codebase Metrics (as of Feb 2026)

| Metric | Value |
|--------|-------|
| **Total Swift Files** | 206 |
| **Total Tokens** | ~205,000 |
| **iOS App** | 136 files |
| **watchOS App** | 29 files |
| **Widgets** | 7 files |
| **Tests** | 27 files |
| **External Dependencies** | 0 |

### Documentation Metrics

| Document | Focus |
|----------|-------|
| Project Overview | Requirements, features |
| Codebase Summary | Code organization |
| Code Standards | Conventions, patterns |
| System Architecture | Design, data flow |
| Deployment Guide | Build, release |
| Design Guidelines | UI/UX, accessibility |
| Project Roadmap | Timeline, features |

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

**Last Updated:** February 28, 2026
**Maintained By:** Phuong Doan
**Generated with:** repomix codebase analysis
