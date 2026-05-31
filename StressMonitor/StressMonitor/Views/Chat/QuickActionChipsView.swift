import SwiftUI

// MARK: - Quick Action Chips View

/// Horizontal scrollable chips for suggested prompts
struct QuickActionChipsView: View {
    let actions: [ChatQuickAction]
    let onSelect: (ChatQuickAction) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(actions) { action in
                    Button {
                        onSelect(action)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: action.icon)
                                .font(.system(size: 12))
                            Text(action.title)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.Wellness.adaptiveCardBackground)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.Wellness.adaptiveSecondaryText.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
