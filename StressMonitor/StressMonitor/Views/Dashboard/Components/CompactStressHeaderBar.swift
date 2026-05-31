import SwiftUI

/// Collapsed header bar shown when ScalingHeaderScrollView is fully collapsed.
/// Displays date on the left and a stress category badge capsule on the right.
struct CompactStressHeaderBar: View {
    let date: Date
    let stressLevel: Double
    let stressCategory: StressCategory

    init(date: Date, stressLevel: Double, stressCategory: StressCategory) {
        self.date = date
        self.stressLevel = stressLevel
        self.stressCategory = stressCategory
    }

    init(result: StressResult) {
        self.date = result.timestamp
        self.stressLevel = result.level
        self.stressCategory = result.category
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(formattedDate)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                .lineLimit(1)

            Spacer()

            stressBadge
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(Color.Wellness.adaptiveCardBackground)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(formattedDate). \(stressCategory.rawValue.capitalized), stress level \(Int(stressLevel))")
    }

    private var stressBadge: some View {
        HStack(spacing: 6) {
            Text(stressCategory.rawValue.capitalized)
            Text("\(Int(stressLevel))")
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(stressCategory.color)
        )
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Previews

#Preview("All categories") {
    VStack(spacing: 0) {
        CompactStressHeaderBar(date: Date(), stressLevel: 18, stressCategory: .relaxed)
        Divider()
        CompactStressHeaderBar(date: Date(), stressLevel: 36, stressCategory: .mild)
        Divider()
        CompactStressHeaderBar(date: Date(), stressLevel: 58, stressCategory: .moderate)
        Divider()
        CompactStressHeaderBar(date: Date(), stressLevel: 82, stressCategory: .high)
    }
    .background(Color.Wellness.adaptiveBackground)
}

#Preview("Dark mode") {
    CompactStressHeaderBar(date: Date(), stressLevel: 82, stressCategory: .high)
        .preferredColorScheme(.dark)
}
