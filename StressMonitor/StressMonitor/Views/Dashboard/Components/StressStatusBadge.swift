import SwiftUI

/// Status badge component for displaying stress status
struct StressStatusBadge: View {
    let status: String
    let color: Color

    init(status: String, color: Color = Color.Wellness.elevatedBadge) {
        self.status = status
        self.color = color
    }

    var body: some View {
        Text(status)
            .font(.system(size: 22, weight: .semibold))
            .foregroundColor(color)
            .accessibilityLabel("Stress status: \(status)")
    }
}

#Preview("StressStatusBadge") {
    VStack(spacing: 16) {
        StressStatusBadge(status: "Stressed")
        StressStatusBadge(status: "Relaxed", color: Color.Wellness.tealCard)
        StressStatusBadge(status: "Elevated", color: Color.Wellness.elevatedBadge)
    }
    .padding()
    .background(Color.Wellness.adaptiveBackground)
}
