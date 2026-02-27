import SwiftUI

// MARK: - Stress Character Card (Figma Design)

/// Character-based stress visualization matching Figma design
/// Displays Stress Buddy mascot with mood-based appearance in a 390x408px card
/// Full Reduce Motion support with static fallbacks
struct StressCharacterCard: View {
    let mood: StressBuddyMood
    let stressLevel: Double
    let hrv: Double?
    let size: StressBuddyMood.CharacterContext
    let lastUpdated: Date?
    let onRefresh: (() -> Void)?

    init(
        mood: StressBuddyMood,
        stressLevel: Double,
        hrv: Double? = nil,
        size: StressBuddyMood.CharacterContext,
        lastUpdated: Date? = nil,
        onRefresh: (() -> Void)? = nil
    ) {
        self.mood = mood
        self.stressLevel = stressLevel
        self.hrv = hrv
        self.size = size
        self.lastUpdated = lastUpdated
        self.onRefresh = onRefresh
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main card content
            VStack(spacing: 0) {
                // Date header with refresh button
                HStack(alignment: .top) {
                    DateHeaderView(date: lastUpdated ?? Date())
                    Spacer()
                    refreshButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)

                Spacer()

                // Status text (centered)
                Text(mood.displayName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(moodColor)
                    .padding(.top, 30)

                Spacer()

                // Character illustration
                characterView
                    .padding(.vertical, 20)

                Spacer()

                // Last updated timestamp
                if let lastUpdated = lastUpdated {
                    Text("Last Updated: \(lastUpdated, style: .relative)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                        .padding(.bottom, 24)
                }
            }
            .frame(width: cardSize.width, height: cardSize.height)
            .background(Color.Wellness.adaptiveCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.04), radius: 7.7, x: 0, y: 3)
            .shadow(color: .black.opacity(0.03), radius: 13.9, x: 0, y: 7)
            .shadow(color: .black.opacity(0.02), radius: 26.4, x: 0, y: 13.9)
            .shadow(color: .black.opacity(0.01), radius: 46.9, x: 0, y: 24.5)

            // Decorative triangle (top-right area, Figma position)
            if size == .dashboard {
                DecorativeTriangleView()
                    .padding(.top, 60)
                    .padding(.trailing, 30)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Refresh Button

    @ViewBuilder
    private var refreshButton: some View {
        if let onRefresh = onRefresh {
            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Refresh stress data")
        }
    }

    // MARK: - Character View

    @ViewBuilder
    private var characterView: some View {
        ZStack {
            // Custom character illustration (replaces SF Symbols)
            StressBuddyIllustration(mood: mood, size: characterSize)
        }
        .accessibilityHidden(true)
    }

    /// Character size based on context
    private var characterSize: CGFloat {
        switch size {
        case .dashboard:
            return 126
        case .widget:
            return 100
        case .watchOS:
            return 60
        }
    }

    // MARK: - Layout Helpers

    private var cardSize: CGSize {
        switch size {
        case .dashboard:
            return CGSize(width: 390, height: 408)
        case .widget:
            return CGSize(width: 338, height: 354)
        case .watchOS:
            return CGSize(width: 180, height: 180)
        }
    }

    /// Mood color matching Figma design (#86CECD for relaxed)
    private var moodColor: Color {
        switch mood {
        case .sleeping, .calm:
            return Color.Wellness.exerciseCyan // #86CECD
        case .concerned:
            return Color.Wellness.daylightYellow
        case .worried:
            return Color.stressModerate
        case .overwhelmed:
            return Color.stressHigh
        }
    }

    private var accessibilityLabel: String {
        var timeText = ""
        if let lastUpdated = lastUpdated {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            timeText = "Last updated \(formatter.localizedString(for: lastUpdated, relativeTo: Date()))"
        }
        return "\(mood.accessibilityDescription). Stress level: \(Int(stressLevel)). \(timeText)"
    }
}

// MARK: - Convenience Initializers

extension StressCharacterCard {
    /// Create character card from StressResult
    init(
        result: StressResult,
        size: StressBuddyMood.CharacterContext,
        onRefresh: (() -> Void)? = nil
    ) {
        self.mood = StressBuddyMood.from(stressLevel: result.level)
        self.stressLevel = result.level
        self.hrv = result.hrv
        self.size = size
        self.lastUpdated = result.timestamp
        self.onRefresh = onRefresh
    }

    /// Create character card with minimal data
    init(
        stressLevel: Double,
        size: StressBuddyMood.CharacterContext,
        lastUpdated: Date? = nil,
        onRefresh: (() -> Void)? = nil
    ) {
        self.mood = StressBuddyMood.from(stressLevel: stressLevel)
        self.stressLevel = stressLevel
        self.hrv = nil
        self.size = size
        self.lastUpdated = lastUpdated
        self.onRefresh = onRefresh
    }
}

// MARK: - Preview

#Preview("All Moods - Dashboard") {
    ScrollView {
        VStack(spacing: 24) {
            ForEach([0.0, 5.0, 15.0, 35.0, 60.0, 85.0], id: \.self) { level in
                StressCharacterCard(
                    mood: .from(stressLevel: level),
                    stressLevel: level,
                    hrv: 65,
                    size: .dashboard,
                    lastUpdated: Date().addingTimeInterval(-30000)
                ) {
                    print("Refresh tapped")
                }
            }
        }
        .padding()
        .background(Color.Wellness.adaptiveBackground)
    }
}

#Preview("Widget Size") {
    VStack(spacing: 16) {
        StressCharacterCard(
            mood: .calm,
            stressLevel: 15,
            hrv: 70,
            size: .widget,
            lastUpdated: Date().addingTimeInterval(-3600)
        )

        StressCharacterCard(
            mood: .worried,
            stressLevel: 60,
            hrv: 45,
            size: .widget,
            lastUpdated: Date().addingTimeInterval(-7200)
        )
    }
    .padding()
    .background(Color.Wellness.adaptiveBackground)
}

#Preview("watchOS Size") {
    VStack(spacing: 12) {
        StressCharacterCard(
            mood: .sleeping,
            stressLevel: 5,
            size: .watchOS,
            lastUpdated: Date()
        )
    }
    .padding()
    .background(Color.Wellness.adaptiveBackground)
}

#Preview("Dark Mode") {
    VStack(spacing: 24) {
        StressCharacterCard(
            mood: .overwhelmed,
            stressLevel: 90,
            hrv: 30,
            size: .dashboard,
            lastUpdated: Date().addingTimeInterval(-1800)
        )
    }
    .padding()
    .background(Color.Wellness.adaptiveBackground)
    .preferredColorScheme(.dark)
}
