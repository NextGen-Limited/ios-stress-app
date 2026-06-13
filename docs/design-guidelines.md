# Design Guidelines: Overview

**System:** iOS Human Interface Guidelines compliant
**Accessibility:** WCAG AA
**Version:** 1.1
**Last Updated:** June 7, 2026

---

## Overview

StressMonitor's design emphasizes clarity, accessibility, and user control. All UI work must follow these guidelines to ensure consistency, usability, and WCAG AA compliance.

**Core Principles:**
1. **Dual Coding** - Color + icon + text (WCAG AA)
2. **Simplicity** - One action per screen
3. **Transparency** - Show data sources and computation
4. **Control** - Users own their data
5. **Wellness** - Calming, approachable aesthetic

## Quick Links

### Visual System
Design tokens and components:
- **[Design Guidelines: Visual](./design-guidelines-visual.md)** - Color system, typography, spacing, layout, corner radius, shadows, Stress Ring component, Category Badge, Measurement Card, iconography, dark mode, animations

### User Experience & Accessibility
Interaction design and accessibility standards:
- **[Design Guidelines: UX](./design-guidelines-ux.md)** - WCAG AA compliance, dual coding, VoiceOver, Dynamic Type, touch targets, color contrast, haptic feedback, StressBuddy character, onboarding flow, data visualization, breathing exercises, trends view, error handling, notification strategy, accessibility testing

---

## Design System Quick Reference

### Stress Level Colors

| Level | Hex | Usage |
|-------|-----|-------|
| **Relaxed** | #34C759 | 0-25 stress |
| **Mild** | #007AFF | 25-50 stress |
| **Moderate** | #FFD60A | 50-75 stress |
| **High** | #FF9500 | 75-100 stress |

**Rule:** Always use color + icon + text for dual coding (WCAG AA)

### Typography Scale

| Style | Size | Weight |
|-------|------|--------|
| Display | 32pt | Bold |
| Headline | 24pt | Semibold |
| Body | 16pt | Regular |
| Footnote | 12pt | Regular |

**Rule:** Support Dynamic Type scaling (user's accessibility settings)

### Spacing Scale

| Level | Size | Usage |
|-------|------|-------|
| XS | 4pt | Icon spacing |
| S | 8pt | Adjacent elements |
| M | 16pt | Section spacing |
| L | 24pt | Major sections |
| XL | 32pt | Screen padding |

### Touch Targets
- **Minimum:** 44x44 points
- **Recommended:** 50x50 points
- **Large buttons:** 60x60 points

### Animation Timing

| Type | Duration | Easing |
|------|----------|--------|
| Micro | 200ms | easeOut |
| Standard | 400ms | easeInOut |
| Entrance | 600ms | easeOut |

---

## Component Library

### Settings Components (NEW - Jun 2026)

**ProfileCard** (full width card)
- Appearance picker (Light/Dark/System segmented control)
- Integration with AppearanceManager singleton
- Delete All Data button
- User profile information display
- Located at top of Settings screen in Ripple UI card-based architecture

**SettingsCard Variants** (13 card components)
- HealthDataCard - HealthKit permission status
- NotificationsCard - Notification preferences
- PrivacyCard - Privacy & data handling
- WatchFaceCard - Watch complication info
- WidgetCard - Widget configuration
- AboutCard - App info
- AppearanceCard - Dark mode toggle (integrated with ProfileCard)
- And 5+ additional service cards

### Primary Components

**Stress Ring** (120-200pt diameter)
- Main measurement display
- Animated progress ring
- Category label + number
- Tap to see details

**Category Badge** (min 44pt height)
- Color + icon + text
- Background highlight
- Used in lists and cards

**Measurement Card** (full width)
- Time + stress level
- Category + confidence
- HRV and HR data
- Tap for details

### Supporting Components

- Buttons (min 44pt)
- Text fields (min 44pt)
- Toggle switches (min 44pt)
- Progress indicators
- Charts and graphs

---

## Navigation Architecture (5-Tab Structure)

**Updated - May 2026:**

The app uses a 5-tab navigation structure:

1. **Home** (`DashboardView.swift`)
   - Main stress monitoring dashboard
   - Current stress level with visual ring
   - Recent measurements and timeline
   - Personalized insights and AI recommendations

2. **Trends** (`TrendsView.swift`)
   - Historical stress analytics
   - Chart visualizations
   - Statistical insights
   - Trend patterns and correlations

3. **Breathing** (`BreathingView.swift`)
   - Guided breathing exercises
   - Figma-aligned breathing circle
   - 3-minute sessions
   - Session history and effectiveness

4. **Characters** (`CharacterCollectionView.swift`)
   - Character collection display
   - Evolution tracking and progress
   - Character detail views
   - Free/premium/streak unlock indicators

5. **Settings** (`SettingsView.swift`)
   - App settings and preferences
   - Data export and deletion
   - HealthKit permission management
   - About and support information

### Tab Bar Design Guidelines

- **Corner Radius:** 64pt (pill-shaped)
- **Spacing:** Equal distribution across 5 tabs
- **Icon sizing:** 24x24pt selected, 22x22pt unselected
- **Separate icon assets** for selected / unselected states
- **Consistent with Apple HIG and watchOS design**

---

## Character Design System (June 2026)

### 5 Elemental Characters with Evolution

**Character Roster:**
1. **Ripple** - Water/Otter element (blue - #007AFF)
2. **Blossom** - Earth/Plant element (green - #34C759)
3. **Ember** - Fire element (orange - #FF9500)
4. **Zephyr** - Air/Wind element (purple - #AF52DE)
5. **Lumi** - Moon element (indigo - #5856D6)

**Evolution System:**
- 3 evolution stages (Seed → Growth → Flourish)
- Triggered by user streaks, completed sessions, resilience scores
- Unique SVG assets per stage and mood state
- Free/premium/streak-gated unlock types

**Asset Naming:** `{character}_{evolution}_{mood}.svg`
- Example: `ripple_seed_calm.svg`, `blossom_flourish_overwhelmed.svg`

### Character Mood States

Character moods reflect current stress level:
- **Calm** (Relaxed 0-25) - Green accent
- **Concerned** (Mild 25-50) - Blue accent
- **Worried** (Moderate 50-75) - Yellow accent
- **Overwhelmed** (High 75-100) - Orange accent
- **Sleeping** (Rest state) - Gray accent

| Character | Element | Color | Rarity | Status |
|-----------|---------|-------|--------|--------|
| **Ripple** | Water | Blue (#007AFF) | Free | Default starter character |
| **Blossom** | Earth | Green (#34C759) | Free | Unlocked early |
| **Ember** | Fire | Orange (#FF9500) | Premium | StoreKit-gated |
| **Zephyr** | Air | Purple (#9370DB) | Premium | StoreKit-gated |
| **Lumi** | Moon | Indigo (#5856D6) | Streak-gated | 30-day streak requirement |

### Evolution System

Each character evolves through 3 stages:
1. **Stage 1 (Droplet/Bud/Spark/Breeze/Crescent)** - Starter form
2. **Stage 2 (Ripple/Blossom/Ember/Zephyr/Lumi)** - Mid form (unlocked at 5 sessions or 5-day streak)
3. **Stage 3 (Tidal/Willow/Inferno/Storm/Eclipse)** - Final form (unlocked at 30 sessions or 30-day streak + high resilience)

### Mood States

Each character has 5 mood expressions tied to stress level:
- **Relaxed** (0-25) - Happy, peaceful
- **Mild** (25-50) - Content, neutral
- **Moderate** (50-75) - Concerned, alert
- **High** (75-100) - Stressed, worried
- **Recovery** - Proud, glowing (post-exercise/breathing)

### SVG Asset Naming

All character assets follow strict naming convention: `{character}_{evolution}_{mood}.svg`

**Examples:**
- `ripple_ripple_relaxed.svg` - Ripple character, Stage 2, relaxed mood
- `ember_inferno_high.svg` - Ember character, Stage 3, high stress mood
- `lumi_crescent_mild.svg` - Lumi character, Stage 1, mild stress mood

See `/docs/design/ASSET_NAMING.md` for comprehensive naming specification.

### Color Palettes

Use character element colors consistently in UI:
- Water (Ripple): `#007AFF` (Apple Blue)
- Earth (Blossom): `#34C759` (Apple Green)
- Fire (Ember): `#FF9500` (Apple Orange)
- Air (Zephyr): `#9370DB` (Purple)
- Moon (Lumi): `#5856D6` (Apple Indigo)

---

## Accessibility Standards (WCAG AA)

### Mandatory Requirements

- [ ] All interactive elements: 44x44 minimum
- [ ] Text contrast: ≥4.5:1 (WCAG AA)
- [ ] Stress indicators: Dual coding (color + icon + text)
- [ ] All buttons: Accessibility labels
- [ ] Text: Minimum 75% scale factor
- [ ] Focus indicators: Visible for keyboard navigation
- [ ] VoiceOver: Logical top-to-bottom navigation
- [ ] Dynamic Type: Scales to 200% without truncation
- [ ] Color blindness: All info without color alone
- [ ] Haptics: Optional (can be disabled)

### Testing Checklist

Before committing UI code:

```
VoiceOver Testing:
[ ] All labels descriptive and concise
[ ] Navigation logical and efficient
[ ] Hints clear for complex controls
[ ] Rotor works for headings/landmarks

Dynamic Type Testing:
[ ] Smallest (85%) - readable without shrinkage
[ ] Largest (200%) - no overlap or truncation
[ ] Line length - max 60 characters for readability

Color Testing:
[ ] Protanopia (red-green colorblind)
[ ] Deuteranopia (red-green colorblind)
[ ] Tritanopia (blue-yellow colorblind)
[ ] All info visible without color

Manual Testing:
[ ] All buttons 44x44 minimum
[ ] Focus indicators visible
[ ] Keyboard navigation works
```

---

## Dark Mode & AppearanceManager (NEW - Jun 2026)

All views automatically adapt to dark mode via **AppearanceManager** singleton:

```swift
// ProfileCard appearance picker controls app-wide theme
@Environment(\.colorScheme) var systemColorScheme
let appearanceManager = AppearanceManager.shared
// Users select: Light / Dark / System (uses device setting)
```

**AppearanceManager Integration:**
- User preference persists to UserDefaults
- ProfileCard (Settings → Appearance) allows Light/Dark/System selection
- Applied globally across all tabs via environment modifier
- Respects Dynamic Light/Dark mode transitions

**Guidelines:**
- Use `Color.primary` and `Color.secondary` (auto-inverted)
- Don't use pure white (#FFF) in dark mode
- Test contrast in both light and dark modes
- Verify animations visible in both modes
- Settings card backgrounds use `adaptiveCardBackground` token (auto-switches)

---

## Haptic Feedback

Use haptics to confirm user actions:

```swift
// Light tap - confirmation
HapticManager.shared.buttonPressed()

// Success - positive feedback
HapticManager.shared.stressLevelChanged(to: .relaxed)

// Warning - alert user
HapticManager.shared.warning()
```

**Rules:**
- Use consistently for same action
- Make optional (can be disabled in settings)
- Avoid overuse (max 1-2 per screen)

---

## StressBuddy Character

Animated character provides encouragement based on stress level:

| Stress | Expression | Message |
|--------|-----------|---------|
| Relaxed | 😊 | "You're doing great!" |
| Mild | 😐 | "Stay calm and breathe" |
| Moderate | 😟 | "Take a moment to relax" |
| High | 😰 | "Try a breathing exercise" |

---

## Data Visualization

### Trend Chart
- 7-day rolling average
- Color-coded by stress category
- Tap to see daily details
- Swipe to change timeframe

### Export Options
- CSV (spreadsheet-compatible)
- JSON (API-compatible)
- PDF (printable report)

---

## Layout Breakpoints

### iPhone Sizes
- **Compact:** iPhone SE, 8, 13 mini (reduce padding)
- **Standard:** Most iPhones (standard padding)
- **Large:** Max pro models (can use more space)

### Apple Watch Sizes
- **40mm:** 2 data points per screen, large touch targets
- **45mm:** 3 data points per screen, standard targets

---

## File Organization

All UI files follow this structure:

```
Views/
├── Action/
│   ├── ActionView.swift                 # Primary quick stress relief interface
│   └── Components/                      # Action components
├── Breathing/
│   ├── BreathingExerciseView.swift      # Box breathing 4-4-4-4 (Figma-aligned)
│   ├── BreathingSessionView.swift
│   ├── BreathingSummaryView.swift
│   ├── BreathingViewModel.swift
│   └── Components/
│       ├── BeforeAfterChart.swift
│       └── BreathingCircleView.swift
├── Chat/
│   ├── ChatBottomSheetView.swift        # AI chat bottom sheet
│   └── QuickActionChipsView.swift       # Prompt suggestions
├── Dashboard/
│   ├── DashboardViewModel.swift
│   └── Components/                      # ~40 component files
│       ├── StressRingView.swift
│       ├── DailyTimelineView.swift
│       ├── AIChatCard.swift
│       └── ...
├── History/
│   ├── MeasurementHistoryView.swift
│   ├── HistoryViewModel.swift
│   └── Components/
├── Journal/
│   └── NoteEntryView.swift
├── Onboarding/
│   ├── OnboardingWelcomeView.swift
│   └── ...                              # 10 files total (View + ViewModel pairs)
├── Settings/
│   ├── SettingsView.swift               # Figma card-based design
│   ├── SettingsViewModel.swift
│   ├── Components/                      # 12 component files
│   └── DataManagement/
├── Shared/
│   └── SafariView.swift
├── Trends/
│   ├── TrendsView.swift                 # Figma-aligned card list
│   ├── TrendsViewModel.swift
│   └── Components/
├── Components/                          # Shared components
│   ├── DemoModeBannerView.swift
│   ├── HapticManager.swift
│   └── TabBar/
├── DesignSystem/
│   ├── Typography.swift
│   ├── Spacing.swift
│   ├── Shadows.swift
│   └── Components/
├── DashboardView.swift
├── MainTabView.swift
└── ...                                 # Additional views (~100 total)
```

---

## Before Submitting UI Code

1. **Visual Review**
   - [ ] Follows color system
   - [ ] Uses correct typography
   - [ ] Proper spacing and alignment
   - [ ] Dark mode verified
   - [ ] All animations smooth

2. **Accessibility Review**
   - [ ] All labels present
   - [ ] Minimum touch targets (44x44)
   - [ ] Contrast ≥4.5:1
   - [ ] Dual coding for stress indicators
   - [ ] VoiceOver tested

3. **Interaction Review**
   - [ ] Haptic feedback appropriate
   - [ ] Loading states shown
   - [ ] Error messages clear
   - [ ] Edge cases handled
   - [ ] No orphaned elements

4. **Device Testing**
   - [ ] Tested on iPhone 15
   - [ ] Tested on iPhone SE
   - [ ] Tested on Apple Watch
   - [ ] Landscape orientation (if applicable)
   - [ ] Light and dark modes

---

## March 2026 Design Patterns

### Adaptive Card Background
All cards now use unified adaptive backgrounds that auto-switch in light/dark mode:

```swift
.background(Color.adaptiveCardBackground)     // White / #2C2C2E
.background(Color.adaptiveSettingsBackground) // #F3F4F8 / #1C1C1E
```

### Settings Card System (Mar 2026)
- Card corner radius: `settingsCardRadius` token
- Card shadow: `settingsCardShadow` preset (color: `#18274B`)
- Section headers: `SettingsSectionHeader` reusable component

### TabBar (Mar 2026)
- Corner radius: 64pt (pill-shaped)
- Spacing: 50pt between tabs (was 80)
- Explicit horizontal padding applied
- Separate icon assets for selected / unselected states

### 7-Day Dot-Matrix Timeline (Mar 2026)
- Rows: Mon–Sun, Columns: 3-hour blocks (7 slots/day)
- Filled dot = stress measurement (colored by category)
- Empty slot = gray dot (no data)
- Integrated between quickStatsRow and breathing CTA in dashboard

---

**Enforced By:** Code review & QA testing
**Last Updated:** June 7, 2026