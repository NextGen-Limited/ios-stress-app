# Design Guidelines: User Experience & Accessibility

**System:** iOS Human Interface Guidelines compliant
**Accessibility:** WCAG AA
**Section:** Accessibility, haptics, StressBuddy, onboarding, data visualization
**Version:** 1.0
**Last Updated:** February 2026

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

| Stress Level | Expression | Color | Message |
|-------------|-----------|-------|---------|
| **Relaxed (0-25)** | Smiling 😊 | Green | "You're doing great!" |
| **Mild (25-50)** | Neutral 😐 | Blue | "Stay calm and breathe" |
| **Moderate (50-75)** | Concerned 😟 | Yellow | "Take a moment to relax" |
| **High (75-100)** | Worried 😰 | Orange | "Try a breathing exercise" |

**Implementation:**
```swift
struct StressBuddyView: View {
  let stressLevel: Double
  let category: StressCategory

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: category.buddyEmoji)
        .font(.system(size: 64))
        .scaleEffect(1.0 + (stressLevel / 200))  // Subtle breathing animation

      Text(category.motivationalMessage)
        .font(.headline)
        .foregroundColor(Color.stressColor(for: category))
    }
  }
}
```

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

| Type | Duration | Target HR Reduction |
|------|----------|-------------------|
| **Box Breathing** | 4 minutes | 10-15 bpm |
| **4-7-8 Breathing** | 5 minutes | 15-20 bpm |
| **Guided Relaxation** | 10 minutes | 20-30 bpm |

### Visual Guidance

Animated circle that expands/contracts with breathing rhythm:

```swift
struct BreathingGuidanceView: View {
  @State var isExpanded = false
  let duration: Double

  var body: some View {
    Circle()
      .frame(width: 200, height: 200)
      .foregroundColor(Color.stressColor(for: .relaxed))
      .scaleEffect(isExpanded ? 1.2 : 0.8)
      .animation(
        Animation.easeInOut(duration: duration).repeatForever(autoreverses: true),
        value: isExpanded
      )
      .onAppear { isExpanded = true }
  }
}
```

---

## Trends Analysis View

### Metrics Displayed

- **Average stress:** 7-day rolling average
- **Peak times:** When stress is typically highest
- **Improvement:** Change from previous period
- **Baseline:** Personal baseline status

### Filter Options

- **Time Range:** Today, Week, Month, 3 Months, Year
- **Category:** All, Relaxed, Mild, Moderate, High
- **Confidence:** Show/hide low-confidence measurements

### Export Formats

Data can be exported as:
- **CSV** - Spreadsheet format (Excel-compatible)
- **JSON** - Structured data format (API-compatible)
- **PDF** - Printable report

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

### Error State (HealthKit Permission Denied)

When user denies HealthKit access:

```
⚠️ HealthKit Access Required

StressMonitor needs access to your Heart Rate data
from Apple Watch to calculate stress levels.

[Grant Access] [Learn More]
```

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
**Design System Version:** 1.0
**Last Updated:** February 2026
**Maintained By:** Phuong Doan
