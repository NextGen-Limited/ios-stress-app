fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios build_widget

```sh
[bundle exec] fastlane ios build_widget
```

Build widget extension only (for CI validation)

### ios setup_match

```sh
[bundle exec] fastlane ios setup_match
```

One-time local setup: generate certs and profiles into the Match repo

### ios build_only

```sh
[bundle exec] fastlane ios build_only
```

Build IPA without uploading (for CI validation)

### ios upload_beta

```sh
[bundle exec] fastlane ios upload_beta
```

Build and upload to TestFlight (no distribution)

### ios distribute_beta

```sh
[bundle exec] fastlane ios distribute_beta
```

Distribute a processed build to a TestFlight group

### ios release

```sh
[bundle exec] fastlane ios release
```

Submit latest TestFlight build for App Store review

### ios increment_build

```sh
[bundle exec] fastlane ios increment_build
```

Auto-increment build number based on latest TestFlight build

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
