import SwiftUI

// MARK: - ActionView (Ripple Redesign)
// Dark-canvas redesign with Ripple character as AI coach.
// 8 sections: Calendar → Daily Focus → Ripple Coach → Bento Health → Quick Actions → Recommendations → Premium → Chat CTA

struct ActionView: View {
    @Environment(TabBarScrollState.self) private var tabBarScrollState
    @State private var selectedDay: Int = 6 // Today (last in week array)
    @State private var currentDate = Date()
    @State private var isChatPresented = false

    private let calendar = Calendar.current

    /// Mock mood data — each day gets a stress level that maps to a color.
    /// In production this would come from a ViewModel.
    private let weekMoods: [MoodLevel] = [.calm, .calm, .balanced, .stressed, .calm, .balanced, .calm]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Week Calendar with Mood Dots
                    moodCalendar

                    // 2. Daily Focus Hero (replaces Quote Card)
                    dailyFocusHero

                    // 3. Ripple AI Coach (replaces AIChatCard)
                    rippleCoachCard

                    // 4. Bento Health Grid (replaces 2 healthCard rows)
                    bentoHealthGrid

                    // 5. Quick Actions (upgraded — 4 cards)
                    quickActionsSection

                    // 6. Ripple's Recommendations (replaces lorem ipsum)
                    recommendationsSection

                    // 7. Premium Card (consistent with Settings)
                    premiumCard

                    // Bottom padding for tab bar
                    Spacer()
                        .frame(height: tabBarScrollState.tabBarHeight + 16)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .trackScrollOffsetForTabBar(state: tabBarScrollState)
            .background(HomeCharacterDesignTokens.darkCanvas)
            .navigationTitle("Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $isChatPresented) {
                ChatBottomSheetView(stressResult: nil, baseline: nil)
            }
        }
    }

    // MARK: - 1. Mood Calendar

    private var moodCalendar: some View {
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { index in
                VStack(spacing: 6) {
                    Text(weekdayLetter(for: index))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(isSelected(index) ? .white : HomeCharacterDesignTokens.mutedInk)

                    Text(dayNumber(for: index))
                        .font(.system(size: 16, weight: isSelected(index) ? .bold : .semibold, design: .rounded))
                        .foregroundStyle(isSelected(index) ? .white : Color(hex: "#E8E8F0"))

                    // Mood dot
                    Circle()
                        .fill(weekMoods[index].color)
                        .frame(width: 7, height: 7)
                        .opacity(isSelected(index) ? 1.0 : 0.6)
                }
                .frame(width: 38, height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected(index) ? HomeCharacterDesignTokens.Ripple.primary.opacity(0.2) : .clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected(index) ? HomeCharacterDesignTokens.Ripple.primary.opacity(0.6) : .clear, lineWidth: 1.5)
                        )
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedDay = index
                    }
                }
            }
        }
    }

    // MARK: - 2. Daily Focus Hero

    private var dailyFocusHero: some View {
        ZStack(alignment: .topTrailing) {
            // Ghosted Ripple in background
            Text("💧")
                .font(.system(size: 120))
                .opacity(0.06)
                .offset(x: 20, y: -20)

            VStack(alignment: .leading, spacing: 10) {
                // Label
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                    Text("DAILY FOCUS")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.0)
                }
                .foregroundStyle(HomeCharacterDesignTokens.Ripple.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(HomeCharacterDesignTokens.Ripple.primary.opacity(0.12), in: Capsule())

                // Insight text
                Text("Ripple noticed your stress peaked at 3 PM yesterday")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "#E8E8F0"))
                    .lineSpacing(3)

                // Suggested action
                HStack(spacing: 10) {
                    Image(systemName: "wind")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            LinearGradient(
                                colors: [HomeCharacterDesignTokens.Ripple.primary, HomeCharacterDesignTokens.Ripple.deep],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 12)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Box Breathing 4-4-4-4")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("2 min · Calms nervous system")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(HomeCharacterDesignTokens.mutedInk)
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(HomeCharacterDesignTokens.Ripple.primary)
                }
                .padding(12)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
            }
            .padding(18)
        }
        .background(HomeCharacterDesignTokens.darkCard, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    // MARK: - 3. Ripple AI Coach Card

    private var rippleCoachCard: some View {
        Button(action: { isChatPresented = true }) {
            HStack(spacing: 14) {
                // Ripple avatar with online pulse
                ZStack {
                    Circle()
                        .fill(HomeCharacterDesignTokens.Ripple.primary.opacity(0.15))
                        .frame(width: 52, height: 52)

                    Text("💧")
                        .font(.system(size: 28))

                    // Online pulse
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(HomeCharacterDesignTokens.darkCard, lineWidth: 2))
                        .offset(x: 18, y: 18)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Ripple")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Your HRV improved 8% this week!")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(HomeCharacterDesignTokens.mutedInk)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(HomeCharacterDesignTokens.Ripple.primary.opacity(0.8))
            }
            .padding(16)
            .background(HomeCharacterDesignTokens.darkCard, in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 4. Bento Health Grid

    private var bentoHealthGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
        ], spacing: 10) {
            // Sleep — wide tile spanning all columns
            bentoSleepTile
                .gridCellColumns(3)

            // Exercise
            bentoTile(icon: "figure.run", title: "Exercise", value: "45m", subtitle: "Goal", color: HomeCharacterDesignTokens.Blossom.accent)

            // Mindfulness
            bentoTile(icon: "leaf.fill", title: "Mindful", value: "25m", subtitle: "Today", color: HomeCharacterDesignTokens.Lumi.accent)

            // Steps
            bentoTile(icon: "figure.walk", title: "Steps", value: "4,500", subtitle: "Goal 10k", color: HomeCharacterDesignTokens.Ripple.primary)

            // Daylight — spans 2 columns
            bentoTile(icon: "sun.max.fill", title: "Daylight", value: "45m", subtitle: "Outside", color: HomeCharacterDesignTokens.Ember.accent)
                .gridCellColumns(2)
        }
    }

    private var bentoSleepTile: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "moon.fill")
                .font(.system(size: 18))
                .foregroundStyle(HomeCharacterDesignTokens.Ripple.light)
                .frame(width: 38, height: 38)
                .background(HomeCharacterDesignTokens.Ripple.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text("Sleep")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(HomeCharacterDesignTokens.mutedInk)
                Text("8h 30m · RHR 58")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Spacer()

            // Progress bar
            VStack(alignment: .trailing, spacing: 4) {
                Text("92%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(HomeCharacterDesignTokens.Blossom.primary)
                ProgressView(value: 0.92)
                    .frame(width: 70)
                    .tint(HomeCharacterDesignTokens.Blossom.primary)
            }
        }
        .padding(14)
        .background(HomeCharacterDesignTokens.darkCard, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }

    private func bentoTile(icon: String, title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(HomeCharacterDesignTokens.mutedInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(HomeCharacterDesignTokens.darkCard, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }

    // MARK: - 5. Quick Actions (upgraded — 4 cards)

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Actions")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
            ], spacing: 10) {
                actionCard(icon: "wind", title: "Box Breathing", duration: "2 min", streak: 3, color: HomeCharacterDesignTokens.Ripple.primary)
                actionCard(icon: "figure.walk", title: "Mini Walk", duration: "5 min", streak: 1, color: HomeCharacterDesignTokens.Blossom.accent)
                actionCard(icon: "heart.fill", title: "Gratitude", duration: "1 min", streak: 5, color: HomeCharacterDesignTokens.Lumi.accent)
                actionCard(icon: "moon.zzz.fill", title: "Wind Down", duration: "10 min", streak: 0, color: HomeCharacterDesignTokens.Zephyr.accent)
            }
        }
    }

    private func actionCard(icon: String, title: String, duration: String, streak: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(color.gradient, in: RoundedRectangle(cornerRadius: 10))

                Spacer()

                // Streak dots
                if streak > 0 {
                    HStack(spacing: 3) {
                        ForEach(0..<min(streak, 5), id: \.self) { _ in
                            Circle()
                                .fill(color.opacity(0.7))
                                .frame(width: 5, height: 5)
                        }
                    }
                }
            }

            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(duration)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(HomeCharacterDesignTokens.mutedInk)
        }
        .padding(14)
        .background(HomeCharacterDesignTokens.darkCard, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }

    // MARK: - 6. Ripple's Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("💧")
                    .font(.system(size: 16))
                Text("Ripple's Recommendations")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 8) {
                recommendationRow(icon: "sun.max.fill", title: "Afternoon Sun Break", description: "10 min outside to reset cortisol", tag: "Energy", color: HomeCharacterDesignTokens.Ember.accent)
                recommendationRow(icon: "bed.double.fill", title: "Earlier Wind-Down", description: "Aim for bed by 10:30 PM tonight", tag: "Sleep", color: HomeCharacterDesignTokens.Ripple.light)
                recommendationRow(icon: "drop.fill", title: "Hydration Check", description: "You're 3 glasses below target", tag: "Body", color: HomeCharacterDesignTokens.Ripple.primary)
            }
        }
    }

    private func recommendationRow(icon: String, title: String, description: String, tag: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(HomeCharacterDesignTokens.mutedInk)
            }

            Spacer()

            Text(tag)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.1), in: Capsule())
        }
        .padding(12)
        .background(HomeCharacterDesignTokens.darkCard, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }

    // MARK: - 7. Premium Card

    private var premiumCard: some View {
        Button(action: {}) {
            HStack(spacing: 14) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#FFD700"), .premiumGold],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Go Premium")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.premiumGold)
                    Text("Unlock advanced insights & AI coaching")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(HomeCharacterDesignTokens.mutedInk)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.premiumGold.opacity(0.6))
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "#1A1A2E"),
                        Color(hex: "#1E1A14"), // Warm tint for gold
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(hex: "#FFD700").opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func isSelected(_ index: Int) -> Bool {
        index == selectedDay
    }

    private func weekdayLetter(for index: Int) -> String {
        let letters = ["S", "M", "T", "W", "T", "F", "S"]
        return letters[index]
    }

    private func dayNumber(for index: Int) -> String {
        guard let date = calendar.date(byAdding: .day, value: index - 6, to: currentDate) else { return "" }
        return "\(calendar.component(.day, from: date))"
    }
}

// MARK: - Mood Level

extension ActionView {
    enum MoodLevel {
        case calm
        case balanced
        case stressed

        var color: Color {
            switch self {
            case .calm:     return HomeCharacterDesignTokens.Blossom.primary // Green
            case .balanced: return HomeCharacterDesignTokens.Ripple.primary   // Blue
            case .stressed: return HomeCharacterDesignTokens.Ember.primary    // Orange
            }
        }
    }
}

// MARK: - Previews

#Preview {
    ActionView()
        .environment(TabBarScrollState())
}

#Preview("Dark Mode") {
    ActionView()
        .preferredColorScheme(.dark)
        .environment(TabBarScrollState())
}
