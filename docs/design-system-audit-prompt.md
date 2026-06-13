# 🔍 DESIGN SYSTEM AUDIT — StressMonitor iOS App

**Project:** `/Users/ddx-pro17/Projects/ios-stress-app`
**Source of truth:** `docs/design/character-concept-sheet.html`
**Scope:** Toàn bộ `StressMonitor/StressMonitor/Views/` — 120+ Swift files

---

## 🎯 MỤC TIÊU AUDIT

### 1. COLOR CONSISTENCY
**Trạng thái mong đợi:** Mọi màu đều đi qua design tokens (`Color+Wellness.swift`, `Color+Extensions.swift`), KHÔNG hardcode raw values.

**Kiểm tra:**
- [ ] Grep `#85C9C9` / `0.52, 0.79, 0.79` / `tealLight` / `tealDark` / `tealCard` / `miniWalkBlue` — **phải = 0 occurences** (đã replace bằng Ripple blue `#4FC3F7`)
- [ ] Grep `Color.white` dùng làm background — chỉ acceptable cho overlay/sheet, KHÔNG cho main screen background
- [ ] Grep `Color(red:` — tìm hardcoded colors thay vì dùng `Color.Wellness.*` token
- [ ] Grep `.background(Color(` — verify dùng `Color.Wellness.adaptiveBackground` hoặc dark canvas `Color(red: 0.04, green: 0.04, blue: 0.06)`
- [ ] Dark canvas `#0A0A0F` áp dụng trên: Dashboard, History, Settings, Trends, Action, Breathing, MiniWalk, Premium, Onboarding
- [ ] Stress tier colors consistent: `#4CAF50 / #81C784 / #FFB74D / #FF8A65 / #E53935` (5-tier from concept sheet, KHÔNG 4-tier Apple colors)

### 2. TYPOGRAPHY
**Trạng thái mong đợi:** SF Pro Rounded duy nhất, zero Roboto, zero hardcoded sizes.

**Kiểm tra:**
- [ ] Grep `"Roboto` trong toàn bộ Views/ — **phải = 0** (đã tìm thấy trong `MiniWalkTimerRing.swift` + `MiniWalkInstructionCard.swift`)
- [ ] Grep `.font(.system(size:` — verify dùng `Typography.*` tokens (`Typography.headline`, `Typography.body`, etc.) thay vì hardcode
- [ ] Grep `.font(.custom(` — **phải = 0** hoặc chỉ cho custom brand font có chủ đích
- [ ] SF Pro Rounded: `.system(..., design: .rounded)` dùng consistent cho mọi headings/numbers
- [ ] Tabular nums (`.monospacedDigit()`) cho mọi timer/counter displays

### 3. CHARACTER / MASCOT CONSISTENCY
**Trạng thái mong đợi:** Ripple (Water Otter) là character duy nhất. Zero cat images.

**Kiểm tra:**
- [ ] Grep `CharacterCalm` / `CharacterConcerned` / `CharacterSleeping` / `cat` — **phải = 0**
- [ ] Grep `Image("cat` / `Image(.catWork` — **phải = 0**
- [ ] Ripple SVG/SwiftUI shape dùng trên: Dashboard, Settings, Trends, Action, Breathing, MiniWalk
- [ ] Character mood system consistent: 😴 Very Calm → 😊 Calm → 😐 Neutral → 😰 Stressed → 🐚 Critical (5 states)
- [ ] Character-reactive visualization: stress level hiển thị qua Ripple face expression, KHÔNG chỉ raw numbers
- [ ] `RippleCharacterView` reusable component tồn tại và được reference từ mọi screen

### 4. COMPONENT PATTERNS
**Trạng thái mong đợi:** GlassCard dùng consistent, card radius unified, button styles unified.

**Kiểm tra:**
- [ ] Card corner radius: **20pt** standard, **14pt** small, **100px** pills — grep `cornerRadius(` để verify
- [ ] `GlassCard` component dùng thay vì manual `RoundedRectangle` + shadow mỗi lần
- [ ] Grep `cornerRadius(33)` — **phải = 0** (đã tìm thấy trong `MiniWalkInstructionCard.swift` — sai design system)
- [ ] Button styles unified: primary = accent gradient `#4FC3F7→#0288D1`, secondary = glass card border
- [ ] `SettingsCard` / `StatCard` / `Badge` design system components được dùng, KHÔNG custom re-implement

### 5. DARK MODE / ADAPTIVE
**Trạng thái mong đợi:** App là dark-first. Light mode support nhưng dark là primary.

**Kiểm tra:**
- [ ] Grep `Color.backgroundLight` / `Color(.systemBackground)` — verify không dùng cho main screens
- [ ] `adaptiveBackground` / `adaptiveCardBackground` / `adaptivePrimaryText` / `adaptiveSecondaryText` dùng consistent
- [ ] Shadows: `Shadows.swift` tokens dùng, KHÔNG inline `.shadow(color: .black.opacity(0.05), radius: 8...)`
- [ ] Overlay/sheet có proper dark adaptation (không trắng chói)

### 6. SPACING & LAYOUT
**Trạng thái mong đợi:** `Spacing.swift` tokens dùng consistent.

**Kiểm tra:**
- [ ] Grep hardcoded `.padding(` values — verify dùng `Spacing.*` tokens (`Spacing.md`, `Spacing.lg`, etc.)
- [ ] Consistent horizontal padding: 16pt standard cho screen content
- [ ] VStack/HStack spacing consistent: 12-24pt range
- [ ] `Spacer()` dùng đúng mục đích, KHÔNG `frame(height:)` hack

### 7. PREMIUM/LOCK PATTERNS
**Trạng thái mong đợi:** Consistent premium visual language.

**Kiểm tra:**
- [ ] Premium gold `#FE9901` consistent trên: Settings, Action, Trends, Premium screen
- [ ] `PremiumLockOverlay` component dùng cho locked features
- [ ] `PremiumBanner` / `PremiumCard` pattern matching across screens

---

## 📊 SCREEN-BY-SCREEN STATUS MATRIX

| Screen | Folder | Redesign HTML? | Code Updated? | Issues |
|---|---|---|---|---|
| Onboarding | `Onboarding/` | ✅ PR #21 | ✅ | — |
| Dashboard | `DashboardView.swift` + 20 components | ❌ | ❌ | Cat images? Hardcoded colors? |
| Action (main) | `Action/ActionView.swift` | ✅ prototype | ❌ | Pending impl |
| Breathing | `Breathing/` (4 files) | ✅ prototype | ❌ | Roboto? Teal? White bg? |
| MiniWalk | `MiniWalk/` (4 files) | ✅ prototype | ❌ | Roboto! Teal? cornerRadius(33)? |
| Settings | `Settings/` (15 files) | ✅ prototype | ❌ | Cat images? Light cards? |
| Trends | `Trends/` (20 files) | ✅ prototype | ❌ | Cat images? Old accent? |
| History | `History/` (7 files) | ❌ | ❌ | Full audit needed |
| Characters | `Characters/` (8 files) | ❌ | ❌ | Evolution system? |
| Chat | `Chat/` (2 files) | ❌ | ❌ | AI card style? |
| Premium | `Premium/` (7 files) | ❌ | ❌ | Paywall redesign exists in HTML only |
| Journal | `Journal/` (1 file) | ❌ | ❌ | Minimal screen |

---

## 🔧 OUTPUT YÊU CẦU

Tạo file: `docs/design/design-system-audit-report.md`

### Format per finding:
```
### [SEVERITY] File — Issue Description
- **File:** `path/to/file.swift`
- **Line:** 42
- **Current:** `Color(red: 0.52, green: 0.79, blue: 0.79)` (old teal #85C9C9)
- **Expected:** `Color.Wellness.rippleBlue` (#4FC3F7)
- **Category:** Color / Typography / Character / Component / Spacing
- **Fix effort:** S/M/L/XL
```

### Severity scale:
- 🔴 **CRITICAL** — Sai design system cơ bản (Roboto font, old teal, cat images, white bg)
- 🟡 **MAJOR** — Inconsistent component pattern, missing dark mode
- 🟢 **MINOR** — Spacing/typography inconsistency
- ⚪ **PASS** — Đã compliant

### Summary table cuối báo cáo:
```
| Category       | Files Checked | Issues Found | Critical | Major | Minor |
|---------------|-------------|-------------|---------|-------|-------|
| Color         | 120+        | ?           | ?       | ?     | ?     |
| Typography    | 120+        | ?           | ?       | ?     | ?     |
| Character     | 120+        | ?           | ?       | ?     | ?     |
| Components   | 120+        | ?           | ?       | ?     | ?     |
| Dark Mode     | 120+        | ?           | ?       | ?     | ?     |
| Spacing       | 120+        | ?           | ?       | ?     | ?     |
```

---

## 🎯 DESIGN TOKENS MONG ĐỢI (reference)

```
Canvas:          #0A0A0F
Card BG:         #1A1A2E
Card BG alt:     #161628
Border:          rgba(255,255,255,0.06)
Accent:          #4FC3F7 (Ripple blue — replaces ALL old teal #85C9C9)
Accent mid:      #81D4FA
Accent deep:     #0288D1
Premium gold:    #FE9901

Stress tiers (5-tier, from concept sheet):
  Very Calm:     #4CAF50
  Calm:          #81C784
  Neutral:       #FFB74D
  Stressed:      #FF8A65
  Critical:      #E53935

Typography: SF Pro Rounded — .system(size:, weight:, design: .rounded)
  NO Roboto. NO Helvetica. NO SF Pro Display without .rounded.

Card radius: 20pt standard, 14pt small, 100px pills
Spacing: via Spacing.swift tokens
Shadows: via Shadows.swift tokens
```

---

## 📋 INSTRUCTIONS

1. Đọc `docs/design/character-concept-sheet.html` trước để hiểu source of truth
2. Đọc `Theme/Color+Wellness.swift` + `Theme/Color+Extensions.swift` để biết current tokens
3. Đọc `DesignSystem/Typography.swift` + `Spacing.swift` + `Shadows.swift` để biết current tokens
4. Scan TỪNG file trong `Views/` — grep từng pattern ở checklist trên
5. Output báo cáo `docs/design/design-system-audit-report.md`
6. CHỈ audit/verify — KHÔNG fix code. Fix sẽ là task riêng.
