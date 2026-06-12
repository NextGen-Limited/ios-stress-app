import SwiftData
import SwiftUI

// MARK: - Stress Character Card (Home Redesign)

/// Character-based stress visualization for the Home tab.
/// Uses the Ripple / Elemental Creatures concept colors from `character-concept-sheet.html`.
struct StressCharacterCard: View {
    let result: StressResult?
    let size: StressBuddyMood.CharacterContext
    var isRequestingAccess: Bool = false
    let onGrantAccess: (() -> Void)?
    let onSettingsTapped: (() -> Void)?

    @State private var showCharacterPicker = false
    @Query(filter: #Predicate<CharacterUnlock> { $0.isActive })
    private var activeUnlocks: [CharacterUnlock]

    var mood: StressBuddyMood {
        StressBuddyMood.from(stressLevel: result?.level ?? 0)
    }

    var stressLevel: Double { result?.level ?? 0 }
    var hrv: Double? { result?.hrv }
    private var lastUpdated: Date? { result?.timestamp }

    private var activeUnlock: CharacterUnlock? { activeUnlocks.first }
    private var activeCreature: CharacterCreature {
        activeUnlock.flatMap { CharacterCreature.find(by: $0.characterId) }
            ?? CharacterCreature.find(by: "ripple")
            ?? CharacterCreature.allCharacters[0]
    }

    init(
        result: StressResult?,
        size: StressBuddyMood.CharacterContext,
        isRequestingAccess: Bool = false,
        onGrantAccess: (() -> Void)? = nil,
        onSettingsTapped: (() -> Void)? = nil
    ) {
        self.result = result
        self.size = size
        self.isRequestingAccess = isRequestingAccess
        self.onGrantAccess = onGrantAccess
        self.onSettingsTapped = onSettingsTapped
    }

    var body: some View {
        VStack(spacing: 18) {
            DateHeaderView(date: lastUpdated ?? Date(), onSettingsTapped: onSettingsTapped)

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
        .background(HomeCharacterDesignTokens.heroGradient)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(HomeCharacterDesignTokens.Ripple.primary.opacity(0.20), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: HomeCharacterDesignTokens.Ripple.deep.opacity(0.13), radius: 24, x: 0, y: 16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Redesign

    @ViewBuilder
    private func redesignedHero(result: StressResult) -> some View {
        VStack(spacing: 18) {
            HStack(alignment: .center, spacing: 16) {
                heroRing(result: result)

                VStack(alignment: .leading, spacing: 12) {
                    characterBadge(result: result)

                    Text(heroMessage(for: result))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(activeCreature.displayName) reacts to your stress in real time — calm waves mean your body is recovering.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                        .lineLimit(3)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                heroMetric(title: "HRV", value: "\(Int(result.hrv))", unit: "ms", icon: "waveform.path.ecg")
                heroMetric(title: "Heart", value: "\(result.heartRate)", unit: "bpm", icon: "heart.fill")
                heroMetric(title: "Buddy", value: activeCreature.displayName, unit: activeCreature.subtitle, icon: activeCreature.elementIconName)
            }
        }
    }

    private func heroRing(result: StressResult) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            activeCreature.element.secondaryColor.opacity(0.84),
                            activeCreature.element.primaryColor.opacity(0.22),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 24,
                        endRadius: 92
                    )
                )
                .frame(width: heroSize + 42, height: heroSize + 42)

            Circle()
                .stroke(activeCreature.element.secondaryColor.opacity(0.58), lineWidth: 12)
                .frame(width: heroSize + 22, height: heroSize + 22)

            Circle()
                .trim(from: 0, to: min(max(result.level / 100, 0), 1))
                .stroke(
                    AngularGradient(
                        colors: [
                            activeCreature.element.primaryColor,
                            HomeCharacterDesignTokens.Blossom.primary,
                            stressAccent(for: result.category),
                            activeCreature.element.primaryColor,
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: heroSize + 22, height: heroSize + 22)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.7, dampingFraction: 0.82), value: result.level)

            characterGlyph

            VStack(spacing: 0) {
                Text("\(Int(result.level))")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("stress")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.86))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.28), lineWidth: 1))
            .offset(y: heroSize * 0.55)
        }
        .frame(width: heroSize + 48, height: heroSize + 72)
        .contentShape(Rectangle())
        .onTapGesture { showCharacterPicker = true }
        .sheet(isPresented: $showCharacterPicker) {
            CharacterPickerSheet()
        }
    }

    @ViewBuilder
    private var characterGlyph: some View {
        if activeCreature.id == "ripple", activeUnlock == nil || activeUnlock?.evolutionStage == .droplet {
            RippleHomeCharacterGlyph(mood: mood, size: heroSize)
        } else {
            StressBuddyIllustration(
                characterId: activeCreature.id,
                evolution: activeUnlock?.evolutionStage ?? .droplet,
                mood: mood,
                size: heroSize
            )
        }
    }

    private func characterBadge(result: StressResult) -> some View {
        HStack(spacing: 8) {
            Image(systemName: result.category.icon)
                .font(.system(size: 12, weight: .bold))
            Text("\(activeCreature.displayName) • \(result.category.rawValue.capitalized)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
        }
        .foregroundStyle(stressAccent(for: result.category))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(stressAccent(for: result.category).opacity(0.12), in: Capsule())
        .overlay(Capsule().stroke(stressAccent(for: result.category).opacity(0.18), lineWidth: 1))
    }

    private func heroMetric(title: String, value: String, unit: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(HomeCharacterDesignTokens.Ripple.deep)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                Text(unit)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.white.opacity(0.54), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.62), lineWidth: 1)
        )
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
        }
    }

    private func stressAccent(for category: StressCategory) -> Color {
        switch category {
        case .relaxed: return HomeCharacterDesignTokens.Blossom.accent
        case .mild: return HomeCharacterDesignTokens.Ripple.primary
        case .moderate: return HomeCharacterDesignTokens.Ember.accent
        case .high: return Color(hex: "#FA363D")
        }
    }

    private var heroSize: CGFloat {
        switch size {
        case .dashboard: return 112
        case .widget: return 96
        case .watchOS: return 58
        }
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

private extension CharacterCreature {
    var elementIconName: String {
        switch element {
        case .water: return "drop.fill"
        case .earth: return "leaf.fill"
        case .fire: return "flame.fill"
        case .air: return "wind"
        case .moon: return "moon.stars.fill"
        }
    }
}

// MARK: - Convenience Initializer (non-optional result)

extension StressCharacterCard {
    init(
        result: StressResult,
        size: StressBuddyMood.CharacterContext,
        onSettingsTapped: (() -> Void)? = nil
    ) {
        self.init(
            result: result as StressResult?,
            size: size,
            onSettingsTapped: onSettingsTapped
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
                        category: StressBuddyMood.from(stressLevel: level) == .overwhelmed ? .high : (level > 50 ? .moderate : (level > 25 ? .mild : .relaxed)),
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
