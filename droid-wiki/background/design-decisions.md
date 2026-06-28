# Design decisions

## MVVM with @Observable instead of Redux or TCA

The app uses MVVM with the `@Observable` macro (iOS 17+) rather than a unidirectional-data-flow architecture like The Composable Architecture (TCA) or an Elm-style store. The reasoning:

- The app's state is naturally scoped per-screen. `StressViewModel` owns dashboard state; `TrendsViewModel` owns trends state; there is little cross-screen shared state beyond `AppRouter` and `PaywallController`, which are already `@Observable` singletons.
- `@Observable` removes the `@Published` boilerplate of `ObservableObject` and works directly with SwiftUI's tracking.
- The team is small (currently one developer). The ceremony of actions, reducers, and stores would slow iteration without a proportionate correctness benefit.

The tradeoff is weaker testability of state transitions compared to TCA. The protocol-based DI pattern partially compensates by making service substitution easy in tests.

## SwiftData over Core Data

SwiftData was chosen over Core Data because:

- iOS 17+ is the deployment floor, so the newer framework is available everywhere.
- The `@Model` macro is more concise than `.xcdatamodeld` files and lives in source alongside the code that uses it.
- SwiftUI integration (`@Query`, `.modelContainer`) is tighter.
- Migrations are declared in Swift (`VersionedSchema`, `SchemaMigrationPlan`) rather than in a separate model editor.

The tradeoff is that SwiftData on iOS 17.0-17.3 had bugs around schema changes that could silently wipe the store. The app declares an explicit `AppMigrationPlan` with lightweight stages to mitigate this.

## Five-factor stress algorithm

The five-factor design (HRV, heart rate, sleep, activity, recovery) was chosen over a single-factor (HRV-only) or two-factor (HRV + HR) approach because:

- Different users have different signal availability. A user who wears their Apple Watch to bed has rich sleep and recovery data; a user who only wears it during the day does not. The weight-redistribution behavior of `MultiFactorStressCalculator` means each user gets the best possible score from whichever signals they have.
- Each factor contributes independent information. HRV reflects autonomic nervous system balance, heart rate reflects acute arousal, sleep reflects restorative quality, activity reflects physical load, recovery reflects accumulated fatigue. Combining them produces a more stable score than any single signal.
- The fallback `StressCalculator` (HRV 70% + HR 30%) is preserved for code paths that only have those two signals, so the multi-factor calculator never produces a worse result than the legacy algorithm.

The tradeoff is complexity. Five factors with circadian baseline adjustment, confidence scoring, and weight redistribution is harder to reason about than a single formula. The per-factor test files (when present) and the explicit `FactorBreakdown` on every result help mitigate this.

## WidgetKit for watch complications

watchOS 10 deprecates ClockKit in favor of WidgetKit. The app uses WidgetKit complications exclusively (registered in `ComplicationBundle.swift`). This was a platform-mandated decision rather than a preference.

## SupabaseLLM as the sole LLM backend

Commit `a4277ec` (2026-06-28) removed the Apple Intelligence on-device fallback and wired `SupabaseLLMService` as the only LLM backend. The reasoning:

- Apple Intelligence availability is uneven across devices and regions. Relying on it would fragment the chat experience.
- The Supabase Edge Function backend handles system prompt construction, model selection, credit deduction, and session persistence. Moving this logic on-device would duplicate it and make it harder to iterate.
- The backend can stream tokens from any OpenAI-compatible provider, giving flexibility to swap models without an app update.

The tradeoff is that chat requires network connectivity and a Supabase account. Offline chat is not supported.

## CloudKit private database over a custom backend

Sync uses CloudKit's private database rather than a custom server because:

- CloudKit provides end-to-end encryption with no additional infrastructure.
- Apple handles authentication, conflict resolution primitives, and change tracking.
- The app has no existing backend beyond the Supabase Edge Functions for chat.

The tradeoff is that CloudKit sync only works for users signed into iCloud, and the conflict resolution semantics are limited. The custom `ConflictResolver` handles the last-writer-wins and device-priority cases that CloudKit's primitives do not cover directly.

## Protocol-based dependency injection

Every service has a protocol in `Services/Protocols/`. ViewModels accept protocols through constructor injection with a default concrete type. This was chosen over `@Environment` injection for services because:

- Protocols make the dependency graph explicit in the type signature.
- Tests substitute mocks by passing a different concrete type to the initializer.
- `@Environment` is retained for the two app-wide singletons (`AppRouter`, `PaywallController`) where environment propagation is genuinely the right model.

## Pure-SwiftUI charts over SwiftUI Charts framework

Trends charts are implemented with `Path` and `Canvas` rather than the SwiftUI Charts framework (introduced in iOS 16). The reasoning:

- The app targets iOS 17+, so the framework is available, but the custom rendering gives finer control over animations, accessibility labels, and the stress-category color coding.
- The custom charts predate the SwiftUI Charts framework's stabilization.

The tradeoff is more code to maintain. A future migration to SwiftUI Charts would reduce the chart code substantially.
