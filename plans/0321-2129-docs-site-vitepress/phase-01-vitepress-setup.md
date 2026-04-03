# Phase 01: VitePress Setup

<!-- Updated: Validation Session 1 - i18n EN+VI added; directory structure changed to locale-based layout -->

**Status:** complete
**Priority:** High
**Effort:** ~4h (doubled from ~2h due to EN+VI content)

## Overview

Initialize VitePress in `docs-site/` subdirectory with i18n support (English + Vietnamese). Configure locale-based navigation, sidebar. Write all content pages in both languages.

## Repository Structure to Create

VitePress i18n uses a root locale + sub-locale directory layout:

```
docs-site/
├── .vitepress/
│   ├── config.ts         # VitePress config with locales: en (root) + vi
│   └── theme/
│       └── index.ts      # Only needed for custom theme (skip for default)
├── en/                   # English content (root locale mapped to /)
│   ├── principle/
│   │   ├── index.md
│   │   ├── stress-levels.md
│   │   ├── what-is-hrv.md
│   │   ├── resting-heart-rate.md
│   │   └── stress-overload-trigger.md
│   ├── user-guide/
│   │   ├── index.md
│   │   ├── measurement-frequency.md
│   │   ├── manual-measurement.md
│   │   └── notifications-troubleshoot.md
│   ├── watch-widget/
│   │   ├── index.md
│   │   ├── watch-face-setup.md
│   │   ├── complications.md
│   │   └── widget-not-updating.md
│   ├── legal/
│   │   ├── privacy.md
│   │   └── terms.md
│   └── index.md
├── vi/                   # Vietnamese content (served at /vi/)
│   ├── principle/
│   │   ├── index.md
│   │   ├── stress-levels.md
│   │   ├── what-is-hrv.md
│   │   ├── resting-heart-rate.md
│   │   └── stress-overload-trigger.md
│   ├── user-guide/
│   │   ├── index.md
│   │   ├── measurement-frequency.md
│   │   ├── manual-measurement.md
│   │   └── notifications-troubleshoot.md
│   ├── watch-widget/
│   │   ├── index.md
│   │   ├── watch-face-setup.md
│   │   ├── complications.md
│   │   └── widget-not-updating.md
│   ├── legal/
│   │   ├── privacy.md
│   │   └── terms.md
│   └── index.md
├── index.md              # Root redirect → /en/ (or auto-detect)
└── package.json
```

> Note: `en/` maps to `/` (root) via `link: '/'` in locales config. `vi/` maps to `/vi/`.

## i18n VitePress Config

```ts
import { defineConfig } from 'vitepress'

const enSidebar = {
  '/principle/': [{ text: 'Principle', items: [
    { text: 'Stress Levels', link: '/principle/stress-levels' },
    { text: 'What is HRV?', link: '/principle/what-is-hrv' },
    { text: 'Resting Heart Rate', link: '/principle/resting-heart-rate' },
    { text: 'Stress Overload Trigger', link: '/principle/stress-overload-trigger' },
  ]}],
  '/user-guide/': [{ text: 'User Guide', items: [
    { text: 'Measurement Frequency', link: '/user-guide/measurement-frequency' },
    { text: 'Manual Measurement', link: '/user-guide/manual-measurement' },
    { text: 'Notification Issues', link: '/user-guide/notifications-troubleshoot' },
  ]}],
  '/watch-widget/': [{ text: 'Watch & Widget', items: [
    { text: 'Watch Face Setup', link: '/watch-widget/watch-face-setup' },
    { text: 'Complications', link: '/watch-widget/complications' },
    { text: 'Widget Not Updating', link: '/watch-widget/widget-not-updating' },
  ]}],
}

const viSidebar = {
  '/vi/principle/': [{ text: 'Nguyên lý', items: [
    { text: 'Cấp độ căng thẳng', link: '/vi/principle/stress-levels' },
    { text: 'HRV là gì?', link: '/vi/principle/what-is-hrv' },
    { text: 'Nhịp tim lúc nghỉ', link: '/vi/principle/resting-heart-rate' },
    { text: 'Khi nào kích hoạt cảnh báo?', link: '/vi/principle/stress-overload-trigger' },
  ]}],
  '/vi/user-guide/': [{ text: 'Hướng dẫn sử dụng', items: [
    { text: 'Tần suất đo tự động', link: '/vi/user-guide/measurement-frequency' },
    { text: 'Đo thủ công', link: '/vi/user-guide/manual-measurement' },
    { text: 'Sự cố thông báo', link: '/vi/user-guide/notifications-troubleshoot' },
  ]}],
  '/vi/watch-widget/': [{ text: 'Watch & Widget', items: [
    { text: 'Cài mặt đồng hồ', link: '/vi/watch-widget/watch-face-setup' },
    { text: 'Complications', link: '/vi/watch-widget/complications' },
    { text: 'Widget không cập nhật', link: '/vi/watch-widget/widget-not-updating' },
  ]}],
}

export default defineConfig({
  title: 'StressMonitor Help',
  locales: {
    root: {
      label: 'English',
      lang: 'en',
      link: '/',
      themeConfig: {
        nav: [
          { text: 'Principle', link: '/principle/' },
          { text: 'User Guide', link: '/user-guide/' },
          { text: 'Watch & Widget', link: '/watch-widget/' },
        ],
        sidebar: enSidebar,
      },
    },
    vi: {
      label: 'Tiếng Việt',
      lang: 'vi',
      link: '/vi/',
      themeConfig: {
        nav: [
          { text: 'Nguyên lý', link: '/vi/principle/' },
          { text: 'Hướng dẫn', link: '/vi/user-guide/' },
          { text: 'Watch & Widget', link: '/vi/watch-widget/' },
        ],
        sidebar: viSidebar,
      },
    },
  },
  themeConfig: {
    footer: {
      copyright: 'Copyright © 2026 StressMonitor',
    },
  },
})
```

## iOS Deep Link URLs with i18n

`DocsURL.swift` should use locale-aware paths. Default to device locale:

```swift
enum DocsURL {
    static let base = URL(string: "https://stressmonitor-docs.vercel.app")!

    static var localePrefix: String {
        Locale.current.language.languageCode?.identifier == "vi" ? "/vi" : ""
    }

    static var help: URL       { base.appending(path: "\(localePrefix)/user-guide/") }
    static var stressLevels: URL { base.appending(path: "\(localePrefix)/principle/stress-levels") }
    static var privacy: URL    { base.appending(path: "\(localePrefix)/legal/privacy") }
    static var terms: URL      { base.appending(path: "\(localePrefix)/legal/terms") }
}
```

> Update Phase 3 plan accordingly — `DocsURL` becomes locale-aware.

## watch-widget/
│   ├── index.md
│   ├── watch-face-setup.md
│   ├── complications.md
│   └── widget-not-updating.md
├── legal/
│   ├── privacy.md
│   └── terms.md
├── index.md              # Home page
└── package.json
```

## Implementation Steps

### 1. Init VitePress

```bash
cd docs-site
npm init -y
npm install -D vitepress
npx vitepress init   # choose minimal template, docs root = .
```

### 2. `package.json` scripts

```json
{
  "scripts": {
    "dev": "vitepress dev",
    "build": "vitepress build",
    "preview": "vitepress preview"
  }
}
```

### 3. `.vitepress/config.ts`

```ts
import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'StressMonitor Help',
  description: 'User guide and documentation for StressMonitor',
  base: '/',
  themeConfig: {
    nav: [
      { text: 'Principle', link: '/principle/' },
      { text: 'User Guide', link: '/user-guide/' },
      { text: 'Watch & Widget', link: '/watch-widget/' },
    ],
    sidebar: {
      '/principle/': [
        {
          text: 'Principle',
          items: [
            { text: 'Stress Levels', link: '/principle/stress-levels' },
            { text: 'What is HRV?', link: '/principle/what-is-hrv' },
            { text: 'Resting Heart Rate', link: '/principle/resting-heart-rate' },
            { text: 'Stress Overload Trigger', link: '/principle/stress-overload-trigger' },
          ],
        },
      ],
      '/user-guide/': [
        {
          text: 'User Guide',
          items: [
            { text: 'Measurement Frequency', link: '/user-guide/measurement-frequency' },
            { text: 'Manual Measurement', link: '/user-guide/manual-measurement' },
            { text: 'Notification Issues', link: '/user-guide/notifications-troubleshoot' },
          ],
        },
      ],
      '/watch-widget/': [
        {
          text: 'Watch & Widget',
          items: [
            { text: 'Watch Face Setup', link: '/watch-widget/watch-face-setup' },
            { text: 'Complications', link: '/watch-widget/complications' },
            { text: 'Widget Not Updating', link: '/watch-widget/widget-not-updating' },
          ],
        },
      ],
    },
    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2026 StressMonitor',
    },
    socialLinks: [],
  },
})
```

### 4. Home page (`index.md`)

```md
---
layout: home
hero:
  name: "StressMonitor"
  text: "Help & Documentation"
  tagline: Understanding your physical stress through HRV and heart rate
  actions:
    - theme: brand
      text: User Guide
      link: /user-guide/
    - theme: alt
      text: How It Works
      link: /principle/
features:
  - icon: 🧠
    title: Principle
    details: How we measure physical stress using HRV and resting heart rate.
  - icon: 📱
    title: User Guide
    details: Measurement frequency, manual checks, and troubleshooting.
  - icon: ⌚
    title: Watch & Widget
    details: Set up watch faces, complications, and home screen widgets.
---
```

### 5. Key content page: `principle/stress-levels.md`

```md
# Stress Levels

StressMonitor categorizes physical stress into four levels based on your personal HRV baseline.

| Level | Indicator | Meaning |
|-------|-----------|---------|
| Excellent State | 🟢 Green | High HRV, low resting HR — very low body pressure |
| Normal State | 🔵 Blue | Normal HRV and HR — manageable pressure |
| Attention Needed | 🟡 Yellow | Low HRV or elevated HR — consider rest |
| Pressure Overload | 🔴 Red | Significant HRV drop and HR spike — elevated health risk |

All thresholds are personalized to your historical baseline, not fixed universal values.
```

### 6. Legal pages

`legal/privacy.md` and `legal/terms.md` — full Privacy Policy and Terms of Service text (to be provided by team).

## Todo

- [ ] Run `npm init` and `npm install vitepress` in `docs-site/`
- [ ] Create `.vitepress/config.ts` with nav + sidebar
- [ ] Write `index.md` home page
- [ ] Write all Principle pages (4)
- [ ] Write all User Guide pages (3)
- [ ] Write all Watch & Widget pages (3)
- [ ] Write `legal/privacy.md` and `legal/terms.md`
- [ ] Run `npm run dev` to verify site renders correctly
- [ ] Run `npm run build` to verify no build errors

## Success Criteria

- `npm run build` exits 0
- All sidebar links resolve (no 404)
- `legal/privacy` and `legal/terms` pages exist with placeholder content at minimum

## Risks

- Legal page content may not be ready — use placeholder text, update before deploy
