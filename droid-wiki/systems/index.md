# Systems

The service layer holds all domain logic for stress calculation, health data, persistence, sync, LLM chat, IAP, and background tasks. Services are organized by responsibility under `StressMonitor/StressMonitor/Services/`. Each subsystem exposes a protocol from `StressMonitor/StressMonitor/Services/Protocols/` and is injected into ViewModels through constructor injection.

| Subsystem | Page |
| --- | --- |
| Stress algorithm | [Stress algorithm](stress-algorithm.md) |
| HealthKit integration | [HealthKit integration](healthkit-integration.md) |
| SwiftData persistence | [Persistence](persistence.md) |
| CloudKit sync | [CloudKit sync](cloudkit-sync.md) |
| LLM coaching chat | [LLM chat](llm-chat.md) |
| StoreKit IAP | [StoreKit IAP](storekit-iap.md) |
| Data export and deletion | [Data management](data-management.md) |
| Background tasks and notifications | [Background tasks](background-tasks.md) |
| Phone-watch connectivity | [Connectivity](connectivity.md) |
