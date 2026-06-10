---
phase: 4
title: "Test Workflow Cache"
status: completed
priority: P2
effort: "30m"
dependencies: []
---

# Phase 4: Test Workflow Cache

## Overview

Improve `_test.yml` (the reusable test workflow) with: (1) SPM package cache using `Package.resolved` hash key, and (2) switch from manual Ruby gem caching to `ruby/setup-ruby` with `bundler-cache: true` for simpler, reliable gem caching.

## Requirements

- Functional:
  - SPM package cache added with `Package.resolved`-based key
  - Ruby setup uses `ruby/setup-ruby@v1` with `bundler-cache: true`
  - Remove manual `actions/cache` for `vendor/bundle` (handled by `ruby/setup-ruby`)
  - Remove manual `bundle config` + `bundle install` step (handled by `ruby/setup-ruby`)
- Non-functional:
  - Cache changes must not break existing DerivedData cache
  - No change to test/lint logic

## Related Code Files

- Modify: `.github/workflows/_test.yml`

## Implementation Steps

1. **Open `.github/workflows/_test.yml`**, locate the `lint-and-test` job steps.

2. **Replace the Ruby Gems cache + Install Dependencies steps** with `ruby/setup-ruby`:

   **Remove** these two steps:
   ```yaml
   - name: Cache Ruby Gems
     uses: actions/cache@v4
     with:
       path: vendor/bundle
       key: gems-${{ runner.os }}-${{ hashFiles('**/Gemfile.lock') }}
       restore-keys: gems-${{ runner.os }}-

   - name: Install Dependencies
     run: |
       bundle config set path vendor/bundle
       bundle update --bundler
       bundle install --jobs 4 --retry 3
   ```

   **Add** this single step in their place:
   ```yaml
   - name: Setup Ruby & Bundler
     uses: ruby/setup-ruby@v1
     with:
       bundler-cache: true    # no ruby-version pin — uses macos-15 system default
   ```

3. **Add SPM cache step** after the DerivedData cache step:
   ```yaml
   - name: Cache SPM Packages
     uses: actions/cache@v4
     with:
       path: |
         ~/Library/Developer/Xcode/DerivedData/**/SourcePackages/checkouts
         ~/Library/Developer/Xcode/DerivedData/**/SourcePackages/repositories
       key: spm-${{ runner.os }}-${{ hashFiles('**/Package.resolved') }}
       restore-keys: |
         spm-${{ runner.os }}-
   ```

4. **Verify** the `build-watchos` job in `_test.yml` — it doesn't use Fastlane/gems so no changes needed there.

5. **Check** that existing `swiftlint` step still works (it uses `which swiftlint`, doesn't depend on Bundler).

## Success Criteria

- [x] `ruby/setup-ruby@v1` with `bundler-cache: true` present in `lint-and-test` job
- [x] Manual `Cache Ruby Gems` and `Install Dependencies` steps removed
- [x] SPM cache step added with `Package.resolved` hash key
- [ ] `_test.yml` syntax valid (validated on next PR trigger)
- [x] No change to SwiftLint or `fastlane test` steps

## Risk Assessment

| Risk | Mitigation |
|------|-----------|
| `ruby/setup-ruby` uses wrong Ruby version | No pin — uses macos-15 system default. If bundler fails on version mismatch, add `.ruby-version` file to repo. |
| SPM cache miss on first run | Expected — first run resolves fresh, subsequent runs hit cache |
| `Package.resolved` not committed | Verify `Package.resolved` is in git (not gitignored). Run `git ls-files | grep Package.resolved`. |
