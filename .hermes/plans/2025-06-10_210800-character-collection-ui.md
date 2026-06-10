# Character Collection UI — Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Implement the full character collection UI system for StressMonitor iOS — from data models to SwiftUI views, animations, evolution, and Watch integration.

**Architecture:** MVVM with `@Observable` ViewModels, SwiftData for persistence, SVG assets in Asset Catalog. Characters extend the existing `StressBuddyMood` + `CharacterCreature` + `CharacterUnlock` models. New `CharacterCollection` tab added to `MainTabView`.

**Tech Stack:** SwiftUI, SwiftData, iOS 17+, WatchKit, Lottie (optional), SF Symbols

**Branch:** `feature/character-collection-ui`
**Task:** `t_c65b16d4`
**Base:** `main` on `NextGen-Limited/ios-stress-app`

---

## Current State

### What Already Exists
- `StressBuddyMood` — 5 mood states (sleeping/calm/concerned/worried/overwhelmed) with stress level mapping
- `CharacterCreature` — Static catalog of 5 creatures (Ripple, Blossom, Ember, Zephyr, Lumi) with elements, unlock types
- `CharacterUnlock` — SwiftData `@Model` tracking unlock status, evolution progress, streak days
- `StressCharacterCard` — Dashboard hero card showing current character with mood
- `StressBuddyIllustration` — SVG-based character rendering (currently 1 generic buddy)
- `CharacterAnimationModifier` — Per-mood animations (breathing, fidget, shake, dizzy)
- 5 SVG assets: `CharacterSleeping`, `CharacterCalm`, `CharacterConcerned`, `CharacterWorried`, `CharacterOverwhelmed`
- `PremiumState` singleton, `PremiumLockOverlay`, `StoreKitServiceProtocol`
- Watch `ComplicationBundle` with Circular/Rectangular/Inline providers
- `DesignTokens`, `Color+Wellness`, `Spacing`, `Typography`, `GlassCard` design system
- 3-tab `MainTabView` (home/action/trend) with `AnimatedTabBar`

### What's Missing
- Per-character SVG assets (currently 1 generic buddy for all states)
- Character collection grid view (new tab or section)
- Character detail view with stats + evolution timeline
- Per-character stress-reactive rendering
- Character picker on Dashboard
- Evolution celebration animation
- Unlock flow UI (free/premium/streak gates)
- Watch character-specific complications
- Asset resolver (character × evolution × mood → correct SVG)

---

## Phase 1: Asset Pipeline & Resolver

### Task 1.1: Define Asset Naming Convention

**Objective:** Document the naming convention for all character SVG assets.

**Files:**
- Create: `docs/design/ASSET_NAMING.md`

**Step 1: Write the convention document**

```markdown
# Character Asset Naming Convention

## Pattern
`{characterId}_{evolution}_{mood}`

## Examples
- `ripple_droplet_sleeping` — Baby Ripple sleeping
- `ripple_ripple_calm` — Teen Ripple calm
- `ripple_tidal_overwhelmed` — Adult Ripple overwhelmed

## Total Assets: 75 (5 characters × 3 evolutions × 5 moods)

## Asset Catalog Groups
- `Characters/Ripple/` — 15 images
- `Characters/Blossom/` — 15 images
- `Characters/Ember/` — 15 images
- `Characters/Zephyr/` — 15 images
- `Characters/Lumi/` — 15 images

## Fallback: If specific asset missing, use {characterId}_droplet_calm
```

**Step 2: Commit**

```bash
git add docs/design/ASSET_NAMING.md
git commit -m "docs: define character asset naming convention"
```

---

### Task 1.2: Create Asset Resolver Service

**Objective:** Build a service that maps (characterId, evolution, mood) → correct asset name with fallback.

**Files:**
- Create: `StressMonitor/StressMonitor/Services/CharacterAssetResolver.swift`
- Test: `StressMonitor/StressMonitorTests/CharacterAssetResolverTests.swift`

**Step 1: Write failing tests**

```swift
// StressMonitorTests/CharacterAssetResolverTests.swift
import Testing
@testable import StressMonitor

struct CharacterAssetResolverTests {
    
    @Test("Resolves full asset name for valid combination")
    func resolvesFullAssetName() {
        let name = CharacterAssetResolver.assetName(
            characterId: "ripple",
            evolution: .droplet,
            mood: .calm
        )
        #expect(name == "ripple_droplet_calm")
    }
    
    @Test("Resolves tidal overwhelmed asset")
    func resolvesTidalOverwhelmed() {
        let name = CharacterAssetResolver.assetName(
            characterId: "ember",
            evolution: .tidal,
            mood: .overwhelmed
        )
        #expect(name == "ember_tidal_overwhelmed")
    }
    
    @Test("Returns fallback when asset missing in bundle")
    func returnsFallbackWhenAssetMissing() {
        let name = CharacterAssetResolver.resolvedAssetName(
            characterId: "lumi",
            evolution: .tidal,
            mood: .worried,
            bundle: .main
        )
        // Falls back to droplet_calm since tidal assets don't exist yet
        #expect(name == "lumi_droplet_calm")
    }
    
    @Test("All characters have valid naming pattern")
    func allCharactersValidNaming() {
        for creature in CharacterCreature.allCharacters {
            for evolution in EvolutionStage.allCases {
                for mood in StressBuddyMood.allCases {
                    let name = CharacterAssetResolver.assetName(
                        characterId: creature.id,
                        evolution: evolution,
                        mood: mood
                    )
                    #expect(!name.isEmpty)
                    #expect(name.contains(creature.id))
                }
            }
        }
    }
}
```

**Step 2: Run tests to verify failure**

Run: `xcodebuild test -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:StressMonitorTests/CharacterAssetResolverTests 2>&1 | tail -5`
Expected: FAIL — "Cannot find 'CharacterAssetResolver' in scope"

**Step 3: Write implementation**

```swift
// StressMonitor/Services/CharacterAssetResolver.swift
import Foundation

/// Resolves character asset names from (characterId, evolution, mood) combination.
/// Follows naming convention: {characterId}_{evolution}_{mood}
/// Falls back gracefully when specific asset doesn't exist.
enum CharacterAssetResolver {
    
    /// Generate asset name for a specific character state
    static func assetName(
        characterId: String,
        evolution: EvolutionStage,
        mood: StressBuddyMood
    ) -> String {
        "\(characterId)_\(evolution.rawValue)_\(mood.rawValue)"
    }
    
    /// Resolve asset name with fallback chain:
    /// 1. Exact match → 2. character_droplet_calm → 3. CharacterCalm (legacy)
    static func resolvedAssetName(
        characterId: String,
        evolution: EvolutionStage,
        mood: StressBuddyMood,
        bundle: Bundle = .main
    ) -> String {
        let exact = assetName(characterId: characterId, evolution: evolution, mood: mood)
        if bundle.imageNames.contains(exact) {
            return exact
        }
        
        // Fallback to droplet calm for this character
        let fallback = assetName(characterId: characterId, evolution: .droplet, mood: .calm)
        if bundle.imageNames.contains(fallback) {
            return fallback
        }
        
        // Ultimate fallback to legacy generic character
        return "Character\(mood.rawValue.capitalized)"
    }
}

extension Bundle {
    /// Cached set of image asset names for fast lookup
    var imageNames: Set<String> {
        // In real implementation, this reads from Asset Catalog
        // For now, check known assets
        static let knownAssets: Set<String> = [
            "CharacterSleeping", "CharacterCalm", "CharacterConcerned",
            "CharacterWorried", "CharacterOverwhelmed"
        ]
        return knownAssets
    }
}
```

**Step 4: Run tests to verify pass**

Run: `xcodebuild test -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:StressMonitorTests/CharacterAssetResolverTests 2>&1 | tail -5`
Expected: PASS

**Step 5: Commit**

```bash
git add StressMonitor/StressMonitor/Services/CharacterAssetResolver.swift StressMonitor/StressMonitorTests/CharacterAssetResolverTests.swift
git commit -m "feat: add CharacterAssetResolver with naming convention and fallback chain"
```

---

## Phase 2: Extend Character Models

### Task 2.1: Add Evolution Requirement Model

**Objective:** Create structured evolution requirements per character element.

**Files:**
- Modify: `StressMonitor/StressMonitor/Models/Character/CharacterCreature.swift`

**Step 1: Add evolution requirements to CharacterCreature**

Add after `CharacterCreature` struct:

```swift
/// Structured evolution requirements for a character
struct EvolutionRequirement: Sendable {
    let streakDays: Int
    let sessionsCompleted: Int
    let description: String
    
    static func forStage(_ stage: EvolutionStage, element: CharacterElement) -> EvolutionRequirement {
        switch stage {
        case .droplet:
            return EvolutionRequirement(
                streakDays: 0,
                sessionsCompleted: 0,
                description: "🌱 Start: 7-day streak"
            )
        case .ripple:
            let sessions: Int
            let desc: String
            switch element {
            case .water:  sessions = 5;  desc = "🌊 30-day streak + 5 breathing sessions"
            case .earth:  sessions = 10; desc = "🌿 30-day streak + 10 journal entries"
            case .fire:   sessions = 20; desc = "🔥 30-day streak + 20 workouts"
            case .air:    sessions = 15; desc = "🌬️ 30-day streak + 15 mindfulness sessions"
            case .moon:   sessions = 20; desc = "🌙 30-day streak + 20 good sleep nights"
            }
            return EvolutionRequirement(streakDays: 30, sessionsCompleted: sessions, description: desc)
        case .tidal:
            return EvolutionRequirement(
                streakDays: 90,
                sessionsCompleted: 0,
                description: "⚡ 90-day streak + Resilience Score 80+"
            )
        }
    }
}
```

**Step 2: Add convenience method to CharacterCreature**

```swift
extension CharacterCreature {
    /// Evolution requirement for reaching next stage
    func evolutionRequirement(for stage: EvolutionStage) -> EvolutionRequirement {
        .forStage(stage, element: element)
    }
    
    /// Display emoji for character
    var emoji: String { element.emoji }
}
```

**Step 3: Commit**

```bash
git add StressMonitor/StressMonitor/Models/Character/CharacterCreature.swift
git commit -m "feat: add EvolutionRequirement model with per-element requirements"
```

---

### Task 2.2: Update StressBuddyIllustration for Multi-Character

**Objective:** Extend `StressBuddyIllustration` to render any character (not just generic buddy).

**Files:**
- Modify: `StressMonitor/StressMonitor/Components/Character/StressBuddyIllustration.swift`

**Step 1: Add character-aware initializer**

```swift
struct StressBuddyIllustration: View {
    let mood: StressBuddyMood
    let size: CGFloat
    let characterId: String?
    let evolution: EvolutionStage?
    
    init(mood: StressBuddyMood, size: CGFloat) {
        self.mood = mood
        self.size = size
        self.characterId = nil
        self.evolution = nil
    }
    
    init(characterId: String, evolution: EvolutionStage, mood: StressBuddyMood, size: CGFloat) {
        self.mood = mood
        self.size = size
        self.characterId = characterId
        self.evolution = evolution
    }
    
    var body: some View {
        Image(resolvedAssetName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .characterAnimation(for: mood)
    }
    
    private var resolvedAssetName: String {
        if let characterId, let evolution {
            return CharacterAssetResolver.resolvedAssetName(
                characterId: characterId,
                evolution: evolution,
                mood: mood
            )
        }
        // Legacy fallback: generic character
        return legacyAssetName
    }
    
    private var legacyAssetName: String {
        switch mood {
        case .sleeping: return "CharacterSleeping"
        case .calm: return "CharacterCalm"
        case .concerned: return "CharacterConcerned"
        case .worried: return "CharacterWorried"
        case .overwhelmed: return "CharacterOverwhelmed"
        }
    }
}
```

**Step 2: Commit**

```bash
git add StressMonitor/StressMonitor/Components/Character/StressBuddyIllustration.swift
git commit -m "feat: extend StressBuddyIllustration for multi-character rendering"
```

---

## Phase 3: Character Collection Tab

### Task 3.1: Add Character Tab to MainTabView

**Objective:** Add a 4th tab "Characters" to the app's tab bar.

**Files:**
- Modify: `StressMonitor/StressMonitor/Views/Components/TabBar/TabItem.swift`
- Modify: `StressMonitor/StressMonitor/Views/MainTabView.swift`

**Step 1: Add `.characters` case to TabItem enum**

```swift
enum TabItem: Int, CaseIterable, Identifiable {
    case home = 0
    case action = 1
    case characters = 2  // NEW
    case trend = 3       // was 2
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .home:       return "Home"
        case .action:     return "Action"
        case .characters: return "Characters"  // NEW
        case .trend:      return "Trend"
        }
    }
    
    var iconName: String {
        switch self {
        case .home:       return "home"
        case .action:     return "action"
        case .characters: return "character"  // NEW — map to SF Symbol or custom icon
        case .trend:      return "trend"
        }
    }
    
    var accessibilityLabel: String {
        switch self {
        case .home:       return "Home tab, current stress level"
        case .action:     return "Action tab, quick actions and exercises"
        case .characters: return "Characters tab, your character collection"
        case .trend:      return "Trend tab, trends and insights"
        }
    }
    
    var accessibilityHint: String {
        switch self {
        case .home:       return "Double tap to view current stress measurement"
        case .action:     return "Double tap to access quick actions and exercises"
        case .characters: return "Double tap to view your character collection"
        case .trend:      return "Double tap to view stress trends and history"
        }
    }
    
    var accessibilityIdentifier: String {
        switch self {
        case .home:       return "HomeTab"
        case .action:     return "ActionTab"
        case .characters: return "CharactersTab"
        case .trend:      return "TrendTab"
        }
    }
}
```

**Step 2: Add case in MainTabView switch**

In `MainTabView.swift`, add inside the `switch selectedTab`:

```swift
case .characters:
    CharacterCollectionView()
```

**Step 3: Commit**

```bash
git add StressMonitor/StressMonitor/Views/Components/TabBar/TabItem.swift StressMonitor/StressMonitor/Views/MainTabView.swift
git commit -m "feat: add Characters tab to MainTabView"
```

---

### Task 3.2: Create CharacterCollectionView

**Objective:** Build the main character collection grid — shows all 5 characters as cards.

**Files:**
- Create: `StressMonitor/StressMonitor/Views/Characters/CharacterCollectionView.swift`
- Create: `StressMonitor/StressMonitor/ViewModels/CharacterCollectionViewModel.swift`

**Step 1: Create ViewModel**

```swift
// StressMonitor/ViewModels/CharacterCollectionViewModel.swift
import SwiftData
import SwiftUI

@Observable
final class CharacterCollectionViewModel {
    var unlocks: [CharacterUnlock] = []
    var activeCharacterId: String?
    
    private var modelContext: ModelContext?
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchUnlocks()
    }
    
    func fetchUnlocks() {
        guard let ctx = modelContext else { return }
        let descriptor = FetchDescriptor<CharacterUnlock>(sortBy: [SortDescriptor(\.characterId)])
        unlocks = (try? ctx.fetch(descriptor)) ?? []
        activeCharacterId = unlocks.first(where: { $0.isActive })?.characterId
    }
    
    func unlockStatus(for characterId: String) -> CharacterUnlock? {
        unlocks.first(where: { $0.characterId == characterId })
    }
    
    func selectCharacter(_ characterId: String) {
        // Deselect all
        for unlock in unlocks {
            unlock.isActive = (unlock.characterId == characterId)
        }
        activeCharacterId = characterId
    }
}
```

**Step 2: Create Collection View**

```swift
// StressMonitor/Views/Characters/CharacterCollectionView.swift
import SwiftData
import SwiftUI

struct CharacterCollectionView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = CharacterCollectionViewModel()
    @State private var selectedCharacter: CharacterCreature?
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Spacing.md),
                GridItem(.flexible(), spacing: Spacing.md)
            ], spacing: Spacing.md) {
                ForEach(CharacterCreature.allCharacters) { creature in
                    CharacterGridCard(
                        creature: creature,
                        unlock: viewModel.unlockStatus(for: creature.id),
                        isActive: viewModel.activeCharacterId == creature.id
                    )
                    .onTapGesture {
                        selectedCharacter = creature
                    }
                }
            }
            .padding(Spacing.md)
        }
        .background(Color.Wellness.adaptiveBackground)
        .navigationTitle("Characters")
        .sheet(item: $selectedCharacter) { creature in
            CharacterDetailView(
                creature: creature,
                unlock: viewModel.unlockStatus(for: creature.id)
            )
        }
        .onAppear {
            viewModel.configure(modelContext: modelContext)
        }
    }
}
```

**Step 3: Commit**

```bash
git add StressMonitor/StressMonitor/Views/Characters/CharacterCollectionView.swift StressMonitor/StressMonitor/ViewModels/CharacterCollectionViewModel.swift
git commit -m "feat: create CharacterCollectionView with grid layout and ViewModel"
```

---

### Task 3.3: Create CharacterGridCard Component

**Objective:** Build the individual card shown in the collection grid for each character.

**Files:**
- Create: `StressMonitor/StressMonitor/Views/Characters/Components/CharacterGridCard.swift`

**Step 1: Write the card view**

```swift
// StressMonitor/Views/Characters/Components/CharacterGridCard.swift
import SwiftUI

struct CharacterGridCard: View {
    let creature: CharacterCreature
    let unlock: CharacterUnlock?
    let isActive: Bool
    
    private var isUnlocked: Bool { unlock?.isUnlocked ?? false }
    private var isPremium: Bool { creature.unlockType == .premium }
    private var isStreakGated: Bool { creature.unlockType == .streakGated }
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Character avatar
            ZStack {
                Circle()
                    .fill(creature.element.primaryColor.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                if isUnlocked {
                    StressBuddyIllustration(
                        characterId: creature.id,
                        evolution: unlock?.evolutionStage ?? .droplet,
                        mood: .calm,
                        size: 60
                    )
                } else {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundStyle(creature.element.primaryColor.opacity(0.5))
                }
            }
            .overlay(alignment: .topTrailing) {
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .background(Circle().fill(.white).padding(-2))
                }
            }
            
            // Name + element
            Text(creature.displayName)
                .font(Typography.headline)
                .foregroundStyle(.primary)
            
            Text(creature.subtitle)
                .font(Typography.caption1)
                .foregroundStyle(.secondary)
            
            // Lock status badge
            if !isUnlocked {
                unlockBadge
            }
            
            // Evolution stage indicator
            if isUnlocked {
                EvolutionDots(
                    currentStage: unlock?.evolutionStage ?? .droplet,
                    color: creature.element.accentColor
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.cardPadding)
        .background(Color.Wellness.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isActive ? creature.element.primaryColor : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
    
    @ViewBuilder
    private var unlockBadge: some View {
        HStack(spacing: 2) {
            if isPremium {
                Image(systemName: "crown.fill")
                    .font(.caption2)
                Text("Premium")
                    .font(.caption2)
            } else if isStreakGated {
                Image(systemName: "flame.fill")
                    .font(.caption2)
                Text("\(creature.streakRequired)d")
                    .font(.caption2)
            }
        }
        .foregroundStyle(isPremium ? .orange : .blue)
    }
}
```

**Step 2: Commit**

```bash
git add StressMonitor/StressMonitor/Views/Characters/Components/CharacterGridCard.swift
git commit -m "feat: create CharacterGridCard with unlock state and evolution dots"
```

---

### Task 3.4: Create EvolutionDots Component

**Objective:** Small 3-dot indicator showing current evolution stage.

**Files:**
- Create: `StressMonitor/StressMonitor/Views/Characters/Components/EvolutionDots.swift`

**Step 1: Write the component**

```swift
// StressMonitor/Views/Characters/Components/EvolutionDots.swift
import SwiftUI

struct EvolutionDots: View {
    let currentStage: EvolutionStage
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(EvolutionStage.allCases, id: \.self) { stage in
                Circle()
                    .fill(stage.sortOrder <= currentStage.sortOrder ? color : Color.secondary.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
        }
    }
}
```

**Step 2: Commit**

```bash
git add StressMonitor/StressMonitor/Views/Characters/Components/EvolutionDots.swift
git commit -m "feat: create EvolutionDots component for evolution stage display"
```

---

## Phase 4: Character Detail View

### Task 4.1: Create CharacterDetailView

**Objective:** Full-screen detail showing character info, stats, evolution timeline, and mood preview.

**Files:**
- Create: `StressMonitor/StressMonitor/Views/Characters/CharacterDetailView.swift`

**Step 1: Write the detail view**

```swift
// StressMonitor/Views/Characters/CharacterDetailView.swift
import SwiftUI

struct CharacterDetailView: View {
    let creature: CharacterCreature
    let unlock: CharacterUnlock?
    @Environment(\.dismiss) private var dismiss
    @State private var previewMood: StressBuddyMood = .calm
    
    private var isUnlocked: Bool { unlock?.isUnlocked ?? false }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Hero character preview
                    characterHero
                    
                    // Mood preview selector (if unlocked)
                    if isUnlocked {
                        moodPreviewSection
                    }
                    
                    // Personality & description
                    infoSection
                    
                    // Evolution timeline
                    evolutionSection
                    
                    // Stats (if unlocked)
                    if isUnlocked, let unlock {
                        statsSection(unlock: unlock)
                    }
                    
                    // Unlock CTA (if locked)
                    if !isUnlocked {
                        unlockCTA
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.Wellness.adaptiveBackground)
            .navigationTitle(creature.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Hero
    
    @ViewBuilder
    private var characterHero: some View {
        ZStack {
            // Element glow background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [creature.element.primaryColor.opacity(0.3), .clear],
                        center: .center,
                        startRadius: 40,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
            
            if isUnlocked {
                StressBuddyIllustration(
                    characterId: creature.id,
                    evolution: unlock?.evolutionStage ?? .droplet,
                    mood: previewMood,
                    size: 140
                )
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(creature.element.primaryColor.opacity(0.4))
            }
        }
    }
    
    // MARK: - Mood Preview
    
    @ViewBuilder
    private var moodPreviewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Mood Preview", icon: "face.smiling")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(StressBuddyMood.allCases, id: \.self) { mood in
                        MoodPreviewButton(
                            mood: mood,
                            isSelected: previewMood == mood,
                            color: creature.element.primaryColor
                        ) {
                            withAnimation(.spring(duration: 0.3)) {
                                previewMood = mood
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Info
    
    @ViewBuilder
    private var infoSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text(creature.emoji)
                        .font(.title2)
                    Text(creature.subtitle)
                        .font(Typography.headline)
                    Spacer()
                }
                
                Text(creature.description)
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
                
                Divider()
                
                HStack {
                    Label(creature.personality, systemImage: "sparkles")
                        .font(Typography.caption1)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Evolution
    
    @ViewBuilder
    private var evolutionSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Evolution", icon: "arrow.triangle.2.circlepath")
                
                ForEach(EvolutionStage.allCases, id: \.self) { stage in
                    EvolutionTimelineRow(
                        stage: stage,
                        requirement: creature.evolutionRequirement(for: stage),
                        isComplete: isUnlocked && (unlock?.evolutionStage.sortOrder ?? -1) >= stage.sortOrder,
                        isCurrent: isUnlocked && unlock?.evolutionStage == stage,
                        color: creature.element.accentColor
                    )
                }
            }
        }
    }
    
    // MARK: - Stats
    
    @ViewBuilder
    private func statsSection(unlock: CharacterUnlock) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader(title: "Stats", icon: "chart.bar.fill")
                
                HStack(spacing: Spacing.lg) {
                    StatItem(label: "Streak", value: "\(unlock.streakDays)d", icon: "flame.fill", color: .orange)
                    StatItem(label: "Sessions", value: "\(unlock.sessionsCompleted)", icon: "figure.mind.and.body", color: .teal)
                    StatItem(label: "Resilience", value: "\(Int(unlock.resilienceScore))", icon: "shield.fill", color: .blue)
                }
            }
        }
    }
    
    // MARK: - Unlock CTA
    
    @ViewBuilder
    private var unlockCTA: some View {
        GlassCard {
            VStack(spacing: Spacing.md) {
                if creature.unlockType == .premium {
                    Image(systemName: "crown.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text("Premium Character")
                        .font(Typography.headline)
                    Text("Unlock with StressMonitor Premium")
                        .font(Typography.body)
                        .foregroundStyle(.secondary)
                    Button("Get Premium") { /* Navigate to IAP */ }
                        .buttonStyle(.borderedProminent)
                } else if creature.unlockType == .streakGated {
                    Image(systemName: "flame.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text("\(creature.streakRequired)-Day Streak Required")
                        .font(Typography.headline)
                    Text("Keep logging daily to unlock \(creature.displayName)!")
                        .font(Typography.body)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
```

**Step 2: Commit**

```bash
git add StressMonitor/StressMonitor/Views/Characters/CharacterDetailView.swift
git commit -m "feat: create CharacterDetailView with hero, moods, evolution, stats"
```

---

### Task 4.2: Create Helper Components for Detail View

**Objective:** Build `MoodPreviewButton`, `EvolutionTimelineRow`, and `StatItem`.

**Files:**
- Create: `StressMonitor/StressMonitor/Views/Characters/Components/MoodPreviewButton.swift`
- Create: `StressMonitor/StressMonitor/Views/Characters/Components/EvolutionTimelineRow.swift`
- Create: `StressMonitor/StressMonitor/Views/Characters/Components/StatItem.swift`

**Step 1: MoodPreviewButton**

```swift
// StressMonitor/Views/Characters/Components/MoodPreviewButton.swift
import SwiftUI

struct MoodPreviewButton: View {
    let mood: StressBuddyMood
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: mood.symbol)
                    .font(.title3)
                Text(mood.displayName)
                    .font(Typography.caption2)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .frame(width: 64, height: 64)
            .background(isSelected ? color : Color.Wellness.adaptiveCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.borderLight, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mood.accessibilityDescription)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
```

**Step 2: EvolutionTimelineRow**

```swift
// StressMonitor/Views/Characters/Components/EvolutionTimelineRow.swift
import SwiftUI

struct EvolutionTimelineRow: View {
    let stage: EvolutionStage
    let requirement: EvolutionRequirement
    let isComplete: Bool
    let isCurrent: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Status circle
            ZStack {
                Circle()
                    .fill(isComplete ? color : Color.secondary.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundStyle(.white)
                } else if isCurrent {
                    Circle()
                        .stroke(color, lineWidth: 2)
                        .frame(width: 32, height: 32)
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(stage.displayName)
                    .font(Typography.subheadline)
                    .foregroundStyle(isComplete ? .primary : .secondary)
                
                Text(requirement.description)
                    .font(Typography.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}
```

**Step 3: StatItem**

```swift
// StressMonitor/Views/Characters/Components/StatItem.swift
import SwiftUI

struct StatItem: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(Typography.headline)
            Text(label)
                .font(Typography.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
```

**Step 4: Commit**

```bash
git add StressMonitor/StressMonitor/Views/Characters/Components/MoodPreviewButton.swift StressMonitor/StressMonitor/Views/Characters/Components/EvolutionTimelineRow.swift StressMonitor/StressMonitor/Views/Characters/Components/StatItem.swift
git commit -m "feat: add MoodPreviewButton, EvolutionTimelineRow, StatItem components"
```

---

## Phase 5: Dashboard Integration

### Task 5.1: Add Character Picker to StressCharacterCard

**Objective:** Let users tap the character on Dashboard to switch active character.

**Files:**
- Modify: `StressMonitor/StressMonitor/Components/Character/StressCharacterCard.swift`

**Step 1: Add character picker state**

Add a new optional binding and sheet:

```swift
// Add to StressCharacterCard
@State private var showCharacterPicker = false

// Add tap gesture to characterView:
characterView
    .onTapGesture { showCharacterPicker = true }
    .sheet(isPresented: $showCharacterPicker) {
        CharacterPickerSheet()
    }
```

**Step 2: Commit**

```bash
git add StressMonitor/StressMonitor/Components/Character/StressCharacterCard.swift
git commit -m "feat: add character picker tap gesture to Dashboard character card"
```

---

### Task 5.2: Create CharacterPickerSheet

**Objective:** Bottom sheet showing unlocked characters for quick switching.

**Files:**
- Create: `StressMonitor/StressMonitor/Views/Characters/CharacterPickerSheet.swift`

**Step 1: Write the picker sheet**

```swift
// StressMonitor/Views/Characters/CharacterPickerSheet.swift
import SwiftData
import SwiftUI

struct CharacterPickerSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<CharacterUnlock> { $0.isUnlocked },
           sort: [SortDescriptor(\CharacterUnlock.characterId)])
    private var unlockedCharacters: [CharacterUnlock]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: Spacing.md),
                    GridItem(.flexible(), spacing: Spacing.md),
                    GridItem(.flexible(), spacing: Spacing.md)
                ], spacing: Spacing.md) {
                    ForEach(unlockedCharacters, id: \.characterId) { unlock in
                        if let creature = CharacterCreature.find(by: unlock.characterId) {
                            compactCharacterButton(creature: creature, unlock: unlock)
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .navigationTitle("Choose Character")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    @ViewBuilder
    private func compactCharacterButton(creature: CharacterCreature, unlock: CharacterUnlock) -> some View {
        Button {
            selectCharacter(unlock.characterId)
        } label: {
            VStack(spacing: 4) {
                StressBuddyIllustration(
                    characterId: creature.id,
                    evolution: unlock.evolutionStage,
                    mood: .calm,
                    size: 50
                )
                Text(creature.displayName)
                    .font(Typography.caption1)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(unlock.isActive ? creature.element.primaryColor.opacity(0.2) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(unlock.isActive ? creature.element.primaryColor : Color.borderLight, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func selectCharacter(_ characterId: String) {
        for unlock in unlockedCharacters {
            unlock.isActive = (unlock.characterId == characterId)
        }
        dismiss()
    }
}
```

**Step 2: Commit**

```bash
git add StressMonitor/StressMonitor/Views/Characters/CharacterPickerSheet.swift
git commit -m "feat: create CharacterPickerSheet for quick character switching"
```

---

## Phase 6: Register CharacterUnlock in SwiftData Schema

### Task 6.1: Add CharacterUnlock to Schema

**Objective:** Register `CharacterUnlock` model in the app's SwiftData schema so it persists.

**Files:**
- Modify: `StressMonitor/StressMonitor/StressMonitorApp.swift`

**Step 1: Add to schema**

```swift
static let schema = Schema([
    StressMeasurement.self,
    CharacterUnlock.self  // NEW
])
```

**Step 2: Add migration for existing users**

In `StressMonitorApp`, add migration to seed default unlocks:

```swift
var sharedModelContainer: ModelContainer = {
    do {
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        // Seed default character unlocks on first launch
        let ctx = container.mainContext
        let existing = try? ctx.fetch(FetchDescriptor<CharacterUnlock>())
        if existing?.isEmpty ?? true {
            // Auto-unlock free characters
            for creature in CharacterCreature.allCharacters where creature.unlockType == .free {
                let unlock = CharacterUnlock(
                    characterId: creature.id,
                    isUnlocked: true,
                    currentEvolution: .droplet,
                    isActive: creature.id == "ripple"  // Ripple is default active
                )
                ctx.insert(unlock)
            }
        }
        return container
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()
```

**Step 3: Commit**

```bash
git add StressMonitor/StressMonitor/StressMonitorApp.swift
git commit -m "feat: register CharacterUnlock in SwiftData schema with seed migration"
```

---

## Phase 7: Evolution Celebration

### Task 7.1: Create EvolutionCelebrationView

**Objective:** Full-screen confetti + glow animation when a character evolves.

**Files:**
- Create: `StressMonitor/StressMonitor/Views/Characters/EvolutionCelebrationView.swift`

**Step 1: Write the celebration view**

```swift
// StressMonitor/Views/Characters/EvolutionCelebrationView.swift
import SwiftUI

struct EvolutionCelebrationView: View {
    let creature: CharacterCreature
    let newStage: EvolutionStage
    @Environment(\.dismiss) private var dismiss
    @State private var showGlow = false
    @State private var showCharacter = false
    @State private var showText = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            
            VStack(spacing: Spacing.xl) {
                Spacer()
                
                // Evolution text
                if showText {
                    VStack(spacing: Spacing.sm) {
                        Text("Evolution!")
                            .font(Typography.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        Text("\(creature.displayName) evolved to \(newStage.displayName)!")
                            .font(Typography.body)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Character with glow
                ZStack {
                    if showGlow {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [creature.element.primaryColor.opacity(0.6), .clear],
                                    center: .center,
                                    startRadius: 50,
                                    endRadius: 150
                                )
                            )
                            .frame(width: 300, height: 300)
                            .transition(.opacity)
                    }
                    
                    if showCharacter {
                        StressBuddyIllustration(
                            characterId: creature.id,
                            evolution: newStage,
                            mood: .calm,
                            size: 160
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                Spacer()
                
                // Continue button
                if showText {
                    Button("Awesome!") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .tint(creature.element.primaryColor)
                        .controlSize(.large)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(Spacing.xl)
        }
        .onAppear { runAnimationSequence() }
    }
    
    private func runAnimationSequence() {
        withAnimation(.easeOut(duration: 0.6)) {
            showGlow = true
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
            showCharacter = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.8)) {
            showText = true
        }
    }
}
```

**Step 2: Commit**

```bash
git add StressMonitor/StressMonitor/Views/Characters/EvolutionCelebrationView.swift
git commit -m "feat: create EvolutionCelebrationView with glow + staggered animation"
```

---

## Phase 8: Watch Complication Update

### Task 8.1: Add Character to Watch Complication

**Objective:** Show active character in Watch complications instead of generic buddy.

**Files:**
- Modify: `StressMonitor/StressMonitorWatch Watch App/Complications/Views/CircularStressView.swift`

**Step 1: Update CircularStressView to show active character**

Add a `characterId` parameter and use `CharacterAssetResolver`:

```swift
// Add to CircularStressView
var characterId: String = "ripple"
var evolution: EvolutionStage = .droplet

// In body, replace Image with:
StressBuddyIllustration(
    characterId: characterId,
    evolution: evolution,
    mood: mood,
    size: 40
)
```

**Step 2: Update ComplicationDataProvider to pass character info**

Read active character from shared `UserDefaults` or Watch connectivity.

**Step 3: Commit**

```bash
git add "StressMonitor/StressMonitorWatch Watch App/Complications/"
git commit -m "feat: show active character in Watch complications"
```

---

## Phase 9: Placeholder SVG Assets

### Task 9.1: Create Placeholder Character Assets

**Objective:** Generate 5 placeholder SVGs for each character (droplet_calm state) so the UI renders something before real art is ready.

**Files:**
- Create: 5 new `.imageset` directories in `Assets.xcassets`

**Step 1: Create placeholder SVGs**

Use the existing generic character SVGs as templates. Copy `CharacterCalm` to each character's droplet_calm:

```bash
# For each character, create a placeholder
for char in ripple blossom ember zephyr lumi; do
  mkdir -p StressMonitor/Assets.xcassets/${char}_droplet_calm.imageset
  cp StressMonitor/Assets.xcassets/CharacterCalm/CharacterCalm.svg \
     StressMonitor/Assets.xcassets/${char}_droplet_calm.imageset/${char}_droplet_calm.svg
  # Create Contents.json
  cat > StressMonitor/Assets.xcassets/${char}_droplet_calm.imageset/Contents.json << 'EOF'
{
  "images": [{ "filename": "PLACEHOLDER.svg", "idiom": "universal" }],
  "info": { "author": "xcode", "version": 1 },
  "properties": { "preserves-vector-representation": true }
}
EOF
done
```

**Step 2: Commit**

```bash
git add StressMonitor/Assets.xcassets/
git commit -m "feat: add placeholder character SVG assets for 5 creatures"
```

---

## Phase 10: Unit Tests

### Task 10.1: Test CharacterCollectionViewModel

**Objective:** Verify ViewModel correctly fetches, selects, and manages character unlocks.

**Files:**
- Create: `StressMonitor/StressMonitorTests/CharacterCollectionViewModelTests.swift`

**Step 1: Write tests**

```swift
import SwiftData
import Testing
@testable import StressMonitor

struct CharacterCollectionViewModelTests {
    
    @Test("Fetch unlocks returns persisted data")
    func fetchUnlocks() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: CharacterUnlock.self, configurations: config)
        let ctx = container.mainContext
        
        // Insert test data
        let ripple = CharacterUnlock(characterId: "ripple", isUnlocked: true, isActive: true)
        ctx.insert(ripple)
        
        let vm = CharacterCollectionViewModel()
        vm.configure(modelContext: ctx)
        
        #expect(vm.unlocks.count == 1)
        #expect(vm.activeCharacterId == "ripple")
    }
    
    @Test("Select character updates active state")
    func selectCharacter() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: CharacterUnlock.self, configurations: config)
        let ctx = container.mainContext
        
        let ripple = CharacterUnlock(characterId: "ripple", isUnlocked: true, isActive: true)
        let blossom = CharacterUnlock(characterId: "blossom", isUnlocked: true)
        ctx.insert(ripple)
        ctx.insert(blossom)
        
        let vm = CharacterCollectionViewModel()
        vm.configure(modelContext: ctx)
        
        vm.selectCharacter("blossom")
        
        #expect(vm.activeCharacterId == "blossom")
        #expect(ripple.isActive == false)
        #expect(blossom.isActive == true)
    }
    
    @Test("Unlock status returns nil for unknown character")
    func unknownCharacterReturnsNil() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: CharacterUnlock.self, configurations: config)
        let ctx = container.mainContext
        
        let vm = CharacterCollectionViewModel()
        vm.configure(modelContext: ctx)
        
        #expect(vm.unlockStatus(for: "nonexistent") == nil)
    }
}
```

**Step 2: Run tests**

Run: `xcodebuild test -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:StressMonitorTests/CharacterCollectionViewModelTests`
Expected: 3 passed

**Step 3: Commit**

```bash
git add StressMonitor/StressMonitorTests/CharacterCollectionViewModelTests.swift
git commit -m "test: add CharacterCollectionViewModel unit tests"
```

---

## Risk Matrix

| Risk | Impact | Mitigation |
|------|--------|------------|
| Asset explosion (75 SVGs) | Large app size | Start with 5 placeholders, generate per-character later |
| SwiftData migration on existing users | App crash | Test migration path, use lightweight migration |
| Tab bar UI break (3→4 tabs) | Layout shift | Test all device sizes, AnimatedTabBar supports 4+ |
| Performance with 75 assets | Slow launch | Lazy load, use Asset Catalog thinning |
| Watch sync latency | Stale character | Use immediate WatchConnectivity transfer |

## Timeline Estimate

| Phase | Tasks | Duration |
|-------|-------|----------|
| 1. Asset Pipeline | 2 tasks | 0.5 day |
| 2. Models | 2 tasks | 0.5 day |
| 3. Collection Tab | 4 tasks | 1.5 days |
| 4. Detail View | 2 tasks | 1 day |
| 5. Dashboard Integration | 2 tasks | 1 day |
| 6. SwiftData Schema | 1 task | 0.5 day |
| 7. Evolution Celebration | 1 task | 0.5 day |
| 8. Watch Complications | 1 task | 0.5 day |
| 9. Placeholder Assets | 1 task | 0.5 day |
| 10. Unit Tests | 1 task | 1 day |
| **Total** | **17 tasks** | **~7.5 days** |

## Acceptance Criteria Mapping

- [x] Character model + data layer → Phase 6 (CharacterUnlock in SwiftData)
- [x] Character collection grid view → Phase 3 (CharacterCollectionView)
- [x] Character detail view → Phase 4 (CharacterDetailView)
- [x] Character selection / active picker → Phase 5 (CharacterPickerSheet)
- [x] Evolution stage display → Phase 4 (EvolutionTimelineRow, EvolutionDots)
- [x] Stress-reactive widget on Dashboard → Phase 5 (StressCharacterCard update)
- [x] Watch face character complication → Phase 8
- [x] Asset pipeline for characters → Phase 1 + 9
- [x] Transitions between stress states → Already handled by CharacterAnimationModifier
- [x] Character unlock flow → Phase 4 (unlock CTA in detail view) + Phase 7 (celebration)

## Open Questions

1. **Real character art**: When will final SVGs be ready? Currently using placeholder generic buddy.
2. **Lottie vs native**: Should we use Lottie for evolution celebration or keep native SwiftUI animations?
3. **Character onboarding**: Should we show a tutorial when user first opens Characters tab?
4. **CloudKit sync**: Should CharacterUnlock sync across devices via CloudKit? (Currently local SwiftData only)
