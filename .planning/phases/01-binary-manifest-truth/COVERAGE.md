# API Coverage — Phase 1: Binary & Manifest Truth

No external API integration: this phase audits and validates build artifacts (privacy manifests, entitlements, plists, the Release binary) and the privacy manifests of third-party SDKs (firebase-ios-sdk, GoogleSignIn-iOS) that were integrated in prior milestones — it adds no new external API surface. The detector's `sdk` signal over the plan prose refers to manifest validation of existing dependencies, not a new integration.
