# Phase 04: CI Separation

<!-- Updated: Validation Session 1 - DEFERRED. No CI exists in this project yet. -->

**Status:** deferred
**Priority:** Low
**Effort:** ~20min (when CI is first added)
**Depends on:** First CI pipeline being added to the project

> **SKIP FOR NOW.** Validation confirmed no GitHub Actions CI exists. Revisit when iOS CI is first configured.

## Overview

Prevent `docs-site/` changes from triggering iOS builds (and vice versa). Scoped path filters in GitHub Actions.

## Implementation Steps

### 1. Check existing CI workflows

```bash
ls .github/workflows/
```

If none exist, skip this phase — no CI to separate.

### 2. iOS Build Workflow — ignore `docs-site/**`

In `.github/workflows/ios-build.yml` (or equivalent), add path ignore:

```yaml
on:
  push:
    branches: [main]
    paths-ignore:
      - 'docs-site/**'
      - '**.md'
  pull_request:
    branches: [main]
    paths-ignore:
      - 'docs-site/**'
      - '**.md'
```

### 3. Docs Deploy Workflow — scope to `docs-site/**`

Vercel auto-deploys via its GitHub integration on every push. To scope it, use Vercel's **Ignored Build Step** setting in the dashboard:

- Project Settings → Git → Ignored Build Step
- Command: `git diff HEAD^ HEAD --name-only | grep -q "^docs-site/"`
- If the command exits 0 (changes found in `docs-site/`), build runs. Otherwise, skip.

Alternatively, add a GitHub Actions workflow for manual control:

```yaml
# .github/workflows/docs-deploy.yml
name: Deploy Docs

on:
  push:
    branches: [main]
    paths:
      - 'docs-site/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
        working-directory: docs-site
      - run: npm run build
        working-directory: docs-site
      - uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: docs-site
```

## Todo

- [ ] Check if `.github/workflows/` exists
- [ ] If iOS CI exists: add `paths-ignore: ['docs-site/**']`
- [ ] Configure Vercel Ignored Build Step OR add `docs-deploy.yml`
- [ ] Push a test change to `docs-site/` — verify iOS CI does not trigger
- [ ] Push a test change to `StressMonitor/` — verify docs deploy does not trigger

## Success Criteria

- iOS build skips on `docs-site/` changes
- Docs deploy only runs on `docs-site/` changes
- Both can still be triggered manually if needed

## Notes

- If no CI exists yet, skip this phase — add when CI is first configured
- Xcode Cloud uses its own trigger config (not GitHub Actions paths) — configure separately in App Store Connect if using Xcode Cloud
