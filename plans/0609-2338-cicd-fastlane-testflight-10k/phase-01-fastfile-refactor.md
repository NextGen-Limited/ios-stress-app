---
phase: 1
title: "Fastfile Refactor"
status: completed
priority: P1
effort: "2h"
dependencies: []
---

# Phase 1: Fastfile Refactor

## Overview

Split the monolithic `beta` lane into two focused lanes: `upload_beta` (build + upload, runs on every push) and `distribute_beta` (distribute-only, runs on manual trigger). Add `changelog_from_git_commits` to replace manual CHANGELOG.md reading.

## Requirements

- Functional:
  - `upload_beta`: match → increment_build → gym → pilot(skip_submission: true, skip_waiting: true)
  - `distribute_beta`: pilot(distribute_only: true, groups: from ENV, changelog: from git)
  - Keep `test`, `build_only`, `increment_build` lanes unchanged
  - Slack notify in both lanes (different messages)
- Non-functional:
  - `upload_beta` must complete in <25 min on `macos-15`
  - `distribute_beta` must complete in <5 min (pure API call, no build)

## Architecture

```
upload_beta lane:
  setup_ci → match(readonly) → increment_build → gym → pilot(skip_submission:true, skip_waiting:true) → slack_notify("uploaded")

distribute_beta lane:
  pilot(distribute_only:true, groups:[ENV groups], changelog:git_commits) → slack_notify("distributed to X")
```

## Related Code Files

- Modify: `fastlane/Fastfile`

## Implementation Steps

1. **Open `fastlane/Fastfile`**, locate the `beta` lane (line 79).

2. **Rename `beta` → `upload_beta`**, capture changelog at build time, then change the `pilot` call:
   ```ruby
   lane :upload_beta do
     setup_ci
     match(type: "appstore", readonly: true, api_key: api_key)
     increment_build

     # Capture changelog NOW (accurate: reflects commits actually in this build)
     notes = begin
       changelog_from_git_commits(
         merge_commit_filtering: "exclude_merges",
         commits_count: 20,
         pretty: "- %s"
       )
     rescue => e
       UI.important("Could not generate changelog: #{e.message}")
       "Build from #{ENV['GITHUB_SHA']&.[](0..6) || 'local'}"
     end
     FileUtils.mkdir_p("build")
     File.write("build/CHANGELOG.txt", notes)

     gym(
       project: PROJECT,
       scheme: SCHEME,
       configuration: "Release",
       export_method: "app-store",
       include_bitcode: false,
       include_symbols: true,
       output_directory: "build/",
       output_name: "StressMonitor.ipa",
       archive_path: "build/StressMonitor.xcarchive",
       xcargs: [
         "-skipPackagePluginValidation",
         "-skipMacroValidation",
         "COMPILER_INDEX_STORE_ENABLE=NO"
       ].join(" "),
       suppress_xcode_output: true
     )

     pilot(
       api_key: api_key,
       app_identifier: APP_IDENTIFIER,
       skip_submission: true,
       skip_waiting_for_build_processing: true
     )

     slack_notify("uploaded to TestFlight (processing)")
   end
   ```

3. **Add `distribute_beta` lane** after `upload_beta` — reads changelog captured at upload time:
   ```ruby
   desc "Distribute a processed build to a TestFlight group"
   lane :distribute_beta do
     groups = (ENV["TESTFLIGHT_GROUPS"] || "Core Testers").split(",").map(&:strip)

     # Read changelog written during upload_beta (accurate, build-time snapshot)
     notes = if File.exist?("build/CHANGELOG.txt")
       File.read("build/CHANGELOG.txt")
     else
       "Build from #{ENV['GITHUB_SHA']&.[](0..6) || 'local'}"
     end

     # pilot auto-selects latest processed build when distribute_only: true
     pilot(
       api_key: api_key,
       app_identifier: APP_IDENTIFIER,
       distribute_only: true,
       groups: groups,
       notify_external_testers: true,
       changelog: notes
     )

     slack_notify("distributed to #{groups.join(', ')}")
   end
   ```

4. **Update `slack_notify` helper** to accept a message parameter:
   ```ruby
   def slack_notify(action = "deployed")
     return unless ENV["SLACK_WEBHOOK_URL"]
     version = get_version_number(xcodeproj: PROJECT, target: "StressMonitor")
     build   = get_build_number(xcodeproj: PROJECT)
     slack(
       slack_url: ENV["SLACK_WEBHOOK_URL"],
       message: "📦 *StressMonitor #{version} (#{build})* #{action}",
       payload: {
         "Build"   => build,
         "Version" => version,
         "Commit"  => ENV["GITHUB_SHA"]&.[](0..6) || "N/A",
         "Run"     => ENV["GITHUB_RUN_ID"] ? "<#{ENV['GITHUB_SERVER_URL']}/#{ENV['GITHUB_REPOSITORY']}/actions/runs/#{ENV['GITHUB_RUN_ID']}|View>" : "local"
       }
     )
   end
   ```

5. **Remove the old `beta` lane** entirely (replaced by `upload_beta`).

6. **Verify locally** (dry run, no secrets needed):
   ```bash
   bundle exec fastlane lanes  # should list: test, build_only, upload_beta, distribute_beta, increment_build
   ```

## Success Criteria

- [x] `bundle exec fastlane lanes` lists `upload_beta` and `distribute_beta`
- [x] Old `beta` lane is removed
- [x] `upload_beta` contains `skip_submission: true, skip_waiting_for_build_processing: true`
- [x] `distribute_beta` contains `distribute_only: true`
- [x] `changelog_from_git_commits` used in `upload_beta` (captures at build time)
- [x] `slack_notify` accepts message argument in both lanes

## Risk Assessment

| Risk | Mitigation |
|------|-----------|
| `distribute_only: true` requires build to be fully processed by Apple | `distribute.yml` workflow should only be triggered after build shows "Ready to Test" in ASC |
| `changelog_from_git_commits` fails if no commits | Wrapped in `rescue` fallback to SHA string |
| Old callers of `fastlane beta` in docs/scripts | Search repo for `fastlane beta` references and update to `fastlane upload_beta` |
