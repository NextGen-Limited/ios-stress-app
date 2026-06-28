# Design Guidelines: User Experience & Accessibility

**System:** iOS Human Interface Guidelines compliant
**Accessibility:** WCAG AA
**Section:** Accessibility, haptics, StressBuddy, onboarding, data visualization, chat UX
**Version:** 1.1
**Last Updated:** June 13, 2026

---

## Accessibility (WCAG AA)

### Dual Coding Requirement

**Every stress indicator must use:**
1. Color (primary signal)
2. Icon or shape (secondary signal)
3. Text label (tertiary signal)

**Example - Correct:**
```
🟢 Green + Checkmark Icon + "Relaxed" Text
```

**Example - Incorrect:**
```
Green circle only ✗ (Color-blind users can't tell)
```

### VoiceOver Support

All interactive elements require accessibility labels:

```swift
Button(action: { viewModel.measureStress() }) {
  Label("Measure", systemImage: "waveform.circle.fill")
}
.accessibilityLabel("Measure stress level")
.accessibilityHint("Fetches your current HRV and heart rate from Apple Watch")
.accessibilityIdentifier("measure_button")
```

### Dynamic Type Support

Text scales with user's accessibility settings:

```swift
Text("Stress Level")
  .font(.headline)
  .minimumScaleFactor(0.75)  // Don't shrink below 75%
  .lineLimit(nil)             // Allow wrapping
```

### Touch Target Size

Minimum 44x44 points for all interactive elements:

```swift
Button("Measure") { ... }
  .frame(minHeight: 44)
  .frame(minWidth: 44)
```

### Color Contrast

Text must have contrast ratio ≥4.5:1 (WCAG AA):

| Foreground | Background | Ratio | Status |
|-----------|-----------|-------|--------|
| Black (#000) | White (#FFF) | 21:1 | ✅ Pass |
| Mild (#007AFF) | White (#FFF) | 8.6:1 | ✅ Pass |
| Yellow (#FFD60A) | White (#FFF) | 10.5:1 | ✅ Pass |
| Moderate (#FFD60A) | Light gray | 7.2:1 | ✅ Pass |

---

## Haptic Feedback

Provide tactile feedback for key actions:

### Haptic Types

```swift
enum HapticFeedback {
  case lightTap       // Light notification
  case mediumTap      // Action confirm
  case heavyTap       // Success/importance
  case rigidTap       // Error/warning
  case success        // Completion
  case warning        // Caution
  case error          // Problem
}
```

### Implementation

```swift
struct HapticManager {
  static let shared = HapticManager()
  private let generator = UIImpactFeedbackGenerator(style: .medium)

  func stressLevelChanged(to level: StressCategory) {
    let impactFeedback = UIImpactFeedbackGenerator(style: level.hapticStyle)
    impactFeedback.impactOccurred()
  }

  func buttonPressed() {
    generator.impactOccurred()
  }
}
```

### Usage

```swift
Button("Measure") {
  HapticManager.shared.buttonPressed()
  viewModel.measureStress()
}

// When stress level updates
.onChange(of: viewModel.currentStress) { newValue in
  HapticManager.shared.stressLevelChanged(to: newValue.category)
}
```

---

## StressBuddy Character

Animated character that reflects stress level and provides encouragement.

### Mood States

| Stress Level | Expression | SVG Asset | Color | Message |
|-------------|-----------|-----------|-------|---------|
| **Sleeping** | Rest state | `CharacterSleeping.svg` | - | "Rest mode" |
| **Relaxed (0-25)** | Smiling | `CharacterCalm.svg` | Green | "You're doing great!" |
| **Mild (25-50)** | Concerned | `CharacterConcerned.svg` | Blue | "Stay calm and breathe" |
| **Moderate (50-75)** | Worried | `CharacterWorried.svg` | Yellow | "Take a moment to relax" |
| **High (75-100)** | Overwhelmed | `CharacterOverwhelmed.svg` | Orange | "Try a breathing exercise" |

### Implementation (Refactored Feb 2026)

The StressBuddy now uses SVG assets instead of code-drawn shapes:

```swift
struct StressBuddyIllustration: View {
  let mood: StressBuddyMood
  let size: CGSize

  var body: some View {
    SvgImageView(assetName: mood.svgAsset, size: size)
      .applyAnimation(for: mood)  // Breathing, fidget, shake animations
  }
}

// SVG assets are loaded from Assets.xcassets
extension StressBuddyMood {
  var svgAsset: String {
    switch self {
    case .sleeping: return "CharacterSleeping"
    case .calm: return "CharacterCalm"
    case .concerned: return "CharacterConcerned"
    case .worried: return "CharacterWorried"
    case .overwhelmed: return "CharacterOverwhelmed"
    }
  }
}
```

**Architecture Change:**
- Previously: 549 LOC of custom SwiftUI shapes
- Now: 66 LOC + 5 SVG assets in Asset Catalog
- Benefits: Easier design updates, faster compilation, smaller binary

---

## Navigation Flow (3-Tab Structure)

**Updated - June 17, 2026:**

### Tab Navigation Pattern

1. **Home Tab** (`DashboardView.swift`)
   - Primary stress measurement interface
   - Current stress level visualization with stress ring
   - **Biological Age Card** — Shows estimated age, difference from chronological age, color-coded trend
   - Quick access to recent measurements
   - Personalized AI insights and chat entry point
   - Weekly dot-matrix timeline view

2. **Action Tab** (`ActionView.swift`)
   - **Breathing exercises** — Guided box breathing with 4-4-4-4 pattern
   - **Ripple AI Coach** — Personalized stress relief guidance
   - **Bento Grid** — Quick action cards for wellness tools
   - **Dark canvas theme** — Calming visual design
   - Entry point to AI chat for conversational support

3. **Trend Tab** (`TrendsView.swift`)
   - Historical stress analysis with multiple charts
   - Statistical insights (mean, max, min, std dev)
   - Weekly heatmap visualization
   - HRV trend analysis
   - Data visualization cards (scrollable)

### Secondary Navigation (Settings - Non-Tab)

Accessed via button/chevron from Home tab:

**Settings Screen** (`SettingsView.swift`)
   - **ProfileCard** — Appearance picker (Light/Dark/System), Delete All Data
   - **CharactersCard** — Gateway to character collection and evolution
     - Tap to open CharacterCollectionView
     - Shows all 5 elemental characters with unlock status
     - Evolution timeline and mood preview
   - Data management cards (export, reset)
   - Watch face preferences (if applicable)
   - CloudKit sync toggle
   - About and help
   - Box breathing (4-4-4-4 pattern) with Figma alignment
   - Animated breathing circle with phase guidance
   - 3-minute session duration
   - Session history and effectiveness tracking
   - Before/after HRV measurement

4. **Characters Tab** (`CharacterCollectionView.swift`)
   - Character collection display grid
   - Evolution tracking and stage indicators
   - Unlock progress visualization
   - Character detail views with mood previews
   - Free/premium/streak-gated unlock types
   - Interactive celebration on evolution

5. **Settings Tab** (`SettingsView.swift`)
   - App settings and preferences
   - Data export (CSV, JSON) with date filtering
   - Data deletion by range or category
   - CloudKit reset utilities
   - HealthKit permission management
   - App information and support

### AI Chat Integration

**Chat Access Points:**
- **Home Tab**: AI Insights Card with chat button
- **Quick Action**: Chat icon in dashboard
- **Bottom Sheet**: Native SwiftUI chat interface

**Streaming Features:**
- Real-time token streaming via SSEParser
- SupabaseLLMService (SSE streaming via Edge Functions)
- SupabaseConfig for environment-based endpoint configuration
- Context-aware health/stress data injection via ChatContextBuilder
- Session-only message history (no SwiftData persistence)

---

## Onboarding Flow

### Screen Progression

1. **Welcome** - Introduction + feature overview (1 screen)
2. **HealthKit Permission** - Request authorization (1 screen)
3. **Baseline Setup** - Collect 10-30 measurements (3-5 screens)
4. **Completion** - Success state (1 screen)

**Visual Treatment:**
- Large illustrations
- One call-to-action per screen
- Progress indicator
- Skip option (except HealthKit)

---

## Data Visualization

### Stress Trend Chart

```
100 │
    │     ╱╲
  75 │   ╱    ╲───╱╲
    │ ╱          ╲
  50 │
    │
  0 └─────────────────
    0h   6h  12h  18h 24h
```

**Color Mapping:**
- Relaxed (0-25): Green area
- Mild (25-50): Blue area
- Moderate (50-75): Yellow area
- High (75-100): Orange area

**Interaction:**
- Tap to see details
- Zoom via pinch
- Swipe to change timeframe

---

## Breathing Exercise Integration

### Exercise Types

| Type | Duration | Pattern | Status |
|------|----------|---------|--------|
| **Box Breathing** | 3 minutes | 4-4-4-4 (inhale-hold-exhale-hold) | Implemented |
| **Coherent Breathing** | 5 minutes | 6 breaths/minute | Planned |
| **4-7-8 Breathing** | 5 minutes | 4-7-8 (inhale-hold-exhale) | Planned |

### Box Breathing Design (Apr 2026)

Figma-aligned 4-4-4-4 pattern with animated breathing circle (`BreathingCircleView`).

**Session flow:**
1. `BreathingExerciseView` - Pattern intro + start button
2. `BreathingSessionView` - Active session with animated circle + phase label
3. `BreathingSummaryView` - Post-session summary + effectiveness

**Visual guidance:**
- Animated circle expands/contracts with breathing rhythm
- Phase label: "Inhale" / "Hold" / "Exhale" / "Hold"
- Progress indicator for 3-minute session
- `BeforeAfterChart` shows HRV comparison

---

## AI Chat UX (Updated - Apr 2026)

### Chat Entry Points
- **ActionView** - Primary access point for quick stress relief
- `AIChatCard` on Dashboard - Context-aware stress insights
- Quick action chips in ActionView - Pre-built prompt suggestions

### Chat UI (`ChatBottomSheetView`)
- Bottom sheet overlay with native SwiftUI
- **Enhanced**: Real-time token streaming via AsyncThrowingStream
- `QuickActionChipsView` for contextual prompt suggestions
- AI Kitten mascot icon in chat header
- **NEW**: SSEParser for efficient token processing

### Streaming Architecture (Updated - Jun 2026)
```
ChatViewModel.send()
  → LLMServiceProtocol.send() → AsyncThrowingStream<String, Error>
  → SupabaseLLMService (HTTP/SSE to Supabase Edge Functions - PRODUCTION)
  → Token-by-token streaming display in ChatBottomSheetView
```

### Chat Context
- `ChatContextBuilder` assembles anonymized health/stress context into system prompt
- **No raw health data transmitted to LLM** (only anonymized context)
- Session-only persistence (no SwiftData for chat messages)
- **Configurable endpoints** via SupabaseConfig (URL + anonKey)

### LLM Provider Strategy (Jun 2026)
1. **`SupabaseLLMService`** (production cloud - RECOMMENDED)
   - HTTP/SSE with SSEParser for reliable streaming
   - Configurable endpoint via SupabaseConfig (easy provider switching)
   - Full production readiness as of Jun 12, 2026

### UX Improvements (Apr 2026, refined Jun 2026)
- **Real-time streaming** - Users see AI response as it's generated
- **Contextual suggestions** - Quick action chips based on stress level
- **Simplified access** - Direct from ActionView for immediate support
- **Streaming indicators** - Visual feedback during AI response generation
- **Production-ready** - Supabase Edge Functions deployed and tested

---

## Trends Analysis View

**Updated:** March 2026 (Figma alignment)

### Layout Pattern

Scrollable card list. No global NavigationStack or TimeRangePicker header — each card has its own static label.

### Cards (top to bottom)

| Card | Component | Chart Type |
|------|-----------|-----------|
| Stress Over Time | `StressBarChartView` | Swift Charts bar chart |
| Weekly Heatmap | `WeeklyHeatmapView` | Circular dot grid |
| HRV Trend | `LineChartView` | Line chart + Y-axis + "Today" label |
| Premium Banner | `PremiumBannerView` | Light-blue gradient + CharacterCalm + orange CTA |
| Smart Insights | `SmartInsightsTeaser` | Static "Coming Soon" teaser |

### Card Style

All cards use the standard card pattern: `adaptiveCardBackground` + `settingsCardRadius` + Settings card shadow. See [Design Guidelines: Visual](./design-guidelines-visual.md) → Standard Card Pattern.

### Mascot Component

`MascotSpeechBubbleView` — speech bubble attached to CharacterCalm SVG asset in `PremiumBannerView`.

### Metrics Displayed

- **Stress Over Time:** Bar chart with daily average by selected time range
- **Weekly Heatmap:** Stress intensity per day/hour as circular dot grid
- **HRV Trend:** HRV history line with Y-axis scale and "Today" reference

---

## Error Handling & Empty States

### Empty State (No Data)

When user hasn't taken any measurements:

```
📊 No Measurements Yet

Take your first measurement to get started.
Your stress data appears here once you begin tracking.

[Measure Now]
```

### Permission Required State

Displayed when HealthKit authorization is denied or not yet determined. Uses `PermissionCardView` component with multi-type support:

**Component:** `PermissionCardView.swift` (131 LOC)
- Icon container with error color background
- Permission type selector (`.healthKit`, `.heartRate`, `.hrv`)
- "Grant Access" button with loading state
- Secondary "Open Settings" button (deep link)

**Implementation:**
```swift
PermissionCardView(
    permissionType: .healthKit,
    isLoading: viewModel.isRequestingAccess,
    onGrantAccess: { Task { await viewModel.requestHealthKitAccess() } }
)
```

**Dashboard State Machine (Mar 2026):**
- **Loading:** Initial fetch in progress
- **Permission Required:** HealthKit denied or `.errorAuthorizationNotDetermined`
- **Content:** Stress data available (4 sections visible)
- **No Data:** Empty state when baseline not yet established

**Permission Denied UX:**
- PermissionCardView at top of scroll
- `SkeletonBlock` placeholders hint at hidden content below
- "Grant Access" triggers `viewModel.requestHealthKitAccess()`
- Double-tap protection via `isRequestingAccess` guard

### Offline State (CloudKit Unavailable)

When sync is disabled:

```
🌐 Waiting for Connection

Your data will sync automatically when you're online.
All changes are saved locally.
```

---

## Settings Organization

### Categories

**Health:**
- HealthKit authorization status
- Permissions management
- Sensor calibration

**Data:**
- Export data (CSV/JSON)
- Delete by date range
- Delete all measurements
- CloudKit reset

**Appearance:**
- Light/Dark mode preference
- Text size
- Haptic feedback toggle

**About:**
- App version
- Privacy policy link
- Open source libraries
- Contact support

---

## Notification Strategy

### Local Notifications

Sent when stress exceeds user-defined threshold:

```
Notification Title: "Your stress level is elevated"
Body: "Try a quick breathing exercise to calm down"
Action: "Take Exercise" | "Dismiss"
```

### Notification Frequency

- **Default:** Once per elevated reading
- **Custom:** User-configurable interval (e.g., 1 per hour)
- **Quiet Hours:** Disable notifications during sleep (10pm-8am)

---

## Accessibility Checklist

Before release, verify all items:

- [ ] All interactive elements have accessibility labels
- [ ] Minimum touch target is 44x44 points
- [ ] Text contrast ratio ≥4.5:1 (WCAG AA)
- [ ] All colors have icon/text fallback (dual coding)
- [ ] Dynamic Type scales to 200% without truncation
- [ ] VoiceOver navigates logically (top to bottom)
- [ ] No auto-playing animations (user controls)
- [ ] Haptic feedback is optional (can be disabled)
- [ ] Focus indicators visible for keyboard navigation
- [ ] Testing with Screen Reader enabled

---

## Testing Accessibility

### Tools

**VoiceOver Testing:**
```
Settings → Accessibility → VoiceOver → On
Navigate entire app using gestures
Verify descriptive labels and hints
```

**Dynamic Type Testing:**
```
Settings → Accessibility → Display & Text Size
Test at smallest (85%) and largest (200%) sizes
Verify no text truncation or overlap
```

**Contrast Testing:**
Use online contrast checker:
```
https://www.tpgi.com/color-contrast-checker/
```

**Color Blindness:**
Use simulator filter:
```
Xcode → Debug → View Debugging → Accessibility Inspector
→ Color Blindness filter
```

---

**Previous:** See `design-guidelines-visual.md` for colors, typography, and components.
**Design System Version:** 1.1
**Last Updated:** June 7, 2026
**Maintained By:** Phuong Doan