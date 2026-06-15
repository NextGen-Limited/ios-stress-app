# Apple Editorial Preparation & Assets Spec — StressMonitor

**Status:** Pre-submission checklist
**Owner:** Phuong Doan
**Last Updated:** June 14, 2026
**Target:** App Store submission (late June 2026)
**Source of truth for visual language:** `docs/design/character-concept-sheet.html`

> This document is the single operational checklist for getting StressMonitor through App
> Review and into contention for an **App Store editorial feature** (App of the Day / Today
> tab). Apple Editorial picks apps that excel in three areas this app is built around:
> **design quality, privacy leadership, and accessibility**. Every section below maps to one
> of those three pillars or to a hard App Review requirement.

---

## Table of Contents

1. [ASO Keyword Strategy](#1-aso-keyword-strategy)
2. [App Store Screenshot Specifications](#2-app-store-screenshot-specifications)
3. [Privacy Messaging Copy](#3-privacy-messaging-copy)
4. [Accessibility Audit Checklist](#4-accessibility-audit-checklist)
5. [App Store Review Preparation](#5-app-store-review-preparation)
6. [Editorial Feature Pitch](#6-editorial-feature-pitch-optional-but-recommended)
7. [Submission Gate Checklist](#7-submission-gate-checklist)

---

## 1. ASO Keyword Strategy

### 1.1 Keyword Tiering

Keywords are organized by search intent and conversion likelihood. Tier 1 are high-intent
core terms; Tier 2 are differentiated long-tail; Tier 3 are discovery/broad terms.

| Tier | Keyword | Intent | Strategy |
|------|---------|--------|----------|
| **1 — Core** | stress monitor | High | Primary. Title-anchored. |
| **1 — Core** | stress tracker | High | Primary. Subtitle-anchored. |
| **1 — Core** | HRV / heart rate variability | Med-High | Differentiator (science). |
| **1 — Core** | stress management | Med | Category term. |
| **1 — Core** | wellbeing | Low-Med | Broad umbrella. |
| **1 — Core** | Apple Watch stress | High | Platform-specific intent. |
| **2 — Diff.** | stress relief | Med | Action intent. |
| **2 — Diff.** | breathing exercise | High | Feature-specific. |
| **2 — Diff.** | meditation breathing | Med | Adjacent category. |
| **2 — Diff.** | health companion | Low | Broad. |
| **2 — Diff.** | recovery score | Med | Biohacker audience. |
| **2 — Diff.** | mood tracker | Med | Adjacent audience overlap. |
| **3 — Discovery** | mindfulness | Med | Discovery, competitive. |
| **3 — Discovery** | wellness | Low | Very broad, low conversion. |
| **3 — Discovery** | self care | Med | Discovery. |
| **3 — Discovery** | calm | Low | Competitor name, avoid in 100-char field. |

### 1.2 The 100-Character Keyword Field

The invisible 100-char keyword field is comma-separated, no spaces between terms, no plural
duplicates (Apple's algorithm stems). Avoid category names already in title/subtitle (they
double-count and waste characters). Do NOT include competitor names like "calm", "gentler",
"welltory" — risk of rejection under Guideline 2.3.10 and no ranking benefit.

```
hrv,heart rate variability,recovery,box breathing,relaxation,mindfulness,wellness,self care,stress relief,meditation breathing,health companion,mood,vitals,biofeedback
```

That is 99 characters. Reserved space for one more 1-char swing; leave as-is for safety.

### 1.3 Title & Subtitle Allocation (30 / 30 char limits)

The Title and Subtitle carry the heaviest ASO weight. They must read naturally AND carry
the two top keywords.

| Field | Content | Chars | Keywords carried |
|-------|---------|-------|------------------|
| **App Name** (30 max) | `StressMonitor: HRV & Stress` | 26 | stress, HRV |
| **Subtitle** (30 max) | `Track stress. Breathe. Relax.` | 29 | stress, breathe, relax |

> Name choice rationale: the brand `StressMonitor` is non-negotiable (brand recognition),
> then `HRV & Stress` injects the single highest-differentiation keyword (`HRV`) next to the
> core category word (`stress`). Avoid stuffing `Apple Watch` in the name — it reads as spam
> and Apple often flags platform names in titles.

### 1.4 Promotional Text (170 chars, re-indexed weekly, no re-review needed)

Use this slot for time-sensitive hooks and to rotate keyword phrases between updates:

```
NEW: Meet Ripple the Water Otter — your stress companion who reacts to how you feel in real time. 5-factor stress science, 100% on-device. No scores, just calm. 🌊
```

### 1.5 Keyword Mapping Summary

| Slot | Size | Priority content |
|------|------|------------------|
| App Name | 30 | Brand + #1 keyword |
| Subtitle | 30 | #2 keyword + action verb |
| 100-char field | 100 | Long-tail + adjacent categories (no duplicates of title/subtitle) |
| Promotional Text | 170 | Rotating hook, weekly re-index |
| Description | 4000 | Natural keyword density (see `app-description.md`) |

> **ASO discipline:** Re-evaluate keyword performance 14 days after launch using App Store
> Connect → Analytics → Impressions + Conversion. Demote terms with <2% conversion, promote
> terms with >8%.

---

## 2. App Store Screenshot Specifications

Apple Editorial judges apps heavily on screenshot quality — they are the first thing a
reviewer and a user see. Screenshots must be **device-accurate, locally rendered from the
real app** (never Figma mockups passed off as in-app), and tell a visual story across the
gallery.

### 2.1 Required Device Sizes (verify against current App Store Connect at submission)

> ⚠️ Apple updates the required/optional device list periodically. Confirm the current set in
> App Store Connect → App Information → Screenshots before exporting. The set below reflects
> the 2024–2025 generation of required and recommended sizes.

| Device Class | Dimensions (portrait, px) | Status | Notes |
|--------------|---------------------------|--------|-------|
| **6.9" iPhone** (16 Pro Max) | 1320 × 2868 | Required (newest) | Becoming default required size. |
| **6.7" iPhone** (14/15 Plus, Pro Max) | 1290 × 2796 | Required | Primary deliverable. |
| **6.5" iPhone** (11 Pro Max / XS Max) | 1242 × 2688 | Required | Can reuse 6.7" artwork (Apple auto-scales within class). |
| **6.1" iPhone** (14/15 Pro) | 1179 × 2556 | Recommended | Covers Pro-sized devices. |
| **5.5" iPhone** (legacy) | 1242 × 2208 | Optional | Only if supporting older devices. |
| **iPad 13"** (M4 13" / 12.9") | 2064 × 2752 | Required if iPad | 2048×2732 acceptable for older 12.9". |
| **Apple Watch** | Per App Store Connect watch section | Required for companion | Use watchOS Simulator export. |

### 2.2 Screenshot Production Workflow

All screenshots are captured from the **running app on Simulator/physical device** at the
exact resolution, then lightly composited (caption overlay only) in Figma. No fabricated UI.

1. Boot target Simulator (e.g. iPhone 15 Pro Max for 6.7").
2. Launch StressMonitor in release configuration (`xcode_build` Release).
3. Navigate to each hero screen; capture via `simulator_screenshot`.
4. Composite caption + brand treatment in a Figma template sized to the device.
5. Export PNG at exact pixel dimensions. Do NOT scale — Apple rejects off-size uploads.
6. Repeat for 6.9", 6.1", and iPad where required.

### 2.3 Screenshot Gallery Storyboard (10 frames recommended)

The first 3 screenshots carry ~80% of conversion weight. Lead with the differentiator
(character) and privacy, not generic dashboards.

| # | Screen | Caption (short, benefit-led) | Visual Focus |
|---|--------|------------------------------|--------------|
| 1 | **Home with Ripple** (Relaxed state) | "Meet Ripple — your stress shows on her face, not a score." | Character-reactive hero. |
| 2 | **Ripple stressed state** | "She knows before you do. Watch her react in real time." | Character evolution/states. |
| 3 | **Privacy card** | "Everything stays on your device. No accounts. No tracking." | Privacy pillar. |
| 4 | **Trends / weekly dot-matrix** | "See your week at a glance." | Trend analytics. |
| 5 | **Box breathing** | "Breathe with the rhythm. 4-4-4-4 box breathing." | Action feature. |
| 6 | **Apple Watch complication** | "Glance at your wrist. Standalone watch app." | Watch integration. |
| 7 | **Character collection** | "Collect 5 elemental companions. They grow with you." | Gamification/retention. |
| 8 | **AI insights / chat** | "Ask anything. On-device intelligence." | AI feature. |
| 9 | **Factor breakdown** | "Backed by 5 real health signals — HRV, sleep, and more." | Science credibility. |
| 10 | **Settings / data export** | "Your data. Export or erase it anytime." | User control. |

### 2.4 Caption Design Rules

- Max 5 words per caption. Scannable.
- Captions sit in the top 25% of the frame so they survive the cropped "preview" thumbnails.
- Use StressMonitor stress-level color accents (Relaxed #34C759, Mild #007AFF) — never red.
- Font: Roboto (matches in-app type system) for brand consistency.
- Avoid screenshots full of text/numbers — character-reactive visuals outperform score-heavy
  frames in testing and align with the "no scary scores" brand position.

### 2.5 App Preview Video (optional but strongly recommended for Editorial)

- **Length:** 15–30 seconds (30s max). Lead with the character within the first 2 seconds.
- **Format:** H.264, MOV/MP4/M4V, portrait orientation to match screenshots.
- **Content arc:** Ripple calm → user triggers a reading → Ripple shifts state → breathing
  exercise calms her back down → end on privacy lockup + app name.
- Apple Editorial frequently requires a preview video to consider an app for Today-tab
  featuring. Prioritize producing this.

---

## 3. Privacy Messaging Copy

Privacy is StressMonitor's strongest Editorial lever and the most scrutinized Review area
(HealthKit + cloud). The copy below is approved-ready and consistent across all surfaces.

### 3.1 One-Line Privacy Promise (App Store "What's New" / promo)

```
Your health data never leaves your device. No accounts, no tracking, no ads — ever.
```

### 3.2 Privacy Section (App Store Description)

```
BUILT PRIVACY-FIRST

• On-device first. Every measurement is computed on your iPhone. Your raw health data
  stays where it belongs — on your device.
• End-to-end encrypted sync. Optional iCloud sync is protected by CloudKit end-to-end
  encryption. Even Apple can't read it.
• No third-party analytics. Zero. No SDKs, no advertising identifiers, no behavior
  tracking, no selling data.
• No account required. Use the full app without ever creating an account.
• You're in control. Export your data anytime as CSV/JSON, or erase it completely.

The only thing that ever leaves your device is fully anonymized chat context for the
optional AI assistant — never your health readings.
```

### 3.3 HealthKit Access Prompts (user-facing copy)

These strings appear in the iOS permission dialog and must explain *why* each data type is
needed. Apple rejects vague justifications under Guideline 5.1.1.

| Data Type | Copy |
|-----------|------|
| Heart Rate Variability | "StressMonitor reads your Heart Rate Variability to detect how your body is responding to stress today." |
| Heart Rate | "We read resting heart rate to compare against your personal baseline and improve accuracy." |
| Sleep | "Sleep quality is a core factor in your stress score — we read it to give you a complete picture." |
| Activity / Movement | "Activity data helps distinguish exercise energy from stress energy." |

### 3.4 App Privacy "Nutrition Label" Mapping

See [Section 5.2](#52-app-privacy-details-nutrition-labels) for the full data-collection
declarations. The TL;DR for marketing: **"Data Not Collected" for tracking, "Data Linked to
You = None," Data Used for App Functionality only.** This is a major Editorial selling point.

---

## 4. Accessibility Audit Checklist

StressMonitor targets **WCAG AA** and full iOS accessibility support. Apple Editorial
explicitly rewards accessible apps. Run this checklist against every shipping screen before
submission. See `docs/design-guidelines.md` § Accessibility for the canonical spec.

### 4.1 VoiceOver

- [ ] Every interactive element has a meaningful `accessibilityLabel`.
- [ ] The **character (Ripple)** announces state, not a number — e.g. "Ripple feels calm,"
      not "Stress level 18." (Aligns with the character-reactive brand position.)
- [ ] Stress level colors have a text/icon alternative announced to VoiceOver (dual coding).
- [ ] Decorative images have `accessibilityHidden(true)`.
- [ ] Custom controls expose `accessibilityValue`, `accessibilityTraits`.
- [ ] Chart data is summarized via `accessibilityLabel` (e.g. "Weekly trend: mostly calm").

### 4.2 Dynamic Type

- [ ] All text uses `Font.Wellness` tokens, NOT hardcoded `.font(.system(size:))` values.
      (Known debt: 264 raw `.system(size:)` calls per the design-system audit — must be
      resolved for AA compliance.)
- [ ] Layout remains usable at **AX5** (largest accessibility size) — no truncation, no
      overlap, no clipped controls.
- [ ] Touch targets remain ≥44×44 pt at all Dynamic Type sizes.

### 4.3 Color & Contrast (WCAG AA: 4.5:1 text, 3:1 large/UI)

- [ ] Body text contrast ≥4.5:1 against background in **both** light and dark mode.
- [ ] Stress-level colors pass contrast as text OR are always paired with an icon + label.
- [ ] No information conveyed by color alone (dual coding enforced).
- [ ] Dark mode verified: no hardcoded `Color.white` backgrounds (known debt flagged in
      design audit — resolve before submission).
- [ ] Color-blind safe: red/green stress states also distinguishable by icon shape.

### 4.4 Motion & Haptics

- [ ] Respect **Reduce Motion** (`@Environment(\.accessibilityReduceMotion)`): disable
      large parallax/character animations, provide crossfade fallback.
- [ ] Respect **Reduce Transparency** for blurred backgrounds.
- [ ] Haptic feedback present for primary actions (measure, complete breathing, unlock).

### 4.5 Keyboard / Switch Control

- [ ] Full keyboard navigation possible (Tab order logical, focus visible).
- [ ] Switch Control accessible for all primary flows.

### 4.6 Audit Sign-off

- [ ] Run Xcode **Accessibility Inspector** on all 5 tabs → 0 critical issues.
- [ ] Manual VoiceOver pass on iPhone (not just Simulator).
- [ ] Dynamic Type AX5 walkthrough on the smallest supported device.

---

## 5. App Store Review Preparation

### 5.1 App Review Guidelines — Compliance Map

Map each applicable Apple guideline to StressMonitor's compliance posture so the reviewer
(and Editorial team) see no ambiguity.

| Guideline | Topic | StressMonitor Posture | Risk |
|-----------|-------|----------------------|------|
| **1.1** | Objectionable content | Wellness app, no UGC. | None. |
| **1.4.1** | Harmful apps | Not medical device; no diagnoses. Add **"not for medical use"** disclaimer. | Low — add disclaimer. |
| **2.1** | App completeness | Resolve Blocker B3 (test suite) before submit. | **Medium** — incomplete = rejection. |
| **2.3.10** | Irrelevant metadata | Keywords are relevant, no competitor names, no price mentions. | None. |
| **2.5.1** | API use | System frameworks only (HealthKit/CloudKit/SwiftData). No private APIs. | None. |
| **2.5.4** | Multitasking | Background refresh within allowed budgets. | None. |
| **4.0** | Design | Polished, accessible, character-driven. Editor-friendly. | Strength. |
| **4.2.1** | Minimum functionality | Full feature set, not a marketing shell. | None. |
| **4.3** | Spam | Genuine differentiated app. | None. |
| **5.1.1** | Data collection | HealthKit read-only with clear purpose strings. | Low. |
| **5.1.2** | Data use | No third-party sharing. | None. |
| **5.1.5** | Location | Not used. | None. |
| **5.2.1** | Health/fitness data | HealthKit, with clear consent. **Not a medical device.** | Medium — disclaimer. |

### 5.2 App Privacy Details ("Nutrition Labels")

Declare in App Store Connect → App Privacy. StressMonitor's posture is unusually clean —
lean into it.

**Data Linked to You:**
- None. StressMonitor does **not** link any data to your identity.

**Data Used to Track You:**
- None. No advertising ID, no tracking SDK.

**Data Not Collected (data used for App Functionality only, on-device):**

| Data Type | Purpose | Linked to Identity | Used for Tracking |
|-----------|---------|--------------------|------------------|
| Health & Fitness (HRV, HR, Sleep, Activity) | App Functionality (stress calculation) | No | No |
| Identifiers (anonymous chat session ID) | App Functionality (AI chat) | No | No |
| Usage Data | None collected | — | — |
| Diagnostics | None collected | — | — |

> Optional AI chat transmits only anonymized conversation context to a server (Supabase Edge
> Functions, or Apple Intelligence on-device for iOS 26+). No health data is transmitted.
> If Supabase endpoint is used, declare it under the relevant privacy policy section.

### 5.3 Age Rating

- **Rating:** 4+ (no objectionable content, no unrestricted web access).
- Unrestricted Web Access: No (AI chat is bounded, not a general browser).
- Gambling: No. Medical advice: No (wellness only — reinforce with disclaimer).

### 5.4 Medical Disclaimer (REQUIRED — add to app + description)

```
StressMonitor is a wellness and mindfulness tool. It is not a medical device, does not
diagnose any condition, and is not a substitute for professional medical advice. Stress
readings are informational. Consult a healthcare professional for medical concerns.
```

This protects against rejection under Guideline 1.4.1 / 5.2.1 and clarifies the app is not
making health claims.

### 5.5 Category & Content

- **Primary Category:** Health & Fitness
- **Secondary Category:** Lifestyle (or Medical — but Health & Fitness is safer; Medical
  invites stricter review).
- **Content Rights:** Confirm all 75 character illustrations are original or properly
  licensed (they are — in-house designed).

### 5.6 App Review Information (reviewer-facing)

Provide in the Review Notes field:

- Test account: Not required (no account system). Note: "No login required — all features
  accessible immediately. To test stress calculation, grant HealthKit access."
- Demo flow: "1) Allow HealthKit. 2) Tap Measure. 3) Watch Ripple react. 4) Open Breathing.
  5) Open Apple Watch app (if reviewer has one)."
- Contact: [Phuong's developer contact email]
- Demo video link (optional but speeds review): link to unlisted walkthrough.

### 5.7 Version & Build

- Version: **1.0.0** (initial release).
- Build: increment per TestFlight upload (1.0.0 (1), (2), ...).
- SDK: Latest iOS SDK. Minimum deployment: iOS 17.0.
- Export compliance: App uses standard encryption only (HealthKit/CloudKit exempt) → answer
  "No" to custom encryption on upload, or document exemption.

---

## 6. Editorial Feature Pitch (optional but recommended)

To be considered for **App of the Day / Today tab**, pitch Apple Editorial directly after
launch (via the App Store Connect "Promote Your App" / editorial request, or an Apple PR
contact). The pitch should hit the three Editorial pillars.

### 6.1 Pitch One-Pager

```
SUBJECT: StressMonitor — App of the Day candidate (privacy-first stress companion)

THE STORY
StressMonitor turns raw heart data into something you can feel — not a number that scares
you. Meet Ripple, a water otter whose expression shifts with your stress in real time.
She's calm when you're calm, hides in her shell when you're overwhelmed. It's stress
awareness without the anxiety of a score.

WHY IT'S EDITORIAL-WORTHY
1. DESIGN: A living character collection (5 elemental creatures, 3 evolution stages, 75
   illustrations) that makes stress tracking feel warm, not clinical. Character-reactive
   visualization — a genuinely novel approach.
2. PRIVACY: "Data Not Collected." Everything runs on-device. Optional end-to-end encrypted
   iCloud sync. No third-party analytics, no accounts, no tracking. Industry-leading.
3. ACCESSIBILITY: Full VoiceOver, Dynamic Type, WCAG AA. The character is accessible to
   screen readers — Ripple's state is announced, not just shown.

SCIENCE (credibility)
A genuine 5-factor algorithm using Heart Rate Variability, heart rate, sleep, activity, and
recovery — not a random number generator. Personal baseline adapts over 30 days.

PLATFORM
iPhone + standalone Apple Watch app + home-screen widgets + complications. Built with zero
third-party dependencies — pure Apple frameworks.

LAUNCH: June 2026. Happy to provide assets, a preview build, or an interview.
```

### 6.2 Editorial Asset Pack (prepare on request)

- App icon (1024×1024, also 120/180 for inline).
- 3 hero screenshots at full res.
- 15–30s preview video (see 2.5).
- Founder quote / short bio (Phuong Doan).
- Press-quality character art (Ripple in all 5 stress states).

---

## 7. Submission Gate Checklist

Do NOT submit until every box is checked. This is the final gate.

### Pre-Submission (Engineering)
- [ ] **B3 resolved** — comprehensive test suite passing (current blocker).
- [ ] No `print()` statements / debug logging in Release build.
- [ ] Build succeeds in Release configuration with no warnings-as-errors failures.
- [ ] Dark mode fully verified (no hardcoded `Color.white` backgrounds — see design audit).
- [ ] Typography tokens enforced (no raw `.font(.system(size:))` — known debt).

### App Store Connect (Metadata)
- [ ] App Name, Subtitle, 100-char keywords entered.
- [ ] Description finalized (see `app-description.md`).
- [ ] Promotional text entered.
- [ ] Screenshots uploaded for all required device sizes.
- [ ] App Privacy nutrition label fully declared.
- [ ] HealthKit usage strings reviewed and accurate.
- [ ] Medical disclaimer present in description + in-app.
- [ ] Age rating set to 4+.
- [ ] Categories set (Health & Fitness primary).
- [ ] Copyright / version / build configured.
- [ ] Export compliance answered.
- [ ] Review Notes + demo flow filled in.

### Quality Gates
- [ ] Accessibility Inspector: 0 critical issues across all 5 tabs.
- [ ] VoiceOver manual pass on physical device.
- [ ] Dynamic Type AX5 walkthrough passes.
- [ ] No crashes across a 7-day TestFlight beta.
- [ ] Privacy posture verified: no unexpected network calls (audit with Instruments/
      Charles).

### Post-Approval
- [ ] Phased release enabled (1% → 100% over 7 days).
- [ ] Crash reporting monitored (MetricKit / TestFlight).
- [ ] ASO performance reviewed at 14 days (App Store Connect Analytics).
- [ ] Editorial pitch sent (if pursuing Today-tab feature).

---

**Appendix — Key Brand Facts (for any writer/designer producing assets)**

- **App name:** StressMonitor
- **Primary character:** Ripple — 💧 Water Otter (blue #4FC3F7). Relaxation & calm.
- **Ripple evolution:** Droplet (#81D4FA) → Ripple (#4FC3F7) → Tidal (#0288D1).
- **Full roster:** Ripple (Water Otter), Blossom (Forest Fox), Ember (Fire Phoenix), Zephyr
  (Cloud Rabbit), Lumi (Moon Owl).
- **Stress algorithm:** 5 factors — HRV (35%), Heart Rate (25%), Sleep (20%), Activity
  (10%), Recovery (10%).
- **Stress states:** Relaxed, Mild, Moderate, High. Colors: #34C759, #007AFF, #FFD60A,
  #FF9500.
- **Platform:** iOS 17+ / watchOS 10+. Pure Apple frameworks, zero third-party dependencies.
- **Privacy posture:** On-device first, E2E CloudKit sync, no third-party analytics, no
  accounts required.
- **Brand position:** "No scores, just calm." Stress awareness through a living companion,
  not clinical numbers.
