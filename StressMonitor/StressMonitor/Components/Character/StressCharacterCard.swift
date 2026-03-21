import SwiftUI

// MARK: - Stress Character Card (Figma Design)

/// Character-based stress visualization matching Figma design
/// Displays Stress Buddy mascot with mood-based appearance in an adaptive card
/// - Dashboard: Flexible width, content-based height
/// - Widget: Fixed 354px height
/// - watchOS: Fixed 180px height
/// Full Reduce Motion support with static fallbacks
struct StressCharacterCard: View {
    let mood: StressBuddyMood
    let stressLevel: Double
    let hrv: Double?
    let size: StressBuddyMood.CharacterContext
    let lastUpdated: Date?
    let onRefresh: (() -> Void)?
    let onSettingsTapped: (() -> Void)?

    init(
        mood: StressBuddyMood,
        stressLevel: Double,
        hrv: Double? = nil,
        size: StressBuddyMood.CharacterContext,
        lastUpdated: Date? = nil,
        onRefresh: (() -> Void)? = nil,
        onSettingsTapped: (() -> Void)? = nil
    ) {
        self.mood = mood
        self.stressLevel = stressLevel
        self.hrv = hrv
        self.size = size
        self.lastUpdated = lastUpdated
        self.onRefresh = onRefresh
        self.onSettingsTapped = onSettingsTapped
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main card content
            VStack(spacing: 0) {
                // Date header with refresh button
                DateHeaderView(date: lastUpdated ?? Date(), onSettingsTapped: onSettingsTapped)

                Spacer()

                // Character illustration
                characterView

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: cardHeight)
            .padding()
            .background(Color.Wellness.adaptiveCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.04), radius: 7.7, x: 0, y: 3)
            .shadow(color: .black.opacity(0.03), radius: 13.9, x: 0, y: 7)
            .shadow(color: .black.opacity(0.02), radius: 26.4, x: 0, y: 13.9)
            .shadow(color: .black.opacity(0.01), radius: 46.9, x: 0, y: 24.5)
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

    /// Adaptive card height - nil for flexible (dashboard), fixed for constrained contexts
    private var cardHeight: CGFloat? {
        switch size {
        case .dashboard:
            return nil  // Flexible - adapts to content and container
        case .widget:
            return 354  // Widget has fixed size
        case .watchOS:
            return 180  // Watch has fixed size
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
        onRefresh: (() -> Void)? = nil,
        onSettingsTapped: (() -> Void)? = nil
    ) {
        self.mood = StressBuddyMood.from(stressLevel: result.level)
        self.stressLevel = result.level
        self.hrv = result.hrv
        self.size = size
        self.lastUpdated = result.timestamp
        self.onRefresh = onRefresh
        self.onSettingsTapped = onSettingsTapped
    }

    /// Create character card with minimal data
    init(
        stressLevel: Double,
        size: StressBuddyMood.CharacterContext,
        lastUpdated: Date? = nil,
        onRefresh: (() -> Void)? = nil,
        onSettingsTapped: (() -> Void)? = nil
    ) {
        self.mood = StressBuddyMood.from(stressLevel: stressLevel)
        self.stressLevel = stressLevel
        self.hrv = nil
        self.size = size
        self.lastUpdated = lastUpdated
        self.onRefresh = onRefresh
        self.onSettingsTapped = onSettingsTapped
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
