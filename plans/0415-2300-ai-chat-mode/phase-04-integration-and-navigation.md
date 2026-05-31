# Phase 4: Integration & Navigation

**Priority:** High
**Status:** Pending
**blockedBy:** Phase 3 (ChatBottomSheetView, ChatViewModel), cross-plan `0415-2219-aichat-card-figma-alignment`

## Context Links

- Design report: [brainstorm-0415-2300-ai-chat-mode-design.md](../reports/brainstorm-0415-2300-ai-chat-mode-design.md)
- Phase 3 output: `ChatBottomSheetView`, `ChatViewModel`, `ChatMessageAdapter`, `QuickActionChipsView`
- File to modify: `Views/Action/ActionView.swift`
- Cross-plan dependency: `0415-2219-aichat-card-figma-alignment` modifies `ActionView.swift` and `AIChatCard.swift`
- ViewModel access pattern: `StressViewModel` holds stress data needed for `ChatContext`
- Navigation pattern: `.sheet` for overlays (per project conventions)

## Overview

Wire `ChatBottomSheetView` into `ActionView` by replacing the `// TODO: Navigate to AI chat screen` comment with sheet presentation. Build `ChatContext` from current stress data available in the view hierarchy. This is the final integration phase.

## Key Insights

- `ActionView` is a struct view (not `@Observable`). State managed via `@State` properties.
- The `AIChatCard` already has `onTap` callback -- just need to set a `@State var showChatSheet = false`.
- `ChatContext` requires `StressResult`, `PersonalBaseline`, etc. These live in `StressViewModel`.
- `ActionView` currently does NOT hold a reference to `StressViewModel`. Need to determine how stress data flows to ActionView.
- Options: (A) Pass `StressViewModel` as dependency to `ActionView`, (B) Pass only `ChatContext` as dependency, (C) Build `ChatContext` inside ActionView's sheet builder.
- Best option: (B) -- `ActionView` receives a pre-built `ChatContext` or the raw data to build one, keeping the dependency minimal.
- The sheet must build `ChatContext` at presentation time (lazy) so data is fresh.

## Requirements

### Functional

- Tapping "Chat with StressCat" button on AIChatCard presents chat bottom sheet
- Sheet builds `ChatContext` from current stress data at presentation time
- Dismissing sheet cancels any in-progress LLM stream
- Chat sheet has drag-to-dismiss gesture
- Accessibility: VoiceOver announces sheet presentation

### Non-Functional

- `ActionView` does NOT import exyte/Chat -- only `ChatBottomSheetView` and `ChatContext`
- Sheet builder creates fresh `ChatViewModel` each presentation (no stale state)
- No retain cycles between ActionView and sheet content
- Minimal changes to existing ActionView code (only aiChatCard section)

## Architecture

```
ActionView
    |  @State showChatSheet: Bool = false
    |  chatContext: ChatContext (built from stress data)
    |
    |  AIChatCard onTap: { showChatSheet = true }
    |  .sheet(isPresented: $showChatSheet) {
    |      ChatBottomSheetView(context: chatContext)
    |  }
    v
ChatBottomSheetView (Phase 3)
```

## Related Code Files

### To Modify

1. `StressMonitor/StressMonitor/Views/Action/ActionView.swift` - Add sheet state, wire AIChatCard tap, present ChatBottomSheetView

### To Create

None.

### To Delete

None.

## Implementation Steps

1. **Determine how stress data reaches ActionView**
   - Read `MainTabView.swift` to see how `ActionView` is instantiated
   - Read parent view hierarchy to find where `StressViewModel` lives
   - Determine if `ActionView` needs a new property or if data is already accessible

2. **Add ChatContext construction to ActionView**
   - Add computed property or method to build `ChatContext` from available stress data
   - If `StressViewModel` is not accessible: add a `chatContext: ChatContext` parameter with default empty context, or pass stress data properties individually
   - Graceful: empty `ChatContext` is valid (LLM still works, just without health context)

3. **Wire sheet presentation in ActionView**
   - Add `@State private var showChatSheet = false`
   - In `aiChatCard` computed property, replace `// TODO: Navigate to AI chat screen` with `showChatSheet = true`
   - Add `.sheet(isPresented: $showChatSheet)` modifier to the `NavigationStack` or outermost container
   - Sheet content: `ChatBottomSheetView(context: buildChatContext())`
   - Build context lazily inside sheet builder closure

4. **Test end-to-end flow**
   - Build and run on simulator
   - Navigate to Action tab
   - Tap AI Chat card
   - Verify sheet presents
   - Verify "Requires iOS 26" message on current simulator (iOS 18)
   - Dismiss sheet via drag
   - Verify no crashes or memory warnings

5. **Accessibility pass**
   - AIChatCard tap announces to VoiceOver
   - Sheet dismissal accessible
   - Quick action chips accessible

## Todo

- [ ] Read MainTabView to determine stress data flow to ActionView
- [ ] Add `@State showChatSheet` to ActionView
- [ ] Add `ChatContext` construction in ActionView
- [ ] Replace TODO in `aiChatCard` with `showChatSheet = true`
- [ ] Add `.sheet` modifier presenting `ChatBottomSheetView`
- [ ] End-to-end manual test on simulator
- [ ] Accessibility verification

## Success Criteria

- Tapping AIChatCard presents ChatBottomSheetView as sheet
- Sheet shows "Requires iOS 26" placeholder on current simulators
- Sheet dismisses via drag gesture
- No compiler warnings
- No exyte/Chat imports in ActionView
- ActionView changes <30 lines added
- End-to-end flow works without crashes
- VoiceOver accessible

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Cross-plan `0415-2219` not complete, ActionView.swift conflict | Medium | High | Wait for cross-plan to merge before starting Phase 4 |
| Stress data not accessible from ActionView | Low | Medium | Pass ChatContext as parameter or use empty context as fallback |
| Sheet presentation conflicts with NavigationStack | Low | Medium | Attach .sheet to NavigationStack, not ScrollView |

## Security Considerations

- No changes to data security model
- Sheet presentation does not persist any new data
- ChatContext built fresh each time -- no stale data leaks

## Next Steps

- Feature complete after this phase
- Future: Phase 2 cloud LLM for iOS 17-25 device support
- Future: Chat persistence (SwiftData) as Pro feature
- Future: Backend proxy for cloud LLM API key security
