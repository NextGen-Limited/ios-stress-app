# StressMonitor

### Understand stress. Notice patterns. Take action.

StressMonitor is a privacy-first iPhone and Apple Watch app that turns HealthKit signals into a personal, explainable stress score. It combines on-device health analysis, long-term trends, guided recovery tools, and an AI coach in one SwiftUI experience.

[![iOS 18.6+](https://img.shields.io/badge/iOS-18.6%2B-0A84FF?logo=apple)](https://developer.apple.com/ios/)
[![watchOS 11.6+](https://img.shields.io/badge/watchOS-11.6%2B-F97316?logo=apple)](https://developer.apple.com/watchos/)
[![Swift](https://img.shields.io/badge/Swift-SwiftUI-F05138?logo=swift&logoColor=white)](https://www.swift.org/)
[![Architecture](https://img.shields.io/badge/Architecture-MVVM-7C3AED)](docs/system-architecture.md)

> Health data remains local-first. HealthKit access is read-only, CloudKit sync is optional, and raw HealthKit samples are not sent to the AI service.

## Features

| Understand | Act | Stay connected |
|---|---|---|
| **Five-factor stress score** from HRV, heart rate, sleep, activity, and recovery | **Guided breathing** with animated pacing and before/after feedback | **Standalone Apple Watch app** with direct HealthKit access |
| **Personal baselines** adapt the model to individual physiology | **Mini Walk** offers a quick, timed reset | **Widgets and complications** surface the latest state at a glance |
| **Confidence and factor breakdowns** explain every result | **AI stress coach** streams contextual guidance through an authenticated API | **Optional CloudKit sync** keeps devices aligned offline-first |
| **History and trend analytics** reveal patterns over time | **Journal and habit check-ins** add context to measurements | **CSV and JSON export** preserves user ownership |

Additional product capabilities include morning readiness, biological-age insights, character progression, notifications, themes, StoreKit subscriptions and credit packs, and complete local/cloud data deletion.

## Screenshots

| Home | Trends | AI Coach |
|---|---|---|
| ![Home — stress score, companion, and mood check-in](docs/screenshots/1-home.png) | ![Trends — distribution, charts, and pattern insights](docs/screenshots/2-trends.png) | ![AI Coach — chat with Ripple](docs/screenshots/3-chat.png) |

| Breathing | Premium |
|---|---|
| ![Guided box-breathing session](docs/screenshots/4-breathing.png) | ![Premium plans and credit packs](docs/screenshots/5-premium.png) |

| Watch — live score | Watch — breathe | Watch — history |
|---|---|---|
| ![Watch menu with live stress score](docs/screenshots/1-watch-menu.png) | ![Watch 4·7·8 breathing](docs/screenshots/2-watch-breathe.png) | ![Watch weekly trend](docs/screenshots/3-watch-history.png) |

## How stress scoring works

Each available signal is evaluated independently against the user's personal baseline. The calculator then redistributes the weights of missing factors, produces a score from 0–100, and reports both confidence and per-factor contributions.

```text
HealthKit
   │
   ├── HRV ────────────┐
   ├── Heart rate ─────┤
   ├── Sleep ──────────┼──> StressFactor contributors
   ├── Activity ───────┤         │
   └── Recovery ───────┘         v
                         MultiFactorStressCalculator
                                   │
                     weight redistribution + confidence
                                   │
                                   v
                    score (0–100) + factor breakdown
```

| Score | State | Meaning |
|---:|---|---|
| 0–25 | Relaxed | The body is showing low physiological strain |
| 26–50 | Mild | Some stress signals are elevated |
| 51–75 | Moderate | Recovery or regulation may be useful |
| 76–90 | High | Multiple signals indicate meaningful strain |
| 91–100 | Severe | Strong physiological stress signals are present |

Every state is dual-coded with color, icon, and text for accessibility.

## Architecture

StressMonitor uses MVVM with `@Observable` state, protocol-based dependency injection, Swift concurrency, and an offline-first data layer.

```text
┌────────────────────────────────────────────────────────────┐
│ SwiftUI                                                    │
│ Views · AppRouter · WidgetKit · watchOS                    │
└───────────────────────────┬────────────────────────────────┘
                            │ user intent / observable state
┌───────────────────────────▼────────────────────────────────┐
│ View models                                                │
│ Stress · Dashboard · Trends · Chat · Settings · Premium   │
└───────────────────────────┬────────────────────────────────┘
                            │ protocol-based dependencies
┌───────────────────────────▼────────────────────────────────┐
│ Domain services                                            │
│ Algorithm · HealthKit · AI/API · StoreKit · Sync · Export │
└───────────────┬──────────────────────────────┬─────────────┘
                │                              │
┌───────────────▼──────────────┐  ┌────────────▼─────────────┐
│ Local and Apple data         │  │ External boundaries      │
│ SwiftData · HealthKit        │  │ CloudKit · Stress API    │
│ App Groups · Keychain        │  │ Firebase Authentication  │
└──────────────────────────────┘  └──────────────────────────┘
```

### Core design decisions

- **Local-first persistence:** SwiftData is the primary store; CloudKit adds optional synchronization and conflict resolution.
- **Explainable calculation:** five small `StressFactor` implementations feed a single orchestrator instead of hiding logic in the UI.
- **Protocol boundaries:** HealthKit, persistence, CloudKit, StoreKit, and network services are replaceable at the ViewModel boundary.
- **Unidirectional flow:** views send intent to ViewModels; ViewModels coordinate services and publish state back to SwiftUI.
- **Platform-aware sharing:** the watch target mirrors the stress algorithm so it can calculate independently; App Groups and WatchConnectivity share presentation data.
- **Authenticated AI:** chat uses Firebase authentication and an SSE-streaming backend; only messages and derived stress context cross that boundary.

For a deeper walkthrough, see the [system architecture](docs/system-architecture.md) and the [runtime architecture diagram](docs/diagrams/stress-calculation-architecture.html).

## Repository map

```text
StressMonitor/
├── StressMonitor/                     # iOS application target
│   ├── Models/                        # SwiftData and domain models
│   ├── Services/                      # Algorithms and system integrations
│   │   ├── Algorithm/                 # Five-factor stress engine
│   │   ├── API/ and LLM/              # Authenticated chat and SSE streaming
│   │   ├── HealthKit/                 # Read-only health collection
│   │   ├── Repository/ and Sync/      # Local persistence and synchronization
│   │   └── StoreKit/                  # Subscriptions and credit packs
│   ├── ViewModels/                    # Observable application state
│   ├── Views/                         # SwiftUI feature modules
│   └── Theme/                         # Color, typography, and assets
├── StressMonitorWatch Watch App/      # Standalone watchOS target
├── StressMonitorWidget/               # Home and Lock Screen widgets
└── StressMonitorTests/                # Active application test target
```

The Xcode project lives at `StressMonitor/StressMonitor.xcodeproj`; similarly named folders at the repository root are legacy and are not part of the build.

## Technology

| Area | Implementation |
|---|---|
| Interface and state | SwiftUI, Observation (`@Observable`), Swift Charts |
| Health and calculation | HealthKit, five-factor personalized stress model |
| Persistence and sync | SwiftData, CloudKit, App Groups, WatchConnectivity |
| Companion experiences | watchOS, WidgetKit, ActivityKit |
| AI and identity | Native URLSession/SSE client, Firebase Auth, Google Sign-In |
| Commerce and security | StoreKit 2, Keychain Services |

Direct Swift Package dependencies are limited to Firebase Authentication and Google Sign-In.

## Documentation

- [Documentation index](docs/INDEX.md)
- [Product overview](docs/project-overview-pdr.md)
- [System architecture](docs/system-architecture.md)
- [Code standards](docs/code-standards.md)
- [Design guidelines](docs/design-guidelines.md)
- [Deployment guide](docs/deployment-guide.md)

---

Built by Phuong Doan.
