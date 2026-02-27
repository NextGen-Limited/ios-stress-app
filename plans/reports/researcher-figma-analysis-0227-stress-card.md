# Figma Stress Character Card Analysis

**Date:** 2026-02-27
**Researcher:** researcher-figma
**Status:** Complete

---

## Executive Summary

Current `StressCharacterCard` implementation uses SF Symbols for character representation. Figma design requires custom character illustration with specific layout, typography (Lato font), and styling. Significant refactoring needed to match Figma design exactly.

**Key Gap:** No custom character illustrations exist - only SF Symbols.

---

## Current Implementation Analysis

### File Locations

| File | Path | Purpose |
|------|------|---------|
| StressCharacterCard.swift | `/StressMonitor/StressMonitor/Components/Character/` | Main card component |
| CharacterAnimationModifier.swift | `/StressMonitor/StressMonitor/Components/Character/` | Animation logic |
| StressBuddyMood.swift | `/StressMonitor/StressMonitor/Models/` | Mood enum + symbols |
| DateHeaderView.swift | `/StressMonitor/StressMonitor/Views/Dashboard/Components/` | Date header |
| Typography.swift | `/StressMonitor/StressMonitor/Views/DesignSystem/` | Font definitions |
| Color+Wellness.swift | `/StressMonitor/StressMonitor/Theme/` | Color palette |
| Shadows.swift | `/StressMonitor/StressMonitor/Views/DesignSystem/` | Shadow presets |

### Current Structure

```
StressCharacterCard
├── characterView (SF Symbol + accessories)
├── stressLevel number (monospaced)
├── mood label (displayName)
└── optional HRV value
```

### Current Design Tokens

**Typography:**
- `Typography.dataLarge` = 48pt bold rounded
- `Typography.headline` = 17pt semibold
- `Typography.footnote` = 13pt regular

**Colors:**
- `Color.Wellness.exerciseCyan` = #86CECD (matches Figma teal)
- `Color.Wellness.adaptivePrimaryText` = #101223 (matches Figma)
- `Color.Wellness.adaptiveSecondaryText` = #777986 (matches Figma)

**Shadows:**
- `AppShadow.card` = black 5% opacity, radius 8, y-offset 2
- `AppShadow.elevated` = black 10% opacity, radius 16, y-offset 4

### Current Character Representation

Uses SF Symbols via `StressBuddyMood` enum:
- `.sleeping` → `moon.zzz.fill`
- `.calm` → `figure.mind.and.body`
- `.concerned` → `figure.walk.circle`
- `.worried` → `exclamationmark.triangle.fill`
- `.overwhelmed` → `flame.fill`

---

## Figma Design Requirements

### Container Specs

| Property | Figma Value | Notes |
|----------|-------------|-------|
| Width | 390px | Fixed width for dashboard |
| Height | 408px | Fixed height |
| Background | #FFFFFF | White card |
| Border Radius | ~12-16px | Soft corners |
| Shadow | Multiple layers | Complex box-shadow stack |

### Shadow Layers (Figma)

```css
box-shadow:
  0px 4px 6px rgba(0, 0, 0, 0.05),
  0px 10px 20px rgba(0, 0, 0, 0.1),
  0px 20px 40px rgba(0, 0, 0, 0.15);
```

SwiftUI equivalent:
```swift
.shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 4)
.shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
.shadow(color: .black.opacity(0.15), radius: 40, x: 0, y: 20)
```

### Typography (Lato Font)

**Date Header:**
- Day: "Sunday" → Lato Bold 700, 28px
- Date: "September 14, 2025" → Lato Bold 700, 14px

**Status:**
- "Relaxed" → 26px, color #86CECD (teal)

**Footer:**
- "Last Updated: 8h 20m" → 13px, color #777986

**Note:** iOS uses SF Pro by default. Lato font requires:
1. Font file import to Assets
2. Info.plist font registration
3. Custom Font extension

### Color Mapping

| Element | Figma | Existing Token | Match? |
|---------|-------|----------------|--------|
| Background | #FFFFFF | Color.Wellness.surfaceLight | YES |
| Primary Text | #101223 | Color.Wellness.adaptivePrimaryText | YES |
| Secondary Text | #777986 | Color.Wellness.adaptiveSecondaryText | YES |
| Accent/Relaxed | #86CECD | Color.Wellness.exerciseCyan | YES |

### Character Illustration

Figma shows custom SVG character with:
- Cute rounded body shape
- Facial features (eyes, mouth)
- Relaxed pose
- Multiple SVG paths/layers

**No equivalent exists in current codebase.**

---

## Gap Analysis

### Missing Components

1. **Character Illustration Assets**
   - No SVG/PNG character files
   - Only SF Symbols available
   - Need 5 mood variants (sleeping, calm, concerned, worried, overwhelmed)

2. **Lato Font**
   - Not included in project
   - iOS default is SF Pro
   - Must add Lato-Bold.ttf

3. **Card Layout**
   - Current: VStack centered
   - Figma: Specific spacing hierarchy

4. **Multi-layer Shadow**
   - Current: Single shadow
   - Figma: 3-layer soft shadow

5. **Date Header Style**
   - Current DateHeaderView: SF Pro 34pt/17pt
   - Figma: Lato 28pt/14pt

### Existing - Can Reuse

- Color palette (matches Figma)
- Animation system (CharacterAnimationModifier)
- Accessibility support (VoiceOver labels)
- StressBuddyMood enum (logic only)

---

## File Changes Required

### Must Modify

| File | Changes |
|------|---------|
| `StressCharacterCard.swift` | Restructure layout, add shadow layers, integrate character assets |
| `DateHeaderView.swift` | Update typography to match Figma (or create variant) |
| `Typography.swift` | Add Lato font definitions |
| `Shadows.swift` | Add multi-layer shadow preset |

### Must Create

| File | Purpose |
|------|---------|
| `Assets.xcassets/Characters/` | Character illustration asset catalog |
| `CharacterIllustration.swift` | SwiftUI view for character SVG rendering |
| `Lato-Bold.ttf` | Font file in Assets |

### Optional Create

| File | Purpose |
|------|---------|
| `FigmaCardStyle.swift` | Reusable card style with Figma shadows |

---

## Implementation Recommendations

### Option A: Custom SVG Characters (Recommended)

**Pros:**
- Exact Figma match
- Scalable vector
- Full customization

**Cons:**
- Requires SVG assets from design team
- More implementation work

**Steps:**
1. Export SVG characters from Figma (5 moods)
2. Add to Asset Catalog as Symbol Assets or Image assets
3. Create `CharacterIllustration` view
4. Update `StressCharacterCard` to use new illustration

### Option B: SwiftUI Shape Characters

**Pros:**
- No external assets needed
- Animatable paths

**Cons:**
- Complex path definitions
- May not match Figma exactly

**Steps:**
1. Define character shapes as SwiftUI Path
2. Create `CharacterShape` view
3. Apply mood-based coloring

### Option C: Hybrid (SF Symbols + Customization)

**Pros:**
- Fastest implementation
- Uses existing infrastructure

**Cons:**
- Won't match Figma exactly
- Less distinctive

**Steps:**
1. Keep SF Symbol base
2. Add custom overlay/decoration
3. Update layout to match Figma structure

---

## Technical Implementation Notes

### Multi-Layer Shadow Modifier

```swift
extension View {
    func figmaCardShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 4)
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            .shadow(color: .black.opacity(0.15), radius: 40, x: 0, y: 20)
    }
}
```

### Lato Font Integration

```swift
extension Font {
    static func latoBold(size: CGFloat) -> Font {
        .custom("Lato-Bold", size: size)
    }
}
```

### Card Layout Structure

```swift
VStack(spacing: 16) {
    // Date header
    DateHeaderView(date: date)
        .font(.latoBold(size: 28)) // Day
        // ...

    Spacer()

    // Character
    CharacterIllustration(mood: mood)
        .frame(height: 180)

    // Status
    Text(mood.displayName)
        .font(.system(size: 26, weight: .medium))
        .foregroundColor(Color.Wellness.exerciseCyan)

    // Last updated
    Text("Last Updated: \(formattedElapsed)")
        .font(.system(size: 13))
        .foregroundColor(Color.Wellness.adaptiveSecondaryText)
}
.padding(24)
.background(Color.Wellness.surfaceLight)
.clipShape(RoundedRectangle(cornerRadius: 16))
.figmacardShadow()
```

---

## Unresolved Questions

1. **Character Assets:** Who provides SVG files? Designer or generate from Figma?
2. **Font Licensing:** Is Lato font acceptable or should use system font for iOS consistency?
3. **Dark Mode:** Figma shows light design - dark mode colors TBD?
4. **Card Sizing:** Fixed 390x408px or responsive to container?
5. **Animation:** Should character illustration animate like current SF Symbol version?
6. **Accessibility:** How to describe character illustration for VoiceOver?

---

## Files Summary

**Analyzed:**
- `/StressMonitor/StressMonitor/Components/Character/StressCharacterCard.swift`
- `/StressMonitor/StressMonitor/Components/Character/CharacterAnimationModifier.swift`
- `/StressMonitor/StressMonitor/Models/StressBuddyMood.swift`
- `/StressMonitor/StressMonitor/Models/StressCategory.swift`
- `/StressMonitor/StressMonitor/Views/Dashboard/Components/DateHeaderView.swift`
- `/StressMonitor/StressMonitor/Views/Dashboard/StressDashboardView.swift`
- `/StressMonitor/StressMonitor/Views/DesignSystem/Typography.swift`
- `/StressMonitor/StressMonitor/Views/DesignSystem/Shadows.swift`
- `/StressMonitor/StressMonitor/Theme/Color+Wellness.swift`
- `/StressMonitor/StressMonitor/Theme/DesignTokens.swift`
- `/StressMonitor/StressMonitorTests/Components/StressCharacterCardTests.swift`
