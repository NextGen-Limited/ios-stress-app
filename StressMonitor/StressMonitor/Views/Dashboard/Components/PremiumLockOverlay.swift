import SwiftUI

// MARK: - Premium Lock Overlay

/// Semi-transparent overlay that indicates premium-only features
/// Displays lock icon and upgrade button when user is not premium
struct PremiumLockOverlay: View {
    var onUpgrade: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.white.opacity(0.63)
                .ignoresSafeArea()

            // Lock button
            Button {
                onUpgrade?()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .semibold))

                    Text("Unlock with Premium")
                        .font(Typography.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color(hex: "#1A1A1A"))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(hex: "#FFD380"))
                .cornerRadius(20)
            }
            .buttonStyle(.plain)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Premium feature locked. Tap to unlock with Premium subscription.")
    }
}

// MARK: - Preview

#Preview("Premium Lock Overlay") {
    ZStack {
        Color.gray.opacity(0.3)
            .frame(width: 358, height: 376)

        PremiumLockOverlay()
    }
    .padding()
}
