# Deployment Guide: Overview

**Platform:** iOS 17+ / watchOS 10+
**Distribution:** TestFlight -> App Store
**Last Updated:** June 7, 2026

**Note:** Apple Intelligence features (on-device AI Chat) require iOS 26+ and compatible hardware. CloudLLMService with SSE streaming provides fallback chat functionality for older devices.

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
- [ ] Test ActionView quick actions and breathing exercises
- [ ] Test AI chat streaming functionality with SSEParser
- [ ] Verify CloudLLM hardcoded endpoint connectivity
- [ ] Test LLMAPITarget configuration

### TestFlight
- [ ] Build & archive for distribution
- [ ] Upload to TestFlight
- [ ] Invite testers
- [ ] Monitor crash logs
- [ ] Review feedback
- [ ] Specifically test streaming chat performance
- [ ] Verify 3-tab navigation flow

### App Store Submission
- [ ] Fill app information (privacy, description, keywords)
- [ ] Configure HealthKit settings
- [ ] Upload screenshots
- [ ] Create release notes
- [ ] Submit for review
- [ ] Monitor review status
- [ ] Highlight new ActionView and streaming AI features

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

### New Features (Apr 2026)
- [ ] **3-Tab Navigation** - Home/Action/Trend flow
- [ ] **ActionView** - Quick actions and breathing access
- [ ] **Streaming AI Chat** - Real-time token rendering via SSEParser
- [ ] **CloudLLM Integration** - SSE endpoint with hardcoded configuration
- [ ] **Box Breathing Exercises** - Figma-aligned animations
- [ ] **LLMAPITarget** - Simplified endpoint management

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
**Last Updated:** June 7, 2026