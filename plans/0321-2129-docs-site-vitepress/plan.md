---
title: VitePress Docs Site + In-App Integration
status: in-progress
created: 2026-03-21
---

# VitePress Docs Site + In-App Integration

User-facing documentation site in `docs-site/` subdirectory, deployed to Vercel, opened in-app via SFSafariViewController.

## Context

- Brainstorm: Structured like https://docs.ideation.love/stresswatch/en/
- Framework: VitePress (lightweight, fast, zero-config)
- Hosting: Vercel (auto-deploy on push)
- In-app: SFSafariViewController sheet from Settings

## Phases

| Phase | File | Status |
|-------|------|--------|
| 01 | [VitePress Setup](./phase-01-vitepress-setup.md) | complete |
| 02 | [Deploy to Vercel](./phase-02-deploy-vercel.md) | ready (manual deploy needed) |
| 03 | [iOS SFSafariViewController Integration](./phase-03-ios-safari-integration.md) | complete |
| 04 | [CI Separation](./phase-04-ci-separation.md) | deferred |

## Key Files

- `docs-site/` — new VitePress project (monorepo subdirectory)
- `StressMonitor/StressMonitor/Views/Settings/Components/AboutCard.swift` — add Help link
- `StressMonitor/StressMonitor/Views/Settings/SettingsView.swift` — wire sheet
- New: `StressMonitor/StressMonitor/Views/Shared/SafariView.swift`
- New: `StressMonitor/StressMonitor/Utilities/DocsURL.swift`

## Success Criteria

- `docs-site/` builds with `npm run build` without errors
- Deployed URL returns HTTP 200 for all 4 content sections in EN + VI
- Help, Privacy, Terms links in Settings open SFSafariViewController sheet
- Phase 4 (CI) deferred until first CI pipeline is added

## Validation Log

### Session 1 — 2026-03-21
**Trigger:** `/plan --validate` before implementation
**Questions asked:** 6

#### Questions & Answers

1. **[Architecture]** URL Identifiable approach for `.sheet(item:)`
   - Options: Retroactive conformance | DocLink struct | @State Bool + URL var
   - **Answer:** Retroactive conformance (`extension URL: @retroactive Identifiable`)
   - **Rationale:** Simplest. No structural overhead. Minor future warning risk is acceptable.

2. **[Scope]** Legal page content strategy
   - Options: Placeholder first | Real content from day 1 | Keep external links
   - **Answer:** Placeholder text first — unblocks Phase 1, fill before App Store submission

3. **[Tradeoffs]** VitePress theme
   - Options: Default | Custom colors | Match StressWatch exactly
   - **Answer:** Default VitePress theme — ship fast, customize later if needed

4. **[Scope]** i18n scope
   - Options: EN only | EN + Vietnamese | Full 9 languages
   - **Answer:** EN + Vietnamese — ship both locales from Phase 1

5. **[Assumptions]** Vercel domain
   - Options: Vercel URL first | Custom domain from day 1
   - **Answer:** Vercel URL first, custom domain later — unblocks deploy

6. **[Risks]** Existing CI workflows
   - Options: No CI yet | Yes, iOS CI exists | Not sure
   - **Answer:** No CI yet — Phase 4 deferred until CI is first added

#### Confirmed Decisions
- URL Identifiable: retroactive conformance — simple, minimal risk
- Legal: placeholder text — unblocks Phase 1
- Theme: default — YAGNI
- i18n: EN + Vietnamese from Phase 1 — **doubles content effort, restructures VitePress config**
- Domain: Vercel URL first
- CI: Phase 4 deferred

#### Action Items
- [x] Phase 1: Add VitePress i18n config with `/en/` and `/vi/` locales
- [x] Phase 1: Double content pages (translate all to Vietnamese)
- [x] Phase 4: Mark as deferred — skip until CI is first configured

#### Impact on Phases
- Phase 1: Significant — VitePress directory structure changes to locale-based layout, all content pages need Vietnamese translations
- Phase 4: Deferred — no action needed until project adds CI
