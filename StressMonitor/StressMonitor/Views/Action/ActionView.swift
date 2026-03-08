import SwiftUI

/// Action view - Quick actions and wellness activities screen
/// Implements Figma design: Action (demo)
struct ActionView: View {
    @State private var selectedDay: Int = 0
    @State private var currentDate = Date()

    private let calendar = Calendar.current
    private let weekDays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 1. Date Header
                    dateHeader

                    // 2. Week Selector
                    weekSelector

                    // 3. Upgrade Popup
                    upgradePopup

                    // 4. Quote Card
                    quoteCard

                    // 5. From Your Watch - Health Section
                    healthSection

                    // 6. Activity Grid
                    activityGrid

                    // 7. Quick Actions
                    quickActionsSection

                    // 8. AI Chat
                    aiChatCard

                    // 9. Recommendations
                    recommendationsCard

                    // Bottom padding
                    Spacer()
                        .frame(height: 100)
                }
                .padding(.horizontal, 16)
            }
            .background(Color.Wellness.adaptiveBackground)
            .navigationTitle("Action")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dayOfWeek)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)

                Text(formattedDate)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }

            Spacer()

            Button {
                // Settings action
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Week Selector

    private var weekSelector: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { index in
                Circle()
                    .fill(index == selectedDay ? Color.Wellness.calmBlue : Color.Wellness.adaptiveCardBackground)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(weekDays[index])
                            .font(.system(size: 14, weight: index == selectedDay ? .semibold : .regular))
                            .foregroundStyle(index == selectedDay ? .white : Color.Wellness.adaptiveSecondaryText)
                    )
            }
        }
    }

    // MARK: - Upgrade Popup

    private var upgradePopup: some View {
        HStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 24))
                .foregroundStyle(Color.Wellness.insightTitle)

            VStack(alignment: .leading, spacing: 2) {
                Text("Upgrade to Premium")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)

                Text("Unlock all features")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Wellness.adaptiveCardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Quote Card

    private var quoteCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\"The greatest glory in living lies not in never falling, but in rising every time we fall.\"")
                .font(.system(size: 15, weight: .medium))
                .italic()
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                .lineSpacing(4)

            Text("Nelson Mandela")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Wellness.adaptiveCardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Health Section

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("From your watch")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)

            // Sleep Card
            healthCard(
                icon: "moon.fill",
                title: "Sleep",
                duration: "8h 30m",
                quality: "Excellent",
                rhr: "58",
                color: Color.Wellness.sleepPurple
            )

            // Exercise Card
            healthCard(
                icon: "figure.run",
                title: "Exercise",
                duration: "45m",
                standing: "12h",
                calories: "850",
                color: Color.Wellness.exerciseCyan
            )
        }
    }

    private func healthCard(
        icon: String,
        title: String,
        duration: String,
        quality: String? = nil,
        rhr: String? = nil,
        standing: String? = nil,
        calories: String? = nil,
        color: Color
    ) -> some View {
        HStack(spacing: 16) {
            // Icon circle
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 53, height: 53)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(color)
                )

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)

                Text(duration)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }

            Spacer()

            // Right side metrics
            HStack(spacing: 16) {
                if let quality = quality {
                    metricColumn(title: "Quality", value: quality)
                }
                if let rhr = rhr {
                    metricColumn(title: "RHR", value: rhr)
                }
                if let standing = standing {
                    metricColumn(title: "Standing", value: standing)
                }
                if let calories = calories {
                    metricColumn(title: "Calories", value: calories)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Wellness.adaptiveCardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    private func metricColumn(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)

            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)
        }
    }

    // MARK: - Activity Grid

    private var activityGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                activityTile(
                    icon: "leaf.fill",
                    title: "Mindfulness",
                    value: "25m",
                    color: Color.Wellness.healthGreen
                )

                activityTile(
                    icon: "waveform",
                    title: "Noise",
                    value: "High",
                    color: Color.Wellness.exerciseCyan
                )

                activityTile(
                    icon: "sun.max.fill",
                    title: "Daylight",
                    value: "45m",
                    color: Color.Wellness.daylightYellow
                )

                activityTile(
                    icon: "figure.walk",
                    title: "Steps",
                    value: "4,500",
                    color: Color.Wellness.calmBlue
                )
            }
        }
    }

    private func activityTile(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)

                Spacer()
            }

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)

            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
        }
        .padding(16)
        .frame(height: 108)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Wellness.adaptiveCardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Action")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    QuickActionCard.boxBreathing()
                    QuickActionCard.miniWalk()
                    QuickActionCard.gratitude()
                }
            }
        }
    }

    // MARK: - AI Chat Card

    private var aiChatCard: some View {
        HStack(spacing: 16) {
            // Cat avatar
            Circle()
                .fill(Color.Wellness.gentlePurple.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Text("🐱")
                        .font(.system(size: 40))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("AI Chat")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)

                Text("Talk with AI Kitten")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)

                Text("\"It's always better to talk to your support group. If you need, Kitten is here for you!\"")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Wellness.adaptiveCardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Recommendations Card

    private var recommendationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recommendations:")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)

                Spacer()

                HStack(spacing: 4) {
                    Text("FAQ")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText)

                    Image(systemName: "chevron.up.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                }
            }

            Text("Dorem ipsum dolor sit amet consectetur adipiscing elit Nunc vulputate libero et velit interdum ac aliquet odio mattis.")
                .font(.system(size: 15))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Wellness.adaptiveCardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Computed Properties

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: currentDate)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: currentDate)
    }
}

// MARK: - Previews

#Preview {
    ActionView()
}

#Preview("Dark Mode") {
    ActionView()
        .preferredColorScheme(.dark)
}
