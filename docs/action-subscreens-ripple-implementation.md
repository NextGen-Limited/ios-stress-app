# 📋 IMPLEMENTATION TASK: Action Subscreens Redesign — Ripple-Driven

**Project:** `/Users/ddx-pro17/Projects/ios-stress-app`
**Branch:** tạo `feature/action-subscreens-ripple` từ `main`
**Design prototype:** http://127.0.0.1:53223/api/projects/stressmonitor-action-subscreens-redesign-d12d/raw/index.html
**Design system:** `docs/design/character-concept-sheet.html` (source of truth)
**Previous PR reference:** #21 (onboarding redesign — same dark canvas + Ripple pattern)

---

## 🎨 DESIGN TOKENS (bắt buộc)

```
Canvas:        #0A0A0F
Card BG:       #1A1A2E
Card BG 2:     #161628
Border:        rgba(255,255,255,0.06)
Accent (Ripple blue):  #4FC3F7
Accent mid:    #81D4FA
Accent deep:   #0288D1
Old teal #85C9C9 → REPLACE with #4FC3F7 everywhere

Stress tiers:
  Very Calm:   #4CAF50
  Calm:        #81C784
  Neutral:     #FFB74D
  Stressed:    #FF8A65
  Critical:    #E53935

Breathing phases:
  Inhale:      #4FC3F7
  Hold:        #81D4FA
  Exhale:      #26C6DA

Typography: SF Pro Rounded ONLY — replace all Roboto-Bold, Roboto-MediumItalic
Corner radius: cards 20px, small 14px, pills 100px
```

---

## 📁 FILES TO MODIFY (7 files)

### 1. `BreathingExerciseView.swift` — Entry screen

- `.background(Color.white)` → dark canvas `Color(red: 0.04, green: 0.04, blue: 0.06)`
- Replace generic `Circle()` timer orb with **RippleBreathingView** (new component — see #3)
- `Color.tealLight` (#85C9C9) → `Color(red: 0.31, green: 0.76, blue: 0.97)` (#4FC3F7)
- `Color.tealDark` → `Color(red: 0.01, green: 0.53, blue: 0.82)` (#0288D1)
- Phase indicator row → **Phase pills** (4 cards, each with emoji icon + label + time, active state highlighted with accent border)
- Progress bar: track `rgba(120,120,128,0.12)`, fill = Ripple blue gradient
- "How it works" card → "💧 How Ripple guides you" — 4 step dots with emoji (🌬️→✋→💨→✋), arrows between
- Buttons: Start/Pause = accent gradient + shadow, Reset = glass card border

**Ripple breathing orb specs:**
- Ripple SVG at center, 130pt
- Scale animation: inhale scale to 1.15 (4s), hold steady (4s), exhale scale to 0.85 (4s), hold steady (4s)
- Concentric decorative rings: dashed outer (260pt) + solid ring (160pt) + rotating active ring

### 2. `BreathingSessionView.swift` — Live session

- Gradient background → dark canvas with subtle radial glow at center `rgba(79,195,247,0.04)`
- `BreathingCircleView` → **RippleBreathingView** at 200pt (HUGE, fills screen)
- Ripple face changes per phase:
  - `.inhale` → serene half-closed eyes, gentle smile, body expanding
  - `.hold` → focused round eyes, determined small smile, body steady
  - `.exhale` → relaxed closed eyes, wide smile, body contracting, water trail particles
- Phase text: 36pt bold, colored per phase (inhale=#4FC3F7, hold=#81D4FA, exhale=#26C6DA)
- Phase progress: 4 dots/pills showing current phase position
- Time remaining: 56pt light weight, tabular nums
- **NEW: Ripple encouragement bubble** — appears mid-session: *"You're doing great! Keep going."* (glass card with Ripple mini avatar)
- End Session button: red-tinted `rgba(229,57,53,0.1)` bg, `#E53935` text, red border

### 3. `BreathingCircleView.swift` → **RENAME to `RippleBreathingView.swift`**

**Before:** 4 nested `Circle()` with `LinearGradient` + white opacity layers. Zero character.

**After:** Ripple character SVG at center with:
- Body: ellipse, fill `#4FC3F7` with radial gradient overlay (`#81D4FA` → `#0288D1`)
- Ears: 2 ellipses `#29B6F6` with inner `#0288D1` at 50% opacity
- Eyes: phase-driven (see #2)
- Cheeks: `#F48FB1` at 30-35% opacity
- Mouth: phase-driven `Path` stroke
- Water sparkles on inhale (small circles `#81D4FA`), water trail on exhale
- Scale animation synced to breathing cycle
- Props: `phase: BreathingPhase`, `scale: Double`, `size: CGFloat`

**IMPORTANT:** Build Ripple as a reusable SwiftUI view. Use `Path` / `Ellipse` / `Circle` shapes — NOT image assets. This is the SAME Ripple SVG pattern used in watch/widget/Settings/Trends redesigns.

### 4. `BreathingSummaryView.swift` — Post-session

- `Color.backgroundLight` → dark canvas
- `checkmark.circle.fill` SF Symbol → **Celebrating Ripple** (100pt, bouncing animation, sparkles ✨⭐ around)
- "Session Complete" → "Amazing! 🎉" + "Ripple is so proud of you!"
- HRV improvement card with raw numbers → **Mood Shift card**: before/after Ripple faces side by side
  - Before: stressed Ripple (worried eyes, sweat drop) in `rgba(255,138,101,0.08)` box
  - Arrow with improvement % in green
  - After: calm Ripple (closed happy eyes, smile) in `rgba(129,199,132,0.08)` box
- **NEW: Stat grid** (2 tiles): Duration ⏱️ + Cycles 🔄
- BeforeAfterChart → **HRV bar chart**: 2 gradient bars (before=red gradient, after=green gradient), values on top, labels below, improvement text "+16ms · +38%"
- **NEW: Ripple message card**: speech bubble with Ripple mini avatar: *"Your heart rhythm improved 38%! I can feel you're calmer now. Try another session tomorrow?"*
- Buttons: Done (accent gradient, full width) + Share Result (glass card, full width with 📤)

### 5. `MiniWalkView.swift` — Walk screen

- Header subtitle: add "10 min · Brisk pace"
- `Color.Wellness.adaptiveBackground` → dark canvas
- `MiniWalkTimerRing` → redesigned (see #6)
- `MiniWalkInstructionCard` → **Ripple companion bubble** (see #7)
- **NEW: Walk stats row** (3 stats): 👟 Steps (live), ❤️ BPM (from HealthKit), 🔥 kcal
- Start button → Pause button when running (accent gradient)
- Reset → End Walk (glass card)

**NEW: MiniWalk completion screen** (doesn't exist yet — add `MiniWalkCompleteView` or sheet):
- Tired-happy Ripple (rosy cheeks `#F48FB1` 40% opacity + sweat drop `#81D4FA`)
- "Nice walk! 🚶" + "Ripple enjoyed every step with you!"
- 3-stat grid: Steps, Minutes, kcal
- Stress impact card: Neutral Ripple → Calm Ripple with "↓ −15% Stress Level"
- Ripple message: *"That was refreshing! Your stress dropped 15%."*
- Buttons: Done + View Full Trends

### 6. `MiniWalkTimerRing.swift` — Timer ring

- **CRITICAL FIX:** `font(.custom("Roboto-Bold", size: 42))` → `font(.system(size: 48, weight: .light, design: .rounded))` — SF Pro Rounded
- `Color.Wellness.miniWalkBlue` → SVG-style gradient ring `#4FC3F7 → #0288D1`
- Ring track: `rgba(120,120,128,0.12)` (NOT `Color.Wellness.timerTrack`)
- Center fill: dark canvas (NOT solid blue circle)
- Time text: white `#E0E0E8`, 48pt light weight, tabular nums
- Progress: `stroke-dasharray` style arc with gradient
- Ring size: 200pt outer, 180pt track

### 7. `MiniWalkInstructionCard.swift` — Instruction card

- **CRITICAL FIX:** `font(.custom("Roboto-MediumItalic", size: 18))` → `font(.system(size: 14, weight: .regular, design: .rounded))`
- Static text → **Ripple companion**: 40pt Ripple avatar (bouncing animation `walk-bob`) + speech bubble
- Dynamic messages based on progress:
  - 0-30%: *"Let's go! Walk at a brisk pace. Focus on breathing."*
  - 30-70%: *"Keep going! You're doing great."*
  - 70-95%: *"Almost there! Just a few more minutes!"*
  - 95-100%: *"Last few seconds! Finish strong!"*
- Bubble: glass card `#1A1A2E`, accent border `rgba(79,195,247,0.12)`, rounded 14px (asymmetric corner)
- `cornerRadius(33)` → `cornerRadius(14)`

---

## 🔧 ADDITIONAL REQUIREMENTS

1. **Ripple Character Component:** Create a reusable `RippleCharacterView` that accepts `mood: RippleMood` enum (`.serene, .focused, .relaxed, .happy, .celebrating, .worried, .determined, .tired`) and `size: CGFloat`. All screens reference this ONE component.

2. **Color cleanup:** Remove ALL `tealLight` / `tealDark` private extensions in BreathingExerciseView.swift. Remove `Color.Wellness.tealCard` / `miniWalkBlue` / `timerTrack` usage. Replace with Ripple blue tokens.

3. **Font cleanup:** Grep for `"Roboto` across the entire Views folder — replace ALL with SF Pro Rounded (`.system(size:, weight:, design: .rounded)`). This is a pre-existing bug.

4. **Haptics:** Keep existing `HapticManager.shared.success()` on MiniWalk complete. Add `.light` haptic on each breathing phase transition.

5. **Accessibility:** Ripple SVGs need `accessibilityLabel` (e.g., "Ripple is calm and happy"). Phase pills need `accessibilityValue` for progress.

6. **Animations:** All transitions use `.easeInOut`. Breathing scale animation must be smooth (not jerky). Use `withAnimation(.easeInOut(duration: phaseDuration))`.

7. **No new dependencies.** Pure SwiftUI shapes (Path, Ellipse, Circle, Canvas if needed).

---

## ✅ ACCEPTANCE CRITERIA

- [ ] All 7 files compile without warnings
- [ ] Zero `Roboto` font references remain
- [ ] Zero `#85C9C9` teal color references remain
- [ ] Dark canvas `#0A0A0F` on all screens
- [ ] Ripple character visible on all 5 screens
- [ ] Breathing orb scales smoothly with phases
- [ ] MiniWalk completion screen exists and shows stats
- [ ] Summary shows before/after Ripple mood faces (not raw numbers as primary indicator)
- [ ] Phase pills highlight correctly during breathing session
- [ ] Walk stats update live (Steps, BPM, kcal)
- [ ] All buttons use accent gradient or glass card style
- [ ] SF Pro Rounded throughout
