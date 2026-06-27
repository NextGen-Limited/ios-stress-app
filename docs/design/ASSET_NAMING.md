# Character Asset Naming Convention

## Current Structure (Post-Commit #45)

### Character SVGs
6 exported SVGs in `Assets.xcassets/Characters/`:
- `ripple` (100×100 viewBox) - Water element
- `blossom` (100×100 viewBox) - Earth element
- `ember` (100×100 viewBox) - Fire element
- `zephyr` (100×100 viewBox) - Air element
- `lumi` (100×100 viewBox) - Moon element
- `ripple-hero` (220×220 viewBox) - Larger detail view

All have `preserves-vector-representation: true`.

### Mood-Face SVGs
5 exported SVGs in `Assets.xcassets/MoodFaces/`:
- `mood-relaxed` (24×24 viewBox) - Relaxed (0-25)
- `mild` (24×24 viewBox) - Mild (25-50)
- `moderate` (24×24 viewBox) - Moderate (50-75)
- `high` (24×24 viewBox) - High (75-100)
- `severe` (24×24 viewBox) - Severe (90+)

These support WCAG dual-coding with colors: relaxed #34C759, mild #007AFF, moderate #FFD60A, high #FF9500, severe #FF3B30.

### Design Source
- `design/characters-export.html` - Character SVG export sheet
- `design/icon-system.html` - Icon system spec (including `MoodFaceIcon` enum mapping)
- `design/exports/characters/` - Generated character SVGs
- `design/exports/mood-faces/` - Generated mood-face SVGs

---

## Legacy Naming (Deprecated - Export Pipeline Only)

### Pattern
`{characterId}_{evolution}_{mood}`

### Examples
- `ripple_droplet_sleeping` — Baby Ripple sleeping
- `ripple_ripple_calm` — Teen Ripple calm
- `ripple_tidal_overwhelmed` — Adult Ripple overwhelmed

### Purpose
This naming convention is **deprecated for runtime use** but retained in `CharacterAssetResolver` methods marked `@available(*, deprecated)` solely for the illustration export pipeline (`CharacterIllustrationExporter`).

### Original Design
75 production assets: 5 characters × 3 evolutions × 5 moods.

### Asset Catalog Groups (Legacy Reference)
- `Characters/Ripple/` — 15 images
- `Characters/Blossom/` — 15 images
- `Characters/Ember/` — 15 images
- `Characters/Zephyr/` — 15 images
- `Characters/Lumi/` — 15 images

---

## Centralized Icon System (Commit #44)

### AppIconSystem Enum
Single source of truth mapping design spec to SF Symbols. Usage: `AppIconSystem.<Category>.<case>.sfSymbol`.

**Categories:**
- `Tab` (4 tabs: home/action/trends/settings; each has `sfSymbol` + `sfSymbolActive` `.fill` variant)
- `Nav` (back/forward/close)
- `Action` (6 quick-start exercises: breathing/bodyScan/miniWalk/coldSplash/gratitude/chat)
- `Metric` (8 health factor icons: heartRate/hrv/sleep/activity/streak/time/date/achievement)
- `Setting` (17 settings rows)
- `System` (11 semantic icons: success/warning/info/locked/privacy/delete/export/download/send/voiceInput/premium)

### MoodFaceIcon Enum
5-level stress scale with SF Symbols and WCAG colors:
- `relaxed` (0-25) - #34C759 green
- `mild` (25-50) - #007AFF blue
- `moderate` (50-75) - #FFD60A yellow
- `high` (75-100) - #FF9500 orange
- `severe` (90+) - #FF3B30 red

Provides `sfSymbol`, `color`, `rangeText`, `label`, `from(stressLevel:)`, `from(mood: RippleMood)`.

### Adoption
36 Swift files reference `AppIconSystem.` replacing scattered raw `systemName:` string literals.

### Companion Views
- `SettingsIconView` - SF Symbol inside 28×28 accent-tinted rounded square
- `MoodFaceView` - Self-contained mood face: colored circle + white SF Symbol face
