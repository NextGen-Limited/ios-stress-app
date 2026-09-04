# AGENTS.md

Guidance for AI agents working in this repo. Product docs live in `docs/` — start at `docs/INDEX.md`. This file only covers what agents get wrong without being told.

## Repo layout — read this first

- The Xcode project is **one level down**: `StressMonitor/StressMonitor.xcodeproj`. Run all xcodebuild/fastlane commands from the repo root with `-project StressMonitor/StressMonitor.xcodeproj`.
- **Orphaned code that is NOT in the Xcode project — edits there never build or run:**
  - `StressMonitorTests/` (repo root)
  - `StressMonitor/Models/`, `StressMonitor/Services/`, `StressMonitor/Views/`
- Real targets live at: app `StressMonitor/StressMonitor/`, tests `StressMonitor/StressMonitorTests/`, watch `StressMonitor/StressMonitorWatch Watch App/` (path contains spaces), widget `StressMonitor/StressMonitorWidget/`.
- Schemes: `StressMonitor`, `"StressMonitorWatch Watch App"` (shared), `StressMonitorWidgetExtension` (CI builds it; no shared scheme file).

## Build & test (mirrors `.github/workflows/_test.yml`)

```bash
# Build iOS (CI parity: signing off)
xcodebuild build -project StressMonitor/StressMonitor.xcodeproj \
  -scheme StressMonitor -destination 'generic/platform=iOS Simulator' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

# Build watchOS — scheme name contains spaces
xcodebuild build -project StressMonitor/StressMonitor.xcodeproj \
  -scheme "StressMonitorWatch Watch App" -destination 'generic/platform=watchOS Simulator' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

# All tests (CI destination: iPhone 16 / OS=latest, Xcode 26.3 on macos-15)
xcodebuild test -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -parallel-testing-enabled NO CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

# Single class / single method: append
#   -only-testing:StressMonitorTests/SSEParserTests
#   -only-testing:StressMonitorTests/SSEParserTests/testMethod

# Local helper: finds/boots a simulator, passes its UUID, results in StressMonitor/build/
python3 scripts/run-tests.py

# Lint — run from repo root (.swiftlint.yml `included:` is StressMonitor/)
swiftlint lint
```

## Testing quirks

- `DataDeletionConsolidationTests`/`CharacterEntitlementSyncTests` no longer gate on `GSD_CI`/`TEST_RUNNER_GSD_CI` (removed 2026-09-04, 02-04/ENV-01/ENV-02): the exit-65 host stall was a container-lifetime bug (fixture returned a context whose owning `ModelContainer` had already deallocated), not a CI-only defect. All suites run in the default invocation everywhere now.
- CI disables parallel testing deliberately; keep `-parallel-testing-enabled NO` when reproducing CI failures.
- IAP tests use the StoreKit config `StressMonitor/StressMonitorTests/StressMonitorProducts.storekit`.
- No HealthKit data on simulator: run with the `-demo-mode` launch argument (Edit Scheme → Run → Arguments) — cycles all stress levels through the real pipeline, not mocks.

## Architecture (MVVM, SwiftUI)

- `@Observable` ViewModels, protocol-based DI (`Services/Protocols/`), SwiftData persistence, CloudKit sync, HealthKit read-only.
- Stress score: `MultiFactorStressCalculator` runs 5 `StressFactor`s (HRV, heart rate, sleep, activity, recovery). Each factor carries its own `weight`; missing factors trigger weight redistribution; per-user `FactorWeights` come from the personal baseline (`BaselineCalculator`, `FactorCalibrator`). `StressCalculator` is the legacy HRV+HR fallback. Score 0–100 → Relaxed / Mild / Moderate / High.
- **The watch target duplicates the algorithm sources** — `MultiFactorStressCalculator`, all `*StressFactor.swift`, protocols exist in both targets. Algorithm changes must be mirrored into `StressMonitorWatch Watch App/Services/`.
- Backend client: `StressMonitor/StressMonitor/Services/API/StressAPIClient*.swift` (auth, chat SSE streaming, credits, preferences, sessions). Base URL resolves `STRESS_API_BASE_URL` from Info.plist → env → UserDefaults → fallback `https://stress-api.dropitx.site`.
- SPM dependencies: `firebase-ios-sdk` (Auth) and `GoogleSignIn-iOS` only. `GoogleService-Info.plist` is committed. (The README package table is stale — trust the pbxproj.)
- Bundle IDs: `stress.ai.com`, `stress.ai.com.watchkitapp`, `stress.ai.com.widget`. Team `K2TYLYAWMK`.
- Deployment targets: iOS 18.6 (some targets 26.1), watchOS 11.6. Older docs claiming "iOS 17+" are stale.

## Conventions

- SwiftLint opt-in rules include `force_unwrapping` and `implicitly_unwrapped_optional` — avoid `!` in new code. CI lint is advisory (`|| true`) but don't regress.
- Floating-point assertions use `accuracy:`; test names follow `test[Method]_[Condition]`.
- UI: dual-code stress levels (color + icon/text), 44pt touch targets, `.accessibleDynamicType()`, `HapticManager` (`Views/Components/`), `Color.stressColor(for:)` (`Theme/Color+Extensions.swift`). Design system docs: `docs/design-guidelines*.md`.
- Simulator interaction: the `argent` MCP server is wired via `opencode.json` — prefer it over raw `xcrun simctl`.

## Release / CI

- PR → `ci.yml` → `_test.yml`: SwiftLint + iOS/watchOS/widget builds + unit tests.
- `deploy.yml` runs after CI success on `main`/`release/*`: fastlane `upload_beta` → TestFlight. `distribute.yml` and `release.yml` are manual dispatch.
- Fastlane (from repo root): `bundle exec fastlane upload_beta|distribute_beta|release|build_only|build_widget|increment_build`. Requires `APP_STORE_CONNECT_API_KEY_*` env; signing via Match (`MATCH_PASSWORD`, `MATCH_GIT_URL`) — CI always syncs Match readonly, never regenerates certs.

## Global rules

- Do not create git commits unless asked.
- Commit author: `Phuong Doan`. No AI attribution or `Co-Authored-By` lines in commit messages.

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **ios-stress-app** (15452 symbols, 197056 relationships, 238 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> Index stale? Run `node .gitnexus/run.cjs analyze` from the project root — it auto-selects an available runner. No `.gitnexus/run.cjs` yet? `npx gitnexus analyze` (npm 11 crash → `npm i -g gitnexus`; #1939).

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows. For regression review, compare against the default branch: `detect_changes({scope: "compare", base_ref: "main"})`.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `query({search_query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `context({name: "symbolName"})`.
- For security review, `explain({target: "fileOrSymbol"})` lists taint findings (source→sink flows; needs `analyze --pdg`).

## Never Do

- NEVER edit a function, class, or method without first running `impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `rename` which understands the call graph.
- NEVER commit changes without running `detect_changes()` to check the affected scope.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/ios-stress-app/context` | Codebase overview, check index freshness |
| `gitnexus://repo/ios-stress-app/clusters` | All functional areas |
| `gitnexus://repo/ios-stress-app/processes` | All execution flows |
| `gitnexus://repo/ios-stress-app/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
