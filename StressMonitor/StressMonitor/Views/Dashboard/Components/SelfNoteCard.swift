import SwiftUI

// MARK: - Self Note Card

/// Teal journal prompt card that opens NoteEntryView as a sheet
struct SelfNoteCard: View {
    @State private var isShowingNoteEntry = false

    var body: some View {
        Button(action: {
            HapticManager.shared.buttonPress()
            isShowingNoteEntry = true
        }) {
            HStack(spacing: DesignTokens.Spacing.md) {
                // Avatar placeholder circle
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    )

                // Text content
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("How was your day?")
                        .font(Typography.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("Tell me about it")
                        .font(Typography.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(DesignTokens.Layout.cardPadding)
            .background(Color.Wellness.tealCard)
            .cornerRadius(DesignTokens.Layout.cornerRadius)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Journal entry. How was your day? Tell me about it.")
        .accessibilityHint("Opens journal entry form")
        .sheet(isPresented: $isShowingNoteEntry) {
            NoteEntryView(isPresented: $isShowingNoteEntry)
        }
    }
}

// MARK: - Preview

#Preview {
    SelfNoteCard()
        .padding()
}
