# StressMonitor overview

StressMonitor is an iOS 17+ and watchOS 10+ app that measures stress from HealthKit biometric signals, presents it through a gamified character companion ("Stress Buddy"), and offers AI coaching, guided breathing, and activity nudges. All health data is stored locally in SwiftData with optional end-to-end encrypted CloudKit sync. The app targets iPhone and Apple Watch, with a shared widget extension for the Home Screen and Live Activities.

The project ships three Xcode targets: the iPhone app (`StressMonitor/StressMonitor`), the watchOS app (`StressMonitor/StressMonitorWatch Watch App`), and the WidgetKit extension (`StressMonitor/StressMonitorWidget`). The codebase is ~390 Swift files and ~54K lines of code with no third-party runtime dependencies beyond a handful of Swift Package Manager UI libraries.

## What StressMonitor does

- Computes a 0-100 stress score from five HealthKit signals: HRV, heart rate, sleep, activity, and recovery.
- Renders the score as a Stress Buddy character that evolves through mood states tied to stress level.
- Streams AI coaching chat responses from a Supabase Edge Function backend.
- Provides breathing exercises, mini-walk sessions, habit tracking, and weekly trend analytics.
- Gatees premium analytics (bio age, long-range trends, advanced breathing) behind a StoreKit 2 subscription paywall.
- Syncs measurements across devices via CloudKit private database with a custom conflict resolver.

## Quick links

- [Architecture](architecture.md) - MVVM, data flow, and the multi-factor stress algorithm.
- [Getting started](getting-started.md) - Prerequisites, build commands, and demo mode.
- [Glossary](glossary.md) - HRV, SDNN, bio age, Ripple, paywall reasons, and more.
- [By the numbers](../by-the-numbers.md) - Codebase statistics snapshot.
- [Lore](../lore.md) - Project history and major eras.
- [How to contribute](../how-to-contribute/index.md) - Workflow, testing, and conventions.
