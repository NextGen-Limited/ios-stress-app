import SwiftUI

/// Home Dashboard View
/// Figma: Action (demo) screen - 390pt width iPhone frame
/// Full scrollable dashboard with all components
struct HomeDashboardView: View {
    @Environment(TabBarScrollState.self) private var tabBarScrollState
    @State private var selectedDate = Date()
    @State private var quickActionOffset: CGFloat = 0
    var dataQualityInfo: DataQualityInfo? = nil

    private let quickActions: [(title: String, description: String, duration: String, color: Color)] = [
        ("Box Breathing", "Small description about the activity", "3 mins", Color.Wellness.boxBreathingPurple),
        ("Mini walk", "Small description about the activity", "3 mins", Color.Wellness.miniWalkBlue),
        ("Gratitude", "Small description about the activity", "0:45s", Color.Wellness.gratitudePurple)
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Header: Date + Settings
                headerSection
                    .padding(.top, 60) // Status bar offset
                    .padding(.horizontal, 16)

                // Week Calendar Strip
                WeekCalendarStrip(selectedDate: $selectedDate)
                    .padding(.top, 16)
                    .frame(width: 358)

                // Widget Promo Card
                WidgetPromoCard()
                    .padding(.top, 14)
                    .padding(.horizontal, 16)

                // Quote Card
                QuoteCard(
                    quote: "The greatest glory in living lies not in never falling, but in rising every time we fall.",
                    author: "Nelson Mandela"
                )
                .padding(.top, 14)
                .padding(.horizontal, 16)

                // Self Note Card
                SelfNoteCard()
                    .padding(.top, 16)
                    .padding(.horizontal, 16)

                // Section: From your watch
                HStack {
                    sectionHeader(title: "From your watch")
                    Spacer()
                    if let quality = dataQualityInfo {
                        DataQualityBadge(qualityInfo: quality)
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)

                // Watch Metric Cards
                VStack(spacing: 16) {
                    WatchMetricCard.sleep(
                        duration: "00h00m",
                        quality: "Excellent",
                        rhr: "50"
                    )

                    WatchMetricCard.exercise(
                        duration: "00h00m",
                        standing: "50m",
                        calories: "1000"
                    )
                }
                .padding(.top, 14)
                .padding(.horizontal, 16)

                // Health Stats Grid
                HealthStatsGrid()
                    .padding(.top, 10.6)
                    .padding(.horizontal, 16)

                // Layout hint text
                layoutHintSection
                    .padding(.top, 16)
                    .padding(.horizontal, 16)

                // Section: Quick Action
                sectionHeader(title: "Quick Action")
                    .padding(.top, 16)
                    .padding(.horizontal, 16)

                // Quick Action Cards (Horizontal Scroll)
                quickActionSection
                    .padding(.top, 14)

                // AI Chat Card
                AIChatCard()
                    .padding(.top, 16)
                    .padding(.horizontal, 16)

                // Recommendations Card
                RecommendationsCard(
                    recommendations: [
                        "Dorem ipsum dolor sit amet",
                        "consectetur adipiscing elit",
                        "Nunc vulputate libero et velit interdum",
                        "ac aliquet odio mattis."
                    ]
                )
                .padding(.top, 16)
                .padding(.horizontal, 16)
                .padding(.bottom, tabBarScrollState.tabBarHeight + 16)
            }
        }
        .trackScrollOffsetForTabBar(state: tabBarScrollState)
        .background(Color.Wellness.adaptiveBackground)
        .ignoresSafeArea(edges: .vertical)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dayName)
                    .font(.custom("Roboto-Bold", size: 32))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                    .tracking(-0.48)

                Text(fullDate)
                    .font(.custom("Roboto-Bold", size: 16))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                    .tracking(-0.24)
            }
            .frame(width: 141, alignment: .leading)

            Spacer()

            Button(action: {}) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 23))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
            }
            .frame(width: 32, height: 32)
        }
    }

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: selectedDate)
    }

    private var fullDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: selectedDate)
    }

    // MARK: - Section Header

    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.custom("Roboto-Bold", size: 14))
                .foregroundStyle(.black)
                .tracking(-0.21)
            Spacer()
        }
    }

    // MARK: - Layout Hint Section

    private var layoutHintSection: some View {
        VStack(spacing: 7) {
            Text("Long press any card to drag and re-order.")
                .font(.custom("Roboto-Regular", size: 14))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                .tracking(-0.21)

            Button(action: {}) {
                Text("Reset Layout")
                    .font(.custom("Roboto-Bold", size: 14))
                    .foregroundStyle(Color.accentTeal)
                    .underline()
                    .tracking(-0.21)
            }
        }
    }

    // MARK: - Quick Action Section

    private var quickActionSection: some View {
        VStack(spacing: 0) {
            // Horizontal scroll with cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(quickActions.indices, id: \.self) { index in
                        let action = quickActions[index]
                        QuickActionCard(
                            title: action.title,
                            description: action.description,
                            duration: action.duration,
                            color: action.color,
                            destination: { PlaceholderDestination(title: action.title) }
                        )
                        .opacity(index == 0 ? 1.0 : (index == 1 ? 0.4 : 0.3))
                        .frame(width: 283)
                        .padding(.leading, index == 0 ? 16 : 0)
                        .padding(.trailing, index == quickActions.count - 1 ? 16 : 0)
                    }
                }
            }
            .frame(height: 98)
            .padding(.top, 0)

            // Page indicators
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(Color.accentTeal)
                        .frame(width: 24.695, height: 8)
                        .opacity(index == 0 ? 1.0 : 0.35)
                }
            }
            .padding(.top, 12)
        }
    }
}

// MARK: - Preview

#Preview("HomeDashboardView") {
    NavigationStack {
        HomeDashboardView()
    }
}
