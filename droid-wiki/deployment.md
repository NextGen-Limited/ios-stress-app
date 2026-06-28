# Deployment

StressMonitor ships to TestFlight and the App Store through Fastlane driven by GitHub Actions, with Xcode Cloud as a fallback CI. Code signing is managed through `match`.

## Targets and bundle IDs

| Target | Bundle ID |
| --- | --- |
| iOS app | `stress.ai.com` |
| watchOS app | `stress.ai.com.watchkitapp` |
| Widget extension | `stress.ai.com.widget` |

Bundle IDs are declared in `fastlane/Fastfile` as `APP_IDENTIFIER`, `WATCH_APP_IDENTIFIER`, and `WIDGET_APP_IDENTIFIER` environment-overridable constants.

## Fastlane lanes

Defined in `fastlane/Fastfile`:

| Lane | Purpose |
| --- | --- |
| `build_widget` | Build the widget extension only (CI validation) |
| `build_only` | Build the IPA without uploading |
| `upload_beta` | Build and upload to TestFlight (no distribution) |
| `distribute_beta` | Distribute a processed build to a TestFlight group |
| `release` | Submit the latest TestFlight build for App Store review |

The `api_key` helper resolves App Store Connect API key credentials from `~/.appstoreconnect/AuthKey.p8` or from the `APP_STORE_CONNECT_API_KEY_P8` environment variable in CI. The token has a 20-minute duration.

## Code signing

`match` manages signing certificates and provisioning profiles from a separate git repo (declared in `fastlane/Matchfile`). The `match` setup lane is a one-time local bootstrap that generates certs and profiles into the match repo. Subsequent CI runs fetch from the match repo read-only.

The `APP_IDENTIFIER` constants above must match the bundle IDs configured in Xcode Signing & Capabilities for each target.

## GitHub Actions

Workflows at `.github/workflows/`:

| Workflow | Purpose |
| --- | --- |
| `ci.yml` | Continuous integration: build and test on PR |
| `deploy.yml` | Build and upload to TestFlight |
| `distribute.yml` | Distribute a TestFlight build to a group |
| `release.yml` | Submit a build for App Store review |
| `_test.yml` | Reusable test workflow |
| `droid-wiki-refresh.yml` | Regenerate this wiki on push to main |

## Xcode Cloud

Scripts at `ci_scripts/`:

- `ci_post_clone.sh` - runs after the repo is cloned.
- `ci_post_xcodebuild.sh` - runs after `xcodebuild` completes.

These are the fallback path when GitHub Actions is unavailable.

## Capabilities

The app entitlements (`StressMonitor/StressMonitor/StressMonitor.entitlements`) enable:

- HealthKit (read-only).
- iCloud (CloudKit private database).
- App Groups (for widget/watch data sharing).
- Background Modes (app refresh, notifications).

## Release process

1. Update version and build number in Xcode.
2. Run `fastlane upload_beta` locally or let CI run on merge to the release branch.
3. Smoke-test the TestFlight build.
4. Run `fastlane distribute_beta` to share with the test group.
5. Run `fastlane release` to submit to App Store review.

See `docs/deployment-guide.md`, `docs/deployment-guide-environment.md`, and `docs/deployment-guide-release.md` for the long-form release runbook.
