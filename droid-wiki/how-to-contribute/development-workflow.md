# Development workflow

## Branch

```bash
git checkout main
git pull
git checkout -b feat/<short-description>
```

Branch names use the `feat/`, `fix/`, `refactor/`, or `docs/` prefix followed by a kebab-case description.

## Code

- Follow [Patterns and conventions](patterns-and-conventions.md).
- Group system imports alphabetically with `Foundation` first and `SwiftUI` last.
- Use `@Observable` for view models; mark them `@MainActor`.
- Inject services through protocols with default concrete-type arguments.
- Keep files under ~500 lines. Split when a file clearly owns two responsibilities.

## Build

```bash
xcodebuild -scheme StressMonitor \
    -destination 'platform=iOS Simulator,name=iPhone 15'
```

For the watch app:

```bash
xcodebuild -scheme "StressMonitorWatch Watch App" \
    -destination 'platform=watchOS Simulator,name=Apple Watch Series 9'
```

## Test

```bash
xcodebuild test -scheme StressMonitor \
    -destination 'platform=iOS Simulator,name=iPhone 15'
```

Or use the `xc-all` MCP plugin tools documented in `CLAUDE.md` and `AGENTS.md`. See [Testing](testing.md).

## Demo mode

Enable `-demo-mode` in the scheme's Run arguments to test on the simulator without real HealthKit data. The demo pipeline cycles through all stress scenarios every 30 seconds.

## Commit

Use conventional commit prefixes:

```bash
git commit -m "feat(home): add stress hero card with character mood"
git commit -m "fix(watch): resolve WCSession activation race"
git commit -m "docs: update architecture with icon system migration"
```

Multi-line commit bodies are encouraged for non-trivial changes. Never include credentials or attribution footers.

## PR

Push and open a PR against `main`. Keep PRs scoped to one concern. Link the PR to any relevant plan document under `docs/plans/` or `plans/`.

## Merge

Squash or rebase-merge onto `main`. The default branch should always build and pass tests.
