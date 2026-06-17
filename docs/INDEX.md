# StressMonitor Documentation Index

**Version:** 1.0 (Pre-Ship RC1)
**Last Updated:** June 17, 2026
**Blocker Status:** 1 critical remaining (B3 - comprehensive test suite rewrite)
**Resolved Blockers:** B1 ✅ (Jun 7), B2 ✅ (Jun 12)

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
- iOS app architecture (250+ files, ~28K LOC)
- watchOS app architecture (46+ files, ~3.2K LOC)
- Widget architecture (7+ files, ~1.4K LOC)
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

### 8. **Project Changelog**
*Not yet created — tracked in git history.*

### 9. **Community & Growth**
Niche community engagement strategy and product positioning for sharing in communities.
- **[Community Niche Strategy](./community/niche-strategy.md)** — Engagement playbook for ME/CFS, ADHD, and burnout communities (positioning, Reddit posting guidelines, content calendar, metrics)
- **[App Positioning One-Pager](./community/app-positioning.md)** — Niche elevator pitches, feature-relevance matrix, and StressWatch comparison table for community sharing

### 10. **App Store & ASO**
App Store editorial preparation, ASO keyword strategy, and submission-ready copy.
- **[Apple Editorial Checklist](./aso/apple-editorial-checklist.md)** — Comprehensive prep guide: ASO keywords, screenshot specs, privacy messaging, accessibility audit, App Review map, editorial pitch, submission gate
- **[App Store Description](./aso/app-description.md)** — Submission-ready description (title, subtitle, 100-char keywords, promotional text, release notes) with keyword-integration audit

---

## Quick Reference

### Codebase Metrics (as of Jun 17, 2026)

| Metric | Value |
|--------|-------|
| **Total Swift Files** | 331+ |
| **Total LOC** | ~36,000+ |
| **iOS App** | 250+ files, ~28.5K LOC |
| **watchOS App** | 46+ files, ~3.5K LOC |
| **Widgets** | 7+ files, ~1.4K LOC |
| **Tests** | 5+ files (placeholder - pending B3 rewrite) |
| **External Dependencies** | 13+ SPM packages |
| **CI/CD** | GitHub Actions (macos-15, Xcode 26) |
| **Character Assets** | 38 SVG files |
| **New (Jun 17)** | BioAgeCalculator, BioAgeCardView, WatchFacePreferences, CharacterIllustrationExporter |

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
| **SPM Dependencies** | 13+ packages (Kingfisher, SwiftUICharts, ExyteChat, AnimatedTabBar, etc.) |
| **WidgetKit (not ClockKit)** | watchOS 10+ requirement |
| **async/await throughout** | Modern concurrency |
| **Foundation Models** | On-device LLM via Apple Intelligence (iOS 26+) |
| **SupabaseLLMService** | Supabase Edge Functions as cloud LLM **production** service (B1 resolved Jun 7) |
| **Real StoreKit 2** | App Store product fetching + transaction monitoring (PR #19, Jun 12) |
| **5-Tab Navigation** | Home/Trends/Breathing/Characters/Settings structure |
| **Character System** | 5 elemental creatures with 3-stage evolution, 38 SVG assets |
| **GitHub Actions CI** | Automated build + test on macos-15 with SPM caching |

---

## Important Constraints

| Constraint | Impact | Mitigation |
|-----------|--------|-----------|
| iOS 17+ only | Excludes iOS 16 users | Target modern users |
| iOS 26+ for Apple Intelligence | AI Chat limited to newest iOS | SupabaseLLM fallback for older devices |
| HealthKit dependency | Requires permissions | Graceful degradation |
| iCloud required for sync | CloudKit needs account | Optional feature |

---

## Privacy & Security

**Privacy-First Design:**
- Local SwiftData storage (encrypted at rest)
- CloudKit E2E encryption (optional)
- Zero third-party analytics services
- Read-only HealthKit access
- User data ownership (full export/delete)

**Security Measures:**
- SupabaseLLMService sends chat messages (not raw health data) to Supabase Edge Functions
- No telemetry or analytics
- HealthKit authorization flow
- Error handling for denied permissions
- Health data never leaves device + iCloud (only anonymized chat context sent to LLM)

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
| **Active Development** | ✅ v1.0 Pre-Ship RC1 | Phuong Doan |
| **Blockers** | 🚫 1 critical (B3 test suite) | Test suite rewrite |
| **Resolved (Jun 12)** | ✅ B1 & B2 | CloudLLM, StoreKit 2 |
| **Bug Fixes** | ✅ Ongoing | GitHub Issues |
| **Feature Requests** | 📋 Roadmap in docs | Roadmap discussion |
| **Documentation** | ✅ Updated Jun 13 | This index |

---

## Version History

| Version | Release | Status | Notable |
|---------|---------|--------|---------|
| **1.0** | Jul/Aug 2026 | 🔄 Pre-Ship RC1 | AI Chat with SSE streaming, 5-tab navigation (Home/Trends/Breathing/Characters/Settings), Character Collection UI (5 characters, 3-stage evolution, 38 SVG assets), SupabaseLLM via Edge Functions + Apple Intelligence, Box Breathing Figma alignment, Mini Walk exercise, Real StoreKit 2 (PR #19 Jun 12), Stress History, Guided Breathing, Watch Complications, Morning Readiness Check. **Remaining Blocker:** Test suite rewrite |
| **1.1** | Q3 2026 | 🔄 Planned | Advanced breathing, stress triggers, weekly reports, localization MVP |
| **2.0** | Q4 2026 | 🎯 Concept | ML insights, Siri Shortcuts, iPad support |

---

**Read the README.md** at project root for quick start and feature overview.

**Last Updated:** June 13, 2026
**Maintained By:** Phuong Doan
**Generated with:** repomix codebase analysis + manual documentation review
