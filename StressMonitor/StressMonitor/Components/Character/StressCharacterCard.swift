import SwiftData
import SwiftUI

// MARK: - Stress Character Card (Home Redesign)

/// Character-based stress visualization for the Home tab.
/// Uses the Ripple / Elemental Creatures concept colors from `character-concept-sheet.html`.
struct StressCharacterCard: View {
    let result: StressResult?
    let size: CharacterDisplayContext
    var isRequestingAccess: Bool = false
    let onGrantAccess: (() -> Void)?

    @State private var showCharacterPicker = false
    @Query(filter: #Predicate<CharacterUnlock> { $0.isActive })
    private var activeUnlocks: [CharacterUnlock]

    var mood: RippleMood {
        RippleMood.from(stressLevel: result?.level ?? 0)
    }

    var stressLevel: Double { result?.level ?? 0 }
    private var lastUpdated: Date? { result?.timestamp }

    private var activeUnlock: CharacterUnlock? { activeUnlocks.first }
    private var activeCreature: CharacterCreature {
        activeUnlock.flatMap { CharacterCreature.find(by: $0.characterId) }
            ?? CharacterCreature.find(by: "ripple")
            ?? CharacterCreature.allCharacters[0]
    }

    init(
        result: StressResult?,
        size: CharacterDisplayContext,
        isRequestingAccess: Bool = false,
        onGrantAccess: (() -> Void)? = nil
    ) {
        self.result = result
        self.size = size
        self.isRequestingAccess = isRequestingAccess
        self.onGrantAccess = onGrantAccess
    }

    var body: some View {
        VStack(spacing: 18) {
            DateHeaderView(date: lastUpdated ?? Date())

            if let result {
                redesignedHero(result: result)
            } else {
                PermissionCardView(
                    permissionType: .healthKit,
                    isLoading: isRequestingAccess,
                    embedded: true,
                    onGrantAccess: onGrantAccess ?? {}
                )
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: cardHeight)
        .padding(20)
        .background {
            ZStack {
                HomeCharacterDesignTokens.heroGradient
                if let tint = stressTint {
                    tint.opacity(0.09)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(activeCreature.element.primaryColor.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: activeCreature.element.primaryColor.opacity(0.12), radius: 24, x: 0, y: 16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Redesign: Centered Character Hero

    @ViewBuilder
    private func redesignedHero(result: StressResult) -> some View {
        VStack(spacing: 16) {
            centeredCharacterRing(result: result)

            Spacer().frame(height: 6)

            characterBadge(result: result)

            Text(heroMessage(for: result))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                .multilineTextAlignment(.center)

            Text("\(activeCreature.displayName) reacts to your stress in real time — calm waves mean your body is recovering.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity)
    }

    private func centeredCharacterRing(result: StressResult) -> some View {
        ZStack {
            // Ambient radial glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            activeCreature.element.primaryColor.opacity(0.22),
                            activeCreature.element.primaryColor.opacity(0.05),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: heroRingSize / 2
                    )
                )
                .frame(width: heroRingSize + 28, height: heroRingSize + 28)

            // Background track ring
            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: ringStroke)
                .frame(width: heroRingSize, height: heroRingSize)

            // Animated stress progress ring
            Circle()
                .trim(from: 0, to: min(max(result.level / 100, 0), 1))
                .stroke(
                    AngularGradient(
                        colors: [
                            activeCreature.element.primaryColor,
                            stressAccent(for: result.category),
                            activeCreature.element.primaryColor,
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: ringStroke, lineCap: .round)
                )
                .frame(width: heroRingSize, height: heroRingSize)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.7, dampingFraction: 0.82), value: result.level)

            // Character illustration (centered)
            characterGlyph

            // Stress level badge anchored below ring
            stressBadge(level: result.level)
                .offset(y: heroRingSize / 2 + 18)
        }
        .frame(width: heroRingSize + 32, height: heroRingSize + 52)
        .contentShape(Rectangle())
        .onTapGesture { showCharacterPicker = true }
        .sheet(isPresented: $showCharacterPicker) {
            CharacterPickerSheet()
        }
    }

    private func stressBadge(level: Double) -> some View {
        VStack(spacing: 0) {
            Text("\(Int(level))")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text("stress")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.22), lineWidth: 1))
    }

    @ViewBuilder
    private var characterGlyph: some View {
        StressBuddyIllustration(
            characterId: activeCreature.id,
            evolution: activeUnlock?.evolutionStage ?? .droplet,
            mood: mood,
            size: heroSize
        )
    }

    private func characterBadge(result: StressResult) -> some View {
        HStack(spacing: 8) {
            Image(systemName: result.category.icon)
                .font(.system(size: 12, weight: .bold))
            Text("\(activeCreature.displayName) • \(result.category.rawValue.capitalized)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
        }
        .foregroundStyle(stressAccent(for: result.category))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(stressAccent(for: result.category).opacity(0.12), in: Capsule())
        .overlay(Capsule().stroke(stressAccent(for: result.category).opacity(0.18), lineWidth: 1))
    }

    private func heroMessage(for result: StressResult) -> String {
        switch result.category {
        case .relaxed:
            return "\(activeCreature.displayName) is floating peacefully."
        case .mild:
            return "\(activeCreature.displayName) sees small ripples — you’re still steady."
        case .moderate:
            return "\(activeCreature.displayName) is getting cautious. Try a short reset."
        case .high:
            return "\(activeCreature.displayName) needs calm water. Start a breathing break."
        case .severe:
            return "\(activeCreature.displayName) is overwhelmed. Take a breathing break now."
        }
    }

    private func stressAccent(for category: StressCategory) -> Color {
        switch category {
        case .relaxed: return HomeCharacterDesignTokens.Blossom.accent
        case .mild: return HomeCharacterDesignTokens.Ripple.primary
        case .moderate: return HomeCharacterDesignTokens.Ember.accent
        case .high: return Color(hex: "#FA363D")
        case .severe: return Color.stressSevere
        }
    }

    private var heroSize: CGFloat {
        switch size {
        case .dashboard: return 140
        case .widget: return 96
        case .watchOS: return 58
        }
    }

    private var heroRingSize: CGFloat { heroSize + 36 }
    private var ringStroke: CGFloat { 12 }

    private var stressTint: Color? {
        guard let result = result else { return nil }
        return stressAccent(for: result.category)
    }

    private var cardHeight: CGFloat? {
        switch size {
        case .dashboard: return nil
        case .widget: return 354
        case .watchOS: return 180
        }
    }

    private var accessibilityLabel: String {
        guard let result = result else {
            return "Health access required. Grant access to read your health data for stress monitoring."
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let timeText = "Last updated \(formatter.localizedString(for: result.timestamp, relativeTo: Date()))"
        return "\(activeCreature.displayName) character. \(mood.accessibilityDescription). Stress level: \(Int(result.level)). \(timeText)"
    }
}

// MARK: - Convenience Initializer (non-optional result)

extension StressCharacterCard {
    init(
        result: StressResult,
        size: CharacterDisplayContext
    ) {
        self.init(
            result: result as StressResult?,
            size: size
        )
    }
}

// MARK: - Preview

#Preview("Home Hero") {
    ScrollView {
        VStack(spacing: 24) {
            ForEach([8.0, 32.0, 62.0, 86.0], id: \.self) { level in
                StressCharacterCard(
                    result: StressResult(
                        level: level,
                        category: level > 90 ? .severe : (level > 75 ? .high : (level > 50 ? .moderate : (level > 25 ? .mild : .relaxed))),
                        confidence: 0.9,
                        hrv: 65,
                        heartRate: 72
                    ),
                    size: .dashboard
                )
            }
        }
        .padding()
    }
    .background(HomeCharacterDesignTokens.homeBackground)
    .modelContainer(for: CharacterUnlock.self, inMemory: true)
}

#Preview("Permission State") {
    StressCharacterCard(
        result: nil as StressResult?,
        size: .dashboard,
        onGrantAccess: {}
    )
    .padding()
    .background(HomeCharacterDesignTokens.homeBackground)
    .modelContainer(for: CharacterUnlock.self, inMemory: true)
}
