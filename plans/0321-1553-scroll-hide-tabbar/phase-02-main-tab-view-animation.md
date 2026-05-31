# Phase 2: MainTabView Animation

<!-- Completed: 2026-03-21 -->

## Overview
- **Priority**: High (depends on Phase 1)
- **Status**: ✅ completed
- **Effort**: 20m

## Context
Current `MainTabView.swift` structure:
```swift
ZStack(alignment: .bottom) {
    NavigationStack { /* tab content */ }
    if !showSettings {
        AnimatedTabBar(...)
            .verticalPadding(16)
            .cornerRadius(24)
            .buttonShadow()
            .padding(.horizontal, 16)
    }
}
```

## Changes to `MainTabView.swift`

### 1. Add state
```swift
@State private var tabBarScrollState = TabBarScrollState()
```

### 2. Capture tab bar height
```swift
// Wrap AnimatedTabBar with height reader
AnimatedTabBar(...)
    // ...existing modifiers...
    .background(
        GeometryReader { proxy in
            Color.clear.onAppear {
                tabBarScrollState.tabBarHeight = proxy.size.height
            }
        }
    )
```

### 3. Add slide animation
```swift
AnimatedTabBar(...)
    // ...existing modifiers...
    .offset(y: tabBarScrollState.isVisible ? 0 : tabBarScrollState.tabBarHeight + 16)
    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: tabBarScrollState.isVisible)
```

The `+ 16` accounts for the `.padding(.horizontal, 16)` — ensures bar fully clears the screen edge.

### 4. Reset on tab switch
```swift
// In selectedIndex Binding setter, after updating selectedTab:
tabBarScrollState.resetToVisible()
```

### 5. Inject into environment
```swift
NavigationStack { ... }
    .environment(tabBarScrollState)
```

## Full updated body diff (key additions marked with ←)
```swift
@State private var tabBarScrollState = TabBarScrollState()   // ←

var body: some View {
    ZStack(alignment: .bottom) {
        NavigationStack { ... }
            .environment(tabBarScrollState)   // ←

        if !showSettings {
            AnimatedTabBar(...)
                .selectedColor(.primaryBlue)
                .unselectedColor(.tabBarUnselected)
                .ballColor(.primaryBlue)
                .ballTrajectory(.straight)
                .verticalPadding(16)
                .cornerRadius(24)
                .buttonShadow()
                .padding(.horizontal, 16)
                .background(GeometryReader { proxy in   // ←
                    Color.clear.onAppear {
                        tabBarScrollState.tabBarHeight = proxy.size.height
                    }
                })
                .offset(y: tabBarScrollState.isVisible   // ←
                    ? 0
                    : tabBarScrollState.tabBarHeight + 16)
                .animation(                              // ←
                    .spring(response: 0.3, dampingFraction: 0.8),
                    value: tabBarScrollState.isVisible
                )
        }
    }
}
```

### selectedIndex binding update
```swift
private var selectedIndex: Binding<Int> {
    Binding(
        get: { selectedTab.rawValue },
        set: { newValue in
            guard newValue != selectedTab.rawValue else { return }
            previousTab = selectedTab
            selectedTab = TabItem(rawValue: newValue) ?? .home
            HapticManager.shared.buttonPress()
            tabBarScrollState.resetToVisible()   // ←
        }
    )
}
```

## Todo
- [x] Add `@State private var tabBarScrollState` to `MainTabView`
- [x] Add `.environment(tabBarScrollState)` to `NavigationStack`
- [x] Add height capture via `GeometryReader` background on `AnimatedTabBar`
- [x] Add `.offset(y:)` + `.animation()` modifiers
- [x] Add `tabBarScrollState.resetToVisible()` in tab switch binding
- [x] Build & verify animation works in simulator
