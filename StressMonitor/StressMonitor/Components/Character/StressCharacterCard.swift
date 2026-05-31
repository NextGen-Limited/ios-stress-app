import SwiftUI

// MARK: - Stress Character Card (Figma Design)

/// Character-based stress visualization matching Figma design.
/// When `result` is non-nil, shows Stress Buddy mascot.
/// When `result` is nil, shows embedded `PermissionCardView` for health access.
/// - Dashboard: Flexible width, content-based height
/// - Widget: Fixed 354px height
/// - watchOS: Fixed 180px height
struct StressCharacterCard: View {
    let result: StressResult?
    let size: StressBuddyMood.CharacterContext
    var isRequestingAccess: Bool = false
    let onGrantAccess: (() -> Void)?
    let onSettingsTapped: (() -> Void)?

    // Computed from result
    var mood: StressBuddyMood {
        StressBuddyMood.from(stressLevel: result?.level ?? 0)
    }

    var stressLevel: Double { result?.level ?? 0 }
    var hrv: Double? { result?.hrv }
    private var lastUpdated: Date? { result?.timestamp }

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
        VStack(spacing: 0) {
            DateHeaderView(date: lastUpdated ?? Date(), onSettingsTapped: onSettingsTapped)

            Spacer()

            if result != nil {
                characterView
            } else {
                PermissionCardView(
                    permissionType: .healthKit,
                    isLoading: isRequestingAccess,
                    embedded: true,
                    onGrantAccess: onGrantAccess ?? {}
                )
            }

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Character View

    @ViewBuilder
    private var characterView: some View {
        ZStack {
            StressBuddyIllustration(mood: mood, size: characterSize)
        }
        .accessibilityHidden(true)
    }

    /// Character size based on context
    private var characterSize: CGFloat {
        switch size {
        case .dashboard: return 126
        case .widget: return 100
        case .watchOS: return 60
        }
    }

    // MARK: - Layout Helpers

    private var cardHeight: CGFloat? {
        switch size {
        case .dashboard: return nil
        case .widget: return 354
        case .watchOS: return 180
        }
    }

    private var moodColor: Color {
        switch mood {
        case .sleeping, .calm:
            return Color.Wellness.exerciseCyan
        case .concerned:
            return Color.Wellness.daylightYellow
        case .worried:
            return Color.stressModerate
        case .overwhelmed:
            return Color.stressHigh
        }
    }

    private var accessibilityLabel: String {
        guard let result = result else {
            return "Health access required. Grant access to read your health data for stress monitoring."
        }
        var timeText = ""
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        timeText = "Last updated \(formatter.localizedString(for: result.timestamp, relativeTo: Date()))"
        return "\(mood.accessibilityDescription). Stress level: \(Int(result.level)). \(timeText)"
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

#Preview("All Moods - Dashboard") {
    ScrollView {
        VStack(spacing: 24) {
            ForEach([0.0, 5.0, 15.0, 35.0, 60.0, 85.0], id: \.self) { level in
                StressCharacterCard(
                    result: StressResult(
                        level: level,
                        category: .relaxed,
                        confidence: 0.9,
                        hrv: 65,
                        heartRate: 72
                    ),
                    size: .dashboard
                )
            }
        }
        .padding()
        .background(Color.Wellness.adaptiveBackground)
    }
}

#Preview("Permission State") {
    StressCharacterCard(
        result: nil as StressResult?,
        size: .dashboard,
        onGrantAccess: {}
    )
    .padding()
    .background(Color.Wellness.adaptiveBackground)
}
