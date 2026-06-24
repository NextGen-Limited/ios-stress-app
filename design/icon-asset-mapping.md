# StressMonitor — Icon & Character Asset Mapping

> Complete reference for SwiftUI implementation. Maps every design-system icon to its SF Symbol equivalent and character SVGs to Asset Catalog names.

---

## Icon System Summary

| Metric | Count |
|--------|-------|
| Total UI icons | 58 |
| Character assets | 5 (+3 evolution stages each) |
| Mood face variants | 5 |
| Icon categories | 7 |

**Specs:** All icons are 24×24 viewBox (except nav-back 14×20, chevron 9×14). Stroke-based at 1.7-2.4pt. Settings icons render inside 28×28 / 7px-radius accent-tinted squares.

---

## 1. Tab Bar Icons

| Asset Name | SF Symbol | Active Variant |
|------------|-----------|----------------|
| `tab-home` | `house` | `house.fill` |
| `tab-action` | `plus.circle` | `plus.circle.fill` |
| `tab-trends` | `chart.bar` | `chart.bar.fill` |
| `tab-settings` | `gearshape` | `gearshape.fill` |

**SwiftUI:**
```swift
Image(systemName: "house")
    .symbolVariant(tab == .home ? .fill : .none)
```

---

## 2. Navigation Icons

| Asset Name | SF Symbol | Notes |
|------------|-----------|-------|
| `nav-back` | `chevron.left` | 14×20 viewBox, 2.4pt stroke |
| `chevron-right` | `chevron.right` | 9×14 viewBox, list rows |
| `close` | `xmark` | 2.4pt stroke |

---

## 3. Action Quick-Start Icons

| Asset Name | SF Symbol | Screen |
|------------|-----------|--------|
| `action-breathing` | `wind` | Box Breathing |
| `action-body-scan` | `figure.mind.and.body` | Body Scan |
| `action-walk` | `figure.walk` | Mini Walk |
| `action-cold-splash` | `snowflake` | Cold Splash |
| `action-gratitude` | `face.smiling` | Gratitude |
| `action-chat` | `bubble.left` | Talk to Companion |

---

## 4. Health Metric Icons

| Asset Name | SF Symbol | Stress Factor |
|------------|-----------|---------------|
| `heart` | `heart.fill` | Heart Rate |
| `activity-pulse` | `waveform.path.ecg` | HRV |
| `moon` | `moon` | Sleep |
| `sun` | `sun.max` | Activity / Light |
| `flame` | `flame.fill` | Recovery / Streak |
| `clock` | `clock` | Time |
| `calendar` | `calendar` | Date / History |
| `star` | `star.fill` | Achievement |

---

## 5. Mood Faces (5-Level Stress Scale)

**CRITICAL:** Always pair face icon with color label for WCAG dual-coding compliance.

| Asset Name | SF Symbol | Stress Range | Color Token |
|------------|-----------|--------------|-------------|
| `mood-relaxed` | `face.smiling` | 0–25 | `--stress-relaxed` #34C759 |
| `mood-mild` | `face.smiling` | 26–50 | `--stress-mild` #007AFF |
| `mood-moderate` | `face.neutral` | 51–75 | `--stress-moderate` #FFD60A |
| `mood-high` | `face.dashed` | 76–90 | `--stress-high` #FF9500 |
| `mood-severe` | `face.frowning` | 91+ | `--stress-severe` #FF3B30 |

**SwiftUI:**
```swift
func moodSymbol(for category: StressCategory) -> String {
    switch category {
    case .relaxed:  return "face.smiling"
    case .mild:     return "face.smiling"
    case .moderate: return "face.neutral"
    case .high:     return "face.dashed"
    case .severe:   return "face.frowning"
    }
}
```

---

## 6. Settings List Icons

All settings icons use the SF Symbol as the base; the colored rounded-square background is applied via a SwiftUI modifier.

| Asset Name | SF Symbol | Settings Row |
|------------|-----------|--------------|
| `setting-characters` | `person.2.crop.square.stack` | Characters |
| `setting-ripple-coach` | `bubble.left.fill` | Ripple Coach |
| `setting-apple-health` | `heart.fill` | Apple Health |
| `setting-apple-watch` | `applewatch` | Apple Watch |
| `setting-biological-age` | `circle.dashed` | Biological Age |
| `setting-hydration` | `drop.fill` | Hydration |
| `setting-caffeine` | `cup.and.saucer.fill` | Caffeine |
| `setting-light-exposure` | `sun.max.fill` | Light Exposure |
| `setting-stress-alerts` | `bell.badge.fill` | Stress Alerts |
| `setting-water-reminder` | `drop.fill` | Water Reminder |
| `setting-daily-summary` | `clock.badge.checkmark` | Daily Summary |
| `setting-stressmonitor-plus` | `star.fill` | StressMonitor Plus |
| `setting-appearance` | `circle.lefthalf.filled` | Appearance |
| `setting-haptics` | `speaker.wave.2.fill` | Haptics |
| `setting-export-data` | `square.and.arrow.up` | Export Data |
| `setting-manage-data` | `trash` | Manage Data |
| `setting-help-privacy` | `questionmark.circle` | Help & Privacy |

**SwiftUI pattern:**
```swift
struct SettingsIcon: View {
    let symbolName: String
    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}
```

---

## 7. System / Semantic Icons

| Asset Name | SF Symbol | Usage |
|------------|-----------|-------|
| `success-check` | `checkmark.circle.fill` | Success states |
| `warning` | `exclamationmark.triangle` | Warning banners |
| `info` | `info.circle` | Info tooltips |
| `lock` | `lock.fill` | Locked characters |
| `shield` | `shield.lefthalf.filled` | Privacy |
| `trash` | `trash` | Delete |
| `export` | `square.and.arrow.up` | Share / Export |
| `download` | `arrow.down.square` | Download |
| `send` | `arrow.up` | Chat send |
| `mic` | `mic.fill` | Voice input |
| `crown` | `crown.fill` | Premium badge |

---

## Character Assets

### Asset Catalog Structure

```
Assets.xcassets/
├── Characters/
│   ├── ripple.imageset        (ripple.svg, 100×100)
│   ├── ripple-hero.imageset   (ripple-hero.svg, 220×220)
│   ├── blossom.imageset       (blossom.svg, 100×100)
│   ├── ember.imageset         (ember.svg, 100×100)
│   ├── zephyr.imageset        (zephyr.svg, 100×100)
│   └── lumi.imageset          (lumi.svg, 100×100)
└── Icons/
    └── (use SF Symbols instead — no raster assets needed)
```

### Character Metadata

| Character | Element | Asset Name | Primary Color | Unlock | Archetype |
|-----------|---------|------------|---------------|--------|-----------|
| Ripple | Water Otter | `ripple` | #4FC3F7 | Free (default) | Calm |
| Blossom | Forest Sprite | `blossom` | #A5D6A7 | Free | Grounding |
| Ember | Flame Fox | `ember` | #FFAB91 | StressMonitor Plus | Energy |
| Zephyr | Wind Wisp | `zephyr` | #D1C4E9 | StressMonitor Plus | Lightness |
| Lumi | Star Pup / Owl | `lumi` | #7986CB | 30-Day Streak | Rest |

### Evolution Stages (per character)

| Character | Stage 1 (Day 1) | Stage 2 (30d) | Stage 3 (90d) |
|-----------|-----------------|---------------|---------------|
| Ripple | Tadpole | River | Ocean |
| Blossom | Seed | Sapling | Canopy |
| Ember | Spark | Flame | Blaze |
| Zephyr | Breeze | Gust | Tempest |
| Lumi | Glimmer | Twinkle | Supernova |

### Display Size Reference

| Size | Use Case | Source SVG |
|------|----------|------------|
| 24pt | Tab icon / Favicon | mini (100×100) |
| 48pt | List row avatar | mini (100×100) |
| 92pt | Character grid tile | mini (100×100) |
| 120pt | Card hero | mini (100×100) |
| 160pt | Detail screen hero | hero (220×220) |

---

## Color Tokens

### Character Palette (CSS variables → Swift Color)

| Token | Hex | Swift |
|-------|-----|-------|
| `--ripple` | #4FC3F7 | `Color(red: 0.31, green: 0.76, blue: 0.97)` |
| `--blossom` | #A5D6A7 | `Color(red: 0.65, green: 0.84, blue: 0.65)` |
| `--ember` | #FFAB91 | `Color(red: 1.0, green: 0.67, blue: 0.57)` |
| `--zephyr` | #D1C4E9 | `Color(red: 0.82, green: 0.77, blue: 0.91)` |
| `--lumi` | #7986CB | `Color(red: 0.47, green: 0.53, blue: 0.80)` |

### Stress Scale Colors

| Token | Hex | Stress Level |
|-------|-----|--------------|
| `--stress-relaxed` | #34C759 | Relaxed (0-25) |
| `--stress-mild` | #007AFF | Mild (26-50) |
| `--stress-moderate` | #FFD60A | Moderate (51-75) |
| `--stress-high` | #FF9500 | High (76-90) |
| `--stress-severe` | #FF3B30 | Severe (91+) |

---

## Implementation Notes

1. **Icons:** Use SF Symbols exclusively — no custom icon assets needed. All 58 UI icons map directly to available SF Symbols in iOS 17+.
2. **Characters:** Store as SVG in Asset Catalog with Preserve Vector Data enabled. The 100×100 viewBox scales cleanly to all display sizes.
3. **Mood faces:** Reuse the same SF Symbol across all stress levels — the color differentiation is the primary signal (face shape is secondary reinforcement).
4. **Dual coding:** NEVER show stress color without an accompanying icon or text label. This is a WCAG accessibility requirement baked into the design system.
5. **Tab bar:** Use `.symbolVariant(.fill)` for active state — matches the existing `.fill-active` CSS convention.
6. **Settings icons:** The 28×28 accent-tinted background is a SwiftUI modifier, not part of the SVG. Apply uniformly with `Color.accentColor` background.

---

## Migration Guide: Using Export Assets Across Screens

The design exports (SVG) are now bundled in the Asset Catalog and accessible through two Swift modules. Use these to ensure every screen references the **same canonical icon/character** — no duplication, no drift.

### Swift Modules

| File | Purpose |
|------|---------|
| `Theme/AppIconSystem.swift` | SF Symbol mappings (`AppIconSystem.Tab`, `.Action`, `.Metric`, `.Setting`, `.System`), `MoodFaceIcon` enum, `SettingsIconView`, `MoodFaceView` |
| `Theme/CharacterAssetCatalog.swift` | Static SVG-backed character images (`CharacterAssetCatalog.image(for:)`), mood-face SVG images (`MoodFaceAssetCatalog.image(for:)`) |

### Asset Catalog Layout

```
Assets.xcassets/
├── Characters/
│   ├── ripple.imageset         (ripple.svg, 100×100, SVG)
│   ├── ripple-hero.imageset    (ripple-hero.svg, 220×220, SVG)
│   ├── blossom.imageset        (blossom.svg, 100×100, SVG)
│   ├── ember.imageset          (ember.svg, 100×100, SVG)
│   ├── zephyr.imageset         (zephyr.svg, 100×100, SVG)
│   └── lumi.imageset           (lumi.svg, 100×100, SVG)
├── MoodFaces/
│   ├── mood-relaxed.imageset   (mood-relaxed.svg, 24×24, SVG)
│   ├── mood-mild.imageset      (mood-mild.svg, 24×24, SVG)
│   ├── mood-moderate.imageset  (mood-moderate.svg, 24×24, SVG)
│   ├── mood-high.imageset      (mood-high.svg, 24×24, SVG)
│   └── mood-severe.imageset    (mood-severe.svg, 24×24, SVG)
└── TabBar/ (existing custom tab icons)
```

All SVG imagesets use `preserves-vector-representation: true` for crisp scaling at any resolution.

### Screen-by-Screen Migration Reference

#### 1. Home / Dashboard
- **Character hero**: `CharacterAssetResolver.characterView(for:mood:size:)` (procedural, mood-reactive) — **or** `CharacterAssetCatalog.image(for:)` for static contexts
- **Stress mood face**: `MoodFaceView(mood: .from(stressLevel: result.level))`
- **Vitals row icons**: `Image(systemName: AppIconSystem.Metric.heartRate.sfSymbol)`
- **Streak badge**: `Image(systemName: AppIconSystem.Metric.streak.sfSymbol)` (flame.fill)

#### 2. Action Tab
- **Quick-start icons**: `Image(systemName: AppIconSystem.Action.breathing.sfSymbol)` etc.
- **Breathing session**: Wind icon throughout (consistent with tab)
- **Mini Walk**: `figure.walk` for the timer and card
- **Talk to Companion**: `bubble.left` — matches chat bottom sheet

#### 3. Trends / History
- **Trend chart axes**: `waveform.path.ecg` (HRV), `heart.fill` (heart rate)
- **Calendar heatmap**: `calendar` for date navigation
- **Achievement stars**: `star.fill`
- **Distribution bars**: Mood color from `MoodFaceIcon.from(stressLevel:)`

#### 4. Settings
- **Row icons**: `SettingsIconView(AppIconSystem.Setting.appleHealth)` — renders 28×28 accent square
- **Companion collection row**: `Image(systemName: "person.2.crop.square.stack")`
- **Export data**: `square.and.arrow.up` icon throughout
- **Premium badge**: `crown.fill`

#### 5. Characters Collection
- **Grid tile avatar**: `CharacterAssetCatalog.image(for: creature.id).resizable().frame(width: 92, height: 92)` — uses the SVG export directly
- **Detail hero**: `CharacterAssetCatalog.heroImage(for: "ripple").resizable().frame(width: 160, height: 160)`
- **Evolution stages**: procedural view via `CharacterAssetResolver.characterView(for:evolution:mood:size:)` with `.scaleFactor`
- **Locked placeholder**: `Image(systemName: AppIconSystem.System.locked.sfSymbol)`

#### 6. Onboarding
- **Success checkmark**: `Image(systemName: AppIconSystem.System.success.sfSymbol)`
- **Health sync**: `Image(systemName: AppIconSystem.Setting.appleHealth.sfSymbol)`

#### 7. Widget
- **Stress gauge**: `MoodFaceView(mood: .from(stressLevel: level), size: 24)`
- **Character avatar**: `CharacterAssetCatalog.image(for: characterId).resizable()`

#### 8. Watch App
- **Complications**: `Image(systemName: AppIconSystem.Metric.heartRate.sfSymbol)`
- **Circular stress view**: Use `MoodFaceIcon.color` for the arc fill

### Quick Migration Pattern

**Before** (ad-hoc SF Symbol strings):
```swift
Image(systemName: "heart.fill")
    .foregroundStyle(.red)
Image(systemName: "flame.fill")
Image(systemName: "square.and.arrow.up")
```

**After** (centralized, type-safe):
```swift
Image(systemName: AppIconSystem.Metric.heartRate.sfSymbol)
Image(systemName: AppIconSystem.Metric.streak.sfSymbol)
SettingsIconView(AppIconSystem.Setting.exportData)
MoodFaceView(mood: .from(stressLevel: stressLevel))
```

### WCAG Dual-Coding Checklist

- [ ] Every stress color shown with a mood face icon or text label
- [ ] `MoodFaceView` always used (never bare `MoodFaceIcon.color` without a symbol)
- [ ] Mood face + color pairing consistent across Home, Trends, History, Widget
- [ ] Settings icons always rendered via `SettingsIconView` (never raw `Image(systemName:)` without the 28×28 square)
