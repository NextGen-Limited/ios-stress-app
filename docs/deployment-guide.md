# Deployment Guide: Overview

**Platform:** iOS 17+ / watchOS 10+
**Distribution:** TestFlight -> App Store
**Last Updated:** June 17, 2026

**Note:** Apple Intelligence features (on-device AI Chat) require iOS 26+ and compatible hardware. SupabaseLLMService with SSE streaming provides cloud fallback for older devices.

---

## Overview

This guide covers the complete deployment process for StressMonitor from local development through App Store release.

## Quick Links

### Setup & Build
Start here if you're deploying for the first time:
- **[Deployment: Environment Setup](./deployment-guide-environment.md)** - Prerequisites, signing, capabilities, build instructions, testing checklist

### TestFlight & Release
Once your app is built and tested:
- **[Deployment: TestFlight & App Store](./deployment-guide-release.md)** - App Store configuration, TestFlight distribution, review process, version management, rollback procedures

---

## Deployment Checklist

### Pre-Deployment
- [ ] Read environment setup guide
- [ ] Configure signing & provisioning
- [ ] Enable required capabilities
- [ ] Run unit tests
- [ ] Complete manual testing on device
- [ ] Verify accessibility compliance
- [ ] Test 3-tab navigation flow (Home/Action/Trend)
- [ ] Test Settings screen access via button/chevron
- [ ] Test biological age card display and calculation
- [ ] Test breathing exercises and timers in Action tab
- [ ] Test character collection access via CharactersCard in Settings
- [ ] Test character evolution unlocks
- [ ] Test dark mode toggle in Settings → ProfileCard
- [ ] Test appearance picker (Light/Dark/System) persistence
- [ ] Test AI chat streaming with Apple Intelligence (iOS 26+) and SupabaseLLMService fallback
- [ ] Verify SupabaseConfig environment setup (URL + anonKey)
- [ ] Test real StoreKit 2 purchasing flow (monthly/annual/weekly) with real/sandbox products
- [ ] Test WidgetKit Live Activity (breathing session on lock screen)
- [ ] Test ControlCenter widget (app launcher)
- [ ] Test watch face background personalization

### TestFlight
- [ ] Build & archive for distribution
- [ ] Upload to TestFlight
- [ ] Invite testers
- [ ] Monitor crash logs
- [ ] Review feedback
- [ ] Specifically test streaming chat performance (both backends)
- [ ] Verify 3-tab navigation flow and tab transitions
- [ ] Test Settings access and CharactersCard → character collection flow
- [ ] Test biological age card calculation and display on Dashboard
- [ ] Test character unlock progression on real devices
- [ ] Verify StoreKit 2 purchases work end-to-end (weekly/monthly/annual)
- [ ] Test dark mode toggle across all tabs on iOS 17+
- [ ] Verify WidgetKit Live Activity displays breathing session correctly
- [ ] Verify ControlCenter widget launches app
- [ ] Test watch face background personalization on actual Apple Watch
- [ ] Test watch complications on actual Apple Watch

### App Store Submission
- [ ] Fill app information (privacy, description, keywords)
- [ ] Configure HealthKit settings and permissions
- [ ] Upload screenshots (3-tab structure, biological age, AI chat, character collection)
- [ ] Create release notes highlighting biological age calculator, watch personalization, weekly billing, and character system
- [ ] Configure StoreKit products and subscription info in App Store Connect (monthly/annual/weekly)
- [ ] Submit for review
- [ ] Monitor review status
- [ ] Highlight new 3-tab navigation, biological age feature, watch face personalization, weekly billing tier, character evolution, and real StoreKit 2 features

### Post-Release
- [ ] Monitor crash rates
- [ ] Track performance metrics
- [ ] Respond to user ratings
- [ ] Plan follow-up updates
- [ ] Monitor streaming chat feedback

---

## Key Features Tested (v1.0)

### Core Functionality
- [ ] Stress measurement via HealthKit
- [ ] Real-time stress calculation
- [ ] Personal baseline adaptation
- [ ] Stress categorization display

### New Features (May-Jun 2026)
- [ ] **AppearanceManager** - Dark mode toggle with Light/Dark/System persistence (Jun 13)
- [ ] **Settings Redesign** - Ripple UI card-based architecture with ProfileCard (Jun 13)
- [ ] **Trends Redesign** - Ripple character with dynamic mascot commentary (Jun 13)
- [ ] **ActionView Redesign** - Dark-canvas theme with Ripple AI Coach (Jun 13)
- [ ] **Watch Character-Reactive** - 5 stress tier emoji display (no numeric scores) (Jun 13)
- [ ] **WidgetKit Live Activity** - Breathing session on lock screen + Dynamic Island (Jun 13)
- [ ] **ControlCenter Widget** - App launcher button in Control Center (Jun 13)
- [ ] **3-Tab Navigation** - Home/Action/Trend flow with non-tab Settings (Jun 17)
- [ ] **Biological Age Calculator** - Biological age estimation from HRV, resting HR, sleep (Jun 17)
- [ ] **BioAgeCardView** - Dashboard card showing age differential with color coding (Jun 17)
- [ ] **Watch Face Personalization** - Background style selection synced via WatchConnectivity (Jun 17)
- [ ] **Weekly Billing Option** - SubscriptionPeriod.weekly added to StoreKit products (Jun 17)
- [ ] **Character Collection** - 5 elemental characters with 3-stage evolution, 38 SVG assets
- [ ] **Streaming AI Chat** - Real-time token rendering via SSEParser
- [ ] **Dual LLM Services** - Apple Intelligence (iOS 26+) + SupabaseLLMService fallback
- [ ] **Real StoreKit 2** - App Store product fetching, transaction monitoring, PremiumState singleton
- [ ] **Box Breathing Exercises** - Figma-aligned animations with HRV biofeedback
- [ ] **Weekly Timeline View** - 7-day × 7-slot dot-matrix grid visualization
- [ ] **Watch Complications** - 4 families (Circular, Rectangular, Inline, Corner)

### Quality Assurance
- [ ] Accessibility compliance (WCAG AA)
- [ ] Dynamic Type scaling
- [ ] VoiceOver support
- [ ] Haptic feedback
- [ ] Dark mode support
- [ ] Apple Watch complications

---

## Key Contacts & Resources

- **Apple Developer Account:** [developer.apple.com](https://developer.apple.com)
- **App Store Connect:** [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
- **HealthKit Documentation:** [developer.apple.com/healthkit](https://developer.apple.com/documentation/healthkit)
- **Human Interface Guidelines:** [developer.apple.com/design/human-interface-guidelines](https://developer.apple.com/design/human-interface-guidelines)
- **WidgetKit Documentation:** [developer.apple.com/widgetkit](https://developer.apple.com/documentation/widgetkit)

---

**Maintained By:** Phuong Doan
**Last Updated:** June 17, 2026