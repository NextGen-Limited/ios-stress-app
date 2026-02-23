import SwiftUI

/// Pill-shaped status badge that displays stress category with dynamic color
struct StatusBadgeView: View {
    let category: StressCategory
    var style: BadgeStyle = .standard

    enum BadgeStyle {
        case standard
        case compact
        case large
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.stressColor(for: category))
                .frame(width: indicatorSize, height: indicatorSize)

            Text(category.displayName.uppercased())
                .font(font)
                .fontWeight(.medium)
                .foregroundColor(Color.stressColor(for: category))
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(Color.stressColor(for: category).opacity(0.15))
        .cornerRadius(cornerRadius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Stress status: \(category.displayName)")
    }

    // MARK: - Style-based Properties

    private var indicatorSize: CGFloat {
        switch style {
        case .standard: return 8
        case .compact: return 6
        case .large: return 10
        }
    }

    private var font: Font {
        switch style {
        case .standard: return .caption
        case .compact: return .caption2
        case .large: return .subheadline
        }
    }

    private var horizontalPadding: CGFloat {
        switch style {
        case .standard: return 12
        case .compact: return 8
        case .large: return 16
        }
    }

    private var verticalPadding: CGFloat {
        switch style {
        case .standard: return 6
        case .compact: return 4
        case .large: return 8
        }
    }

    private var cornerRadius: CGFloat {
        switch style {
        case .standard: return 20
        case .compact: return 12
        case .large: return 24
        }
    }
}

#Preview("Status Badge Variations") {
    VStack(spacing: 16) {
        ForEach(StressCategory.allCases, id: \.self) { category in
            StatusBadgeView(category: category)
        }

        Divider()

        HStack(spacing: 12) {
            StatusBadgeView(category: .relaxed, style: .compact)
            StatusBadgeView(category: .mild, style: .standard)
            StatusBadgeView(category: .high, style: .large)
        }
    }
    .padding()
    .background(Color.oledBackground)
}
