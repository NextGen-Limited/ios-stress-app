# Design system

The visual language: colors, typography, icon system, character assets, spacing, and accessibility helpers. Lives under `StressMonitor/StressMonitor/Theme/` with supporting components in `StressMonitor/StressMonitor/Views/DesignSystem/` and accessibility utilities in `StressMonitor/StressMonitor/Utilities/`.

## Theme tokens

| File | Purpose |
| --- | --- |
| `StressMonitor/StressMonitor/Theme/DesignTokens.swift` | Core spacing, radius, and sizing constants |
| `StressMonitor/StressMonitor/Theme/Color+Extensions.swift` | `Color(hex:)`, light/dark variants, stress color helpers |
| `StressMonitor/StressMonitor/Theme/Color+Wellness.swift` | Wellness-specific palette |
| `StressMonitor/StressMonitor/Theme/Font+WellnessType.swift` | Wellness typography scale |
| `StressMonitor/StressMonitor/Theme/Gradients.swift` | Reusable gradients |
| `StressMonitor/StressMonitor/Theme/HomeCharacterDesignTokens.swift` | Home-tab background and character placement tokens |
| `StressMonitor/StressMonitor/Theme/AppIconSystem.swift` | Centralized SF Symbol mapping |
| `StressMonitor/StressMonitor/Theme/CharacterAssetCatalog.swift` | Character SVG asset names |

## Icon system

`AppIconSystem` (at `StressMonitor/StressMonitor/Theme/AppIconSystem.swift`) is the single source of truth for every SF Symbol in the app. It groups icons by category: Tab bar (4 tabs with active/inactive variants), Navigation, Action quick-start, Health metrics, Mood faces, Settings rows, and System/semantic. Use `AppIconSystem.Tab.home.sfSymbol` instead of hardcoding strings.

The icon system was introduced in commit `c45b74d` and rolled out across 37 files in commit `03563bb`. Source of truth is `design/icon-system.html` and `design/icon-asset-mapping.md`.

## Stress colors (dual coding)

`StressCategory.color` returns a different hex for light and dark mode. Colors must always be paired with the corresponding `icon` and `pattern` to satisfy WCAG dual-coding requirements. The canonical mapping lives in `StressMonitor/StressMonitor/Models/StressCategory.swift`.

| Category | Light | Dark | Icon |
| --- | --- | --- | --- |
| relaxed | #34C759 | #30D158 | leaf.fill |
| mild | #007AFF | #0A84FF | circle.fill |
| moderate | #FFD60A | #FFD60A | triangle.fill |
| high | #FF9500 | #FF9F0A | square.fill |
| severe | #FF3B30 | #FF453A | exclamationmark.octagon.fill |

## Typography

StressMonitor loads custom fonts (SF Pro variants and Roboto in the Ripple UI era) through `FontBlaster` at `StressMonitor/StressMonitor/Utilities/FontBlaster.swift`. The dashboard kicks off `FontBlaster.blast()` in a background `Task` on first appear to avoid blocking the launch sequence. `Font+WellnessType.swift` defines the semantic type scale (heroTitle, sectionTitle, body, caption, etc.).

## Spacing and layout

`StressMonitor/StressMonitor/Views/DesignSystem/Spacing.swift` and `Shadows.swift` provide reusable spacing and shadow modifiers. `Typography.swift` in the same directory holds type-style modifiers.

## Accessibility utilities

| File | Purpose |
| --- | --- |
| `StressMonitor/StressMonitor/Utilities/AccessibilityModifiers.swift` | `.accessibleDynamicType()` and common a11y modifiers |
| `StressMonitor/StressMonitor/Utilities/DynamicTypeScaling.swift` | Dynamic Type size adjustments |
| `StressMonitor/StressMonitor/Utilities/HighContrastModifier.swift` | High-contrast mode support |
| `StressMonitor/StressMonitor/Utilities/ColorBlindnessSimulator.swift` | Design-QA color-blind simulation |
| `StressMonitor/StressMonitor/Utilities/PatternOverlay.swift` | Pattern overlays for dual coding |
| `StressMonitor/StressMonitor/Utilities/Animation+Wellness.swift` | Animation presets |
| `StressMonitor/StressMonitor/Utilities/AnimationPresets.swift` | Spring and transition presets |

## Design source files

The `design/` directory at the repo root holds the HTML mockups that drove the June 2026 redesign: `index.html`, `design-system.html`, `icon-system.html`, `characters-export.html`, and per-screen HTML files under `design/screens/`. These are reference artifacts, not part of the build.

## Entry points for modification

- **Add a new icon**: add a case to the relevant `AppIconSystem` enum with its SF Symbol and update `design/icon-asset-mapping.md`.
- **Change the color palette**: edit `Color+Wellness.swift` and `Color+Extensions.swift`. Keep `StressCategory.color` in sync.
- **Add a new type style**: add a static font in `Font+WellnessType.swift` and apply via modifier.
