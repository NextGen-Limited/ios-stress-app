# Background

Technical rationale for design decisions in StressMonitor. This section explains why choices were made, not just what they are.

## Decisions

See [Design decisions](design-decisions.md) for architectural rationale and [Pitfalls](pitfalls.md) for known danger zones.

| Decision | Summary |
| --- | --- |
| MVVM + `@Observable` | Clean state management, testable, no `@Published` boilerplate |
| SwiftData over CoreData | iOS 17+ native, SwiftUI-friendly, macro-based models |
| Five-factor stress algorithm | Graceful degradation when factors missing; more accurate than HRV-only |
| WidgetKit for watch complications | Required for watchOS 10+ (ClockKit deprecated) |
| SupabaseLLM as sole backend | Removed Apple Intelligence fallback in commit `a4277ec` |
| CloudKit private database | End-to-end encrypted, no server infrastructure required |
| Protocol-based DI | Every service has a protocol; mocking is a one-line change |
