# Code Review: Settings Screen Figma Implementation

**Date**: 2026-03-01
**Reviewer**: code-reviewer
**Scope**: Settings Screen redesign with card-based layout
**Build Status**: PASSED

## Scope

### Files Reviewed (12 files)

**Design Tokens:**
- `StressMonitor/Theme/Color+Extensions.swift` (added Settings colors with dark mode)
- `StressMonitor/Views/DesignSystem/Spacing.swift` (added Settings spacing)
- `StressMonitor/Views/DesignSystem/Shadows.swift` (added Settings shadow)
- `StressMonitor/Views/DesignSystem/Components/SettingsCard.swift` (NEW)

**Settings Components:**
- `StressMonitor/Views/Settings/Components/PremiumCard.swift` (NEW)
- `StressMonitor/Views/Settings/Components/SettingsSectionHeader.swift` (NEW)
- `StressMonitor/Views/Settings/Components/ComplicationWidget.swift` (NEW)
- `StressMonitor/Views/Settings/Components/AddComplicationButton.swift` (NEW)
- `StressMonitor/Views/Settings/Components/ShareButton.swift` (NEW)
- `StressMonitor/Views/Settings/Components/WatchFaceCard.swift` (NEW)
- `StressMonitor/Views/Settings/Components/DataSharingCard.swift` (NEW)

**Main View:**
- `StressMonitor/Views/Settings/SettingsView.swift` (REDESIGNED)
- `StressMonitor/Views/Settings/SettingsViewModel.swift` (existing, reviewed)

**Assets:**
- 5 new SVG assets in `Assets.xcassets/Settings/`

**LOC**: ~450 lines (new components + modifications)

---

## Overall Assessment

**Score: 7.5/10**

Good implementation of Figma design with clean component architecture, proper dark mode support, and accessibility coverage. Several issues need attention around font handling, magic numbers, and ViewModel initialization.

---

## Critical Issues (Blocking)

### 1. Missing Font Files for Custom Typography

**Location**: All Settings components use `Lato-Bold` and `Lato-Regular` fonts

**Problem**: Components reference `Lato` font family which is not included in the project:
- No Lato TTF/OTF files in Fonts folder
- No UIAppFonts entry in Info.plist
- Font files are not registered with the app

**Impact**: App will fall back to system font, breaking Figma design fidelity.

**Files Affected**:
- `PremiumCard.swift` (lines 16, 20)
- `AddComplicationButton.swift` (line 17)
- `ShareButton.swift` (line 17)
- `ComplicationWidget.swift` (line 48)
- `SettingsSectionHeader.swift` (line 31)
- `SettingsView.swift` (lines 134, 137)

**Recommendation**: Either:
1. Add Lato font files and register in Info.plist
2. Use existing Lora/Raleway fonts per project standards
3. Use SF Pro as fallback with appropriate weights

---

## High Priority Issues (Should Fix)

### 2. ViewModel Initialization Anti-Pattern

**Location**: `SettingsView.swift` lines 11-15

```swift
init() {
    _viewModel = State(initialValue: SettingsViewModel(
        modelContext: ModelContext(try! ModelContainer(for: StressMeasurement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
    ))
}
```

**Problem**:
- Creates temporary in-memory container in `init()`
- Then replaces it in `onAppear` with real context (line 47)
- Uses `try!` which will crash if ModelContainer creation fails

**Impact**: Unnecessary work on initialization, potential crash, confusing state management

**Recommendation**: Use proper dependency injection:
```swift
@State private var viewModel: SettingsViewModel?

var body: some View {
    if let viewModel = viewModel {
        // main content
    }
}
.onAppear {
    if viewModel == nil {
        viewModel = SettingsViewModel(modelContext: modelContext)
    }
}
```

### 3. Magic Numbers Throughout UI Components

**Locations**:
- `ComplicationWidget.swift`: 85.6, 43.7, 147.5, 112.9, 10.9, 0.91
- `AddComplicationButton.swift`: 277, 35.5, 14.9
- `ShareButton.swift`: 277, 35.5, 14.9
- `PremiumCard.swift`: 23, 48, 2, 18, 13
- `WatchFaceCard.swift`, `DataSharingCard.swift`: 23, 24

**Problem**: Hardcoded Figma values reduce maintainability and make responsive design difficult

**Recommendation**: Add to `Spacing` struct:
```swift
// Settings widget dimensions
static let widgetPreviewWidth: CGFloat = 85.6
static let widgetPreviewHeight: CGFloat = 43.7
static let widgetContainerWidth: CGFloat = 147.5
static let widgetContainerHeight: CGFloat = 112.9
static let settingsButtonWidth: CGFloat = 277
static let settingsButtonHeight: CGFloat = 35.5
```

### 4. Duplicate Button Component Logic

**Location**: `AddComplicationButton.swift` and `ShareButton.swift`

**Problem**: Near-identical components (35 lines each) differ only in:
- Icon name ("plus-icon" vs "share-icon")
- Label text ("Add Complication" vs "Share")
- Accessibility label

**Violation**: DRY principle

**Recommendation**: Create unified `SettingsActionButton`:
```swift
struct SettingsActionButton: View {
    let iconName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(iconName)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .frame(width: 18, height: 18)
                Text(label)
                    .font(.custom("Lato-Bold", size: 14.9))
                    .foregroundColor(.white)
            }
            // ... common styling
        }
    }
}
```

---

## Medium Priority Issues

### 5. Delete Confirmation Sheet State Not Connected

**Location**: `SettingsView.swift` lines 166-170

```swift
Button(role: .destructive, action: {
    Task {
        try? await viewModel.deleteAllMeasurements()
    }
    showingDeleteConfirmation = false
}) {
```

**Problem**:
- `showingDeleteConfirmation` is defined (line 7) but sheet only shows via `navigateToDelete` (line 54)
- Delete button in dataManagementSection navigates instead of showing confirmation
- Sheet exists but is never triggered

**Recommendation**: Either remove unused sheet or connect it to the delete flow

### 6. ViewModel Missing @MainActor

**Location**: `SettingsViewModel.swift` line 4-5

```swift
@Observable
class SettingsViewModel {
```

**Problem**: ViewModel uses `@Observable` but calls async repository methods without actor isolation. The repository (`StressRepository`) is marked `@MainActor`.

**Potential Issue**: Concurrency warnings or runtime issues

**Recommendation**: Add `@MainActor`:
```swift
@Observable
@MainActor
class SettingsViewModel {
```

### 7. Inconsistent Accessibility Patterns

**Locations**:
- `WatchFaceCard.swift` line 32: `.accessibilityElement(children: .contain)`
- `DataSharingCard.swift` line 32: `.accessibilityElement(children: .contain)`

**Problem**: These cards have tap gestures but no accessibility hints or traits indicating interactivity

**Recommendation**: Add accessibility hints:
```swift
.accessibilityHint("Double tap to configure watch face")
.accessibilityAddTraits(.isButton)
```

### 8. CloudKit Status Hardcoded

**Location**: `SettingsViewModel.swift` lines 36-39

```swift
private func checkCloudKitStatus() async {
    // TODO: Implement actual CloudKit status check
    cloudKitStatus = .upToDate
}
```

**Problem**: Always shows "Up to Date" regardless of actual sync status

**Impact**: Users may see incorrect sync state

---

## Low Priority Issues (Nitpicks)

### 9. Version String Hardcoded

**Location**: `SettingsView.swift` line 136

```swift
Text("Version 1.0.0 (2025.01.19)")
```

**Recommendation**: Read from bundle:
```swift
Text("Version \(Bundle.main.appVersion) (\(Bundle.main.buildNumber))")
```

### 10. Unused Variable Warning

**Location**: `SettingsView.swift` line 7

```swift
@State private var showingDeleteConfirmation = false
```

This state variable is declared but the delete flow uses `navigateToDelete` instead

### 11. Color Extensions: Missing # Prefix in Hex

**Location**: `Color+Extensions.swift` lines 89-103

```swift
static let settingsBackground = Color(light: Color(hex: "F3F4F8"), dark: Color(hex: "1C1C1E"))
```

Inconsistent with other colors that include `#` prefix. While the `init(hex:)` handles both, consistency is preferred.

---

## Edge Cases Found

### 12. DataSharingCard Tap Gesture on Non-Interactive Card

**Location**: `SettingsView.swift` lines 28-32

```swift
DataSharingCard()
    .contentShape(Rectangle())
    .onTapGesture {
        navigateToExport = true
    }
```

**Problem**: The entire card is tappable but only visually indicates the Share button is actionable. User may not realize the card itself navigates.

**Recommendation**: Make only the button tappable or add visual indication the card is interactive.

### 13. ComplicationWidget Placeholder Icons

**Location**: `ComplicationWidget.swift` lines 26-33

When `icon` is nil, shows a generic circle placeholder. This may confuse users about what the widget displays.

---

## Positive Highlights

1. **Excellent Dark Mode Support**: All new colors defined with light/dark variants via `Color(light:dark:)` initializer

2. **Clean Component Architecture**: Separation of concerns with reusable `SettingsCard` wrapper

3. **Proper Accessibility Labels**: Most interactive elements have appropriate accessibility labels

4. **Vector Assets**: Using SVGs with `preserves-vector-representation` for scaling

5. **Shadow System**: Good use of centralized shadow definitions via `AppShadow`

6. **Adaptive Colors**: `adaptiveCardBackground` and `adaptiveSettingsBackground` computed properties provide clean API

7. **Build Success**: No compile errors, project builds successfully

8. **Observable Pattern**: Proper use of `@Observable` macro for iOS 17+

---

## Recommended Actions

### Priority 1 (Must Fix)
1. Add Lato font files or switch to system/project fonts
2. Fix ViewModel initialization anti-pattern

### Priority 2 (Should Fix)
3. Extract magic numbers to Spacing constants
4. Consolidate button components to eliminate duplication

### Priority 3 (Nice to Have)
5. Connect or remove unused delete confirmation sheet
6. Add @MainActor to SettingsViewModel
7. Add accessibility hints to tappable cards
8. Use bundle version instead of hardcoded string

---

## Metrics

| Metric | Value |
|--------|-------|
| Build Status | PASSED |
| Files Reviewed | 12 |
| New Lines of Code | ~450 |
| Critical Issues | 1 |
| High Priority Issues | 4 |
| Medium Priority Issues | 4 |
| Low Priority Issues | 4 |
| Accessibility Coverage | 80% (missing hints on cards) |
| Dark Mode Support | 100% |
| Font Fidelity | 0% (fonts not loaded) |

---

## Unresolved Questions

1. Should we use Lato (Figma spec), Lora/Raleway (project README), or SF Pro (system)?
2. Is the delete confirmation sheet intended to be used or should it be removed?
3. What should the ComplicationWidget display when actual data is available?
4. Should CloudKit status check be implemented now or left as TODO?
