# Glossary

Terms specific to StressMonitor. Apple framework terms (SwiftData, HealthKit, CloudKit, WidgetKit, StoreKit) are used as Apple defines them.

| Term | Definition |
| --- | --- |
| Stress Buddy | The character companion rendered on the Home tab. Its mood and evolution stage reflect the user's current stress category. Also called "Ripple" after the default water-otter character. |
| Ripple | The default Stress Buddy character (Water element). The UI design system borrows the name: "RippleMood", "RippleBreathingView". |
| Stress Factor | A type conforming to the `StressFactor` protocol that computes a normalized 0-1 score plus confidence from a `StressContext`. Five ship: HRV, Heart Rate, Sleep, Activity, Recovery. |
| Multi-Factor Score | The composite 0-100 stress level produced by `MultiFactorStressCalculator`. A weighted sum of available factor values, normalized so missing factors redistribute their weight. |
| Stress Category | One of five tiers binning the stress level: relaxed (0-25), mild (25-50), moderate (50-75), high (75-90), severe (90-100). Drives color, icon, and character mood. |
| HRV | Heart Rate Variability. StressMonitor reads SDNN-based HRV from HealthKit (`.heartRateVariabilitySDNN`), not RMSSD. SDNN runs slightly higher but normalizes correctly against a personal baseline. |
| SDNN | Standard Deviation of Normal-to-Normal intervals. The HRV metric Apple HealthKit exposes. |
| Bio Age | Biological age estimate from `BioAgeCalculator` comparing HRV, resting HR, and recovery against age-expected baselines. Premium feature. |
| Personal Baseline | Per-user rolling averages for HRV (including hourly circadian adjustments) and resting heart rate. Owned by `PersonalBaseline` and calibrated by `FactorCalibrator`. |
| Stress Context | The `StressContext` struct carrying raw biometric inputs plus baseline that gets handed to the calculator. All fields are optional to support graceful degradation. |
| Stress Result | The `StressResult` struct output by the calculator: level, category, confidence, raw HRV/HR, timestamp, and an optional `FactorBreakdown`. |
| Factor Breakdown | Per-factor component values and data completeness percentage attached to a `StressResult`. Powers the "stress sources" card on the dashboard. |
| Confidence | A 0-1 score blending data completeness (40% weight) with the average of per-factor confidences (60%). Penalizes low HRV, extreme HR, few samples, and stale readings. |
| Paywall Reason | An enum case on `PaywallController` describing why the paywall was shown (general, trendsLongRange, bioAgeDetail, characters, breathingAdvanced). Drives analytics. |
| Premium State | The `PremiumState` singleton consulted by `PaywallController` and the UI to gate features. Backed by StoreKit entitlements. |
| Evolution Stage | One of three Tamagotchi-style growth stages for a character: droplet, ripple, tidal. Unlocked through sustained low-stress periods or IAP. |
| Character Element | The elemental affinity of a Stress Buddy character: water, earth, fire, air, moon. Each maps to a color palette and an emoji. |
| App Router | The `AppRouter` singleton owning the selected tab and a `NavigationPath` per tab. Enables deep links and cross-tab routing. |
| Widget Shared Data | The compact snapshot written to the App Group so the widget extension and watch app can render the latest stress without a HealthKit query. |
| Demo Mode | A launch-argument flag (`-demo-mode`, DEBUG-only) that swaps `HealthKitManager` for `SimulatorHealthKitService`, which cycles through all stress scenarios every 30 seconds. |
| SSE | Server-Sent Events. The streaming transport used by `SupabaseLLMService` to receive chat tokens from the Edge Function. Parsed by `SSEParser`. |
| Edge Function | The Supabase serverless function at `/chat` that constructs the system prompt, selects the LLM model, deducts credits, and streams tokens back to the app. |
