import SwiftUI

struct StatCard: View {
    let icon: String
    let value: String
    var unit: String?
    let label: String
    var tintColor: Color = .primaryBlue
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(tintColor)
                .frame(width: 44, height: 44)
                .background(tintColor.opacity(0.15))
                .cornerRadius(12)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(Typography.dataSmall)
                    .foregroundColor(.primary)

                if let unit = unit {
                    Text(unit)
                        .font(Typography.caption1)
                        .foregroundColor(.secondary)
                }
            }

            Text(label)
                .font(Typography.caption1)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.cellPadding)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
        )
        .contentShape(Rectangle())
        .modifier(ActionModifier(action: action))
    }
}

private struct ActionModifier: ViewModifier {
    let action: (() -> Void)?

    func body(content: Content) -> some View {
        if let action = action {
            content.onTapGesture(perform: action)
        } else {
            content
        }
    }
}
