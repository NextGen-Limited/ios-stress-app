# Phase 02: Deploy to Vercel

**Status:** ready — vercel.json added, manual deploy required
**Priority:** High
**Effort:** ~30min
**Depends on:** phase-01 (build must pass)

## Overview

Deploy `docs-site/` to Vercel with zero-config auto-deploy on push to `main`. Set root directory to `docs-site/` so Vercel only builds the VitePress project.

## Implementation Steps

### 1. Add `vercel.json` inside `docs-site/`

```json
{
  "buildCommand": "npm run build",
  "outputDirectory": ".vitepress/dist",
  "installCommand": "npm install",
  "framework": null
}
```

`framework: null` prevents Vercel from auto-detecting and overriding the config.

### 2. Deploy via Vercel CLI or Dashboard

**Option A — CLI (faster):**
```bash
cd docs-site
npx vercel --prod
# When prompted:
#   Root directory: . (already in docs-site/)
#   Build command: npm run build
#   Output dir: .vitepress/dist
```

**Option B — Dashboard:**
1. New Project → Import this GitHub repo
2. Set **Root Directory** to `docs-site`
3. Framework Preset: Other
4. Build Command: `npm run build`
5. Output Directory: `.vitepress/dist`
6. Deploy

### 3. Note the deployed URL

After deploy, capture the production URL (e.g. `https://stressmonitor-docs.vercel.app`).

Update `DocsURL.swift` (Phase 03) with this URL.

### 4. Custom domain (optional)

In Vercel dashboard → Domains → add custom domain (e.g. `docs.stressmonitor.app`). Requires DNS CNAME record pointing to `cname.vercel-dns.com`.

## Todo

- [ ] Add `docs-site/vercel.json`
- [ ] Deploy to Vercel (CLI or dashboard)
- [ ] Verify all page routes return HTTP 200
- [ ] Copy production URL for Phase 03
- [ ] (Optional) Configure custom domain

## Success Criteria

- `https://<your-vercel-url>/principle/stress-levels` returns 200
- `https://<your-vercel-url>/legal/privacy` returns 200
- Auto-deploy triggers on push to `main` (verify in Vercel dashboard)

## Risks

- Vercel free tier has build minute limits — VitePress builds are fast (~10s), no concern
- If custom domain not ready, use Vercel-generated URL in `DocsURL.swift` and update later
