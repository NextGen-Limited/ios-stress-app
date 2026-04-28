# Phase 1: Add Lato Font + IAP Design Tokens

**Priority:** High | **Effort:** Small | **Status:** Pending

## Overview
Download Lato font family and add IAP-specific color/typography tokens to the existing design system.

## Key Insights
- Project uses Roboto (not Lato). Figma requires Lato Regular/Medium/Bold/Black.
- Font registration done via `Info.plist` `UIAppFonts` array
- Color system in `Theme/Color+Extensions.swift` already has `accentTeal` (#85C9C9) — matches Figma CTA
- Typography in `Views/DesignSystem/Typography.swift` — add Lato tokens alongside existing Roboto

## Related Code Files
- **Modify:** `StressMonitor/StressMonitor/Views/DesignSystem/Typography.swift`
- **Modify:** `StressMonitor/StressMonitor/Theme/Color+Extensions.swift`
- **Modify:** `StressMonitor/StressMonitor/Info.plist`
- **Create:** `StressMonitor/StressMonitor/Fonts/Lato-Regular.ttf`
- **Create:** `StressMonitor/StressMonitor/Fonts/Lato-Medium.ttf`
- **Create:** `StressMonitor/StressMonitor/Fonts/Lato-Bold.ttf`
- **Create:** `StressMonitor/StressMonitor/Fonts/Lato-Black.ttf`

## Implementation Steps

### 1.1 Download Lato Font Files
- Download Lato family from Google Fonts (https://fonts.google.com/specimen/Lato)
- Need: Lato-Regular.ttf, Lato-Medium.ttf, Lato-Bold.ttf, Lato-Black.ttf
- Place in `StressMonitor/StressMonitor/Fonts/`

### 1.2 Register Fonts in Info.plist
Add to `UIAppFonts` array (existing pattern):
```xml
<string>Lato-Regular.ttf</string>
<string>Lato-Medium.ttf</string>
<string>Lato-Bold.ttf</string>
<string>Lato-Black.ttf</string>
```
- Add font files to Xcode project target "StressMonitor" (Build Phases → Copy Bundle Resources)

### 1.3 Add Lato Typography Tokens
Add to `Typography.swift`:
```swift
// MARK: - Custom Fonts (Lato - IAP Screen)

static func lato(_ weight: LatoWeight, size: CGFloat) -> Font {
    .custom(weight.fontName, size: size)
}

enum LatoWeight: String {
    case regular = "Lato-Regular"
    case medium = "Lato-Medium"
    case bold = "Lato-Bold"
    case black = "Lato-Black"

    var fontName: String { rawValue }
}

// IAP specific sizes (from Figma)
static let iapNavTitle = Font.custom("Lato-Bold", size: 18)
static let iapTagline = Font.custom("Lato-Black", size: 21)
static let iapSectionHeader = Font.custom("Lato-Bold", size: 16)
static let iapPlanName = Font.custom("Lato-Bold", size: 13)
static let iapPrice = Font.custom("Lato-Bold", size: 20)
static let iapPerMonth = Font.custom("Lato-Regular", size: 11.5)
static let iapSavings = Font.custom("Lato-Bold", size: 12)
static let iapSubtitle = Font.custom("Lato-Regular", size: 11.5)
static let iapCTA = Font.custom("Lato-Bold", size: 14)
static let iapUtilityLabel = Font.custom("Lato-Medium", size: 13)
static let iapBadge = Font.custom("Lato-Bold", size: 13)
```

### 1.4 Add IAP Color Tokens
Add to `Color+Extensions.swift`:
```swift
// MARK: - IAP Screen Colors (Figma)

/// IAP section header teal - #158B8B
static let iapHeaderTeal = Color(hex: "158B8B")
/// IAP CTA button teal - #85C9C9 (same as accentTeal, explicit alias)
static let iapCTATeal = Color(hex: "85C9C9")
/// IAP plan selected border amber - #FFAE3B
static let iapAmber = Color(hex: "FFAE3B")
/// IAP savings green - #4FC01B
static let iapSavingsGreen = Color(hex: "4FC01B")
/// IAP primary text - #111827
static let iapTextPrimary = Color(hex: "111827")
/// IAP secondary text - #6B7280
static let iapTextSecondary = Color(hex: "6B7280")
/// IAP muted text (nav title) - #808080
static let iapTextMuted = Color(hex: "808080")
/// IAP chevron/icon gray - #9CA3AF
static let iapChevronGray = Color(hex: "9CA3AF")
/// IAP icon border - #9EA7B8
static let iapIconBorder = Color(hex: "9EA7B8")
/// IAP restore icon blue - #3B82F6
static let iapRestoreBlue = Color(hex: "3B82F6")
/// IAP manage icon dark - #374151
static let iapManageDark = Color(hex: "374151")
/// IAP tagline gradient start - #00D9FF
static let iapGradientStart = Color(hex: "00D9FF")
/// IAP tagline gradient end - #24B9CC
static let iapGradientEnd = Color(hex: "24B9CC")
```

### 1.5 Add IAP Shadow Token
Add to `Shadows.swift`:
```swift
/// IAP plan card shadow (Figma multi-layer)
static let iapPlanCard = ShadowDefinition(
    color: Color(hex: "5C5C5C").opacity(0.1),
    radius: 8,
    x: 0,
    y: 2
)

/// IAP utility row shadow
static let iapUtilityRow = ShadowDefinition(
    color: Color(hex: "18274B").opacity(0.06),
    radius: 6,
    x: 0,
    y: 3
)
```

## Success Criteria
- [ ] Lato font renders correctly in preview
- [ ] All IAP color tokens accessible via `Color.iapXxx`
- [ ] No compilation errors
- [ ] Existing design system untouched (additive only)

## Risk Assessment
- **Low risk**: Additive changes only, no existing code modified
- **Font availability**: Lato is Google Fonts (free, SIL license) — no licensing issues
