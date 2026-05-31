---
name: AI Chat Card Figma Alignment
status: planning
created: 2026-04-15
author: phuongddx
blockedBy: []
blocks: []
---

# AI Chat Card — Figma Alignment

Enhance AIChatCard to match Figma design exactly. Download cat mascot as PDF.

## Overview

| Priority | Effort | Files |
|----------|--------|-------|
| Medium | Small | 3 files |

**Figma source**: `EHvjgTBOvThoVuk0cyE6tp` node `3365-9941`

## Problem

1. `AIChatCard.swift` — placeholder `cat.fill` system icon, Roboto fonts (Figma uses Lato)
2. `ActionView.swift` — has its own inline `aiChatCard` that ignores the `AIChatCard` component entirely (uses emoji cat)
3. No AI Kitten mascot asset exists — need to download from Figma as PDF

## Solution

### Phase 1: Download Mascot Asset

- Use Figma MCP `download_figma_images` to get the cat mascot group (node `3365:9976`) as PDF
- Save to `Assets.xcassets/AIKitten.imageset/` with proper `Contents.json`
- PDF preserves vector representation at all scales (matches existing TabBar icon pattern)

**Node to download**: `3365:9976` (Group 1000003372 — the main cat mascot group containing all sub-layers)

### Phase 2: Update AIChatCard.swift

Match Figma pixel-perfectly:

| Element | Current | Target |
|---------|---------|--------|
| Cat mascot | `Image(systemName: "cat.fill")` | `Image("AIKitten")` asset, 128x128pt |
| Title font | Roboto-Bold 24px | Lato-Bold 24px (or system `.bold` if Lato unavailable) |
| Subtitle font | Roboto-Regular 14px | Lato-Regular 14px |
| Description font | Roboto-Regular 13px | Lato-Regular 13px |
| Button font | Roboto-Medium 14px | Lato-SemiBold 14px |
| Disclaimer font | Roboto-Regular 10px | SF Pro Rounded 10px (system `.rounded` weight) |
| Layout | Mascot offset workaround | Clean ZStack: mascot top-right, content left |
| Button bg | `Color.accentTeal` | `#85C9C9` (verify `accentTeal` matches) |
| Disclaimer link | `Color(hex: "A231CF")` | `Color(hex: "808080")` per Figma |

### Phase 3: Integrate into ActionView

Replace inline `aiChatCard` property (lines 342-380) with:

```swift
AIChatCard(onTap: { /* navigate to chat */ })
```

Remove dead inline implementation.

## Files to Modify

| File | Action |
|------|--------|
| `Assets.xcassets/AIKitten.imageset/` | **Create** — PDF mascot + Contents.json |
| `Views/Dashboard/Components/AIChatCard.swift` | **Update** — real mascot, correct fonts, clean layout |
| `Views/Action/ActionView.swift` | **Update** — use `AIChatCard` component, remove inline version |

## Success Criteria

- [ ] AIChatCard renders with real cat mascot from Figma
- [ ] Layout matches Figma node `3365-9941` (358pt card, proper spacing)
- [ ] CTA button "Chat with StressCat" works
- [ ] Disclaimer text centered at bottom
- [ ] ActionView uses `AIChatCard` component (no inline duplicate)
- [ ] Builds without errors

## Risk

| Risk | Mitigation |
|------|------------|
| Lato font not bundled | Fall back to system San Francisco — visually close enough |
| Cat mascot SVG too complex for PDF | Download as PNG @ 3x scale if PDF fails |
| `accentTeal` color mismatch | Verify against Figma `#85C9C9`, update if needed |

## Next Steps

- Implement phase 1 (asset download) first
- Then phases 2-3 can be done together
