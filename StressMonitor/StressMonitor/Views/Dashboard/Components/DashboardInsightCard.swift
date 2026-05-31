import SwiftUI

/// AI insight card for dashboard with title and description
struct DashboardInsightCard: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.Wellness.insightTitle)

            Text(description)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color.Wellness.insightText)
                .lineLimit(nil)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Wellness.adaptiveCardBackground)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Insight: \(title). \(description)")
    }
}

#Preview("DashboardInsightCard") {
    VStack {
        DashboardInsightCard(
            title: "Daily Insight",
            description: "Your stress levels have been lower this week. Keep up the good work with your breathing exercises."
        )
        Spacer()
    }
    .padding()
    .background(Color.Wellness.adaptiveBackground)
}
