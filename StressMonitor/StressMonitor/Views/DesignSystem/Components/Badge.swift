import SwiftUI

struct Badge: View {
    let text: String
    var color: Color = .primaryBlue
    var icon: String?

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(Typography.caption1)
            }

            Text(text)
                .font(Typography.caption1)
                .fontWeight(.semibold)
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .cornerRadius(12)
    }
}

struct StressBadge: View {
    let level: Double

    var body: some View {
        let category = StressCategory(from: level)
        Badge(
            text: category.displayName,
            color: Color.stressColor(for: category),
            icon: Color.stressIcon(for: category)
        )
    }
}
