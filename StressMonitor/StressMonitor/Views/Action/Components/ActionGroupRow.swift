import SwiftUI

/// iOS grouped-list row for the Breathe / Move / Reflect sections of the Action tab.
///
/// SF Symbol icon tile + title + subtitle + trailing chevron, wired as a
/// NavigationLink so the parent NavigationStack pushes `Destination`. Reusable
/// across all three groups.
struct ActionGroupRow<Destination: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tint.opacity(0.14))
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tint)
                }
                .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.6))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.Wellness.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.Wellness.adaptiveSecondaryText.opacity(0.10), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityHint("Double tap to open")
    }
}

#Preview("ActionGroupRow") {
    NavigationStack {
        VStack(spacing: 10) {
            ActionGroupRow(
                icon: "wind",
                title: "Box Breathing",
                subtitle: "4-4-4-4 · 2 min",
                tint: HomeCharacterDesignTokens.Ripple.primary,
                destination: { Text("Box Breathing") }
            )
            ActionGroupRow(
                icon: "figure.walk",
                title: "Mini Walk",
                subtitle: "5 min reset",
                tint: HomeCharacterDesignTokens.Blossom.accent,
                destination: { Text("Mini Walk") }
            )
            Spacer()
        }
        .padding()
        .background(HomeCharacterDesignTokens.homeBackground)
    }
}
